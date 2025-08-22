#!/usr/bin/env bash
set -euo pipefail
ROOT=sentinel_app/public
CSS="$ROOT/style.css"
JS="$ROOT/app.js"

mark(){ grep -qF "$1" "$2" 2>/dev/null; }

# ---------- CSS ----------
M1='/* == addons:toc+cards v1 == */'
if ! mark "$M1" "$CSS"; then
cat >> "$CSS" <<'CSS'
/* == addons:toc+cards v1 == */
:root{ --border:rgba(255,255,255,.14); }

.toc{ position:sticky; top:64px; z-index:2; padding:10px; margin:6px 0 12px;
      background:rgba(255,255,255,.02); border:1px solid var(--border); border-radius:12px; }
.toc a{ display:inline-block; margin:4px 8px 0 0; padding:4px 8px; border-radius:999px; border:1px solid var(--border); }
.toc a:focus-visible{ outline:2px solid #74d0ff; outline-offset:2px; }

@media (min-width:721px){
  .toc{ top:10px; background:transparent; border:none; padding:0; }
  .toc a{ border:none; padding:0; margin:0 12px 0 0; }
}

/* Cartes repliables sur mobile */
.card-toggle{ display:none; }
@media (max-width:720px){
  .card-toggle{ display:inline-flex; align-items:center; gap:6px; font-size:13px;
                padding:4px 8px; border:1px solid var(--border); border-radius:999px; }
  .card.is-collapsed .card-content{ display:none; }
}
CSS
fi

# ---------- JS ----------
M2='/* == addons:toc+cards v1 == */'
if ! mark "$M2" "$JS"; then
cat >> "$JS" <<'JS'
/* == addons:toc+cards v1 == */
(()=>{"use strict";

/* ToC auto depuis tous les <h2 id="..."> présents */
(function(){
  const hs=[...document.querySelectorAll('h2[id]')];
  if(hs.length<2) return;
  const toc=document.createElement('nav'); toc.className='toc';
  hs.forEach(h=>{
    const a=document.createElement('a'); a.href='#'+h.id; a.textContent=h.textContent.trim();
    toc.appendChild(a);
  });
  const host=document.query

# --- PACK ADD-ONS: ToC + cartes repliables + cache-bust + deploy ---
cat > scripts/pack_addons_toc_cards.sh <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
ROOT=sentinel_app/public
CSS="$ROOT/style.css"
JS="$ROOT/app.js"

mark(){ grep -qF "$1" "$2" 2>/dev/null; }

# ---------- CSS ----------
M1='/* == addons:toc+cards v1 == */'
if ! mark "$M1" "$CSS"; then
cat >> "$CSS" <<'CSS'
/* == addons:toc+cards v1 == */
:root{ --border:rgba(255,255,255,.14); }

.toc{ position:sticky; top:64px; z-index:2; padding:10px; margin:6px 0 12px;
      background:rgba(255,255,255,.02); border:1px solid var(--border); border-radius:12px; }
.toc a{ display:inline-block; margin:4px 8px 0 0; padding:4px 8px; border-radius:999px; border:1px solid var(--border); }
.toc a:focus-visible{ outline:2px solid #74d0ff; outline-offset:2px; }

@media (min-width:721px){
  .toc{ top:10px; background:transparent; border:none; padding:0; }
  .toc a{ border:none; padding:0; margin:0 12px 0 0; }
}

/* Cartes repliables sur mobile */
.card-toggle{ display:none; }
@media (max-width:720px){
  .card-toggle{ display:inline-flex; align-items:center; gap:6px; font-size:13px;
                padding:4px 8px; border:1px solid var(--border); border-radius:999px; }
  .card.is-collapsed .card-content{ display:none; }
}
CSS
fi

# ---------- JS ----------
M2='/* == addons:toc+cards v1 == */'
if ! mark "$M2" "$JS"; then
cat >> "$JS" <<'JS'
/* == addons:toc+cards v1 == */
(()=>{"use strict";

/* ToC auto depuis tous les <h2 id="..."> présents */
(function(){
  const hs=[...document.querySelectorAll('h2[id]')];
  if(hs.length<2) return;
  const toc=document.createElement('nav'); toc.className='toc';
  hs.forEach(h=>{
    const a=document.createElement('a'); a.href='#'+h.id; a.textContent=h.textContent.trim();
    toc.appendChild(a);
  });
  const host=document.querySelector('section, main, .hero, body');
  (host?.firstChild?host:document.body).insertBefore(toc, host.firstChild||document.body.firstChild);
})();

/* Cartes repliables en mobile : ouvertes en desktop */
(function(){
  const mq=matchMedia('(max-width:720px)');
  const cards=[...document.querySelectorAll('.card')];
  if(!cards.length) return;

  // s'assure d'avoir un conteneur .card-content & un bouton
  cards.forEach(card=>{
    // ne touche pas aux cartes déjà préparées
    if(!card.querySelector('.card-content')){
      const h3=card.querySelector('h3,header h3')||card.firstElementChild;
      const wrap=document.createElement('div'); wrap.className='card-content';
      // prend tous les suivants du titre dans la carte
      let n=h3?.nextSibling;
      const bucket=[];
      while(n){ const next=n.nextSibling; bucket.push(n); n=next; }
      bucket.forEach(x=>wrap.appendChild(x));
      card.appendChild(wrap);
    }
    if(!card.querySelector('.card-toggle')){
      const h3=card.querySelector('h3,header h3')||card.firstElementChild;
      if(h3){
        const btn=document.createElement('button');
        btn.type='button'; btn.className='card-toggle'; btn.textContent='Afficher';
        h3.appendChild(btn);
        btn.addEventListener('click',()=>{
          card.classList.toggle('is-collapsed');
          btn.textContent=card.classList.contains('is-collapsed')?'Afficher':'Masquer';
        });
      }
    }
  });

  const apply=()=>{ cards.forEach(c=>{
    if(mq.matches) c.classList.add('is-collapsed'); else c.classList.remove('is-collapsed');
    const btn=c.querySelector('.card-toggle'); if(btn) btn.textContent = c.classList.contains('is-collapsed')?'Afficher':'Masquer';
  }); };
  apply(); mq.addEventListener('change',apply);
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
  git commit -m "ux(addons): ToC auto + cartes repliables (mobile) + cache bust v$ts" || true
  ./deploy_now.sh
else
  echo "⚠️ deploy_now.sh non trouvé : commit/déploiement sautés."
fi

echo "✅ Pack ADD-ONS appliqué."
