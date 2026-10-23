// Replaced by scripts/prepare_web_pwa.py after a release build.
// Development builds deliberately avoid caching source files.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil(self.registration.unregister()));
