const fs=require('node:fs'),path=require('node:path');
const source=require('../data/illustration-profiles.json');
const data={profiles:source.profiles,baseOverrides:source.baseOverrides||{}};
fs.writeFileSync(path.join(__dirname,'../web/sticker-profiles.js'),'/* Generated from data/illustration-profiles.json; artwork does not assert a complete recipe. */\n(function(root){const data='+JSON.stringify(data)+';root.TeaArtProfiles=data;if(typeof module!=="undefined")module.exports=data;})(typeof window==="undefined"?globalThis:window);\n');
console.log(Object.keys(data.profiles).length+' ingredient illustration profiles built');
