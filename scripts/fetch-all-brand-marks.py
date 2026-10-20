#!/usr/bin/env python3
"""Keep a single unchanged, locally cached brand mark per brand."""
import concurrent.futures as cf,hashlib,json,pathlib,re,subprocess,tempfile,urllib.request
ROOT=pathlib.Path(__file__).resolve().parents[1]
slugs={'yidian':'yi-dian-dian','coco':'coco-dou-ke','chagee':'ba-wang-cha-ji','mixue':'mi-xue-bing-cheng','guming':'gu-ming','heytea':'xi-cha','nayuki':'nai-xue-de-cha','molly':'mo-li-nai-bai','chabaidao':'cha-bai-dao','auntie':'hu-shang-a-yi','chayan':'cha-yan-yue-se','luckin':'rui-xing-ka-fei'}
records=[]
for bid,slug in slugs.items():
 url=f'https://www.nckfhsm.com/brands/{slug}/menu/available'
 p=ROOT/'build'/'menu-cache'/(hashlib.sha256(url.encode()).hexdigest()+'.html')
 if not p.exists():continue
 for block in re.findall(r'<script[^>]*type=["\']application/ld\+json["\'][^>]*>(.*?)</script>',p.read_text(),re.S):
  d=json.loads(block)
  if d.get('@type')=='WebPage' and isinstance(d.get('primaryImageOfPage'),str):records.append({'brand':bid,'url':d['primaryImageOfPage'],'source':url,'file':f'brand-{bid}.png'})
def fetch(r):
 path=ROOT/'web'/'assets'/r['file']
 if path.exists():return r
 req=urllib.request.Request(r['url'],headers={'User-Agent':'TeaDiary brand identification'})
 data=urllib.request.urlopen(req,timeout=25).read()
 if data.startswith(b'\x89PNG\r\n\x1a\n'):path.write_bytes(data)
 else:
  with tempfile.TemporaryDirectory(prefix='tea-brand-') as td:
   original=pathlib.Path(td)/'source';original.write_bytes(data)
   subprocess.run(['sips','-s','format','png',str(original),'--out',str(path)],check=True,capture_output=True)
 print(r['brand'],'saved',flush=True);return r
with cf.ThreadPoolExecutor(max_workers=4) as pool:result=list(pool.map(fetch,records))
(ROOT/'web'/'assets'/'brand-sources-v11.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(len(result),'brand marks saved',flush=True)
