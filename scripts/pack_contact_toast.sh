#!/usr/bin/env bash
set -euo pipefail
ROOT=sentinel_app/public
CSS="$ROOT/style.css"
JS="$ROOT/app.js"

# 1) CSS (toast + busy)
if ! grep -q '/* == contact: toast v1 ==' "$CSS"; then
cat >> "$CSS" <<'CSS'
/* == contact: toast v1 == */
.toast{position:fixed;left:50%;bottom:16px;transform:translate(-50%,120%);opacity:0;
  background:rgba(10,14,20,.9);color:#fff;border:1px solid rgba(255,255,255,.12);
  padding:10px 14px;border-radius:12px;backdrop-filter:saturate(120%) blur(8px);
  z-index:9999;transition:transform .25s ease,opacity .25s;pointer-events:none}
.toast.show{transform:translate(-50%,0);opacity:1}
.toast.ok{border-color:#74d0ff}
.toast.bad{border-color:#ff6a6a}
button.is-busy{pointer-events:none;opacity:.6}
@media (max-width:720px){.toast{width:calc(100% - 32px)}}
CSS
fi

# 2) JS (ok/bad -> toast + busy sur submit)
if ! grep -q '/* == contact: toast v1 == */' "$JS"; then
cat >> "$JS" <<'JS'
/* == contact: toast v1 == */
(()=>{ 
  function toast(msg, kind='ok'){
    let t=document.querySelector('.toast');
    if(!t){ t=document.createElement('div'); t.className='toast'; document.body.appendChild(t); }
    t.className='toast show ' + (kind==='bad'?'bad':'ok');
    t.textContent=msg;
    clearTimeout(window.__toastT); window.__toastT=setTimeout(()=>t.classList.remove('show'), 4000);
  }
  window.ok  = window.ok  || ((m)=>toast(m,'ok'));
  window.bad = window.bad || ((m)=>toast(m,'bad'));
  const form=document.querySelector('form[action="#contact"], form#contact, .contact form');
  if(form){
    const btn=form.querySelector('button[type="submit"], [type="submit"]');
    form.addEventListener('submit', ()=>{ btn&&btn.classList.add('is-busy'); setTimeout(()=>btn&&btn.classList.remove('is-busy'), 6000); });
  }
})();
JS
fi

# 3) Cache-bust + commit + deploy
ts=$(date +%s)
for h in "$ROOT"/*.html; do
  sed -i -E "s|(\\./style\\.css)(\\?v=[0-9]+)?|\\1?v=$ts|g; s|(app\\.js)(\\?v=[0-9]+)?|\\1?v=$ts|g" "$h"
done
git add "$CSS" "$JS" "$ROOT"/*.html || true
git commit -m "ux(contact): toast + busy + cache bust v$ts" || true
[[ -x ./deploy_now.sh ]] && ./deploy_now.sh || echo "⚠️ deploy_now.sh non trouvé : déploiement sauté."
echo "✅ Pack Contact UX appliqué."
