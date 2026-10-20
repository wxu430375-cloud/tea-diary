/* Every cup uses the same brand-mark pipeline and an explicitly calibrated label anchor. */
(function(root){
const escape=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const artData=typeof module!=='undefined'?require('./sticker-profiles.js'):root.TeaArtProfiles;
const profiles=artData.profiles;
const normalizeName=s=>String(s||'').normalize('NFKC').toLowerCase().replace(/[\s·・]/g,'');
const namedArt=new Map([...Object.entries(profiles).flatMap(([key,p])=>p.names.map(name=>[normalizeName(name),'v12-'+key])),...Object.entries(artData.baseOverrides||{}).map(([name,key])=>[normalizeName(name),key])]);
const layouts=Object.freeze({
 'apple-tea-blank':{x:110.8,y:124.3},berry:{x:110.4,y:123},dragonfruit:{x:111.5,y:120.5},grape:{x:110,y:125.1},milk:{x:110.3,y:130},lemon:{x:110.7,y:122},cocoa:{x:110.7,y:121.7},orange:{x:110,y:121.5},
 'coffee-latte':{x:113.3,y:130.3},'coffee-dark':{x:111.2,y:131.5},'coconut-latte':{x:108.2,y:131},'pearl-milk':{x:110,y:122.2},'tea-amber':{x:112.7,y:129},'peach-tea':{x:116,y:115.5},
 ...Object.fromEntries(Object.entries(profiles).map(([key,p])=>['v12-'+key,p.anchor]))
});
const artMap=Object.freeze({apple:'apple-tea-blank',berry:'berry',dragonfruit:'dragonfruit',grape:'grape',flower:'milk',milk:'milk',lemon:'lemon',cocoa:'cocoa',orange:'orange',mango:'orange',passion:'orange',pearl:'pearl-milk',tea:'tea-amber',rose:'peach-tea',peach:'peach-tea',litchi:'peach-tea',longan:'tea-amber','coffee-latte':'coffee-latte','coffee-dark':'coffee-dark','coconut-latte':'coconut-latte'});
function artFor(d){
 const exact=namedArt.get(normalizeName(d?.name));if(exact)return exact;
 const text=(d?.name||'')+(d?.ingredients||[]).join('');
 // Shape-specific fallbacks also improve saved older entries and custom drinks.
 if(/桃胶.*木薯|木薯.*桃胶/.test(text))return 'v12-cassava-milk';
 if(/血糯米/.test(text))return 'v12-sticky-rice-milk';
 if(/芋圆/.test(text))return 'v12-taro-balls';
 if(/芋泥|芋头/.test(text))return 'v12-taro-milk';
 if(/杨枝甘露/.test(text))return 'v12-mango-pomelo';
 if(/珍珠.*泰奶|泰奶.*珍珠/.test(text))return 'v12-thai-pearl';
 if(/泰奶/.test(text))return 'v12-thai-milk';
 if(/布丁/.test(text))return 'v12-pudding-milk';
 if(/玫瑰/.test(text)&&/奶|乳|普洱/.test(text))return 'v12-rose-milk';
 if(/桂花/.test(text)&&/奶|乳/.test(text))return 'v12-osmanthus-milk';
 if(/美式|冷萃/.test(text))return 'coffee-dark';
 if(/拿铁|咖啡/.test(text))return /椰/.test(text)?'coconut-latte':'coffee-latte';
 if(d?.brand==='luckin'&&/玛奇朵/.test(d.name))return 'coffee-latte';
 if(d?.motif==='tea'&&/奶|乳|忌廉|芝士/.test(text))return 'milk';
 if(d?.motif==='litchi'&&/奶|乳/.test(text))return 'milk';
 if(d?.motif==='longan'&&/奶|乳/.test(text))return 'milk';
 if(d?.motif==='milk')return 'v12-classic-milktea';
 return artMap[d?.motif]||'v12-classic-milktea';
}
function brandBadge(d,anchor,uid){
 const b=TeaCatalog.brands.find(b=>b.id===d.brand)||TeaCatalog.brands[0];
 const x=anchor.x,y=anchor.y,size=24;
 // Same unmodified brand asset, same optical size. Never stretch or substitute text.
 return `<defs><clipPath id="${uid}"><circle cx="${x}" cy="${y}" r="${size/2}"/></clipPath></defs><g class="brand-badge" data-brand="${b.id}" data-anchor-x="${x}" data-anchor-y="${y}" aria-hidden="true"><circle cx="${x}" cy="${y}" r="12.1" fill="#fffdf3"/><image href="assets/brand-${b.id}.png" x="${x-size/2}" y="${y-size/2}" width="${size}" height="${size}" preserveAspectRatio="xMidYMid meet" clip-path="url(#${uid})"/><circle cx="${x}" cy="${y}" r="12.1" fill="none" stroke="#75654d" stroke-opacity=".3" stroke-width=".5"/></g>`;
}
function sticker(drink,variant=0){
 const d=drink||TeaCatalog.catalog[0];const asset=artFor(d);const anchor=layouts[asset];
 const uid='brand-'+String(d.id).replace(/[^a-zA-Z0-9-]/g,'')+'-'+variant;
 const accents=d.id.startsWith('custom-')?`<path d="M184 64l2 7 7 2-7 2-2 7-2-7-7-2 7-2z" fill="${escape(d.color)}" opacity=".8"/>`:'';
 return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 230" role="img" aria-label="${escape(d.name)}蜡笔贴纸" data-art="${asset}"><image href="assets/${asset}.png" width="220" height="230" preserveAspectRatio="xMidYMid meet"/>${brandBadge(d,anchor,uid)}${accents}</svg>`;
}
root.TeaSticker={sticker,sketch:sticker,escape,artFor,layouts};
})(typeof window==='undefined'?globalThis:window);
