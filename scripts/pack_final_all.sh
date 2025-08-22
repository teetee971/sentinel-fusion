#!/usr/bin/env bash
set -euo pipefail

ROOT=sentinel_app/public
CSS="$ROOT/style.css"
JS="$ROOT/app.js"

# ---------- CSS : finitions & compactage ----------
mark() { grep -qF "$1" "$2" 2>/dev/null; }

# 1) Titres/espacements + cartes plus compactes
M1='/* == final:layout v1 == */'
if ! mark "$M1" "$CSS"; then
cat >> "$CSS" <<'CSS'
/* == final:layout v1 == */
:root{
  --radius:12px;
}
h2{ font-size:clamp(22px,4.8vw,30px); margin:.9em 0 .35em; }
h3{ font-size:clamp(18px,4.2vw,22px); margin:.9em 0 .35em; }
.lead{ font-size:clamp(16px,1.8vw,18px); opacity:.9; }
.card{ background:rgba(255,255,255,.02); border:1px solid rgba(255,255,255,.08); border-radius:var(--radius); padding:16px; }
.card + .card{ margin-top:12px; }
.card h3{ margin-top:6px; margin-bottom:10px; font-weight:700; }
.u.bullets{ list-style:none; padding-left:0; margin:.2rem 0; }
.u.bullets li{ margin:.35rem 0; line-height:1.38; display:list-item; }
.u.bullets li + li{ margin-top:.25rem; }

/* CTA boutons */
a .btn, .a_btn, .btn{ display:inline-flex; justify-content:center; align-items:center; min-height:44px; padding:12px 16px; border-radius:12px; }

/* Table : base compacte (desktop) */
table.compare{ border-spacing:0; }
table.compare th, table.compare td{ padding:10px 12px; }
table.compare tr{ background:rgba(255,255,255,.015); border-bottom:1px solid rgba(255,255,255,.06); }

