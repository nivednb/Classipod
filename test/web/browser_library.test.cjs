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
    indexedDB, navigator: {}, window: {jsmediatags: metadataReader}, Blob,
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
    title: 'Malayalam song', artist: 'Artist', album: 'Album',
    picture: {format: 'image/jpeg', data: [1, 2, 3]},
  }}); }};
  const app = page(new IDBFactory(), reader);
  await app.importFiles([song('Song [abcdefghijk].m4a')]);
  const row = JSON.parse(await app.api.list())[0];
  assert.equal(row.id, 'browser:/Browser Music/Song [abcdefghijk].m4a');
  assert.equal(row.title, 'Malayalam song');
  assert.equal(row.artist, 'Artist');
  assert.equal(row.album, 'Album');
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
