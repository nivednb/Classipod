"""Generate a versioned, same-origin offline shell from a Flutter web build."""
import argparse
import hashlib
import json
from pathlib import Path


def prepare(root: Path) -> None:
    # Content-address the entrypoints so installed apps cannot reuse an older
    # JavaScript bundle from the HTTP cache after a deployment.
    main = root / 'main.dart.js'
    bootstrap = root / 'flutter_bootstrap.js'
    index = root / 'index.html'
    if main.exists() and bootstrap.exists():
        main_name = 'main.' + hashlib.sha256(main.read_bytes()).hexdigest()[:16] + '.dart.js'
        main.rename(root / main_name)
        script = bootstrap.read_text().replace('main.dart.js', main_name)
        bootstrap_name = 'flutter_bootstrap.' + hashlib.sha256(script.encode()).hexdigest()[:16] + '.js'
        (root / bootstrap_name).write_text(script)
        bootstrap.unlink()
        index.write_text(index.read_text().replace('flutter_bootstrap.js', bootstrap_name))
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
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(FILES.map(path => new Request(path, {cache: 'reload'})))));
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
