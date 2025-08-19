// Clock
const clock = document.getElementById('clock');
function tick(){
  const d = new Date();
  const fmt = d.toLocaleDateString('fr-FR', {weekday:'long', day:'2-digit', month:'long', year:'numeric'});
  const hms = d.toTimeString().slice(0,5);
  if(clock) clock.textContent = `${fmt} — ${hms}`;
}
tick(); setInterval(tick, 1000);

// Security score animation
const scoreTarget = 96; // adapte si besoin
const fg = document.querySelector('.ring .fg');
const bar = document.getElementById('scoreBar');
const val = document.getElementById('scoreVal');
const C = 2*Math.PI*50; // circumference (r=50)
let cur = 0;
const grad = document.createElementNS('http://www.w3.org/2000/svg','linearGradient');
grad.id = 'grad'; grad.setAttribute('x1','0'); grad.setAttribute('x2','1');
grad.innerHTML = `<stop offset="0%" stop-color="#63b3ff"/><stop offset="100%" stop-color="#2760ff"/>`;
document.querySelector('.ring').prepend(Object.assign(document.createElementNS('http://www.w3.org/2000/svg','defs'),{innerHTML:grad.outerHTML}));

function anim(){
  cur += (scoreTarget-cur)*0.08;
  const dash = C - (C*cur/100);
  if(fg){ fg.setAttribute('stroke-dashoffset', String(dash)); }
  if(bar){ bar.style.width = `${cur}%`; }
  if(val){ val.textContent = String(Math.round(cur)); }
  if(Math.abs(cur-scoreTarget) > .5) requestAnimationFrame(anim);
}
requestAnimationFrame(anim);

// News demo
const feed = document.getElementById('feed');
const items = [
  {t:"Nouvelle attaque Zero-Day détectée (CVÉ-2025-5433) ciblant les routeurs TP-Link", tags:"Vulnérabilités · CERT EU", ago:"5 min"},
  {t:"Propagande IA détectée sur les réseaux sociaux en Europe de l’Est", tags:"VPN · Cloudflare Radar", ago:"1 h"},
  {t:"Restrictions VPN en Iran après <em>augmentation</em> de la censure Internet", tags:"IA · The Hacker News", ago:"9 h"},
  {t:"Ransomware ciblant 4200 hôpitaux aux États-Unis", tags:"IA · The Hacker News", ago:"9 h"}
];
if(feed){
  items.forEach(it=>{
    const li = document.createElement('li');
    li.innerHTML = `
      <div class="row"><span class="badge"></span><strong>${it.t}</strong></div>
      <div class="meta">${it.tags} · ${it.ago}</div>`;
    feed.appendChild(li);
  });
}

// Dock (visuel actif)
document.querySelectorAll('.dock button').forEach(btn=>{
  btn.addEventListener('click',()=>{
    document.querySelectorAll('.dock button').forEach(b=>b.classList.remove('active'));
    btn.classList.add('active');
  });
});
