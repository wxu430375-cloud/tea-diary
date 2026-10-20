const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const api=require('../web/catalog.js');
const baseline=require('./catalog-v1-ids.json');
const audit=require('../docs/catalog-audit.json'),review=require('../data/catalog-evidence.json');
for(const old of baseline){const d=api.catalog.find(d=>d.id===old.id);if(d){assert.equal(d.brand,old.brand);assert.equal(d.name,old.name);}else assert(audit.items.some(x=>x.id===old.id&&x.status==='withdrawn'));}
assert.equal(api.brands.length,12);
assert.equal(audit.items.length,492);assert.equal(new Set(audit.items.map(d=>d.id)).size,492);
assert.equal(audit.currentCount,api.catalog.length);
assert.equal(review.groups.reduce((n,g)=>n+g.names.length,0),api.catalog.length);
for(const b of api.brands)assert(api.catalog.some(d=>d.brand===b.id),b.name);
const ctx={TeaCatalog:api,TeaArtProfiles:require("../web/sticker-profiles.js")};vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../web/stickers.js'),'utf8'),ctx);
for(const d of api.catalog){
 assert.equal(d.existenceVerified,true);
 const g=review.groups.find(g=>g.brand===d.brand&&g.names.includes(d.name));assert(g,d.name+' lacks reviewed evidence');
 assert.equal(d.evidence.url,g.url);assert.equal(d.evidence.observedName,d.name);
 assert(!new URL(d.evidence.url).hostname.endsWith('nckfhsm.com'),'Aggregator is not existence proof');
 assert.deepEqual(d.ingredients,g.ingredients?.[d.name]||[],'Unreviewed recipe must not ship');
 assert.equal(d.verified,d.ingredients.length>0);
 const hit=api.matchLabel(api.brands.find(b=>b.id===d.brand).name+'\n'+d.name+'\n少冰 三分糖')[0];
 assert.equal(hit?.drink.id,d.id,'Wrong label match: '+d.brand+' '+d.name);
 const svg=ctx.TeaSticker.sticker(d);const marks=[...svg.matchAll(/href="assets\/brand-([a-z]+)\.png"/g)];
 assert.equal(marks.length,1);assert.equal(marks[0][1],d.brand);
 assert(!svg.includes('<text'),'No placeholder text logos allowed');
 for(const m of svg.matchAll(/href="(assets\/[a-zA-Z0-9-]+\.(?:png|svg))"/g))assert(fs.existsSync(path.join(__dirname,'../web',m[1])),m[1]);
 assert(svg.includes('width="24" height="24"'),'Logo size must stay constant');
}
for(const [text,name] of [['luckin coffee 生椰拿铁 原创','生椰拿铁'],['瑞幸 标准美式 大杯','标准美式'],['瑞幸 柚c美式 大杯 少冰','柚C美式'],['古茗 桃胶木薯炖奶 温 三分糖','桃胶木薯炖奶'],['茉莉奶白 抹茶白兰','抹茶白兰'],['一点点 苹果奶绿','苹果奶绿']])assert.equal(api.matchLabel(text)[0]?.drink.name,name,text);
assert(!api.catalog.some(d=>d.brand==='molly'&&d.name==='白兰抹茶'),'Cake cannot be a drink');
assert(!api.catalog.some(d=>/蛋糕|周边|双杯|一茶一酥|联名杯|杯套/.test(d.name)));
const pearl=api.catalog.find(d=>d.brand==='luckin'&&d.name==='经典珍珠奶茶');assert(pearl.evidence.corroboration.includes('20261012'));
console.log(`Passed: ${api.catalog.length} reviewed entries, all exact label matches and artwork paths, 492 legacy audit decisions, 2 requested additions, cake exclusion, and sourced Luckin pearl tea.`);
