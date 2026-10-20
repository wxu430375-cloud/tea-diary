#!/usr/bin/env python3
"""Loopback-only portable preview. Uses Apple Vision or installed Tesseract offline."""
import base64, json, os, pathlib, shutil, subprocess, tempfile
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
ROOT = pathlib.Path(__file__).resolve().parent
class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()
    def do_POST(self):
        origin = self.headers.get('Origin', '')
        if origin and origin not in (f'http://127.0.0.1:{self.server.server_port}', f'http://localhost:{self.server.server_port}'):
            return self.respond(403, {'error':'来源不允许'})
        if self.path != '/api/ocr': return self.respond(404, {'error':'接口不存在'})
        try:
            length = int(self.headers.get('Content-Length', '0'))
            if not 0 < length < 20_000_000: return self.respond(413, {'error':'照片过大'})
            image = json.loads(self.rfile.read(length))['image']
            if not image.startswith('data:image/jpeg;base64,'): raise ValueError('图片格式错误')
            data = base64.b64decode(image.split(',',1)[1], validate=True)
            with tempfile.TemporaryDirectory(prefix='tea-ocr-') as folder:
                path = pathlib.Path(folder)/'label.jpg'; path.write_bytes(data)
                helper = ROOT/'build'/'tea-ocr'
                if helper.exists() and os.uname().sysname == 'Darwin':
                    result = subprocess.run([str(helper),str(path)],capture_output=True,text=True,timeout=60,check=True)
                    return self.respond(200,json.loads(result.stdout))
                if shutil.which('tesseract'):
                    result = subprocess.run(['tesseract',str(path),'stdout','-l','chi_sim+eng'],capture_output=True,text=True,timeout=60,check=True)
                    return self.respond(200,{'text':result.stdout})
                return self.respond(503,{'error':'离线OCR尚未安装。Mac请使用安装包或运行构建脚本；其他系统需安装Tesseract及中文语言包。你也可以手动选择单品。'})
        except Exception:
            self.respond(400,{'error':'没有完成识别，请使用清晰的标签照片，或手动填写文字。'})
    def respond(self,status,value):
        data=json.dumps(value,ensure_ascii=False).encode();self.send_response(status);self.send_header('Content-Type','application/json; charset=utf-8');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
if __name__=='__main__':
    port=int(os.environ.get('TEA_PORT','8765'))
    server=ThreadingHTTPServer(('127.0.0.1',port),partial(Handler,directory=str(ROOT/'web')))
    print(f'茶茶手账 http://127.0.0.1:{port}',flush=True)
    server.serve_forever()
