const THEME_KEY="sentinel-theme";
const body=document.body;

/* Theme (dark by défaut) */
(function(){ const t=localStorage.getItem(THEME_KEY)||"dark"; body.setAttribute("data-theme",t); })();
document.getElementById("themeBtn")?.addEventListener("click",()=>{
  const next = body.getAttribute("data-theme")==="dark" ? "light" : "dark";
  body.setAttribute("data-theme", next); localStorage.setItem(THEME_KEY,next);
});

/* Horloge */
(function tick(){
  const el=document.getElementById("clock");
  if(el){ el.textContent=new Date().toLocaleString("fr-FR",{weekday:"long",day:"2-digit",month:"long",hour:"2-digit",minute:"2-digit"}); }
  setTimeout(tick,30_000);
})();

/* Security Score (démo) */
(function score(){
  const s = 92 + Math.floor(Math.random()*6);
  document.getElementById("scoreNum").textContent=String(s);
  document.getElementById("scoreBar").style.strokeDasharray=`${s} 100`;
})();

/* Actus (démo statique) */
const feed=[
 {t:"Nouvelle attaque Zero-Day détectée (CVE-2025-5433) ciblant routeurs TP-Link", m:"Vulnérabilités · CERT EU · 5 min"},
 {t:"Propagande IA détectée sur réseaux sociaux en Europe de l’Est", m:"VPN · Cloudflare Radar · 1 h"},
 {t:"Restrictions VPN en Iran après augmentation de la censure Internet", m:"IA · The Hacker News · 9 h"},
 {t:"Ransomware ciblant 4200 hôpitaux aux États-Unis", m:"IA · The Hacker News · 9 h"}
];
const ul=document.getElementById("newsList");
if(ul){ feed.forEach(n=>{ const li=document.createElement("li"); li.innerHTML=`<div class="t">🛈 ${n.t}</div><div class="m">${n.m}</div>`; ul.appendChild(li); }); }
