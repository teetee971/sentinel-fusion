
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
