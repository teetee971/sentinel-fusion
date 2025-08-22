#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="sentinel_app/public"
CSS="$ROOT/style.css"
JS="$ROOT/app.js"

echo "→ Pack UX ALL (thème + nav v2 + mobile + table+)"

# ---------- helpers ----------
add_once(){ # add_once "marker" "file" <<'EOF' ... EOF
  local mark="$1" file="$2"; shift 2
  if grep -qF "$mark" "$file" 2>/dev/null; then
    echo "  = $file contient déjà: $mark"
  else
    echo "  + patch -> $(basename "$file") ($mark)"
    cat >> "$file"
  fi
}
cache_bust(){
  local ts; ts=$(date +%s)
  for f in "$ROOT"/*.html; do
    sed -i -E "s|(style\.css)(\?v=[0-9]+)?|\1?v=$ts|g; s|(app\.js)(\?v=[0-9]+)?|\1?v=$ts|g" "$f"
  done
  echo "  + cache-bust = $ts"
}
ensure_compare_class(){
  for p in "$ROOT"/index.html "$ROOT"/comparatif.html; do
    [[ -f "$p" ]] || continue
    if ! grep -q 'table class="compare"' "$p"; then
      sed -i '0,/<table/{s/<table/<table class="compare"/}' "$p"
      echo "  + class=compare ajouté dans $(basename "$p")"
    fi
  done
}

# ---------- CSS (thème + nav v2 + mobile + table+) ----------
add_once '/* === theme:variables v1 === */' "$CSS" <<'CSS'
/* === theme:variables v1 === */
:root{
  --bg:#0a0e14; --text:#e8ecf1; --muted:rgba(255,255,255,.72);
  --card:rgba(255,255,255,.02); --border:rgba(255,255,255,.12);
  --radius:12px; --accent-a:#74d0ff; --accent-b:#3b82f6;
}
html{scroll-behavior:smooth;}
a:focus-visible,.btn:focus-visible{outline:2px solid var(--accent-a); outline-offset:2px;}
:target{scroll-margin-top:76px;} @media (max-width:720px){:target{scroll-margin-top:72px;}}
/* === /theme:variables v1 === */
CSS

add_once '/* === nav:active-premium v2 === */' "$CSS" <<'CSS'
/* === nav:active-premium v2 === */
nav.sub{position:sticky;top:0;z-index:10;background:rgba(10,14,20,.66);
  backdrop-filter:saturate(120%) blur(8px)}
nav.sub{position:relative;}
nav.sub .indicator{position:absolute;left:var(--ind-x,0);width:var(--ind-w,0);
  bottom:-2px;height:2px;background:linear-gradient(90deg,var(--accent-a),var(--accent-b));
  transform:scaleX(1);transform-origin:left;
  transition:transform .22s cubic-bezier(.4,0,.2,1), left .22s ease, width .22s ease;}
/* Hover/focus: petite preview */
nav.sub a:hover::after, nav.sub a:focus-visible::after{transform:scaleX(1)}
/* === /nav:active-premium v2 === */
CSS

add_once '/* === ux:mobile-pack v1 === */' "$CSS" <<'CSS'
/* === ux:mobile-pack v1 === */
@media (max-width:720px){
  h1{font-size:clamp(26px,5vw,34px);line-height:1.15;margin:.5rem 0 .35rem}
  h2{font-size:clamp(20px,4.3vw,26px);margin:.75rem 0 .35rem}
  h3{font-size:clamp(17px,3.9vw,22px);margin:.5rem 0 .25rem}
  .lead{font-size:clamp(15px,3.7vw,18px);opacity:.92}
  section{padding:14px 0}
  .card{padding:12px 14px;border-radius:10px}
  nav.sub{padding:8px 10px;font-size:15px}
}
/* Sommaire mobile */
.toc{position:sticky;top:0;z-index:9;display:flex;flex-wrap:wrap;gap:8px;padding:8px 10px;
     background:rgba(10,14,20,.72);backdrop-filter:saturate(120%) blur(8px)}
.toc a{font-size:13px;padding:6px 10px;border:1px solid var(--border);border-radius:999px;white-space:nowrap}
@media(min-width:721px){.toc{display:none}}
/* Sections repliables */
.card-toggle{width:100%;text-align:left;display:flex;justify-content:space-between;gap:8px;cursor:pointer}
.card-content{display:none}.card-content.open{display:block!important}
/* CTA flottant */
@media (max-width:720px){
  .cta-fab{position:fixed;left:16px;right:16px;bottom:16px;z-index:30}
  .has-cta{padding-bottom:80px}
}
/* Chips podium */
.podium{margin:10px 0 14px}.podium-title{font-weight:600;opacity:.85;margin-bottom:6px}
.chips{display:flex;flex-wrap:wrap;gap:8px}
.chip{display:inline-flex;align-items:center;gap:6px;padding:6px 10px;border:1px solid var(--border);border-radius:999px;white-space:nowrap}
.chip .medal{font-size:14px}@media (max-width:720px){.chip{padding:6px 9px;font-size:13px}}
/* === /ux:mobile-pack v1 === */
CSS

add_once '/* === table:plus v1 === */' "$CSS" <<'CSS'
/* === table:plus v1 === */
table.compare{width:100%;border-collapse:separate;border-spacing:0}
table.compare tbody tr:nth-child(odd){background:var(--card)}
table.compare td, table.compare th{padding:10px 12px;border-bottom:1px dashed rgba(255,255,255,.08)}
@media(min-width:721px){
  table.compare thead th{position:sticky;top:76px;background:var(--bg);z-index:2}
  .sortable thead th{cursor:pointer}
}
@media (max-width:720px){
  table.compare thead{display:none}
  table.compare tr{display:block;border:1px solid var(--border);border-radius:12px;padding:10px;margin:10px 0;background:var(--card)}
  table.compare td{display:flex;gap:10px;justify-content:space-between;padding:8px 0;border:none}
  table.compare td::before{content:attr(data-label);opacity:.7;font-weight:600;flex:0 0 48%}
}
/* === /table:plus v1 === */
CSS

# ---------- JS (nav glide + toc + collapsibles + table data-label + tri + CTA) ----------
add_once '// === ux:all-pack v1 ===' "$JS" <<'JS'
// === ux:all-pack v1 ===

// H2 -> id (slug) si absent
(function(){
  document.querySelectorAll('h2:not([id])').forEach(h=>{
    let s=h.textContent.trim().toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-+|-+$/g,'');
    if(!s) s='h2-'+Math.random().toString(36).slice(2,7);
    if(!document.getElementById(s)) h.id=s;
  });
})();

