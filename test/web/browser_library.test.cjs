const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const vm = require('node:vm');
const {IDBFactory} = require('fake-indexeddb');
const source = readFileSync(require('node:path').join(__dirname, '../../web/browser_library.js'), 'utf8');

function page(indexedDB = new IDBFactory(), metadataReader = null) {
  const inputs = [];
  let serial = 0;
  const revoked = [];
  const context = {
    indexedDB, navigator: {}, window: {jsmediatags: metadataReader}, Blob, setTimeout, clearTimeout,
    URL: {createObjectURL: () => `blob:page-${Math.random()}-${++serial}`,
      revokeObjectURL: url => revoked.push(url)},
    document: {
      body: {append: input => inputs.push(input)},
      createElement: () => ({listeners: {}, remove() {}, click() {},
        addEventListener(name, callback) {this.listeners[name] = callback;}}),
    },
  };
  vm.runInNewContext(source, context);
  async function importFiles(files) {
    const promise = context.window.classipodLibrary.importSongs();
    const input = inputs.at(-1);
    input.files = files;
    await input.listeners.change();
    return promise;
  }
  return {api: context.window.classipodLibrary, inputs, importFiles, revoked};
}
function song(name, bytes = 'audio') {
  const blob = new Blob([bytes], {type: 'audio/mpeg'});
  return Object.assign(blob, {name, lastModified: 1});
}

test('imports Unicode filenames, filters non-audio, and survives a new page', async () => {
  const db = new IDBFactory();
  const first = page(db);
  assert.equal(await first.importFiles([song('മലരേ.mp3'), song('notes.txt')]), 1);
  const rows = JSON.parse(await first.api.list());
  assert.equal(rows[0].title, 'മലരേ');
  assert.equal(rows[0].path, '/Browser Music/മലരേ.mp3');
  assert.equal(JSON.parse(await first.api.list())[0].url, rows[0].url);
  const second = JSON.parse(await page(db).api.list());
  assert.equal(second[0].id, rows[0].id);
  assert.notEqual(second[0].url, rows[0].url);
});

test('re-import replaces a filename and revokes its old object URL', async () => {
  const app = page();
  await app.importFiles([song('a.mp3')]);
  const original = JSON.parse(await app.api.list())[0];
  await app.importFiles([song('a.mp3', 'updated audio')]);
  const updated = JSON.parse(await app.api.list());
  assert.equal(updated.length, 1);
  assert.equal(updated[0].id, original.id);
  assert.notEqual(updated[0].url, original.url);
  assert.deepEqual(app.revoked, [original.url]);
});

test('cancel releases the picker and nested paths remain distinct', async () => {
  const app = page();
  const cancelled = app.api.importSongs();
  await assert.rejects(app.api.importSongs(), /already open/);
  app.inputs[0].listeners.cancel();
  assert.equal(await cancelled, 0);
  const a = Object.assign(song('a.mp3'), {webkitRelativePath: 'One/a.mp3'});
  const b = Object.assign(song('a.mp3'), {webkitRelativePath: 'Two/a.mp3'});
  await app.importFiles([a, b]);
  const rows = JSON.parse(await app.api.list());
  assert.equal(rows.length, 2);
  assert.notEqual(rows[0].id, rows[1].id);
});

test('database failure rejects import instead of claiming files were saved', async () => {
  const app = page({open() {throw new Error('storage unavailable');}});
  await assert.rejects(app.importFiles([song('a.mp3')]), /storage unavailable/);
});


