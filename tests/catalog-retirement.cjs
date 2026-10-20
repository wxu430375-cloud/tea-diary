const assert=require('node:assert/strict'),fs=require('node:fs');
const {catalog,brands}=require('../web/catalog.js');
const candidates=require('../data/catalog-candidates-v11.json');
const source=fs.readFileSync(require.resolve('../web/app.js'),'utf8');
const helper=source.split('\n').find(l=>l.startsWith('const editableDrinks='));
const choices=new Function('allDrinks',helper+';return editableDrinks;')(()=>catalog);
const line=source.split('\n').find(l=>l.startsWith('function validateBackup'));
const validate=new Function('brands',line+';return validateBackup;')(brands);
const retired=candidates.drinks.filter(d=>!catalog.some(c=>c.id===d.id));
assert(retired.length>0);
for(const d of retired){
 const snapshot={...d,ingredients:[],flavor:'Previous diary snapshot'};
 const entry={id:'legacy-entry',date:'2026-10-19',drinkId:d.id,drink:snapshot,createdAt:'2026-10-19T06:00:00Z',note:'Legacy note',ocrText:'Original label',photo:'',sugar:'三分糖',ice:'少冰',mood:'开心'};
 const backup={schema:1,entries:[entry],custom:[]},before=JSON.stringify(backup);
 assert.strictEqual(choices(entry).find(x=>x.id===d.id),snapshot,'Editing must retain withdrawn choice');
 assert.equal(choices(entry).filter(x=>x.id===d.id).length,1);
 assert.strictEqual(validate(backup).entries[0],entry);
 assert.equal(JSON.stringify(backup),before,'Library audit must not mutate diary');
 assert(!choices(null).some(x=>x.id===d.id),'Retired choice must not reappear in new entries');
}
const valid=catalog.find(d=>d.ingredientEvidence);
const bad={...valid,ingredientEvidence:'javascript:alert(1)'};
assert.throws(()=>validate({schema:1,custom:[bad],entries:[]}));
assert.equal(choices(null).length,catalog.length);
console.log(`Passed: all ${retired.length} withdrawn drink snapshots remain editable/importable without mutation or re-entering the catalog; unsafe ingredient links rejected.`);
