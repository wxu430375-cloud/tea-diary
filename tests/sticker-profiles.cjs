const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),crypto=require('node:crypto');
const api=require('../web/catalog.js'),art=require('../web/sticker-profiles.js');
const ctx={TeaCatalog:api,TeaArtProfiles:art};vm.runInNewContext(fs.readFileSync(require.resolve('../web/stickers.js'),'utf8'),ctx);
const {artFor,sticker,layouts}=ctx.TeaSticker;
assert.equal(Object.keys(art.profiles).length,36);
const hashes=new Set();
for(const [key,p] of Object.entries(art.profiles)){
 const data=fs.readFileSync(require.resolve('../web/assets/v12-'+key+'.png'));
 assert.equal(data.subarray(0,8).toString('hex'),'89504e470d0a1a0a');
 assert(data.readUInt32BE(16)>=400&&data.readUInt32BE(20)>=600,'Image detail too low: '+key);
 assert.equal(data[25],6,'Transparency must be RGBA: '+key);
 hashes.add(crypto.createHash('sha256').update(data).digest('hex'));
 assert(p.references.every(u=>u.startsWith('https://'))&&p.references.length>0);
 assert(p.anchor.x>95&&p.anchor.x<130&&p.anchor.y>100&&p.anchor.y<145,key+' label anchor');
 for(const name of p.names){const d=api.catalog.find(d=>d.name===name);if(d)assert.equal(artFor(d),'v12-'+key,name);}
}
assert.equal(hashes.size,36,'Each new illustration must be a different image');
const expected={'桃胶木薯炖奶':'cassava-milk','血糯米奶茶':'sticky-rice-milk','芋头奶绿':'taro-milk','招牌芋圆奶茶':'taro-balls','芒果阿达子':'mango-jelly','杨枝甘露':'mango-pomelo','幽兰拿铁':'cream-pecan','豆乳玉麒麟':'soy-cheese','柚C美式':'yuzu-americano','橙C美式':'orange-americano','苹果C美式':'apple-americano','布丁奶茶':'pudding-milk','奶茶三兄弟':'pudding-jelly','经典泰奶':'thai-milk','黑糖珍珠泰奶':'thai-pearl'};
for(const [name,profile] of Object.entries(expected)){const d=api.catalog.find(d=>d.name===name);assert(d);assert.equal(artFor(d),'v12-'+profile);assert.equal(artFor({...d,ingredients:[]}),artFor(d),'Saved snapshot must select same artwork');}
assert.equal(artFor({id:'custom-test',brand:'guming',name:'桃胶木薯顿奶',ingredients:[],motif:'pearl'}),'v12-cassava-milk','Common wording must not fall back to pearls');
const counts=new Map();let updated=0;
for(const d of api.catalog){const key=artFor(d);assert(layouts[key]);counts.set(key,(counts.get(key)||0)+1);if(key.startsWith('v12-'))updated++;assert(sticker(d).includes('assets/brand-'+d.brand+'.png'));}
assert(counts.size>=45,'Library variety regressed');assert(updated>=api.catalog.length/2,'At least half the catalog should use the new ingredient drawings');
assert(Math.max(...counts.values())<api.catalog.length*.15,'One generic illustration dominates the shelf');
console.log(`Passed: 36 unique transparent illustrations, ${counts.size} used themes, ${updated} refreshed drinks, calibrated labels, shape-specific food/coffee cases, and snapshot compatibility.`);