/* Focus visible accessible */
:focus-visible, button:focus-visible{ outline:2px solid #74d0ff; outline-offset:2px; border-radius:6px; }

/* H2/H3 ancre sous nav sticky */
@media (max-width:720px){
  :target{ scroll-margin-top:76px; }
}
/* Nav secondaire sticky + compact mobile */
@media (max-width:720px){
  nav.sub{ position:sticky; top:0; backdrop-filter:saturate(120%) blur(8px);
           background:rgba(10,14,20,.6); padding:8px 10px; margin-bottom:8px; }
  nav.sub a{ padding:8px 10px; font-size:15px; }
}

/* Table reflow mobile => cartes empilées lisibles */
@media (max-width:720px){
  table.compare{ width:100%; border-collapse:separate; border-spacing:0; }
  table.compare thead{ display:none; }
  table.compare tr{ display:block; border:1px solid rgba(255,255,255,.12); border-radius:12px; padding:10px; margin:10px 0; background:rgba(255,255,255,.02); }
  table.compare td{ display:flex; gap:10px; justify-content:space-between; padding:8px 0; border:none; }
  table.compare td + td{ border-top:1px dashed rgba(255,255,255,.08); }
  table.compare td::before{ content:attr(data-label); opacity:.7; font-weight:600; flex:0 0 48%; }
}

/* Sommaire mobile (fab) – flottant discret */
@media (max-width:720px){
  .cta-fab{ position:fixed; left:16px; right:16px; bottom:16px; z-index:30;
    box-shadow:0 10px 30px rgba(0,0,0,.35); }
  .hero{ padding-bottom:80px; } /* évite que le CTA masque le contenu */
}

/* Chips/podiums plus denses */
:root{ --chipPad:9px; --chipGap:6px; --border:rgba(255,255,255,.14); }
.podium{ margin:10px 0 14px; }
.podium .title{ font-weight:600; opacity:.85; margin-bottom:6px; }
.chips{ display:flex; flex-wrap:wrap; gap:var(--chipGap); margin:4px 0 12px; }
.chip{ display:inline-flex; align-items:center; gap:6px; padding:6px 10px; border:1px solid var(--border); border-radius:999px; white-space:nowrap; }
.chip .medal{ font-size:14px; line-height:1; }
@media (max-width:720px){
  .chip{ padding:6px 9px; font-size:13px; }
}
CSS
fi

# 2) Thème – variables d’accent (facile à retoucher si besoin)
M2='/* == final:theme v1 == */'
if ! mark "$M2" "$CSS"; then
cat >> "$CSS" <<'CSS'
/* == final:theme v1 == */
:root{
  --accent-a:#74d0ff;   /* clair */
  --accent-b:#3b82f6;   /* foncé */
}
nav.sub a:is(:hover,:focus-visible)::after{ transform:scaleX(1); }
nav.sub a::after{
  content:""; position:absolute; left:0; right:0; bottom:-2px; height:2px;
  background:linear-gradient(90deg,var(--accent-a),var(--accent-b));
  transform:scaleX(0); transform-origin:left; transition:transform .22s cubic-bezier(.4,0,.2,1);
}
CSS
fi

# ---------- JS : utilitaires, accessibilité & perf ----------
M3='/* == final:js v1 == */'
if ! mark "$M3" "$JS"; then
cat >> "$JS" <<'JS'
/* == final:js v1 == */
(()=>{"use strict";

/* Table compare -> injecte data-label pour reflow mobile */
(function(){
  const t=document.querySelector('table.compare'); if(!t) return;
  const heads=[...t.querySelectorAll('thead th')].map(th=>th.textContent.trim());
  [...t.querySelectorAll('tbody tr')].forEach(tr=>{
    [...tr.children].forEach((td,i)=>td.setAttribute('data-label', heads[i]||''));
  });
})();

/* Tri simple au clic sur <th> (desktop) */
(function(){
  const t=document.querySelector('table.compare'); if(!t) return;
  const ths=t.querySelectorAll('thead th'); if(!ths.length) return;
  ths.forEach((th,idx)=>{
    th.title='Trier';
    th.addEventListener('click',()=>{
      const dir=th.dataset.sort==='asc'?'desc':'asc';
      ths.forEach(x=>x.removeAttribute('data-sort')); th.dataset.sort=dir;
      const rows=[...t.tBodies[0].rows];
      const ax=(a,b)=> {
        const aa=a.cells[idx].textContent.trim().toLowerCase();
        const bb=b.cells[idx].textContent.trim().toLowerCase();
        if(aa===bb) return 0; return (aa>bb?1:-1)*(dir==='asc'?1:-1);
      };
      rows.sort(ax).forEach(r=>t.tBodies[0].appendChild(r));
    });
  });
})();

/* CTA flottant ("Contact & démo") si présent et viewport mobile */
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

/* Perf & a11y : lazyload images, sécurise les liens externes */
(function(){
  document.querySelectorAll('img:not([loading])').forEach(img=>{
    img.loading='lazy'; img.decoding='async';
  });
  document.querySelectorAll('a[target="_blank"]').forEach(a=>{
    if(!a.rel) a.rel='noopener noreferrer';
  });
})();
})();
JS
fi

# ---------- Cache-bust + commit/deploy ----------
ts=$(date +%s)
for f in "$ROOT"/*.html; do
  sed -i -E "s|(\\./style\\.css)(\\?v=[0-9]+)?|\\1?v=$ts|g; s|(app\\.js)(\\?v=[0-9]+)?|\\1?v=$ts|g" "$f"
done

if [[ -x ./deploy_now.sh ]]; then
  git add "$CSS" "$JS" "$ROOT"/*.html || true
  git commit -m "ux(final): finitions + mobile compact + perf/a11y + cache bust v$ts" || true
  ./deploy_now.sh
else
  echo "⚠️ deploy_now.sh non trouvé : commit/déploiement sautés."
fi

echo "✅ Pack FINAL appliqué."
