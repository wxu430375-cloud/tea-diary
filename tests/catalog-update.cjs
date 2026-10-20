const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const api=require('../web/catalog.js');
const baseline=require('./catalog-v1-ids.json');
for(const old of baseline){const d=api.catalog.find(d=>d.id===old.id);assert(d,old.id);assert.equal(d.brand,old.brand);assert.equal(d.name,old.name);}
assert.equal(api.brands.length,12);assert(api.catalog.length>400);
for(const b of api.brands)assert(api.catalog.filter(d=>d.brand===b.id).length>=30,b.name+' menu not expanded');
assert(api.catalog.filter(d=>d.brand==='luckin').length>=60);
const ctx={TeaCatalog:api};vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../web/stickers.js'),'utf8'),ctx);
for(const d of api.catalog){
 const hit=api.matchLabel(api.brands.find(b=>b.id===d.brand).name+'\n'+d.name+'\n少冰 三分糖')[0];
 assert.equal(hit?.drink.id,d.id,'Wrong label match: '+d.brand+' '+d.name);
 const svg=ctx.TeaSticker.sticker(d);const marks=[...svg.matchAll(/href="assets\/brand-([a-z]+)\.png"/g)];
 assert.equal(marks.length,1);assert.equal(marks[0][1],d.brand);
 assert(!svg.includes('<text'),'No placeholder text logos allowed');
 for(const m of svg.matchAll(/href="(assets\/[a-zA-Z0-9-]+\.(?:png|svg))"/g))assert(fs.existsSync(path.join(__dirname,'../web',m[1])),m[1]);
 assert(svg.includes('width="24" height="24"'),'Logo size must stay constant');
}
for(const [text,name] of [['luckin coffee 生椰拿铁 原创','生椰拿铁'],['瑞幸 标准美式 大杯','标准美式'],['茉莉奶白 白兰抹茶','白兰抹茶'],['一点点 苹果奶绿','苹果奶绿'],['coco 苹果奶绿','苹果奶绿']])assert.equal(api.matchLabel(text)[0]?.drink.name,name,text);
console.log(`Passed: ${baseline.length} unchanged legacy IDs, all ${api.catalog.length} exact label matches and artwork/logo paths, 12 expanded brand menus, coffee and nested-name cases.`);