test('uses embedded metadata and artwork without changing stored song IDs', async () => {
  const reader = {read(blob, callbacks) { callbacks.onSuccess({tags: {
    title: 'Malayalam song', artist: 'Artist', album: 'Album', genre: 'Pop',
    picture: {format: 'image/jpeg', data: [1, 2, 3]},
  }}); }};
  const app = page(new IDBFactory(), reader);
  await app.importFiles([song('Song [abcdefghijk].m4a')]);
  const row = JSON.parse(await app.api.list())[0];
  assert.equal(row.id, 'browser:/Browser Music/Song [abcdefghijk].m4a');
  assert.equal(row.title, 'Malayalam song');
  assert.equal(row.artist, 'Artist');
  assert.equal(row.album, 'Album');
  assert.equal(row.genre, 'Pop');
  assert.match(row.artwork, /^blob:/);
  await app.importFiles([song('Song [abcdefghijk].m4a', 'replacement')]);
  assert.ok(app.revoked.includes(row.artwork));
});

test('hides video ID only in display title', async () => {
  const app = page();
  await app.importFiles([song('Title [abcdefghijk].m4a')]);
  const row = JSON.parse(await app.api.list())[0];
  assert.equal(row.title, 'Title');
  assert.match(row.id, /\[abcdefghijk\]/);
});


test('playlist picker accepts multiple local M3U files without an iOS filter', async () => {
  const app = page();
  const result = app.api.pickPlaylists();
  const input = app.inputs.at(-1);
  assert.equal(input.accept, undefined);
  assert.equal(input.multiple, true);
  input.files = [Object.assign(new Blob(['#EXTM3U\nSong.m4a']), {name: 'M.playlist.m3u8'}),
    Object.assign(new Blob(['#EXTM3U\nOther.m4a']), {name: 'H.playlist.m3u8'})];
  await input.listeners.change();
  const files = JSON.parse(await result);
  assert.deepEqual(files.map(file => file.name), ['M.playlist.m3u8', 'H.playlist.m3u8']);
  assert.match(files[0].text, /Song.m4a/);
});

test('metadata and artwork persist across fresh page sessions without rereading audio', async () => {
  const db = new IDBFactory();
  let reads = 0;
  const reader = {read(blob, callbacks) { reads++; callbacks.onSuccess({tags: {
    title: 'Cached title', artist: 'Artist', album: 'Album', genre: 'Pop',
    picture: {format: 'image/jpeg', data: [1, 2, 3]},
  }}); }};
  const first = page(db, reader);
  await first.importFiles([song('Track [abcdefghijk].m4a')]);
  const firstRow = JSON.parse(await first.api.list())[0];
  assert.equal(reads, 1);
  const second = page(db, reader);
  const secondRow = JSON.parse(await second.api.list())[0];
  assert.equal(reads, 1, 'the next session must reuse cached tags');
  assert.equal(secondRow.title, firstRow.title);
  assert.equal(secondRow.artist, firstRow.artist);
  assert.equal(secondRow.genre, firstRow.genre);
  assert.match(secondRow.artwork, /^blob:/);
  assert.notEqual(secondRow.artwork, firstRow.artwork);
});

test('re-imported audio invalidates cached tags even when size and timestamp match', async () => {
  const db = new IDBFactory();
  let reads = 0;
  const reader = {read(blob, callbacks) { reads++; blob.text().then(text =>
    callbacks.onSuccess({tags: {title: text}})); }};
  const first = page(db, reader);
  await first.importFiles([song('same.m4a', 'first')]);
  assert.equal(JSON.parse(await first.api.list())[0].title, 'first');
  const second = page(db, reader);
  await second.importFiles([song('same.m4a', 'other')]);
  assert.equal(JSON.parse(await second.api.list())[0].title, 'other');
  assert.equal(reads, 2);
  const third = page(db, reader);
  assert.equal(JSON.parse(await third.api.list())[0].title, 'other');
  assert.equal(reads, 2);
});

test('metadata-cache failure does not block music or change its data', async () => {
  const actual = new IDBFactory();
  const db = {open(name, version) {
    if (name === 'classipod-metadata-cache-v1') throw new Error('cache unavailable');
    return actual.open(name, version);
  }};
  let reads = 0;
  const reader = {read(blob, callbacks) { reads++; callbacks.onSuccess({tags:{title:'Still plays'}}); }};
  const first = page(db, reader);
  await first.importFiles([song('safe.m4a')]);
  assert.equal(JSON.parse(await first.api.list())[0].title, 'Still plays');
  assert.equal(JSON.parse(await page(db, reader).api.list())[0].title, 'Still plays');
  assert.equal(reads, 2);
});

