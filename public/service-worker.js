const CACHE_NAME = 'pwa-cache-v0.2';

const PRECACHE_URLS = [
    '/',
    '/dist/index.js',
    '/dist/index.css',
    '/dist/slider.css',
    '/public/icons/arrow.svg',
    '/public/icons/keyboard.svg',
    '/public/icons/stop.svg',
    '/public/icons/pause_play.svg',
    '/public/icons/apps/youtube.svg',
    '/public/icons/apps/kodi.svg',
];

async function precache() {
    const cache = await caches.open(CACHE_NAME);
    return cache.addAll(PRECACHE_URLS);
}

self.addEventListener('install', (event) => {
    event.waitUntil(precache());
});

/**
 * @param {Request} request
 */
function isCacheable(request) {
    const url = new URL(request.url);
    return url.pathname == "/"
        || url.pathname.endsWith(".js")
        || url.pathname.endsWith(".css")
        || url.pathname.endsWith(".svg")
        || url.pathname.endsWith(".png");
}

/**
 * Checks the cache first, then performs network request to refresh the cache
 * @param {Request} request
 */
async function cacheRetrieve(request) {
    const fetchResponsePromise = fetch(request).then(async (networkResponse) => {
        if (networkResponse.ok) {
            const cache = await caches.open(CACHE_NAME);
            cache.put(request, networkResponse.clone());
        }
        return networkResponse;
    });

    return (await caches.match(request)) || (await fetchResponsePromise);
}


self.addEventListener('fetch', /** @param {FetchEvent} event */ event => {
    if (isCacheable(event.request)) {
        event.respondWith(cacheRetrieve(event.request));
    }
});



self.addEventListener('activate', /** @param {ExtendableEvent} event */ event => {
    const cacheWhitelist = [CACHE_NAME];
    event.waitUntil(
        caches.keys().then((cacheNames) => {
            return Promise.all(
                cacheNames.map((cacheName) => {
                    if (!cacheWhitelist.includes(cacheName)) {
                        return caches.delete(cacheName);
                    }
                })
            );
        })
    );
});
