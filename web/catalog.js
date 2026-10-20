/* Shipped entries must have reviewed existence evidence. */
(function(root){
const extra=typeof module!=="undefined"?require("./catalog-extra.js"):root.TeaCatalogExtra;
const brands=extra.brands;
const catalog=extra.drinks;
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
