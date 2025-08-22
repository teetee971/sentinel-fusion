#!/usr/bin/env bash
set -euo pipefail
ROOT=sentinel_app/public
CSS="$ROOT/style.css"
JS="$ROOT/app.js"

mark(){ grep -qF "$1" "$2" 2>/dev/null; }

# ---------- CSS ----------
TAG_CSS='/* == addons:a11y-perf-print v1 == */'
if ! mark "$TAG_CSS" "$CSS"; then
cat >> "$CSS" <<'CSS'
/* == addons:a11y-perf-print v1 == */

/* Meilleure ancre sous nav sticky */
h2, h3{ scroll-margin-top:76px; }
@media (max-width:720px){ h2, h3{ scroll-margin-top:96px; } }

/* Réduction légère des espacements sur mobile pour compacter la lecture */
@media (max-width:720px){
  .grid{ gap:18px; }
  .card{ padding:14px 14px; }
  .bullets li{ margin:6px 0; }
}

/* Impression claire, lisible, sans chrome marketing */
@media print{
  :root{ color-scheme: light only; }
  html,body{ background:#fff !important; }
  *{ color:#000 !important; box-shadow:none !important; text-shadow:none !important; }
  .hero, nav, .nav, .toc, .cta-fab, .btn, .chips, .podium, footer{ display:none !important; }
  a[href^="http"]::after{ content:" (" attr(href) ")"; font-weight:normal; }
  section, article{ break-inside: avoid; }
  h1,h2,h3{ page-break-after: avoid; }
}
CSS
fi

# ---------- JS ----------
TAG_JS='/* == addons:a11y-perf-print v1 == */'
if ! mark "$TAG_JS" "$JS"; then
cat >> "$JS" <<'JS'
/* == addons:a11y-perf-print v1 == */
(()=>{"use strict";
/* aria-current sur l’onglet actif (meilleure a11y) */
(function(){
  const page=(document.body.getAttribute('data-page')||location.pathname.replace(/\.html$/,'').replace(/\/$/,'/'))||'/';
  const norm=(s)=> (s||'').replace(/\.html$/,'').replace(/\/$/,'/');
  document.querySelectorAll('nav.sub a').forEach(a=>{
    const href=norm(a.getAttribute('href'));
    if(!href) return;
    if(page==='/' ? (href==='/'||/\/index$/.test(href)) : page.startsWith(href)){
      a.setAttribute('aria-current','page');
    } else {
      a.removeAttribute('aria-current');
    }
  });
})();
})();
JS
fi

# ---------- cache-bust + commit/deploy ----------
ts=$(date +%s)
for f in "$ROOT"/*.html; do
  sed -i -E "s|(\\./style\\.css)(\\?v=[0-9]+)?|\\1?v=$ts|g; s|(app\\.js)(\\?v=[0-9]+)?|\\1?v=$ts|g" "$f"
done

if [[ -x ./deploy_now.sh ]]; then
  git add "$CSS" "$JS" "$ROOT"/*.html || true
  git commit -m "ux(a11y+perf+print): aria-current + ancres compactes + print CSS + cache bust v$ts" || true
  ./deploy_now.sh
else
  echo "⚠️ deploy_now.sh non trouvé : commit/déploiement sautés."
fi

echo "✅ Pack A11Y+PERF+PRINT appliqué."
