// Service Worker — 週末帶小孩去哪
// 策略:stale-while-revalidate
// - 第一次訪問後,index.html 進 Cache Storage
// - 之後即使離線也能用(包含全 800 筆景點 + 座標)
// - 背景 fetch 新版,有更新下次開頁時生效
// - SW 註冊失敗不阻 app 啟動(單檔哲學保得住)

const CACHE_NAME = 'kids-weekend-v3.38';
const PRECACHE = ['./', './index.html', './manifest.json'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE_NAME).then(c => c.addAll(PRECACHE)));
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (e) => {
  // 只 cache 同源請求(GitHub Pages 自家檔)
  // 跨域請求(雖然本工具沒有,但 user 點 Google Maps 是新分頁不走 SW)直接走網路
  if (new URL(e.request.url).origin !== location.origin) return;
  if (e.request.method !== 'GET') return;

  e.respondWith(
    caches.match(e.request).then(cached => {
      const fetchPromise = fetch(e.request).then(res => {
        // 成功才更新 cache
        if (res && res.status === 200) {
          const clone = res.clone();
          caches.open(CACHE_NAME).then(c => c.put(e.request, clone));
        }
        return res;
      }).catch(() => cached);  // offline → fallback to cache
      // stale-while-revalidate:有 cache 立刻回傳,背景 fetch 新版
      return cached || fetchPromise;
    })
  );
});
