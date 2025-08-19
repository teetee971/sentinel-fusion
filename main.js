const THEME_KEY="sentinel-theme";
const body=document.documentElement;

// Theme boot
(function bootTheme(){
  const t = localStorage.getItem(THEME_KEY) || "dark";
  body.setAttribute("data-theme", t);
})();

document.getElementById("themeBtn")?.addEventListener("click", ()=>{
  const next = body.getAttribute("data-theme")==="dark" ? "light" : "dark";
  body.setAttribute("data-theme", next);
  localStorage.setItem(THEME_KEY, next);
});

// Horloge
(function tick(){
  const el=document.getElementById("clock");
  if(el){ el.textContent=new Date().toLocaleString("fr-FR",{weekday:"long", day:"2-digit", month:"long", hour:"2-digit", minute:"2-digit"}); }
  setTimeout(tick, 30_000);
})();

// Score (démo + anneau)
(function score(){
  const s = 82 + Math.floor(Math.random()*10);
  const ring=document.getElementById("ringScore"); const bar=document.getElementById("scoreBar");
  if(ring){ ring.style.setProperty("--p", s); ring.textContent = String(s); }
  if(bar) bar.style.width = s+"%";
})();

// Mini-modules utilisables
const modules = {
  // OSINT: utilisation d’un “read-proxy” public (CORS OK) pour parser de 2 sources
  osint: async function(){
    const sources = [
      "https://r.jina.ai/http://feeds.feedburner.com/TheHackersNews",
      "https://r.jina.ai/http://www.cert.ssi.gouv.fr/alerte/"
    ];
    const news=[];
    for(const url of sources){
      try{
        const t = await fetch(url).then(r=>r.text());
        // extraction rapide de titres (best-effort)
        (t.match(/<title[^>]*>(.*?)<\/title>/gi)||[]).slice(1,6).forEach(x=>{
          news.push({t:x.replace(/<[^>]+>/g,"").trim(), m:"source: "+(url.includes("cert")?"CERT-FR":"THN")});
        });
      }catch(e){}
    }
    const ul=document.getElementById("newsList"); if(!ul) return;
    ul.innerHTML="";
    news.slice(0,6).forEach(n=>{
      const li=document.createElement("li");
      li.innerHTML = `<div class="t">🔹 ${n.t}</div><div class="m">${n.m}</div>`;
      ul.appendChild(li);
    });
  },

  // Réseau: test IP publique + latence HTTP vers Cloudflare
  net: async function(){
    let ip="?", ms="?";
    try{
      ip = await fetch("https://api.ipify.org?format=json").then(r=>r.json()).then(j=>j.ip);
    }catch(e){}
    try{
      const t0=performance.now();
      await fetch("https://www.cloudflare.com/cdn-cgi/trace", {mode:"cors"});
      ms = Math.round(performance.now()-t0);
    }catch(e){}
    alert(`IP publique: ${ip}\nLatence (HTTP): ${ms} ms`);
  },

  // Cognitive firewall (démo UI rapide)
  cog: function(){
    alert("Analyse en cours (démo)…\nProfil recommandé : Premium IA+ (détection proactive + Quantum Shield)");
  }
};

document.getElementById("m_osint")?.addEventListener("click", modules.osint);
document.getElementById("m_net")?.addEventListener("click", modules.net);
document.getElementById("m_cog")?.addEventListener("click", modules.cog);

// Workbox-like cache très simple (offline demo)
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('sw.js').catch(()=>{});
}

// Premier chargement du flux
modules.osint();
