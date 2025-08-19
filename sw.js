const ASSETS = ["./","index.html","style.css","main.js","shield.svg"];
self.addEventListener("install",e=>{
  e.waitUntil(caches.open("sentinel-v1").then(c=>c.addAll(ASSETS)));
});
self.addEventListener("fetch",e=>{
  e.respondWith(caches.match(e.request).then(r=>r||fetch(e.request)));
});
