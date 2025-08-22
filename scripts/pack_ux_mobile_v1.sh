#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="sentinel_app/public"
CSS="$ROOT/style.css"
JS="$ROOT/app.js"

echo "→ Pack UX – Mobile v1"

# --- helpers ---------------------------------------------------------------
add_once(){ # add_once "marker" "file" <<'EOF' ... EOF
  local mark="$1" file="$2"; shift 2
  if grep -qF "$mark" "$file" 2>/dev/null; then
    echo "  = $file contient déjà: $mark"
  else
    echo "  + patch -> $file ($mark)"
    cat >> "$file"
  fi
}

cache_bust(){ # bump ?v= timestamps in all html
  local ts; ts=$(date +%s)
  for f in "$ROOT"/*.html; do
    sed -i -E "s|(style\.css)(\?v=[0-9]+)?|\1?v=$ts|g; s|(app\.js)(\?v=[0-9]+)?|\1?v=$ts|g" "$f"
  done
  echo "  + cache-bust = $ts"
}

ensure_compare_class(){ # ensure <table class="compare">
  for p in "$ROOT"/index.html "$ROOT"/comparatif.html; do
    [[ -f "$p" ]] || continue
    if ! grep -q 'table class="compare"' "$p"; then
      sed -i '0,/<table/{s/<table/<table class="compare"/}' "$p"
      echo "  + class=\"compare\" ajouté dans $(basename "$p")"
    fi
  done
}

# --- CSS -------------------------------------------------------------------
add_once '/* === ux:mobile-pack v1 === */' "$CSS" <<'CSS'
/* === ux:mobile-pack v1 === */

/* Global accessibilité/anchors */
html{scroll-behavior:smooth;}
:target{scroll-margin-top:76px;}
@media (max-width:720px){:target{scroll-margin-top:72px;}}
a:focus-visible,.btn:focus-visible{outline:2px solid #74d0ff; outline-offset:2px}

/* Rythme + nav mobile compact */
@media (max-width:720px){
  h1{font-size:clamp(26px,5vw,34px);line-height:1.15;margin:.5rem 0 .35rem}
  h2{font-size:clamp(20px,4.3vw,26px);margin:.75rem 0 .35rem}
  h3{font-size:clamp(17px,3.9vw,22px);margin:.5rem 0 .25rem}
  .lead{font-size:clamp(15px,3.7vw,18px);opacity:.92}
  section{padding:14px 0}
  .card{padding:12px 14px;border-radius:10px}
  nav.sub{position:sticky;top:0;background:rgba(10,14,20,.66);
          backdrop-filter:saturate(120%) blur(8px);padding:8px 10px;font-size:15px}
}

/* Sommaire mobile auto (injecté via JS) */
.toc{position:sticky;top:0;z-index:5;display:flex;gap:8px;padding:8px 10px;
     background:rgba(10,14,20,.72);backdrop-filter:saturate(120%) blur(8px)}
.toc a{font-size:13px;padding:6px 10px;border:1px solid rgba(255,255,255,.14);
       border-radius:999px;white-space:nowrap}
@media(min-width:721px){.toc{display:none}}

/* Sections repliables (mobile) */
.card-toggle{width:100%;text-align:left;display:flex;justify-content:space-between;
             gap:8px;cursor:pointer}
.card-content{display:none}
.card-content.open{display:block!important}

/* Tableau -> cartes (mobile) */
@media (max-width:720px){
  table.compare{width:100%;border-collapse:separate;border-spacing:0}
  table.compare thead{display:none}
  table.compare tr{display:block;border:1px solid rgba(255,255,255,.12);
                   border-radius:12px;padding:10px;margin:10px 0;
                   background:rgba(255,255,255,.02)}
  table.compare td{display:flex;gap:10px;justify-content:space-between;
                   padding:8px 0;border:none}
  table.compare td::before{content:attr(data-label);opacity:.7;font-weight:600;flex:0 0 48%}
}

/* CTA flottant (duplique “contact/démo”) */
@media (max-width:720px){
  .cta-fab{position:fixed;left:16px;right:16px;bottom:16px;z-index:30}
  .has-cta{padding-bottom:80px} /* évite que le CTA masque le contenu */
}

/* Podiums en “chips” compacts */
.podium{margin:10px 0 14px}
.podium-title{font-weight:600;opacity:.85;margin-bottom:6px}
.chips{display:flex;flex-wrap:wrap;gap:8px}
.chip{display:inline-flex;align-items:center;gap:6px;padding:6px 10px;
      border:1px solid rgba(255,255,255,.14);border-radius:999px;white-space:nowrap}
.chip .medal{font-size:14px;line-height:1}
@media (max-width:720px){.chip{padding:6px 9px;font-size:13px}}

/* === /ux:mobile-pack v1 === */
CSS

# --- JS --------------------------------------------------------------------
add_once '// === ux:mobile-pack v1 ===' "$JS" <<'JS'
// === ux:mobile-pack v1 ===

// Sommaire auto depuis <h2 id="...">
(function(){
  const hs=[...document.querySelectorAll('h2[id]')];
  if(!hs.length) return;
  const toc=document.createElement('nav'); toc.className='toc';
  hs.forEach(h=>{const a=document.createElement('a'); a.href='#'+h.id; a.textContent=h.textContent.trim(); toc.appendChild(a);});
  document.body.insertBefore(toc, document.body.firstChild);
})();

// Sections .card repliables (mobile)
(function(){
  if(!matchMedia('(max-width:720px)').matches) return;
  document.querySelectorAll('.card h3').forEach(h3=>{
    const btn=document.createElement('button'); btn.className='card-toggle'; btn.innerHTML=h3.innerHTML;
    const wrap=document.createElement('div'); wrap.className='card-content';
    while(h3.nextSibling) wrap.appendChild(h3.nextSibling);
    h3.replaceWith(btn); btn.after(wrap);
    btn.addEventListener('click',()=>wrap.classList.toggle('open'));
  });
})();

// Tableau -> cartes : mettre les data-label depuis THEAD
(function(){
  const t=document.querySelector('table.compare'); if(!t) return;
  const heads=[...t.querySelectorAll('thead th')].map(th=>th.textContent.trim());
  t.querySelectorAll('tbody tr').forEach(tr=>{
    [...tr.children].forEach((td,i)=>td.setAttribute('data-label', heads[i]||''));
  });
})();

// CTA flottant (duplique le bouton “Contact & démo” s’il existe)
(function(){
  if(!matchMedia('(max-width:720px)').matches) return;
  const src=document.querySelector('.hero .btn')||
             document.querySelector('a.btn[href*="contact"]')||
             document.querySelector('a[href*="#contact"]');
  if(!src) return;
  const wrap=document.createElement('div'); wrap.className='cta-fab';
  const clone=src.cloneNode(true); wrap.appendChild(clone);
  document.body.appendChild(wrap);
  document.body.classList.add('has-cta');
})();

// === /ux:mobile-pack v1 ===
JS

# --- HTML touches -----------------------------------------------------------
ensure_compare_class

# --- cache-bust + (optionnel) commit/deploy --------------------------------
cache_bust

if [[ -x ./deploy_now.sh ]]; then
  git add "$CSS" "$JS" "$ROOT"/*.html || true
  git commit -m "ux(mobile pack v1): compact + toc + collapsibles + table→cards + CTA + cache-bust" || true
  ./deploy_now.sh
else
  echo "ℹ️  deploy_now.sh introuvable : commit/déploiement non exécuté."
fi

echo "✓ Pack UX – Mobile v1 appliqué."
