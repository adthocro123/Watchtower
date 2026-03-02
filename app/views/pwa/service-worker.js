const CACHE_VERSION = "scoutrail-v1"

const PRECACHE_URLS = [
  "/",
  "/manifest.json"
]

const DB_NAME = "scoutrail"
const DB_VERSION = 1
const STORE_NAME = "offline_entries"

// --- Install: precache core shell ---

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) => {
      return cache.addAll(PRECACHE_URLS)
    }).then(() => self.skipWaiting())
  )
})

// --- Activate: clean up old caches ---

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys
          .filter((key) => key !== CACHE_VERSION)
          .map((key) => caches.delete(key))
      )
    }).then(() => self.clients.claim())
  )
})

// --- Fetch: strategy varies by request type ---

self.addEventListener("fetch", (event) => {
  const { request } = event
  const url = new URL(request.url)

  // Skip non-GET requests (let POST/PATCH/DELETE go through normally)
  if (request.method !== "GET") return

  // API calls: network-first
  if (url.pathname.startsWith("/api/")) {
    event.respondWith(networkFirst(request))
    return
  }

  // Static assets (JS, CSS, images, fonts): cache-first
  if (isStaticAsset(url.pathname)) {
    event.respondWith(cacheFirst(request))
    return
  }

  // HTML pages: stale-while-revalidate
  event.respondWith(staleWhileRevalidate(request))
})

// --- Caching strategies ---

async function networkFirst(request) {
  try {
    const response = await fetch(request)
    if (response.ok) {
      const cache = await caches.open(CACHE_VERSION)
      cache.put(request, response.clone())
    }
    return response
  } catch {
    const cached = await caches.match(request)
    return cached || new Response(JSON.stringify({ error: "offline" }), {
      status: 503,
      headers: { "Content-Type": "application/json" }
    })
  }
}

async function cacheFirst(request) {
  const cached = await caches.match(request)
  if (cached) return cached

  try {
    const response = await fetch(request)
    if (response.ok) {
      const cache = await caches.open(CACHE_VERSION)
      cache.put(request, response.clone())
    }
    return response
  } catch {
    return new Response("", { status: 503, statusText: "Offline" })
  }
}

async function staleWhileRevalidate(request) {
  const cached = await caches.match(request)

  const fetchPromise = fetch(request).then((response) => {
    if (response.ok) {
      const cache = caches.open(CACHE_VERSION).then((c) => c.put(request, response.clone()))
    }
    return response
  }).catch(() => null)

  return cached || await fetchPromise || offlineFallback()
}

function offlineFallback() {
  return new Response(
    `<!DOCTYPE html>
    <html>
      <head><title>ScoutRail - Offline</title>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        body { font-family: system-ui; background: #111827; color: #f3f4f6; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
        .container { text-align: center; padding: 2rem; }
        h1 { color: #10B981; }
        p { color: #9ca3af; }
      </style></head>
      <body>
        <div class="container">
          <h1>ScoutRail</h1>
          <p>You are currently offline.</p>
          <p>Any scouting entries you submitted are saved and will sync automatically when you reconnect.</p>
        </div>
      </body>
    </html>`,
    { status: 200, headers: { "Content-Type": "text/html" } }
  )
}

// --- Background sync for offline form submissions ---

self.addEventListener("sync", (event) => {
  if (event.tag === "sync-scouting-entries") {
    event.waitUntil(syncOfflineEntries())
  }
})

async function syncOfflineEntries() {
  try {
    const db = await openDB()
    const tx = db.transaction(STORE_NAME, "readonly")
    const store = tx.objectStore(STORE_NAME)

    const entries = await new Promise((resolve, reject) => {
      const request = store.getAll()
      request.onsuccess = () => resolve(request.result)
      request.onerror = () => reject(request.error)
    })

    db.close()

    if (entries.length === 0) return

    const response = await fetch("/api/v1/scouting_entries/bulk_sync", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: JSON.stringify({ entries })
    })

    if (!response.ok) return

    const result = await response.json()
    const syncedUuids = result.results
      .filter((r) => r.status === "created" || r.status === "existing")
      .map((r) => r.client_uuid)

    if (syncedUuids.length > 0) {
      const deleteDb = await openDB()
      const deleteTx = deleteDb.transaction(STORE_NAME, "readwrite")
      const deleteStore = deleteTx.objectStore(STORE_NAME)

      for (const uuid of syncedUuids) {
        deleteStore.delete(uuid)
      }

      await new Promise((resolve, reject) => {
        deleteTx.oncomplete = resolve
        deleteTx.onerror = () => reject(deleteTx.error)
      })

      deleteDb.close()
    }

    // Notify any open clients
    const clients = await self.clients.matchAll()
    for (const client of clients) {
      client.postMessage({ type: "sync-complete", count: syncedUuids.length })
    }
  } catch (error) {
    console.error("[ScoutRail SW] Background sync failed:", error)
  }
}

function openDB() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION)
    request.onupgradeneeded = (event) => {
      const db = event.target.result
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        db.createObjectStore(STORE_NAME, { keyPath: "client_uuid" })
      }
    }
    request.onsuccess = () => resolve(request.result)
    request.onerror = () => reject(request.error)
  })
}

// --- Helpers ---

function isStaticAsset(pathname) {
  return /\.(js|css|png|jpg|jpeg|gif|svg|ico|woff2?|ttf|eot)(\?.*)?$/.test(pathname) ||
         pathname.startsWith("/assets/")
}
