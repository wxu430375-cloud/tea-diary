const assert=require('node:assert/strict');const fs=require('node:fs');const {catalog,brands}=require('../web/catalog.js');
const source=fs.readFileSync(require.resolve('../web/app.js'),'utf8');
const line=source.split('\n').find(l=>l.startsWith('function validateBackup'));
const validate=new Function('brands',line+';return validateBackup;')(brands);
const record={id:'fixture-1',date:'2026-10-20',drinkId:catalog[0].id,drink:catalog[0],createdAt:'2026-10-20T06:30:00Z',note:'测试手账',ocrText:'1点点 苹果茉莉绿',photo:'',sugar:'三分糖',ice:'少冰',mood:'开心'};
const backup={schema:1,entries:[record],custom:[]};assert.equal(validate(backup).entries.length,1);
for(const alter of [b=>b.schema=9,b=>b.entries.push({...record}),b=>b.entries[0].photo='data:image/svg+xml;base64,PHN2Zz4=',b=>b.entries[0].date='2026-99-99',b=>b.entries[0].createdAt='invalid',b=>b.entries[0].id='bad" onclick="',b=>b.entries[0].drink.color='url(https://example.com)',b=>b.entries[0].drink.source=['x','javascript:alert(1)','x']]){const b=structuredClone(backup);alter(b);assert.throws(()=>validate(b));}
console.log('Passed: valid round-trip backup and 8 malformed, duplicate, unsafe image or link cases.');
