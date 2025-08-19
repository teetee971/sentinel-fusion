import { toast } from "./main.js";
const out = document.getElementById('toolOut');
const write = (o) => { out.textContent = (typeof o==="string"?o:JSON.stringify(o,null,2)); };

// IP publique (ipify)
async function publicIP(){
  try{
    const r = await fetch('https://api.ipify.org?format=json',{cache:'no-store'});
    const j = await r.json(); write(j); toast(`IP publique: ${j.ip}`);
  }catch(e){ write(String(e)); toast('IP: erreur'); }
}

// DNS Cloudflare (application/dns-json)
async function dnsQuery(name){
  const q = name?.trim(); if(!q) return write("Entrez un nom de domaine.");
  try{
    const url=`https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(q)}&type=A`;
    const r = await fetch(url,{headers:{'accept':'application/dns-json'}}); const j=await r.json();
    write(j); toast(`DNS ${q} → ${j?.Answer?.[0]?.data||'—'}`);
  }catch(e){ write(String(e)); toast('DNS: erreur'); }
}

// Latence vers 1.1.1.1
async function latency(){
  try{
    const t0=performance.now();
    await fetch('https://1.1.1.1/cdn-cgi/trace',{cache:'no-store'});
    const ms=Math.round(performance.now()-t0);
    write({latency_ms:ms}); toast(`Latence ~ ${ms} ms`);
  }catch(e){ write(String(e)); toast('Latence: erreur'); }
}

// Fingerprint léger (local)
function fingerprint(){
  const d=window.devicePixelRatio||1;
  const fp={
    ua:navigator.userAgent,
    lang:navigator.language,
    tz:Intl.DateTimeFormat().resolvedOptions().timeZone,
    mem:navigator.deviceMemory??'n/a',
    cores:navigator.hardwareConcurrency??'n/a',
    screen:{w:screen.width,h:screen.height,dpr:d}
  };
  write(fp); toast("Fingerprint local généré");
}

// Bind
document.getElementById('btnIP')   ?.addEventListener('click', publicIP);
document.getElementById('btnDNS')  ?.addEventListener('click', ()=>dnsQuery(document.getElementById('domainInput')?.value));
document.getElementById('btnPing') ?.addEventListener('click', latency);
document.getElementById('btnFP')   ?.addEventListener('click', fingerprint);

// Démos “modules” (clics tuiles)
function bindDemo(id,label){ document.getElementById(id)?.addEventListener('click',()=>toast(`${label} (démo)`)); }
bindDemo('btnCF','Cognitive Firewall'); bindDemo('btnOSINT','OSINT Intelligence');
bindDemo('btnPrivacy','Confidentialité Renforcée'); bindDemo('btnVisualFW','Pare-feu Visuel');
bindDemo('btnIR','Réponse Incident'); bindDemo('btnAPT','Détection APT / Pegasus');
bindDemo('btnNetGuard','Garde Réseau'); bindDemo('btnAuto','Mises à jour Automatiques');
bindDemo('btnQP','Quantum Protector'); bindDemo('btnVault','Coffre-fort');
bindDemo('btnLauncher','Lanceur sécurisé'); bindDemo('btnLog','Journal IA temps réel');
