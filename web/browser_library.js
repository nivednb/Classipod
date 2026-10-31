/* Local audio stays in this origin's IndexedDB. No upload endpoint is used. */
(() => {
  'use strict';
  const audioExtension = /\.(mp3|m4a|mp4|aac|wav|flac|ogg|opus|aif|aiff)$/i;
  const objectUrls = new Map();
  let database;
  let metadataDatabase;
  let pendingPicker = false;

  function openDatabase() {
    if (!database) database = new Promise((resolve, reject) => {
      const request = indexedDB.open('classipod-local-audio-v1', 1);
      request.onupgradeneeded = () => {
        request.result.createObjectStore('songs', {keyPath: 'id'});
      };
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => { database = null; reject(request.error); };
      request.onblocked = () => { database = null; reject(new Error('Close other ClassiPod tabs and retry.')); };
    });
    return database;
  }

  function normalizePath(value) {
    const parts = [];
    for (const part of value.replaceAll('\\', '/').split('/')) {
      if (!part || part === '.') continue;
      if (part === '..') parts.pop();
      else parts.push(part);
    }
    return '/Browser Music/' + parts.join('/');
  }

  async function saveFiles(files) {
    const audio = Array.from(files).filter(file => audioExtension.test(file.name));
    if (!audio.length) return 0;
    const db = await openDatabase();
    // One transaction: quota errors roll back this import, preserving the library.
    await new Promise((resolve, reject) => {
      const transaction = db.transaction('songs', 'readwrite');
      const store = transaction.objectStore('songs');
      try {
        for (const file of audio) {
          const path = normalizePath(file.webkitRelativePath || file.name);
          store.put({id: 'browser:' + path, path, name: file.name,
            mime: file.type, blob: file, modified: file.lastModified,
            revision: Date.now().toString(36) + '-' + Math.random().toString(36).slice(2)});
        }
      } catch (error) {
        transaction.abort();
        reject(error);
        return;
      }
      transaction.oncomplete = resolve;
      transaction.onabort = () => reject(transaction.error || new Error('Import cancelled.'));
      transaction.onerror = () => {};
    });
    // Re-importing the same filename replaces that entry after the commit.
    for (const file of audio) {
      const id = 'browser:' + normalizePath(file.webkitRelativePath || file.name);
      const old = objectUrls.get(id);
      if (old) URL.revokeObjectURL(old);
      objectUrls.delete(id);
      const art = artworkUrls.get(id);
      if (art) URL.revokeObjectURL(art);
      artworkUrls.delete(id);
      tagsById.delete(id);
    }
    // This is a request, not a guarantee of permanent storage on iOS.
    if (navigator.storage?.persist) navigator.storage.persist().catch(() => {});
    return new Set(audio.map(file => normalizePath(file.webkitRelativePath || file.name))).size;
  }

  // An independent, disposable cache: it never upgrades or rewrites the song database.
  // A failed cache is a performance loss only; the original songs remain readable.
  function openMetadataDatabase() {
    if (!metadataDatabase) metadataDatabase = new Promise(resolve => {
      try {
        const request = indexedDB.open('classipod-metadata-cache-v1', 1);
        request.onupgradeneeded = () => request.result.createObjectStore('metadata', {keyPath: 'id'});
        request.onsuccess = () => resolve(request.result);
        request.onerror = request.onblocked = () => resolve(null);
      } catch (_) { resolve(null); }
    });
    return metadataDatabase;
  }
  function cacheSignature(row) {
    return JSON.stringify([row.revision || null, row.modified || 0, row.blob.size, row.mime || '']);
  }
  async function readMetadataCache() {
    const empty = () => ({db: null, entries: new Map()});
    // A stuck or blocked optional cache must never stall the user's library.
    let timer;
    const timeout = new Promise(resolve => { timer = setTimeout(() => resolve(empty()), 1000); });
    const load = (async () => {
      const db = await openMetadataDatabase();
      if (!db) return empty();
      return new Promise(resolve => {
        try {
          const req = db.transaction('metadata', 'readonly').objectStore('metadata').getAll();
          req.onsuccess = () => resolve({db, entries: new Map(req.result.map(item => [item.id, item]))});
          req.onerror = () => resolve(empty());
        } catch (_) { resolve(empty()); }
      });
    })();
    const result = await Promise.race([load, timeout]);
    clearTimeout(timer);
    return result;
  }
  function saveMetadataCache(db, entries) {
    if (!db || !entries.length) return;
    try {
      const tx = db.transaction('metadata', 'readwrite');
      const store = tx.objectStore('metadata');
      // Read and account inside the write transaction so concurrent tabs cannot
      // each exceed the shared 12 MiB artwork budget.
      const request = store.getAll();
      request.onsuccess = () => {
        const sizes = new Map();
        let used = 0;
        for (const item of request.result) {
          const size = item.tags?.picture?.size || 0;
          sizes.set(item.id, size);
          used += size;
        }
        for (const entry of entries) {
          const size = entry.tags.picture?.size || 0;
          const previous = sizes.get(entry.id) || 0;
          if (used - previous + size > 12 * 1024 * 1024) continue;
          used += size - previous;
          sizes.set(entry.id, size);
          store.put(entry);
        }
      };
      // Quota or cache errors never block or delete the music library.
      tx.onerror = tx.onabort = () => {};
    } catch (_) { /* continue without the optional cache */ }
  }
  const tagsById = new Map();
  const artworkUrls = new Map();
  function materializeTags(row, tags) {
    let artwork;
    try {
      if (tags.picture) {
        artwork = artworkUrls.get(row.id);
        if (!artwork) {
          artwork = URL.createObjectURL(tags.picture);
          artworkUrls.set(row.id, artwork);
        }
      }
    } catch (_) { /* malformed artwork never prevents loading */ }
    return {...tags, artwork};
  }
  function readTags(row, cached, pending) {
    if (tagsById.has(row.id)) return tagsById.get(row.id);
    const signature = cacheSignature(row);
    if (cached && cached.signature === signature && cached.tags && typeof cached.tags === 'object') {
      const result = Promise.resolve(materializeTags(row, cached.tags));
      tagsById.set(row.id, result);
      return result;
    }
    const promise = new Promise(resolve => {
      if (!window.jsmediatags) return resolve({});
      try {
        window.jsmediatags.read(row.blob, {
          onSuccess(result) {
            const t = result.tags || {};
            let picture;
            try {
              if (t.picture?.data?.length) {
                picture = new Blob([new Uint8Array(t.picture.data)],
                  {type: t.picture.format || 'image/jpeg'});
              }
            } catch (_) { /* keep readable tags if artwork is malformed */ }
            const tags = {title: typeof t.title === 'string' ? t.title : null,
              artist: typeof t.artist === 'string' ? t.artist : null,
              album: typeof t.album === 'string' ? t.album : null,
              genre: typeof t.genre === 'string' ? t.genre : null, picture};
            // Bound extra storage per track; large covers continue to load normally.
            if (!picture || picture.size <= 256 * 1024) {
              pending.push({id: row.id, signature, tags});
            }
            resolve(materializeTags(row, tags));
          },
          onError() { resolve({}); },
        });
      } catch (_) { resolve({}); }
    });
    tagsById.set(row.id, promise);
    return promise;
  }
  async function list() {
    const db = await openDatabase();
    const rowsPromise = new Promise((resolve, reject) => {
      const request = db.transaction('songs', 'readonly').objectStore('songs').getAll();
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
    const [rows, cache] = await Promise.all([rowsPromise, readMetadataCache()]);
    const pending = [];
    const result = new Array(rows.length);
    let next = 0;
    async function worker() {
      while (next < rows.length) {
        const index = next++;
        const row = rows[index];
        if (!objectUrls.has(row.id)) objectUrls.set(row.id, URL.createObjectURL(row.blob));
        const tags = await readTags(row, cache.entries.get(row.id), pending);
        result[index] = {id: row.id, path: row.path, mime: row.mime,
          title: tags.title || row.name.replace(audioExtension, '').replace(/\s*\[[A-Za-z0-9_-]{11}\]$/, ''),
          artist: tags.artist, album: tags.album, genre: tags.genre, artwork: tags.artwork,
          url: objectUrls.get(row.id)};
      }
    }
    await Promise.all(Array.from({length: Math.min(4, rows.length)}, worker));
    saveMetadataCache(cache.db, pending);
    return JSON.stringify(result);
  }

  // Playback only needs one file, not another scan of the entire library.
  async function resolveSong(id) {
    const db = await openDatabase();
    const row = await new Promise((resolve, reject) => {
      const request = db.transaction('songs', 'readonly').objectStore('songs').get(id);
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
    if (!row) return 'null';
    if (!objectUrls.has(row.id)) objectUrls.set(row.id, URL.createObjectURL(row.blob));
    return JSON.stringify({url: objectUrls.get(row.id)});
  }

  function importSongs() {
    if (pendingPicker) return Promise.reject(new Error('A file picker is already open.'));
    pendingPicker = true;
    // Click before awaiting: Safari requires the picker to start on a user gesture.
    return new Promise((resolve, reject) => {
      const input = document.createElement('input');
      input.type = 'file';
      input.accept = 'audio/*,.mp3,.m4a,.aac,.wav,.flac,.ogg,.opus';
      input.multiple = true;
      input.hidden = true;
      document.body.append(input);
      const cleanup = () => { input.remove(); pendingPicker = false; };
      input.addEventListener('cancel', () => { cleanup(); resolve(0); }, {once: true});
      input.addEventListener('change', async () => {
        try { resolve(await saveFiles(input.files)); }
        catch (error) { reject(error); }
        finally { cleanup(); }
      }, {once: true});
      input.click();
    });
  }

  function pickPlaylists() {
    if (pendingPicker) return Promise.reject(new Error('A file picker is already open.'));
    pendingPicker = true;
    return new Promise((resolve, reject) => {
      const input = document.createElement('input');
      input.type = 'file';
      // No accept filter: iOS Files may otherwise disable M3U8 documents.
      input.multiple = true;
      input.hidden = true;
      document.body.append(input);
      const cleanup = () => { input.remove(); pendingPicker = false; };
      input.addEventListener('cancel', () => { cleanup(); resolve('[]'); }, {once: true});
      input.addEventListener('change', async () => {
        try {
          const files = Array.from(input.files).filter(f => /\.m3u8?$/i.test(f.name));
          resolve(JSON.stringify(await Promise.all(files.map(async f => ({name: f.name, text: await f.text()})))));
        } catch (error) { reject(error); }
        finally { cleanup(); }
      }, {once: true});
      input.click();
    });
  }

  async function offlineReady() {
    if (!('serviceWorker' in navigator)) return false;
    const registration = await navigator.serviceWorker.ready;
    return registration.active?.scriptURL.endsWith('/personal-player-sw.js') || false;
  }

  window.classipodLibrary = Object.freeze({list, resolveSong, importSongs, pickPlaylists, offlineReady});
})();
