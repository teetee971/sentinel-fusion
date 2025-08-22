#!/usr/bin/env bash
set -euo pipefail

ROOT=sentinel_app/public
CSS="$ROOT/style.css"
JS="$ROOT/app.js"

# 0) Arbo Pages Functions (API côté serveur)
mkdir -p functions/api/vpn

# functions/api/vpn/index.js : routeur simple
cat > functions/api/vpn/index.js <<'JS'
export async function onRequest(context){
  const { request, env } = context;
  const url = new URL(request.url);
  const path = url.pathname.replace(/^\/api\/vpn\/?/, ""); // status, peers, peers/:id/enable
  const upstream = (suffix="") => `${env.VPN_API.replace(/\/$/,'')}/${suffix.replace(/^\//,'')}`;

  // Sécurité: exiger token côté Worker
  const AUTH = `Bearer ${env.VPN_TOKEN}`;
  const stdHeaders = { 'Authorization': AUTH, 'Content-Type':'application/json' };

  // Helper: proxy JSON
  const proxy = async (method, target, body=null) => {
    const res = await fetch(target, { method, headers: stdHeaders, body: body?JSON.stringify(body):undefined });
    const text = await res.text();
    let data; try{ data = JSON.parse(text); } catch{ data = { raw:text }; }
    return new Response(JSON.stringify(data), { status: res.status, headers: { 'Content-Type':'application/json' }});
  };

  // Routes de base (adapte-les à ton orchestrateur)
  if (request.method === 'GET' && (path === '' || path === 'status')) {
    return proxy('GET', upstream('status'));
  }
  if (request.method === 'GET' && path === 'peers') {
    return proxy('GET', upstream('peers'));
  }
  // Toggle peer: POST /api/vpn/peers/:id/enable {enable:true|false}
  if (request.method === 'POST' && /^peers\/[^/]+\/enable$/.test(path)) {
    const id = path.split('/')[1];
    const body = await request.json().catch(()=>({}));
    // Exemples d'upstream à adapter:
    // - wg-easy: POST /clients/:id/enable {enabled:true|false}
    // - headscale: POST /api/machines/:id/route
    // - tailscale: POST /api/v2/tailnet/.../devices/:id/disable
    return proxy('POST', upstream(`peers/${id}/enable`), { enable: !!body.enable });
  }

  return new Response(JSON.stringify({ error:'Not found', path }), { status: 404, headers:{'Content-Type':'application/json'}});
}
JS

# 1) CSS (panneau & bouton)
if ! grep -q '/* == vpn: ui v1 ==' "$CSS"; then
cat >> "$CSS" <<'CSS'
/* == vpn: ui v1 == */
.vpn-chip{position:fixed; right:16px; bottom:16px; z-index:9998; padding:8px 12px; border-radius:999px;
  border:1px solid rgba(255,255,255,.14); background:rgba(10,14,20,.8); color:#fff; backdrop-filter:saturate(120%) blur(8px);}
.vpn-pane{position:fixed; right:16px; bottom:64px; width: min(420px,calc(100% - 32px)); max-height:60vh; overflow:auto; z-index:9999;
  background:rgba(10,14,20,.92); color:#fff; border:1px solid rgba(255,255,255,.12); border-radius:16px; padding:12px;}
.vpn-pane h4{margin:.3rem 0 .5rem 0}
.vpn-list{display:flex; flex-direction:column; gap:6px}
.vpn-item{display:flex; justify-content:space-between; align-items:center; border:1px solid rgba(255,255,255,.12);
  border-radius:10px; padding:6px 8px; background:rgba(255,255,255,.03)}
.vpn-item small{opacity:.8}
.vpn-item button{padding:6px 10px; border-radius:8px; border:1px solid rgba(255,255,255,.18); background:transparent; color:#fff}
CSS
fi

# 2) JS (UI + appels API)
if ! grep -q '/* == vpn: ui v1 == */' "$JS"; then
cat >> "$JS" <<'JS'
/* == vpn: ui v1 == */
(()=>{

async function api(p, opt={}){
  const r = await fetch(`/api/vpn/${p}`, { headers:{'Accept':'application/json'}, ...opt });
  if(!r.ok) throw new Error(`API ${p}: ${r.status}`);
  return await r.json();
}

function el(tag, attrs={}, ...kids){
  const e=document.createElement(tag);
  Object.entries(attrs).forEach(([k,v])=> (k in e)?(e[k]=v):e.setAttribute(k,v));
  kids.forEach(k=> e.append(k));
  return e;
}

async function render(){
  let pane=document.querySelector('.vpn-pane');
  if(!pane){ pane=el('div',{className:'vpn-pane'}); document.body.appendChild(pane); }
  pane.innerHTML='Statut…';
  try{
    const status = await api('status');      // { up:true, version:'...', iface:'wg0', ... }
    const peers  = await api('peers');       // [{id:'abc', name:'Laptop', online:true, rx:..., tx:...}, ...]
    const head   = el('div',{}, 
      el('h4',{},'VPN — statut'),
      el('div',{}, JSON.stringify(status))
    );
    const list = el('div',{className:'vpn-list'});
    (Array.isArray(peers)?peers:[]).forEach(p=>{
      const row = el('div',{className:'vpn-item'},
        el('div',{}, el('strong',{}, p.name||p.id), el('br'), el('small',{}, p.online?'en ligne':'hors ligne')),
        el('div',{}, el('button',{onclick:async ()=>{
          try{
            await api(`peers/${encodeURIComponent(p.id)}/enable`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({enable: !p.enabled})});
            location.reload();
          }catch(e){ (window.bad||alert)(e.message); }
        }}, (p.enabled===false?'Activer':'Désactiver')))
      );
      list.appendChild(row);
    });
    pane.replaceChildren(head, list);
  }catch(e){
    pane.textContent = `Erreur API: ${e.message}`;
  }
}

function ensureUI(){
  if(document.querySelector('.vpn-chip')) return;
  const chip = el('button',{className:'vpn-chip', title:'VPN'}, 'VPN');
  chip.addEventListener('click', render);
  document.body.appendChild(chip);
}
ensureUI();

})();
JS
fi

# 3) Cache-bust + commit + deploy
ts=$(date +%s)
for h in "$ROOT"/*.html; do
  sed -i -E "s|(\\./style\\.css)(\\?v=[0-9]+)?|\\1?v=$ts|g; s|(app\\.js)(\\?v=[0-9]+)?|\\1?v=$ts|g" "$h"
done
git add functions "$CSS" "$JS" "$ROOT"/*.html || true
git commit -m "vpn(real): API proxy + UI légère + cache bust v$ts" || true
[[ -x ./deploy_now.sh ]] && ./deploy_now.sh || echo "⚠️ deploy_now.sh non trouvé : déploiement sauté."
echo "✅ Pack VPN appliqué."
