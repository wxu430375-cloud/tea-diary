const assert=require('node:assert/strict');
const {matchLabel,catalog,brands}=require('../web/catalog.js');
const cases=[['1点点\n苹果茉莉绿\n大杯 少冰 三分糖','苹果茉莉绿','yidian'],['一点点 苹果茉莉绿茶','苹果茉莉绿','yidian'],['CoCo都可\n红果小姐姐\n少冰','红果小姐姐','coco'],['coco 鲜百香双响炮','鲜百香双响炮','coco'],['霸王茶姬\n伯牙绝弦\n五分糖','伯牙绝弦','chagee'],['蜜雪冰城 冰鮮檸檬水','冰鲜柠檬水','mixue'],['喜茶 多肉葡萄','多肉葡萄','heytea'],['古茗 云岭茉莉白','云岭茉莉白','guming']];
for(const [text,name,brand] of cases){const result=matchLabel(text)[0];assert.equal(result?.drink.name,name,text);assert.equal(result.drink.brand,brand);}
assert.deepEqual(matchLabel(''),[]);assert.deepEqual(matchLabel('门店电话 123456 取餐码 888'),[]);
assert.match(matchLabel('CoCo 苹果茉莉绿')[0].reason,/冲突/);
assert.equal(new Set(catalog.map(d=>d.id)).size,catalog.length);
for(const d of catalog){assert(brands.some(b=>b.id===d.brand));assert(d.source[1].startsWith('https://'));assert(/^#[a-f0-9]{6}$/i.test(d.color));}
console.log(`Passed: ${cases.length} realistic label cases, empty/noise, conflicting brand, and ${catalog.length} catalog records.`);
