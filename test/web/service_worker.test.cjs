const {test} = require('node:test');
const assert = require('node:assert/strict');
const {mkdtempSync,writeFileSync,readFileSync,rmSync} = require('node:fs');
const {tmpdir} = require('node:os');
const {join,resolve} = require('node:path');
const {execFileSync} = require('node:child_process');
const vm = require('node:vm');

test('offline navigation returns the cached shell; external audio is untouched', async () => {
  const directory = mkdtempSync(join(tmpdir(),'classipod-shell-'));
  try {
    writeFileSync(join(directory,'index.html'),'test player');
    execFileSync('python3',[resolve(__dirname,'../../scripts/prepare_web_pwa.py'),directory]);
    const listeners = {};
    const cachedShell = new Response('test player');
    const cache = {match: async request => request === './index.html' ? cachedShell : undefined};
    vm.runInNewContext(readFileSync(join(directory,'personal-player-sw.js'),'utf8'),{
      URL, self: {location:{origin:'https://example.com'},
        addEventListener: (name, callback) => {listeners[name] = callback;}},
      caches: {open: async () => cache},
      fetch: async () => {throw new Error('offline');},
    });
    let result;
    listeners.fetch({request:{url:'https://example.com/Classipod/deep-link',method:'GET',mode:'navigate'},
      respondWith: promise => {result = promise;}});
    assert.equal(await (await result).text(),'test player');
    let intercepted = false;
    listeners.fetch({request:{url:'https://audio.example/song.mp3',method:'GET'},
      respondWith: () => {intercepted = true;}});
    assert.equal(intercepted,false);
  } finally {rmSync(directory,{recursive:true,force:true});}
});
