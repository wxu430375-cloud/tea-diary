/* Every cup uses the same brand-mark pipeline and an explicitly calibrated label anchor. */
(function(root){
const escape=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const layouts=Object.freeze({
 'apple-tea-blank':{x:110.8,y:124.3},berry:{x:110.4,y:123},dragonfruit:{x:111.5,y:120.5},grape:{x:110,y:125.1},milk:{x:110.3,y:130},lemon:{x:110.7,y:122},cocoa:{x:110.7,y:121.7},orange:{x:110,y:121.5},
 'coffee-latte':{x:113.3,y:130.3},'coffee-dark':{x:111.2,y:131.5},'coconut-latte':{x:108.2,y:131},'pearl-milk':{x:110,y:122.2},'tea-amber':{x:112.7,y:129},'peach-tea':{x:116,y:115.5}
});
const artMap=Object.freeze({apple:'apple-tea-blank',berry:'berry',dragonfruit:'dragonfruit',grape:'grape',flower:'milk',milk:'milk',lemon:'lemon',cocoa:'cocoa',orange:'orange',mango:'orange',passion:'orange',pearl:'pearl-milk',tea:'tea-amber',rose:'peach-tea',peach:'peach-tea',litchi:'peach-tea',longan:'tea-amber','coffee-latte':'coffee-latte','coffee-dark':'coffee-dark','coconut-latte':'coconut-latte'});
function artFor(d){
 const text=(d?.name||'')+(d?.ingredients||[]).join('');
 if(d?.brand==='luckin'&&/玛奇朵/.test(d.name))return 'coffee-latte';
 if(d?.motif==='tea'&&/奶|乳|忌廉|芝士/.test(text))return 'milk';
 if(d?.motif==='litchi'&&/奶|乳/.test(text))return 'milk';
 if(d?.motif==='longan'&&/奶|乳/.test(text))return 'milk';
 return artMap[d?.motif]||'milk';
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
