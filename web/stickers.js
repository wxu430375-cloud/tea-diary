/* Deterministic, ingredient-led crayon illustrations; no remote image requests. */
(function(root){
const escape=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function sketch(drink,variant=0){
const d=drink||TeaCatalog.catalog[0],brand=TeaCatalog.brands.find(b=>b.id===d.brand)||{mark:d.brandName||'茶茶',color:'#718861'};
const seed=[...d.id+variant].reduce((n,c)=>(n*31+c.charCodeAt(0))>>>0,7);let n=seed;const rnd=()=>{n=(n*1664525+1013904223)>>>0;return n/4294967296;};
let strokes='';for(let i=0;i<180;i++){let x=59+rnd()*95,y=59+rnd()*129;strokes+=`<path d="M${x} ${y}l${9+rnd()*16} ${-7+rnd()*6}" stroke="${i%3?'#fff9e5':d.color}" opacity="${i%3?'.38':'.6'}" stroke-width="${1+rnd()*2}"/>`;}
let bits='';const motif=d.motif;
if(motif==='pearl'||motif==='cocoa')for(let i=0;i<18;i++)bits+=`<circle cx="${76+rnd()*63}" cy="${155+rnd()*27}" r="${3+rnd()*3}" fill="#77533f"/>`;
else for(let i=0;i<12;i++)bits+=`<rect x="${68+rnd()*70}" y="${155+rnd()*30}" width="${5+rnd()*7}" height="${5+rnd()*6}" rx="2" fill="${d.color}" stroke="#fff9df" stroke-width="1.4" transform="rotate(${rnd()*30} 100 170)"/>`;
let fruit='';
if(['flower','rose','tea','milk'].includes(motif)){
 for(let j=0;j<2;j++){let x=149+j*17,y=171-j*16;fruit+=`<g transform="translate(${x} ${y})"><path d="M0 5Q-10 30-5 38" fill="none" stroke="#768a59" stroke-width="2"/>`;for(let k=0;k<5;k++)fruit+=`<ellipse cx="0" cy="-6" rx="4" ry="7" fill="${motif==='rose'?'#df9caa':'#fffcdf'}" stroke="#8b876b" stroke-width=".8" transform="rotate(${k*72})"/>`;fruit+='<circle r="3" fill="#dab85b"/></g>';}
}else if(motif==='grape'){for(let j=0;j<7;j++)fruit+=`<circle cx="${149+(j%3)*8}" cy="${165+Math.floor(j/3)*9}" r="7" fill="#b39ac9" stroke="#766184" stroke-width="1.6"/>`;fruit+='<path d="M155 162q1-14 14-11q-3 11-14 11" fill="#859b59" stroke="#646f44"/>';}
else if(['lemon','orange','passion'].includes(motif)){fruit=`<circle cx="157" cy="177" r="21" fill="${motif==='orange'?'#efb462':'#efe19b'}" stroke="#948654" stroke-width="2"/><circle cx="157" cy="177" r="16" fill="none" stroke="#fff7d1" stroke-width="2"/>`;for(let j=0;j<6;j++)fruit+=`<path d="M157 177l0 -15" stroke="#fff7d1" stroke-width="2" transform="rotate(${j*60} 157 177)"/>`;}
else if(motif==='cocoa'||motif==='pearl'){fruit='<path d="M139 169l24-5 10 25-26 4z" fill="#a17a61" stroke="#6b5246" stroke-width="2"/><path d="M151 168l9 23M143 180l25-5" stroke="#6b5246" stroke-width="1.5"/>';}
else if(motif==='berry'){fruit='<path d="M143 168q15-12 27 3q-1 12-13 24q-14-9-14-27" fill="#df8b8a" stroke="#98615c" stroke-width="2"/><path d="M142 170l10-7 5 5 6-5 8 10" fill="#8ca165" stroke="#748450"/>';for(let j=0;j<7;j++)fruit+=`<path d="M${148+(j%3)*7} ${174+Math.floor(j/3)*6}l1 2" stroke="#fff6ce" stroke-width="1.8"/>`;}
else if(motif==='mango'){fruit='<path d="M142 183q-3-35 23-25q22 25-8 36q-10 2-15-11" fill="#e9c067" stroke="#a98e50" stroke-width="2"/>';}
else{fruit=`<path d="M156 164q-14-9-20 5q-7 15 9 27q7 4 12-1q10 4 18-9q8-18-6-23q-7-2-13 1" fill="${motif==='apple'?'#b7c67e':motif==='longan'?'#d1bd93':'#e3b6bb'}" stroke="#81825d" stroke-width="2"/><path d="M155 166q-2-10 3-14" fill="none" stroke="#777050" stroke-width="2"/><path d="M158 158q9-9 15-2q-7 8-15 2" fill="#879a57"/>`;}
return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 230" role="img" aria-label="${escape(d.name)}手绘贴纸"><defs><clipPath id="clip${seed}"><path d="M56 51Q104 47 158 52L144 192Q110 201 73 192Z"/></clipPath><filter id="rough${seed}" x="-10%" y="-10%" width="120%" height="120%"><feTurbulence type="fractalNoise" baseFrequency=".055" numOctaves="3" seed="${seed%99}" result="noise"/><feDisplacementMap in="SourceGraphic" in2="noise" scale="1.7"/></filter></defs><g filter="url(#rough${seed})"><path d="M141 53l8-32 7 2-8 34" fill="#e6b4ad" stroke="#73674f" stroke-width="2"/><g clip-path="url(#clip${seed})"><path d="M53 52h110v145H54z" fill="#f8f5df"/><path d="M53 77q30 7 53 0t60 1v119H54z" fill="${escape(d.color)}"/><path d="M53 147q32 7 55 0t60 3v49H54z" fill="${motif==='milk'||motif==='flower'?'#eee6cf':d.color}"/>${bits}${strokes}</g><path d="M56 51Q104 47 158 52L144 192Q110 201 73 192Z" fill="none" stroke="#655e4b" stroke-width="2.7" stroke-linejoin="round"/><path d="M57 53q48 5 100 0" fill="none" stroke="#655e4b" stroke-width="1.6"/><ellipse cx="108" cy="120" rx="30" ry="17" fill="${brand.color}"/><text x="108" y="124" text-anchor="middle" fill="#fff9e7" font-family="Arial, sans-serif" font-weight="bold" font-size="${brand.mark.length>7?8:12}">${escape(brand.mark)}</text>${fruit}<path d="M42 87l-5-6m6 18-9 2m146 23 7-6" stroke="#bb9b78" stroke-width="2" stroke-linecap="round"/><path d="M43 150q-9-10-11-2q-2 5 11 11q13-8 7-11q-3-2-7 2" fill="#e5acb0"/></g></svg>`;
}
const artMap={apple:'apple-tea',berry:'berry',dragonfruit:'dragonfruit',grape:'grape',flower:'milk',milk:'milk',lemon:'lemon',cocoa:'cocoa',orange:'orange'};
const logoMap={yidian:'logo-yidian.png',coco:'logo-coco.png',chagee:'logo-chagee.svg'};
function sticker(d,variant=0){
 if(!d||d.id.startsWith('custom-')||!artMap[d.motif])return sketch(d,variant);
 const asset=artMap[d.motif],b=TeaCatalog.brands.find(b=>b.id===d.brand)||{mark:'茶茶',color:'#718861'};
 const labelY={milk:130,berry:123,grape:125,lemon:125,cocoa:127,dragonfruit:120}[asset]||125;
 const mark=logoMap[d.brand]?`${d.brand==='coco'?`<ellipse cx="110" cy="${labelY}" rx="24" ry="12" fill="#cc7847"/>`:''}<image href="assets/${logoMap[d.brand]}" x="91" y="${labelY-8}" width="38" height="16" preserveAspectRatio="xMidYMid meet"/>`:`<text x="110" y="${labelY+3}" text-anchor="middle" fill="${b.color}" font-family="Arial, sans-serif" font-weight="bold" font-size="${b.mark.length>7?6:8}">${escape(b.mark)}</text>`;
 return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 220 230" role="img" aria-label="${escape(d.name)}蜡笔贴纸"><image href="assets/${asset}.png" width="220" height="230" preserveAspectRatio="xMidYMid meet"/>${asset==='apple-tea'?'':mark}</svg>`;
}
root.TeaSticker={sticker,sketch,escape};
})(typeof window==='undefined'?globalThis:window);
