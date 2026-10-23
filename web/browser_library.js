/* Local audio stays in this origin's IndexedDB. No upload endpoint is used. */
(() => {
  'use strict';
  const audioExtension = /\.(mp3|m4a|mp4|aac|wav|flac|ogg|opus|aif|aiff)$/i;
  const objectUrls = new Map();
  let database;
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
            mime: file.type, blob: file, modified: file.lastModified});
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
    }
    // This is a request, not a guarantee of permanent storage on iOS.
    if (navigator.storage?.persist) navigator.storage.persist().catch(() => {});
    return new Set(audio.map(file => normalizePath(file.webkitRelativePath || file.name))).size;
  }

  async function list() {
    const db = await openDatabase();
    const rows = await new Promise((resolve, reject) => {
      const request = db.transaction('songs', 'readonly').objectStore('songs').getAll();
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
    return JSON.stringify(rows.map(row => {
      if (!objectUrls.has(row.id)) objectUrls.set(row.id, URL.createObjectURL(row.blob));
      return {id: row.id, path: row.path, mime: row.mime,
        title: row.name.replace(audioExtension, ''), url: objectUrls.get(row.id)};
    }));
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

  async function offlineReady() {
    if (!('serviceWorker' in navigator)) return false;
    const registration = await navigator.serviceWorker.ready;
    return registration.active?.scriptURL.endsWith('/personal-player-sw.js') || false;
  }

  window.classipodLibrary = Object.freeze({list, importSongs, offlineReady});
})();