test('oversized artwork is not cached or lost', async () => {
  const db = new IDBFactory();
  let reads = 0;
  const reader = {read(blob, callbacks) { reads++; callbacks.onSuccess({tags: {
    title: 'Large cover', picture: {format: 'image/jpeg', data: new Uint8Array(256 * 1024 + 1)},
  }}); }};
  const first = page(db, reader);
  await first.importFiles([song('large.m4a')]);
  assert.match(JSON.parse(await first.api.list())[0].artwork, /^blob:/);
  assert.match(JSON.parse(await page(db, reader).api.list())[0].artwork, /^blob:/);
  assert.equal(reads, 2);
});

test('playback resolves one song without reading tags for the library', async () => {
  const db = new IDBFactory();
  let reads = 0;
  const reader = {read(blob, callbacks) { reads++; callbacks.onSuccess({tags: {title:'Title'}}); }};
  const first = page(db, reader);
  await first.importFiles([song('a.m4a'), song('b.m4a')]);
  const second = page(db, reader);
  const result = JSON.parse(await second.api.resolveSong('browser:/Browser Music/a.m4a'));
  assert.match(result.url, /^blob:/);
  assert.equal(reads, 0);
  assert.equal(JSON.parse(await second.api.resolveSong('browser:/Browser Music/missing.m4a')), null);
});

test('a stalled optional metadata cache cannot stop music loading', async () => {
  const actual = new IDBFactory();
  const db = {open(name, version) {
    if (name === 'classipod-metadata-cache-v1') return {};
    return actual.open(name, version);
  }};
  const reader = {read(blob, callbacks) { callbacks.onSuccess({tags:{title:'Available'}}); }};
  const app = page(db, reader);
  await app.importFiles([song('safe.m4a')]);
  assert.equal(JSON.parse(await app.api.list())[0].title, 'Available');
});

test('artwork cache has a total size limit without hiding uncached covers', async () => {
  const db = new IDBFactory();
  let reads = 0;
  const picture = new Uint8Array(256 * 1024);
  const reader = {read(blob, callbacks) { reads++; callbacks.onSuccess({tags: {
    title: 'Cover', picture: {format: 'image/jpeg', data: picture},
  }}); }};
  const first = page(db, reader);
  await first.importFiles(Array.from({length: 50}, (_, i) => song(`cover-${i}.m4a`)));
  assert.equal(JSON.parse(await first.api.list()).length, 50);
  const rows = JSON.parse(await page(db, reader).api.list());
  assert.equal(rows.length, 50);
  assert.ok(rows.every(row => row.artwork));
  assert.equal(reads, 52, 'only 48 covers fit in the 12 MiB cache');
});

test('malformed cache entries are ignored and tags are read normally', async () => {
  const db = new IDBFactory();
  let reads = 0;
  const reader = {read(blob, callbacks) { reads++; callbacks.onSuccess({tags:{title:'Valid'}}); }};
  const first = page(db, reader);
  await first.importFiles([song('safe.m4a')]);
  await first.api.list();
  const cache = await new Promise((resolve, reject) => {
    const request = db.open('classipod-metadata-cache-v1', 1);
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
  await new Promise((resolve, reject) => {
    const tx = cache.transaction('metadata', 'readwrite');
    const store = tx.objectStore('metadata');
    const get = store.get('browser:/Browser Music/safe.m4a');
    get.onsuccess = () => store.put({...get.result, tags:null});
    tx.oncomplete = resolve;
    tx.onerror = () => reject(tx.error);
  });
  assert.equal(JSON.parse(await page(db, reader).api.list())[0].title, 'Valid');
  assert.equal(reads, 2);
});
