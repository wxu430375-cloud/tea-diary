/* Catalog is editorial metadata, never a complete recipe or a live menu. */
(function(root){
const extra=typeof module!=="undefined"?require("./catalog-extra.js"):root.TeaCatalogExtra||{brands:[],drinks:[]};
const sources={
 apple:['一点点 · 苹果系列上新','https://www.alittle-tea.com/latestnews-detail/104/','官方'],
 dot:['一点点 · 饮品介绍','https://www.alittle-tea.com/ourdrinks/','官方'],
 cocoa:['一点点 · 冬日热饮','https://www.alittle-tea.com/latestnews-detail/146/','官方'],
 longan:['一点点 · 龙眼系列','https://www.alittle-tea.com/latestnews-detail/101/','官方'],
 litchi:['一点点 · 荔枝系列','https://www.alittle-tea.com/latestnews-detail/102/','官方'],
 redfruit:['红果小姐姐 · 菜单资料','https://www.nckfhsm.com/en/products/hong-guo-xiao-jie-jie','第三方菜单 · 以门店为准'],
 coco:['CoCo · 品牌与核心产品','https://www.coco-tea.com.cn/detail/136.html','品牌网站'],
 chagee:['霸王茶姬 · 新加坡官方菜单','https://www.chagee.com.sg/zh-sg/product/fresh-milk-tea-series','官方 · 海外菜单'],
 mixue:['蜜雪冰城 · 产品实力','https://www.mxbc.com/product_strength.html','官方'],
 mixuehk:['蜜雪冰城 · 香港菜单','https://mixue.hk/','官方 · 香港菜单'],
 guming:['古茗 · 招股书','https://www.hkexnews.hk/listedco/listconews/sehk/2025/0204/2025020400012_c.pdf','官方披露'],
 heytea:['多肉葡萄 · 产品访谈报道','https://pangjing.cn/heytea-ip-2020/','行业报道']
};
const extraSources={molly:['白兰 · 菜单资料','https://www.nckfhsm.com/products/bai-lan'],mollymatcha:['白兰抹茶 · 菜单资料','https://www.nckfhsm.com/en/products/bai-lan-mo-cha-mo-li-nai-bai'],mollyflower:['一朵茉莉花 · 菜单资料','https://www.nckfhsm.com/zh-tw/products/yi-duo-mo-li-hua'],chabaidao:['豆乳玉麒麟 · 菜单资料','https://www.nckfhsm.com/products/dou-ru-yu-qi-lin'],auntie:['血糯米奶茶 · 菜单资料','https://www.nckfhsm.com/en/products/xue-nuo-mi-nai-cha'],nayuki:['霸气芝士草莓 · 历史菜单资料','https://www.nckfhsm.com/products/ba-qi-zhi-shi-cao-mei-shou-chuang'],chayan:['幽兰拿铁 · 菜单资料','https://www.nckfhsm.com/products/you-lan-na-tie']};
for(const [k,v] of Object.entries(extraSources))sources[k]=[...v,'第三方菜单 · 以门店为准'];
const brands=[
 ['yidian','一点点','1点点','#527d4e',['1点点','一点点','1點點','alittletea']],
 ['coco','CoCo都可','CoCo','#db703b',['coco','都可']],
 ['chagee','霸王茶姬','CHAGEE','#9b453c',['霸王茶姬','chagee']],
 ['mixue','蜜雪冰城','蜜雪冰城','#d9595c',['蜜雪冰城','mixue']],
 ['guming','古茗','古茗','#6c7950',['古茗','guming']],
 ['heytea','喜茶','喜茶 HEYTEA','#454637',['喜茶','heytea']],
 ['nayuki','奈雪的茶','奈雪の茶','#87a453',['奈雪的茶','奈雪','nayuki']],
 ['molly','茉莉奶白','茉莉奶白','#758d7d',['茉莉奶白']],
 ['chabaidao','茶百道','茶百道','#527a8c',['茶百道','chabaidao']],
 ['auntie','沪上阿姨','沪上阿姨','#ba746b',['沪上阿姨','aunteajenny']],
 ['chayan','茶颜悦色','茶颜悦色','#a27553',['茶颜悦色','茶顔悅色']]
].map(([id,name,mark,color,aliases])=>({id,name,mark,color,aliases})).concat(extra.brands);
const rows=[
 ['yidian','苹果茉莉绿',['苹果茉莉绿茶','苹果绿茶'],['苹果粒','茉莉绿茶'],'清甜果香 · 茉莉花香','apple','#b6ca77','apple'],
 ['yidian','苹果奶绿',[],['苹果','奶绿'],'清甜苹果 · 醇厚奶香','apple','#ced18d','apple'],
 ['yidian','可可芭蕾',['可可巴蕾'],['可可','奶'],'醇香可可 · 顺滑','cocoa','#b08165','cocoa'],
 ['yidian','波霸奶茶',[],['波霸','奶茶'],'软糯波霸 · 奶香','cocoa','#c9a985','pearl'],
 ['yidian','四季奶青',[],['四季春茶','奶'],'清扬茶香 · 奶香','cocoa','#c6c5a1','tea'],
 ['yidian','A2牛乳红茶',[],['A2牛乳','红茶'],'鲜奶香 · 红茶香','cocoa','#d4b690','milk'],
 ['yidian','六窨茉莉绿茶',['六窨茉莉绿'],['茉莉绿茶'],'清新花香','dot','#bad5a3','flower'],
 ['yidian','四季春茶',[],['四季春茶'],'清爽茶香','dot','#c3c577','tea'],
 ['yidian','15颗龙眼茉莉绿',['龙眼茉莉绿'],['龙眼肉','龙眼浆','茉莉绿茶'],'鲜甜龙眼 · 清爽茶香','longan','#c8d3a1','longan'],
 ['yidian','15颗龙眼椰奶绿',['龙眼椰奶绿'],['龙眼肉','龙眼浆','椰奶','茉莉绿茶'],'椰香 · 鲜甜龙眼','longan','#e1d3aa','longan'],
 ['yidian','荔枝奶绿',[],['荔枝肉','荔枝汁','茉莉奶绿'],'清甜荔枝 · 花香','litchi','#e0c5c1','litchi'],
 ['coco','红果小姐姐',[],['红心火龙果','风味发酵乳','橙子'],'火龙果香 · 酸奶风味','redfruit','#e888aa','dragonfruit'],
 ['coco','鲜百香双响炮',['百香双响炮'],[],'百香果主题 · 配料待补证','coco','#e6bd64','passion'],
 ['coco','奶茶三兄弟',[],[],'奶茶主题 · 配料待补证','coco','#c5a482','pearl'],
 ['coco','生椰杨枝甘露',['杨枝甘露'],[],'生椰果茶主题 · 配料待补证','coco','#edc36a','mango'],
 ['coco','芒果阿达子',[],[],'芒果主题 · 配料待补证','coco','#ecc46e','mango'],
 ['chagee','伯牙绝弦',[],['茉莉雪芽','牛乳'],'清新茉莉 · 细腻奶香','chagee','#dbdcc0','flower'],
 ['chagee','青沫观音',[],['铁观音','牛乳'],'清淡兰香 · 顺滑','chagee','#cbc29b','tea'],
 ['chagee','青青糯山',[],['糯米香叶绿茶','牛乳'],'糯香 · 谷物香','chagee','#b9c294','tea'],
 ['chagee','桂馥兰香',[],['乌龙茶','桂花','牛乳'],'桂花香 · 焙火香','chagee','#dac698','flower'],
 ['chagee','白雾红尘',[],['大红袍','牛乳'],'浓郁茶香','chagee','#c6a98a','tea'],
 ['chagee','去云南·玫瑰普洱',['玫瑰普洱'],['普洱茶','玫瑰','牛乳'],'玫瑰花香 · 陈香','chagee','#d3a6a6','rose'],
 ['mixue','冰鲜柠檬水',['冰鮮檸檬水','柠檬水'],['柠檬'],'酸甜 · 清爽','mixue','#e7d97e','lemon'],
 ['mixue','草莓摇摇奶昔',[],['冰淇淋','茶汤','草莓果酱'],'莓果香 · 冰淇淋奶香','mixue','#e6acb1','berry'],
 ['mixue','茉莉奶绿',[],['茉莉茶','奶'],'清新茉莉 · 奶香','mixue','#cbd6ae','flower'],
 ['mixue','棒打鲜橙',['棒打鮮橙'],['鲜橙','橙柚酱','绿茶'],'鲜橙香 · 清爽','mixuehk','#e6b36a','orange'],
 ['mixue','蜜桃四季春',[],['桃果浆','水蜜桃果浆','四季春茶','脆啵啵'],'蜜桃香 · 茶香','mixuehk','#e7c0b2','peach'],
 ['mixue','芋圆葡萄',['芋圓葡萄'],['红葡萄汁','椰果','芋圆','四季春茶'],'葡萄香 · 软糯','mixuehk','#bfa5cf','grape'],
 ['guming','云岭茉莉白',[],['云南茶底','广西茉莉花','鲜奶'],'茉莉花香 · 鲜奶香','guming','#d7d9b7','flower'],
 ['heytea','多肉葡萄',['芝芝多肉葡萄'],['葡萄'],'葡萄果香 · 多汁','heytea','#b9a2cf','grape'],
 ['molly','白兰',[],['白兰窨花茶','牛奶'],'清幽兰香 · 熟乳香','molly','#d6dcc1','flower'],
 ['molly','白兰抹茶',[],['白兰花茶','抹茶','牛奶'],'兰香 · 抹茶香','mollymatcha','#a8ba8a','tea'],
 ['molly','一朵茉莉花',[],['茉莉龙芽','牛奶','茉莉忌廉','碧根果'],'茉莉花香 · 奶香','mollyflower','#dce0b9','flower'],
 ['chabaidao','豆乳玉麒麟',[],['乌龙奶茶','黄豆粉','芝士'],'豆香 · 咸甜芝士','chabaidao','#d8c8a2','milk'],
 ['auntie','血糯米奶茶',[],['血糯米','奶茶'],'香甜软糯 · 奶香','auntie','#c9b5bd','pearl'],
 ['nayuki','霸气芝士草莓',['霸气芝士草莓(首创)'],['草莓','茉莉绿茶','奶盖'],'鲜莓酸甜 · 奶盖香','nayuki','#e6a7af','berry'],
 ['chayan','幽兰拿铁',[],['红茶','奶油'],'红茶涩香 · 奶油柔滑','chayan','#d0b797','milk']
];
const catalog=rows.map((r,i)=>({id:'drink-'+i,brand:r[0],name:r[1],aliases:r[2],ingredients:r[3],flavor:r[4],source:sources[r[5]],color:r[6],motif:r[7],verified:r[3].length>0,checkedAt:'2026-10-20'}));
const catalogKey=d=>d.brand+":"+normalize(d.name).replace(/[（(](原创|首创|超大杯|特大杯|大杯|中杯)[）)]/g,"");
const existingByName=new Map(catalog.map(d=>[catalogKey(d),d]));
for(const d of extra.drinks){const prior=existingByName.get(catalogKey(d));if(prior){prior.aliases=[...new Set([...(prior.aliases||[]),d.name,...d.aliases])].filter(a=>a!==prior.name);if(!prior.ingredients.length&&d.ingredients.length){prior.ingredients=d.ingredients;prior.flavor=d.flavor;prior.source=d.source;prior.verified=d.verified;}}else{catalog.push(d);existingByName.set(catalogKey(d),d);}}
function normalize(s){return String(s).normalize('NFKC').toLowerCase().replace(/[\s·・の\-—_.,，。:：()（）]/g,'').replace(/點/g,'点').replace(/綠/g,'绿').replace(/檸/g,'柠').replace(/檬/g,'檬').replace(/鮮/g,'鲜').replace(/圓/g,'圆');}
function matchLabel(text,custom=[]){
 const t=normalize(text); if(!t)return [];
 const brand=brands.find(b=>b.aliases.some(a=>t.includes(normalize(a))));
 const brandToken=brand?.aliases.map(normalize).sort((a,b)=>b.length-a.length).find(a=>t.includes(a));
 const productText=brandToken?t.replace(brandToken,''):t;
 return [...catalog,...custom].map(d=>{const names=[d.name,...(d.aliases||[])].map(normalize);const exactNames=names.filter(n=>productText.includes(n));const exact=exactNames.length>0;const matchedLength=Math.max(0,...exactNames.map(n=>n.length));const overlap=Math.max(...names.map(n=>{let hits=0;for(let i=0;i<n.length-1;i++)if(productText.includes(n.slice(i,i+2)))hits++;return hits/Math.max(1,n.length-1);}));const same=brand?.id===d.brand;let score=exact?(same?1:brand?.id?0.58:0.91):overlap*0.64+(same?0.12:0);return {drink:d,score,matchedLength,reason:exact?(same?'品牌与单品文字匹配':brand?'品牌文字冲突，请核对':'单品文字匹配，请核对品牌'):'相似文字，请确认'};}).filter(r=>r.score>=0.28).sort((a,b)=>b.score-a.score||b.matchedLength-a.matchedLength).slice(0,5);
}
const api={brands,catalog,matchLabel,normalize};root.TeaCatalog=api;if(typeof module!=='undefined')module.exports=api;
})(typeof window==='undefined'?globalThis:window);
