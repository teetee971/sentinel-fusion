#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
APP_DIR="${APP_DIR:-$HOME/sentinel_app}"
say(){ printf "\033[1;36m[✔]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[✘]\033[0m %s\n" "$*" >&2; exit 1; }
[ -d "$APP_DIR" ] || err "Dossier introuvable: $APP_DIR"
cd "$APP_DIR"

say "Écriture de landing.html / landing.css / landing.js …"

# ----------------------------- landing.html -----------------------------
cat > landing.html <<'HTML'
<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Sentinel – Quantum Vanguard AI Pro</title>
  <link rel="stylesheet" href="landing.css" />
</head>
<body>
  <header class="appbar container">
    <div class="brand">
      <span class="logo" aria-hidden="true">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" aria-hidden="true">
          <path d="M12 2l8 3v6c0 5.25-3.5 9.63-8 11-4.5-1.37-8-5.75-8-11V5l8-3Z" stroke="url(#g)" stroke-width="1.4"/>
          <defs><linearGradient id="g" x1="0" y1="0" x2="24" y2="24">
            <stop stop-color="#59a7ff"/><stop offset="1" stop-color="#22d3ee"/></linearGradient></defs>
        </svg>
      </span>
      <div class="brand-text"><strong>Sentinel</strong> Quantum Vanguard <span class="tag">AI&nbsp;Pro</span></div>
    </div>
    <nav class="nav">
      <a href="#modules">Modules</a>
      <a href="#pricing">Tarifs</a>
      <a href="#faq">FAQ</a>
      <a class="btn small" href="index.html">Ouvrir le Dashboard</a>
      <button id="toggleTheme" class="btn ghost small" aria-label="Thème">🌗</button>
    </nav>
  </header>

  <!-- HERO -->
  <section class="hero container">
    <div class="hero-text">
      <h1>La sécurité du futur, <span class="accent">dès aujourd’hui</span></h1>
      <p>IA prédictive, analyse comportementale, OSINT en direct et bouclier quantique.
         Protégez vos appareils et vos équipes avec une console unique.</p>
      <div class="hero-cta">
        <a href="#audit" class="btn primary">Lancer mon évaluation</a>
        <a href="index.html" class="btn">Voir le Dashboard</a>
      </div>
      <ul class="trust">
        <li>✅ Résilience absolue</li>
        <li>🛡️ Quantum Shield</li>
        <li>🔒 Chiffrement bout-à-bout</li>
      </ul>
    </div>
    <div class="hero-art" aria-hidden="true">
      <div class="orb orb-a"></div><div class="orb orb-b"></div><div class="orb orb-c"></div>
    </div>
  </section>

  <!-- MODULES -->
  <section id="modules" class="container">
    <h2 class="h2">Modules clés</h2>
    <div class="grid features">
      <article class="card feat" data-ic="🤖"><h3>IA Prédictive</h3><p>Analyse comportementale, détection proactive des signaux faibles.</p></article>
      <article class="card feat" data-ic="🌐"><h3>Scanner OSINT</h3><p>Veille sources ouvertes & Dark Web avec corrélation de risques.</p></article>
      <article class="card feat" data-ic="🛡️"><h3>Quantum Shield</h3><p>Bouclier de cybersécurité quantique (anti-interception).</p></article>
      <article class="card feat" data-ic="🔗"><h3>VPN IA</h3><p>Routage adaptatif, anti-censure, Smart-proxy intégré.</p></article>
      <article class="card feat" data-ic="📞"><h3>Call Screening</h3><p>Anti-démarchage, scoring des appels suspects en temps réel.</p></article>
      <article class="card feat" data-ic="🧩"><h3>DNS Proxy</h3><p>Filtrage DNS, blocage malveillant et politique par profil.</p></article>
    </div>
  </section>

  <!-- AUDIT -->
  <section id="audit" class="container audit">
    <h2 class="h2">Testez votre niveau en cybersécurité</h2>
    <p class="muted">Évaluation rapide basée sur l’IA (≈ 3 min) pour analyser vos risques et vous orienter vers une stratégie adaptée.</p>
    <form class="card audit-form" onsubmit="return false;">
      <label>Votre contexte principal
        <select>
          <option>Personnel</option><option>PME</option><option>Équipe Sécurité</option><option>Institution</option>
        </select>
      </label>
      <label>Surface d’attaque perçue
        <select>
          <option>Faible</option><option>Moyenne</option><option>Élevée</option>
        </select>
      </label>
      <button class="btn primary" id="startEval">Lancer l’évaluation</button>
      <div id="evalResult" class="hint"></div>
    </form>
  </section>

  <!-- PRICING -->
  <section id="pricing" class="container">
    <h2 class="h2">Choisissez votre plan</h2>
    <div class="grid pricing">
      <article class="card price">
        <div class="title">Gratuit</div>
        <div class="amount">0€</div>
        <ul><li>Console de base</li><li>Scanner OSINT (limité)</li><li>Mises à jour mensuelles</li></ul>
        <a class="btn" href="#audit">Commencer</a>
      </article>
      <article class="card price best">
        <div class="title">Premium IA+</div>
        <div class="amount">29€<span>/mois</span></div>
        <ul><li>IA prédictive complète</li><li>Quantum Shield</li><li>VPN IA + DNS Proxy</li><li>Équipe : jusqu’à 5 appareils</li></ul>
        <a class="btn primary" href="#audit">Essayer</a>
      </article>
      <article class="card price">
        <div class="title">Gouvernement Pro</div>
        <div class="amount">99€<span>/mois</span></div>
        <ul><li>Mode silencieux</li><li>Support dédié</li><li>Durcissement console</li></ul>
        <a class="btn" href="#audit">Nous contacter</a>
      </article>
    </div>
  </section>

  <!-- FAQ -->
  <section id="faq" class="container faq">
    <h2 class="h2">FAQ</h2>
    <details class="card"><summary>Comment fonctionne l’IA prédictive ?</summary><p>Elle corrèle événements, métriques et OSINT pour identifier des patterns précurseurs d’incidents.</p></details>
    <details class="card"><summary>Les données quittent-elles mon appareil ?</summary><p>Par défaut, le traitement se fait localement. Les envois vers le cloud sont optionnels et chiffrés.</p></details>
    <details class="card"><summary>Puis-je utiliser le dashboard sur mobile ?</summary><p>Oui, l’UI est responsive et optimisée pour les smartphones.</p></details>
  </section>

  <footer class="dock container foot">
    <small>© <span id="year"></span> Sentinel Quantum Vanguard AI Pro — Tous droits réservés.</small>
  </footer>

  <script type="module" src="landing.js"></script>
