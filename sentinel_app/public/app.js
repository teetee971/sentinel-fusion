
document.getElementById('init').addEventListener('click', async () => {
  const question = prompt("Pose ta question à Sentinel IA");
  if (!question) return;

  const res = await fetch("/api/ia", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ prompt: question })
  });

  const data = await res.json();
  const response = data.response || "Pas de réponse IA.";

  alert(response);

  // 🔊 Lecture vocale automatique
  const synth = window.speechSynthesis;
  const utter = new SpeechSynthesisUtterance(response);
  utter.lang = "fr-FR"; // Changer ici pour d'autres langues : "en-US", "es-ES", etc.
  utter.pitch = 1.0;
  utter.rate = 1.0;
  synth.speak(utter);
});
// == vnp:ui v1 ==
(function(){
  const EP = window.VNP_ENDPOINT||'';
  function vnpToast(msg){
    let t=document.querySelector('.vnp-toast');
    if(!t){ t=document.createElement('div'); t.className='vnp-toast'; document.body.appendChild(t); }
    t.textContent=msg; t.classList.add('show'); clearTimeout(t._to);
    t._to=setTimeout(()=>t.classList.remove('show'),2600);
  }
  function ensureModal(){
    let m=document.querySelector('.vnp-modal'); if(m) return m;
    m=document.createElement('div'); m.className='vnp-modal';
    m.innerHTML='<div class="vnp-card"><h3>Bouclier mobile — activation</h3>\
      <form class="vnp-form" novalidate>\
        <input class="hp" name="_gotcha" tabindex="-1" autocomplete="off" style="position:absolute;left:-9999px;opacity:0">\
        <div class="vnp-row">\
          <label>Téléphone*<br><input type="tel" name="phone" required placeholder="+33…"></label>\
          <label>Plateforme<br><select name="platform"><option>Android</option><option>iOS</option></select></label>\
        </div>\
        <label>E-mail (optionnel)<br><input type="email" name="email" placeholder="vous@exemple.fr"></label>\
        <label>Message (optionnel)<br><textarea name="message" rows="3" placeholder="Contexte, besoins…"></textarea></label>\
        <div class="vnp-actions"><button type="button" data-cancel>Fermer</button><button type="submit" class="btn">Activer</button></div>\
      </form></div>';
    document.body.appendChild(m);
    m.addEventListener('click',e=>{ if(e.target===m) m.classList.remove('open'); });
    m.querySelector('[data-cancel]').addEventListener('click',()=>m.classList.remove('open'));
    const form=m.querySelector('form');
    form.addEventListener('submit',async(ev)=>{
      ev.preventDefault(); if(!EP){ vnpToast('Endpoint VNP manquant.'); return; }
      const fd=new FormData(form);
      const phone=(fd.get('phone')||'').toString().trim();
      if(phone.length<5){ vnpToast('Téléphone invalide.'); return; }
      const payload={
        phone, platform:(fd.get('platform')||'').toString(),
        email:(fd.get('email')||'').toString().trim(),
        message:(fd.get('message')||'').toString().trim(),
        page:location.href, t:new Date().toISOString()
      };
      const btn=form.querySelector('[type="submit"]'); btn.classList.add('is-busy');
      try{
        const r=await fetch(EP,{
          method:'POST',
          headers:{'Content-Type':'application/json','Accept':'application/json'},
          body:JSON.stringify(payload)
        });
        if(r.ok){ vnpToast('Demande envoyée.'); form.reset(); m.classList.remove('open'); }
        else{ vnpToast('Échec envoi.'); }
      }catch(_){ vnpToast('Réseau indisponible.'); }
      btn.classList.remove('is-busy');
    });
    return m;
  }
  function open(){ ensureModal().classList.add('open'); }
  document.querySelectorAll('a[href="#vnp"],[data-vnp],.js-vnp-open').forEach(el=>{
    el.addEventListener('click',e=>{ e.preventDefault(); open(); });
  });
  if (matchMedia('(max-width:720px)').matches){
    const src=document.querySelector('a[href="#vnp"],[data-vnp],.js-vnp-open');
    if(src){
      const fab=document.createElement('div'); fab.className='vnp-fab';
      const cta=src.cloneNode(true); cta.textContent=src.textContent||'Activer le bouclier';
      fab.appendChild(cta); document.body.appendChild(fab); document.body.classList.add('has-vnp');
      cta.addEventListener('click',e=>{ e.preventDefault(); open(); });
    }
  }
})();
// >>> nav-glide v1 >>>
(function(){
  const nav=document.querySelector('nav.sub');
  if(!nav) return;
  let ind=nav.querySelector('.indicator');
  if(!ind){ ind=document.createElement('i'); ind.className='indicator'; nav.appendChild(ind); }
  nav.setAttribute('data-glide','');

  const links=[...nav.querySelectorAll('a')];

  function moveTo(el){
    if(!el) return;
    const nr=nav.getBoundingClientRect();
    const r=el.getBoundingClientRect();
    nav.style.setProperty('--ind-x', (r.left - nr.left)+'px');
    nav.style.setProperty('--ind-w', r.width+'px');
  }

  function currentLink(){
    const page=(document.body.getAttribute('data-page')||location.pathname)
      .replace(/\/index\.html$/,'/');
    return links.find(a=>{
      const href=(a.getAttribute('href')||'').replace(/\.html$/,'');
      if(page==='/' && (href==='/'||/index$/.test(href))) return true;
      return href && page && href.startsWith(page);
    }) || links[0];
  }

  let active=currentLink();
  moveTo(active);

  links.forEach(a=>{
    a.addEventListener('mouseenter', ()=>moveTo(a));
    a.addEventListener('focus',      ()=>moveTo(a));
    a.addEventListener('click',      ()=>{ active=a; });
  });
  nav.addEventListener('mouseleave', ()=>moveTo(active));
  window.addEventListener('resize',  ()=>moveTo(active));
})();
// <<< nav-glide v1 <<<
// ux(table): inject data-labels for stacked cards on mobile
(function(){
  document.querySelectorAll('table.compare').forEach(tbl=>{
    const heads=[...tbl.querySelectorAll('thead th')].map(th=>th.textContent.trim());
    tbl.querySelectorAll('tbody tr').forEach(tr=>{
      [...tr.children].forEach((td,i)=> td.setAttribute('data-label', heads[i]||''));
    });
  });
})();
// ux(card): make .card collapsible (mobile closed by default)
(function(){
  const mq = window.matchMedia('(max-width:720px)');
  document.querySelectorAll('.card').forEach(card=>{
    const h3 = card.querySelector('h3'); if(!h3) return;
    const btn=document.createElement('button'); btn.className='card-toggle'; btn.innerHTML=h3.innerHTML;
    h3.replaceWith(btn);
    const content=document.createElement('div'); content.className='card-content';
    while(btn.nextSibling){ content.appendChild(btn.nextSibling); }
    card.appendChild(content);
    const set = open => { content.style.display=open?'block':'none'; card.classList.toggle('is-open',open); };
    set(!mq.matches);                            // desktop: open, mobile: closed
    btn.addEventListener('click',()=> set(!card.classList.contains('is-open')));
    mq.addEventListener('change',()=> set(!mq.matches));
  });
})();
// ux(toc): build a chip bar from page <h2 id="...">
(function(){
  const hs=[...document.querySelectorAll('h2[id]')];
  if(hs.length<2) return;
  const toc=document.createElement('nav'); toc.className='toc';
  hs.forEach(h=>{ const a=document.createElement('a'); a.href='#'+h.id; a.textContent=h.textContent.trim(); toc.appendChild(a); });
  const firstSection=document.querySelector('.section') || document.body.firstChild;
  document.body.insertBefore(toc, firstSection);
})();
// ux(CTA mobile): float primary hero button
(function(){
  if(!matchMedia('(max-width:720px)').matches) return;
  const btn=document.querySelector('.hero .btn') || document.querySelector('a.btn[href*="contact"], a.btn[href*="#contact"]');
  if(!btn) return;
  btn.classList.add('cta-fab');
  document.body.classList.add('has-cta');
})();
// ux(podiums->chips): transforme les paragraphes "🥇/🥈/🥉 ..." en chips compactes
(function(){
  const h=[...document.querySelectorAll('h2,h3')]
    .find(n=>/Podiums?\s+par\s+usage/i.test(n.textContent));
  if(!h) return;

  // Récupère tous les paragraphes/puces jusqu'au prochain H2/H3
  const nodes=[]; let el=h.nextElementSibling;
  while(el && !/^H[23]$/.test(el.tagName)){ if(el.matches('p,li')) nodes.push(el); el=el.nextElementSibling; }

  if(!nodes.length) return;
  const box=document.createElement('div');

  nodes.forEach(n=>{
    const txt=n.textContent.trim(); const split=txt.split(':');
    if(split.length<2) return;
    const title=split.shift().trim();
    const wrap=document.createElement('div'); wrap.className='podium';
    wrap.innerHTML=`<div class="podium-title">${title}</div><div class="chips"></div>`;
    const target=wrap.querySelector('.chips');

    split.join(':').split(/•|,|\u00B7/).map(s=>s.trim()).filter(Boolean).forEach(item=>{
      const medal=(item.match(/(🥇|🥈|🥉)/)||[])[1]||'';
      const label=item.replace(/(🥇|🥈|🥉)/g,'').trim().replace(/^[-–•]+/,'');
      const chip=document.createElement('span'); chip.className='chip';
      if(medal){ const i=document.createElement('span'); i.className='chip-medal'; i.textContent=medal; chip.appendChild(i); }
      const l=document.createElement('span'); l.className='label'; l.textContent=label; chip.appendChild(l);
      target.appendChild(chip);
    });

    box.appendChild(wrap);
    n.remove(); // remplace le paragraphe par le bloc chips
  });

  h.insertAdjacentElement('afterend', box);
})();
// === ux:mobile-pack v1 ===

// Sommaire depuis les <h2 id="...">
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

// Table -> cartes : data-labels depuis THEAD
(function(){
  const t=document.querySelector('table.compare'); if(!t) return;
  const heads=[...t.querySelectorAll('thead th')].map(th=>th.textContent.trim());
  t.querySelectorAll('tbody tr').forEach(tr=>{
    [...tr.children].forEach((td,i)=>td.setAttribute('data-label', heads[i]||''));
  });
})();

// CTA flottant (duplique le bouton contact/démo)
(function(){
  if(!matchMedia('(max-width:720px)').matches) return;
  const src=document.querySelector('.hero .btn')||
             document.querySelector('a.btn[href*="contact"]')||
             document.querySelector('a[href*="#contact"]');
  if(!src) return;
  const wrap=document.createElement('div'); wrap.className='cta-fab';
  wrap.appendChild(src.cloneNode(true));
  document.body.appendChild(wrap);
})();

// === /ux:mobile-pack v1 ===
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
