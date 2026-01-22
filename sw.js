// Service Worker iArmy
const CACHE_NAME = 'iarmy-v1';

// Install - cache les fichiers essentiels
self.addEventListener('install', (event) => {
  console.log('[SW] Install');
  self.skipWaiting();
});

// Activate - nettoie les anciens caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Activate');
  event.waitUntil(clients.claim());
});

// Fetch - strategie network-first (toujours chercher en ligne d'abord)
self.addEventListener('fetch', (event) => {
  // Ne pas intercepter les requetes API
  if (event.request.url.includes('supabase.co') ||
      event.request.url.includes('googleapis.com')) {
    return;
  }

  event.respondWith(
    fetch(event.request)
      .catch(() => caches.match(event.request))
  );
});
