const THEME_KEY="sentinel-theme";
const root=document.documentElement;
function applyTheme(n){ root.classList.toggle('dark', n==='dark'); }
applyTheme(localStorage.getItem(THEME_KEY)||'dark');
document.getElementById('toggleTheme')?.addEventListener('click',()=>{
  const next=root.classList.contains('dark')?'light':'dark';
  localStorage.setItem(THEME_KEY,next); applyTheme(next);
});
document.getElementById('year').textContent=new Date().getFullYear();

// Smooth scroll
document.querySelectorAll('a[href^="#"]').forEach(a=>{
  a.addEventListener('click',e=>{ const id=a.getAttribute('href'); if(id.length>1){ e.preventDefault(); document.querySelector(id)?.scrollIntoView({behavior:'smooth'}); }});
});

// Mini évaluation (démo)
document.getElementById('startEval')?.addEventListener('click',()=>{
  const res=document.getElementById('evalResult');
  res.textContent="Analyse en cours… (démo)";
  setTimeout(()=>{res.textContent="Profil recommandé : Premium IA+ (détection proactive + Quantum Shield).";},900);
});
// ===== PRO PATCH v2 : dock actif =====
document.querySelectorAll('.dock .dock-btn').forEach(btn=>{
  btn.addEventListener('click',()=>{
    document.querySelectorAll('.dock .dock-btn').forEach(b=>b.classList.remove('active'));
    btn.classList.add('active');
  });
});
