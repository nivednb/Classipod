"""Generate a versioned, same-origin offline shell from a Flutter web build."""
import argparse
import hashlib
import json
from pathlib import Path


def prepare(root: Path) -> None:
    paths = sorted(
        p.relative_to(root).as_posix()
        for p in root.rglob('*')
        if p.is_file()
        and not any(part.startswith('.') for part in p.relative_to(root).parts)
        and p.name not in {
            'personal-player-sw.js', 'flutter_service_worker.js', '.DS_Store', '.nojekyll',
        }
    )
    digest = hashlib.sha256()
    for path in paths:
        digest.update(path.encode())
        digest.update((root / path).read_bytes())
    cache = 'classipod-shell-' + digest.hexdigest()[:16]
    script = """'use strict';
const CACHE = __CACHE__;
const FILES = __FILES__;
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(FILES)));
});
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter(key => key.startsWith('classipod-shell-') && key !== CACHE)
      .map(key => caches.delete(key)));
    await self.clients.claim();
  })());
});
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || url.origin !== self.location.origin) return;
  // Audio blobs live in IndexedDB; no personal files pass through this cache.
  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const cached = await cache.match(event.request, {ignoreSearch: true});
    if (cached) return cached;
    if (event.request.mode === 'navigate') {
      try { return await fetch(event.request); }
      catch (_) { return cache.match('./index.html'); }
    }
    return fetch(event.request);
  })());
});
"""
    script = script.replace('__CACHE__', json.dumps(cache)).replace(
        '__FILES__', json.dumps(['./'] + ['./' + path for path in paths]),
    )
    (root / 'personal-player-sw.js').write_text(script)
    (root / '.nojekyll').touch()
    print(f'Prepared {len(paths)} offline assets in {cache}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('build_directory', type=Path)
    prepare(parser.parse_args().build_directory)
