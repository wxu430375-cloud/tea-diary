#!/usr/bin/env python3
"""Download public identification marks. Third-party trademark rights are reserved."""
import urllib.request,re,pathlib,json
ROOT=pathlib.Path(__file__).resolve().parents[1]/'web'/'assets'
records=[]
for name,url in [('coco','https://www.coco-tea.com.cn/static/portal/images/logo.png'),('yidian','https://www.alittle-tea.com/images/cm.png')]:
 try:
  data=urllib.request.urlopen(url,timeout=20).read(); (ROOT/f'logo-{name}.png').write_bytes(data);records.append({'brand':name,'url':url})
  print(name,'saved')
 except Exception as e: print(name,type(e).__name__)
try:
 url='https://www.chagee.com.sg/zh-sg/product/fresh-milk-tea-series'
 html=urllib.request.urlopen(url,timeout=20).read().decode()
 match=re.search(r'logo-width[^>]*>\s*(<svg\b.*?</svg>)',html,re.S)
 if match:
  svg=match.group(1).replace('<svg ','<svg xmlns="http://www.w3.org/2000/svg" fill="#9b453c" ')
  (ROOT/'logo-chagee.svg').write_text(svg);records.append({'brand':'chagee','url':url});print('chagee saved')
except Exception as e: print('chagee',type(e).__name__)
(ROOT/'brand-sources.json').write_text(json.dumps(records,ensure_ascii=False,indent=2))
