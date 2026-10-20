#!/usr/bin/env python3
"""Collect factual product/ingredient summaries, never reviews or full descriptions."""
import concurrent.futures as cf,hashlib,html,json,pathlib,re,time,urllib.request
ROOT=pathlib.Path(__file__).resolve().parents[1];CACHE=ROOT/'build'/'menu-cache';CACHE.mkdir(parents=True,exist_ok=True)
BRANDS=[('yidian','一点点','yi-dian-dian'),('coco','CoCo都可','coco-dou-ke'),('chagee','霸王茶姬','ba-wang-cha-ji'),('mixue','蜜雪冰城','mi-xue-bing-cheng'),('guming','古茗','gu-ming'),('heytea','喜茶','xi-cha'),('nayuki','奈雪的茶','nai-xue-de-cha'),('molly','茉莉奶白','mo-li-nai-bai'),('chabaidao','茶百道','cha-bai-dao'),('auntie','沪上阿姨','hu-shang-a-yi'),('chayan','茶颜悦色','cha-yan-yue-se'),('luckin','瑞幸咖啡','rui-xing-ka-fei')]
def get(url):
 p=CACHE/(hashlib.sha256(url.encode()).hexdigest()+'.html')
 if p.exists():return p.read_text()
 for attempt in range(2):
  try:
   req=urllib.request.Request(url,headers={'User-Agent':'TeaDiary catalog source verification'})
   text=urllib.request.urlopen(req,timeout=25).read().decode('utf-8','replace');p.write_text(text);return text
  except Exception:
   if attempt:raise
   time.sleep(.4)
def ld(text):
 for part in re.findall(r'<script[^>]*type=["\']application/ld\+json["\'][^>]*>(.*?)</script>',text,re.S):
  try:
   value=json.loads(part)
   for d in value if isinstance(value,list) else [value]:
    if isinstance(d,dict):yield d
  except ValueError:pass
def clean_name(name):return re.sub(r'\s+','',re.sub(r'[（(](?:原创|首创|升级|首发|超大杯|特大杯|大杯|中杯)[）)]','',name)).strip()
def norm(name):return re.sub(r'[\s·・の\-—_.,，。:：()（）]','',clean_name(name).lower())
def menu(brand):
 bid,name,slug=brand;items=[];icon=None;seen={}
 for page in range(1,4 if bid!='luckin' else 12):
  url=f'https://www.nckfhsm.com/brands/{slug}/menu/available'+(f'?page={page}' if page>1 else '')
  try:
   text=get(url)
   for d in ld(text):
    if d.get('@type')=='WebPage' and page==1:icon=d.get('primaryImageOfPage')
    if d.get('@type')=='ItemList':
     for v in d.get('itemListElement',[]):
      i=v.get('item',{});raw=i.get('name','');key=norm(raw)
      if not key or not i.get('url') or any(t in raw for t in ['套餐','冰箱贴','保温','蛋挞','帆布袋','挂件','小样']):continue
      if key in seen:seen[key]['aliases'].append(raw);continue
      item={'brand':bid,'name':clean_name(raw),'aliases':[raw] if raw!=clean_name(raw) else [],'url':i['url']};seen[key]=item;items.append(item)
  except Exception as e:print('MENU FAILED',bid,page,type(e).__name__,flush=True)
 
 if bid=='luckin':
  staples=['生椰拿铁','拿铁','标准美式','美式咖啡','美式','厚乳拿铁','丝绒拿铁','椰云拿铁','酱香拿铁','香草拿铁','卡布奇诺','焦糖玛奇朵','摩卡','澳瑞白','陨石拿铁','橙C美式','冰吸生椰拿铁','小黄油拿铁']
  items.sort(key=lambda i:staples.index(i['name']) if i['name'] in staples else len(staples))
 items=items[:36 if bid!='luckin' else 80];print(bid,len(items),'discovered',flush=True);return brand,items,icon