</body>
</html>
HTML

# ----------------------------- landing.css ------------------------------
cat > landing.css <<'CSS'
@import url("style.css"); /* réutilise le Thème Pro */

.nav{display:flex;gap:10px;align-items:center;flex-wrap:wrap}
.nav a{color:var(--text);text-decoration:none;opacity:.9}
.nav a:hover{opacity:1}
.btn.small{padding:6px 10px;font-size:13px}

.hero{display:grid;gap:24px;grid-template-columns:1.1fr .9fr;align-items:center;margin-top:6px}
@media (max-width:960px){ .hero{grid-template-columns:1fr} }
.hero-text h1{margin:0 0 8px;font-size:34px}
.hero-text p{margin:0 0 14px;max-width:60ch}
.hero-cta{display:flex;gap:10px;flex-wrap:wrap}
.btn.primary{background:linear-gradient(90deg,var(--accent),var(--primary));border-color:transparent}
.trust{display:flex;gap:16px;list-style:none;padding:0;margin:10px 0 0;color:var(--muted);flex-wrap:wrap}

.hero-art{position:relative;height:220px}
.orb{position:absolute;filter:blur(10px);border-radius:50%}
.orb-a{width:180px;height:180px;background:#1b94ff44;right:10%;top:10%}
.orb-b{width:140px;height:140px;background:#22d3ee55;right:28%;bottom:0}
.orb-c{width:90px;height:90px;background:#5b9dff66;right:0;bottom:20%}

.features{grid-template-columns:repeat(auto-fit,minmax(230px,1fr))}
.feat{min-height:130px}
.feat::before{
  content:attr(data-ic);display:inline-grid;place-items:center;margin-bottom:8px;
  width:38px;height:38px;border-radius:12px;background:rgba(91,157,255,.12);
  border:1px solid rgba(91,157,255,.32)
}
.audit{margin-top:8px}
.audit-form{display:grid;gap:12px;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));align-items:end}
.audit-form label{display:grid;gap:6px;font-size:14px}
.audit-form select{padding:10px;border-radius:10px;border:1px solid var(--border);background:#0f1a33;color:var(--text)}
.audit-form button{grid-column:1/-1}

.pricing{grid-template-columns:repeat(auto-fit,minmax(240px,1fr))}
.price .title{font-weight:800;margin-bottom:6px}
.price .amount{font-size:28px;font-weight:800;margin-bottom:8px}
.price.best{box-shadow:0 0 0 1px var(--primary),0 12px 30px rgba(0,0,0,.45)}
.price ul{margin:0 0 12px 16px}

.faq details{cursor:pointer}
.faq summary{font-weight:700;margin-bottom:6px}
.foot{justify-content:center;text-align:center}
CSS

# ----------------------------- landing.js -------------------------------
cat > landing.js <<'JS'
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
JS

say "Landing ajoutée."
echo "👉 Ouvre: http://127.0.0.1:5173/landing.html (via npm run preview)"