// Sommaire auto (mobile)
(function(){
  const hs=[...document.querySelectorAll('h2[id]')]; if(!hs.length) return;
  const toc=document.createElement('nav'); toc.className='toc';
  hs.forEach(h=>{const a=document.createElement('a'); a.href='#'+h.id; a.textContent=h.textContent.trim(); toc.appendChild(a);});
  document.body.insertBefore(toc, document.body.firstChild);
})();

// Nav glide v2 (barre animée + actif)
(function(){
  const nav=document.querySelector('nav.sub'); if(!nav) return;
  let ind=nav.querySelector('.indicator'); if(!ind){ind=document.createElement('i');ind.className='indicator';nav.appendChild(ind);}
  const links=[...nav.querySelectorAll('a')];
  function current(){
    const page=(document.body.getAttribute('data-page')||location.pathname.replace(/\.html$/,'')||'/');
    return links.find(a=>{
      const h=(a.getAttribute('href')||'').replace(/\.html$/,'');
      if(page==='/' && (/^\/$|\/index$/.test(h))) return true;
      return h && (page===h || page.startsWith(h));
    })||links[0];
  }
  function moveTo(a){
    if(!a) return;
    const r=a.getBoundingClientRect(), nr=nav.getBoundingClientRect();
    nav.style.setProperty('--ind-x',(r.left-nr.left)+'px');
    nav.style.setProperty('--ind-w',r.width+'px');
  }
  let active=current(); moveTo(active);
  links.forEach(a=>{['mouseenter','focus'].forEach(e=>a.addEventListener(e,()=>moveTo(a)));
                    a.addEventListener('click',()=>{active=a;});});
  nav.addEventListener('mouseleave',()=>moveTo(active));
  window.addEventListener('resize',()=>moveTo(active));
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

// Tableau -> data-label + tri simple
(function(){
  const t=document.querySelector('table.compare'); if(!t) return;
  // data-label depuis THEAD
  const heads=[...t.querySelectorAll('thead th')].map(th=>th.textContent.trim());
  t.querySelectorAll('tbody tr').forEach(tr=>{
    [...tr.children].forEach((td,i)=>td.setAttribute('data-label', heads[i]||''));
  });
  // tri (desktop)
  t.classList.add('sortable');
  const ths=[...t.querySelectorAll('thead th')];
  ths.forEach((th,idx)=>{
    th.title='Trier';
    th.addEventListener('click',()=>{
      const dir=th.dataset.sort==='asc'?'desc':'asc';
      ths.forEach(x=>x.removeAttribute('data-sort')); th.dataset.sort=dir;
      const rows=[...t.tBodies[0].rows];
      rows.sort((a,b)=>{
        const ax=a.cells[idx].textContent.trim().toLowerCase();
        const bx=b.cells[idx].textContent.trim().toLowerCase();
        if(ax===bx) return 0; return (ax>bx?1:-1)*(dir==='asc'?1:-1);
      });
      rows.forEach(r=>t.tBodies[0].appendChild(r));
    });
  });
})();

// CTA flottant (duplique “Contact & démo” si dispo)
(function(){
  if(!matchMedia('(max-width:720px)').matches) return;
  const src=document.querySelector('.hero .btn')||
             document.querySelector('a.btn[href*="contact"]')||
             document.querySelector('a[href*="#contact"]');
  if(!src) return;
  const wrap=document.createElement('div'); wrap.className='cta-fab';
  wrap.appendChild(src.cloneNode(true)); document.body.appendChild(wrap);
  document.body.classList.add('has-cta');
})();

// === /ux:all-pack v1 ===
JS

# ---------- HTML touches ----------
ensure_compare_class

# ---------- cache-bust + commit/deploy ----------
cache_bust

if [[ -x ./deploy_now.sh ]]; then
  git add "$CSS" "$JS" "$ROOT"/*.html || true
  git commit -m "ux(all): thème + nav v2 + mobile + table+ + cache-bust" || true
  ./deploy_now.sh
else
  echo "ℹ️  deploy_now.sh non trouvé : commit/déploiement sautés."
fi

echo "✓ Pack UX ALL appliqué."