MOTIFS=[('dragonfruit',['火龙果']),('grape',['葡萄','黑提','青提']),('berry',['草莓','莓莓','蔓越莓','杨梅','蓝莓']),('apple',['苹果']),('peach',['蜜桃','水蜜桃','桃桃']),('mango',['芒果','杨枝甘露','芒芒']),('lemon',['柠檬','香柠','青柠','柠C']),('orange',['橙','橘']),('rose',['玫瑰']),('longan',['龙眼']),('litchi',['荔枝','荔荔']),('cocoa',['可可','巧克力','黑巧','阿华田']),('pearl',['珍珠','波霸','三兄弟','血糯米','芋圆']),('flower',['茉莉','桂花','白兰','玉兰','栀子'])]
COLORS={'dragonfruit':'#e690b2','grape':'#b7a2cf','berry':'#e3a5ad','apple':'#b7ca82','peach':'#e3bcac','mango':'#e9c173','lemon':'#e4d78a','orange':'#e9ba78','rose':'#d5a7af','longan':'#d2cfaa','litchi':'#e0c5c3','cocoa':'#b18b6c','pearl':'#c9ac8b','flower':'#d2d8b4','milk':'#d6c7ad','tea':'#c6c58d','coffee-latte':'#c5a584','coffee-dark':'#a87d50','coconut-latte':'#dec7ad'}
def detail(item):
 try:
  text=get(item['url']);product=next((d for d in ld(text) if d.get('@type')=='Product'),{})
  expected=next(n for i,n,s in BRANDS if i==item['brand'])
  if product.get('brand',{}).get('name')!=expected:raise ValueError('Brand mismatch')
  ingredients=[]
  for prop in product.get('additionalProperty',[]):
   if prop.get('name') in ['原料','主要原料','配料']:ingredients+=re.split(r'[,，、;；+＋\n]',str(prop.get('value','')))
  intro=re.search(r'>介绍</div>\s*<div[^>]*>(.*?)</div>',text,re.S)
  if intro:
   first=html.unescape(re.sub('<[^>]*>','',intro.group(1))).strip().split('\n\n')[0].strip()
   if len(first)<90 and re.search('[、+＋]',first) and not re.search('[。！？!]',first):ingredients+=re.split(r'[,，、+＋]',first)
  ingredients=list(dict.fromkeys(re.sub(r'^含[:：]','',i.strip()) for i in ingredients if i.strip()))[:10]
  ingredients=[i for i in ingredients if len(i)<45 and not any(t in i for t in ['参考','温馨','图片','推荐','标签','以实物'])]
  motif=next((m for m,tokens in MOTIFS if any(t in item['name'] for t in tokens)),'milk')
  if item['brand']=='luckin' and any(t in item['name'] for t in ['拿铁','美式','冷萃','咖啡','澳瑞白','卡布奇诺','摩卡','康宝蓝']):motif='coconut-latte' if '椰' in item['name'] else 'coffee-dark' if any(t in item['name'] for t in ['美式','冷萃']) else 'coffee-latte'
  elif motif=='milk' and any(t in item['name'] for t in ['纯茶','红茶','绿茶','春茶','乌龙','观音','折桂令','山茶']):motif='tea'
  return {'id':'menu-'+hashlib.sha256((item['brand']+':'+norm(item['name'])).encode()).hexdigest()[:16],'brand':item['brand'],'name':item['name'],'aliases':list(dict.fromkeys(item['aliases'])),'ingredients':ingredients,'flavor':' · '.join(ingredients[:3]) if ingredients else '配料待核对 · 按单品主题绘制','source':[expected+' · '+item['name']+'资料',item['url'],'第三方菜单 · 非实时，区域与季节版本可能不同'],'color':COLORS[motif],'motif':motif,'verified':bool(ingredients),'checkedAt':'2026-10-20'}
 except Exception as e:print('DETAIL FAILED',item['brand'],item['name'],type(e).__name__,flush=True);return None
if __name__=='__main__':
 with cf.ThreadPoolExecutor(max_workers=4) as p:menus=list(p.map(menu,BRANDS))
 items=[i for _,xs,_ in menus for i in xs]
 with cf.ThreadPoolExecutor(max_workers=4) as p:drinks=[d for d in p.map(detail,items) if d]
 icons={b[0]:{'url':icon,'source':f'https://www.nckfhsm.com/brands/{b[2]}/menu/available'} for b,_,icon in menus if isinstance(icon,str) and icon.startswith('https://')}
 (ROOT/'build'/'brand-icons.json').write_text(json.dumps(icons,ensure_ascii=False,indent=2))
 data={'brands':[{'id':'luckin','name':'瑞幸咖啡','mark':'瑞幸咖啡','color':'#254675','aliases':['瑞幸咖啡','瑞幸','luckincoffee','luckin']}],'drinks':drinks}
 (ROOT/'web'/'catalog-extra.js').write_text('/* Factual menu metadata only. Sources and check dates are per item. */\n(function(root){const data='+json.dumps(data,ensure_ascii=False,separators=(',',':'))+';root.TeaCatalogExtra=data;if(typeof module!=="undefined")module.exports=data;})(typeof window==="undefined"?globalThis:window);\n')
 print('COMPLETE',len(drinks),'items;',len(icons),'brand marks',flush=True)
