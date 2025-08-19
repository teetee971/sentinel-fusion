export function toast(msg){
  const t=document.createElement('div');
  t.className='toast';
  t.textContent=msg;
  Object.assign(t.style,{position:'fixed',bottom:'20px',left:'50%',transform:'translateX(-50%)',
    background:'rgba(15,25,50,.85)',border:'1px solid rgba(130,170,210,.35)',padding:'10px 12px',
    borderRadius:'10px',backdropFilter:'blur(8px)',zIndex:9999});
  document.body.appendChild(t); setTimeout(()=>t.remove(),1800);
}

const THEME_KEY='sentinel-theme', body=document.body;
// boot thème
(function(){
  const t=localStorage.getItem(THEME_KEY)||'dark';
  body.setAttribute('data-theme',t);
})();
document.getElementById('themeBtn')?.addEventListener('click',()=>{
  const next=body.getAttribute('data-theme')==='dark'?'light':'dark';
  body.setAttribute('data-theme',next); localStorage.setItem(THEME_KEY,next);
});

// horloge
(function tick(){
  const el=document.getElementById('clock');
  if(el) el.textContent=new Date().toLocaleString('fr-FR',{weekday:'long',day:'2-digit',month:'long',hour:'2-digit',minute:'2-digit'});
  setTimeout(tick,30000);
})();

// score (démo)
(function score(){
  const s=92+Math.floor(Math.random()*6);
  const n=document.getElementById('scoreNum'); const b=document.getElementById('scoreBar');
  if(n) n.textContent=String(s); if(b) b.style.width=s+'%';
})();

// actus (démo statique)
const feed=[
 {t:"Nouvelle attaque Zero-Day détectée (CVE-2025-5433) ciblant routeurs TP-Link", m:"Vulnérabilités · CERT EU · 5 min"},
 {t:"Propagande IA détectée sur réseaux sociaux en Europe de l’Est", m:"VPN · Cloudflare Radar · 1 h"},
 {t:"Restrictions VPN en Iran : hausse de la censure Internet", m:"IA · The Hacker News · 9 h"},
 {t:"Ransomware ciblant 4200 hôpitaux aux États-Unis", m:"IA · The Hacker News · 9 h"}
];
(function news(){
  const ul=document.getElementById('newsList'); if(!ul) return;
  feed.forEach(n=>{ const li=document.createElement('li'); li.innerHTML=`<div class="t">• ${n.t}</div><div class="m">${n.m}</div>`; ul.appendChild(li); });
})();

// charge les modules (liaisons boutons + outils)
import './modules.js';
