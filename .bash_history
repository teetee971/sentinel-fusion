      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: 'npm' }
      - name: Detect & Build
        id: b
        run: |
          if [ -f package.json ] && jq -e '.scripts.build?!=null' package.json >/dev/null 2>&1; then
            npm ci --omit=dev || npm i
            npm run build
            echo "dist=dist" >> "$GITHUB_OUTPUT"
          else
            echo "dist=." >> "$GITHUB_OUTPUT"
          fi
      - name: Deploy
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CF_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: ${{ secrets.CLOUDFLARE_PROJECT_NAME }}
          directory: ${{ steps.b.outputs.dist }}
          branch: ${{ secrets.CLOUDFLARE_PAGES_BRANCH || 'main' }}
YAML

cat > .gitignore <<'GIT'
node_modules/
dist/
.http.pid
GIT

git init -q
git config user.email "ci@example" ; git config user.name "Sentinel Bot"
git checkout -b "$DEFAULT_BRANCH"
git add -A && git commit -m "feat(ui): Fusion PS5 + Futur-Cyber"
# crée repo si besoin
REMOTE_URL="https://github.com/${GH_USER}/${REPO_NAME}.git"
curl -fsS -H "Authorization: token ${GH_TOKEN}" \
  -H "Content-Type: application/json" \
  -X POST "https://api.github.com/user/repos" \
  -d "{\"name\":\"${REPO_NAME}\",\"private\":false}" >/dev/null 2>&1 || true
git remote add origin "$REMOTE_URL" 2>/dev/null || git remote set-url origin "$REMOTE_URL"
git push -u origin "$DEFAULT_BRANCH" --force

echo "👉 Rendez-vous dans GitHub > Settings > Secrets and variables > Actions et ajoute:"
echo "   CF_API_TOKEN, CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_PROJECT_NAME, (optionnel) CLOUDFLARE_PAGES_BRANCH"
echo "Puis fais un commit/push pour déclencher le déploiement."
BASH

chmod +x deploy_github.sh
# 7) lance un preview
./preview.sh 5520
echo "✅ Pack prêt dans: $(pwd)"
# === Sentinel Fusion (PS5 + Futur-Cyber) ===
mkdir -p ~/sentinel_fusion && cd ~/sentinel_fusion
# 1) index.html
cat > index.html <<'HTML'
<!doctype html><html lang="fr" data-theme="dark">
<head>
  <meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>Sentinel Quantum Vanguard AI Pro</title>
  <link rel="stylesheet" href="style.css"/>
  <meta name="theme-color" content="#0a1222"/>
</head>
<body>
  <header class="topbar _container">
    <div class="ps5">PS5</div>
    <div class="brand"><span class="b-ic">🛡️</span><b>Sentinel</b> Quantum Vanguard <span class="tag">AI Pro</span></div>
    <div class="actions">
      <button id="themeBtn" class="btn ghost" title="Basculer le thème">🌗</button>
      <span id="clock" class="hint"></span>
    </div>
  </header>

  <main class="_container shell">
    <!-- Héro : blason + anneaux -->
    <section class="hero">
      <div class="shield">
        <div class="ring ring1"></div><div class="ring ring2"></div><div class="ring ring3"></div>
        <div class="core"></div>
      </div>
      <div class="hero-text">
        <h1>Sentinel Quantum Vanguard AI Pro</h1>
        <p class="sub">Protection proactive • Intelligence extrême • Résilience totale.</p>
      </div>
    </section>

    <!-- Grille des modules -->
    <section class="grid modules">
      <a class="card" id="btnCF"      data-ic="🧠">Cognitive Firewall</a>
      <a class="card" id="btnOSINT"   data-ic="🛰️">OSINT Intelligence</a>
      <a class="card" id="btnPrivacy" data-ic="🔐">Confidentialité Renforcée</a>
      <a class="card" id="btnVisualFW"data-ic="🧩">Pare-feu Visuel</a>
      <a class="card" id="btnIR"      data-ic="🛠️">Réponse Incident</a>
      <a class="card" id="btnAPT"     data-ic="🕵️">Détection APT / Pegasus</a>
      <a class="card" id="btnNetGuard"data-ic="📡">Garde Réseau</a>
      <a class="card" id="btnAuto"    data-ic="🔄">Mise à jour Automatique</a>
      <a class="card" id="btnQP"      data-ic="🎯">Quantum Protector</a>
      <a class="card" id="btnVault"   data-ic="🗄️">Coffre-fort de confidentialité</a>
      <a class="card" id="btnLauncher"data-ic="🎛️">Lanceur principal sécurisé</a>
      <a class="card" id="btnLog"     data-ic="📊">Journal IA en temps réel</a>
    </section>

    <!-- Panneaux : news + score + outils démo -->
    <section class="panels">
      <article class="panel">
        <div class="panel-title">Actualité Cyber & Modules IA</div>
        <ul id="newsList" class="news"></ul>
      </article>

      <article class="panel compact">
        <div class="panel-title">Security score</div>
        <div class="donut"><span id="scoreNum">96</span></div>
        <div class="bar"><i id="scoreBar" style="width:82%"></i></div>
      </article>

      <article class="panel">
        <div class="panel-title">Outils (démos branchées)</div>
        <div class="tools">
          <div class="row">
            <button id="btnIP">IP publique</button>
            <input id="domainInput" placeholder="ex: cloudflare.com"/>
            <button id="btnDNS">DNS Cloudflare</button>
            <button id="btnPing">Latence 1.1.1.1</button>
            <button id="btnFP">Fingerprint</button>
          </div>
          <pre id="toolOut" class="out"></pre>
        </div>
      </article>
    </section>
  </main>

  <footer class="_container footer">
    <span class="tagline">Protection proactive. Intelligence extrême. Résilience totale.</span>
  </footer>

  <script type="module" src="main.js"></script>
</body></html>
HTML

# 2) style.css (PS5 + Futur-Cyber)
cat > style.css <<'CSS'
:root{
  --bg:#0a1020;--panel:#0e162a;--panel2:#0b1426;--glass:#0b1630b8;
  --text:#e9eef8;--muted:#98a7c6;--border:rgba(130,170,210,.25);
  --primary:#63a4ff;--accent:#22d3ee;--glow:#3aa2ff;--ok:#3ddc97;--warn:#ffcb6b;
}
*{box-sizing:border-box}html,body{height:100%}
body{
  margin:0;color:var(--text);font:15px/1.55 Inter,system-ui,"Segoe UI",Roboto,Arial;
  background:
    radial-gradient(1200px 620px at 10% -10%, #0f203e 0%, transparent 55%),
    radial-gradient(1200px 520px at 110% -10%, #0b1a37 0%, transparent 60%),
    var(--bg);
}
._container{max-width:1120px;margin:auto;padding:22px 18px}

/* Topbar */
.topbar{display:flex;align-items:center;justify-content:space-between;gap:12px}
.ps5{letter-spacing:.4px;opacity:.7}
.brand{display:flex;align-items:center;gap:8px;font-weight:700}
.b-ic{display:grid;place-items:center;width:28px;height:28px;border-radius:8px;background:#0d1a33;border:1px solid var(--border)}
.tag{color:var(--accent);font-weight:700}
.actions{display:flex;align-items:center;gap:10px}
.btn{border:1px solid var(--border);background:#0f1a2f;color:var(--text);border-radius:10px;padding:8px 10px}
.btn.ghost{background:transparent}
.hint{color:var(--muted)}

/* Hero */
.shell{display:grid;gap:22px}
.hero{display:grid;grid-template-columns:200px 1fr;gap:22px;align-items:center}
@media (max-width:900px){.hero{grid-template-columns:1fr}}
.shield{position:relative;width:200px;height:200px;margin:auto}
.ring{position:absolute;inset:0;border-radius:50%}
.ring1{box-shadow:0 0 60px rgba(99,164,255,.35) inset}
.ring2{border:2px dashed rgba(99,164,255,.25);animation:spin 22s linear infinite}
.ring3{border:2px solid rgba(99,164,255,.12);box-shadow:0 0 0 25px rgba(99,164,255,.08) inset}
.core{position:absolute;inset:35px;border-radius:14px;background:radial-gradient(120px 80px at 50% 40%,rgba(99,164,255,.45),transparent 60%),#081227;border:1px solid rgba(99,164,255,.35);box-shadow:0 12px 60px rgba(0,0,0,.55),0 0 32px rgba(99,164,255,.35)}
@keyframes spin{to{transform:rotate(360deg)}}
.hero-text h1{margin:0;font-size:28px}
.hero-text .sub{margin:6px 0 0;color:var(--muted)}

/* Modules (PS5 tiles) */
.grid{display:grid;gap:14px}
.modules{grid-template-columns:repeat(auto-fit,minmax(210px,1fr))}
.card{
  display:flex;align-items:center;gap:12px;padding:16px;border-radius:16px;
  background:linear-gradient(180deg,var(--panel),var(--panel2));
  border:1px solid var(--border);position:relative;overflow:hidden;
  box-shadow:0 1px 0 rgba(255,255,255,.02) inset,0 16px 40px rgba(0,0,0,.40);
  transition:.18s ease; font-weight:650; letter-spacing:.2px;
}
.card:hover{transform:translateY(-2px); box-shadow:0 0 0 1px var(--primary),0 24px 46px rgba(0,0,0,.55)}
.card::before{
  content:attr(data-ic); display:grid;place-items:center; font-size:18px;
  width:40px;height:40px;border-radius:12px; background:rgba(99,164,255,.12);
  border:1px solid rgba(99,164,255,.35); box-shadow:0 0 16px rgba(99,164,255,.28);
}

/* Panneaux */
.panels{display:grid;grid-template-columns:1.4fr .8fr 1fr;gap:18px}
@media (max-width:1024px){.panels{grid-template-columns:1fr}}
.panel{
  padding:16px;border-radius:16px;background:linear-gradient(180deg,var(--panel),var(--panel2));
  border:1px solid var(--border); box-shadow:0 10px 28px rgba(0,0,0,.35);
}
.panel-title{font-weight:750;margin-bottom:8px}
.compact .donut{display:grid;place-items:center;font-weight:800;font-size:28px;text-align:center}
.bar{height:8px;border-radius:999px;background:rgba(255,255,255,.06);overflow:hidden}
.bar>i{display:block;height:100%;background:linear-gradient(90deg,var(--accent),var(--primary))}

/* News */
.news{list-style:none;margin:0;padding:0;display:grid;gap:10px}
.news li{padding:10px 12px;border-radius:12px;background:linear-gradient(180deg,var(--panel),var(--panel2));border:1px solid var(--border)}
.news .t{font-weight:700}.news .m{font-size:12px;color:var(--muted)}

/* Outils */
.tools{display:grid;gap:12px}.row{display:grid;gap:8px;grid-template-columns:repeat(auto-fit,minmax(160px,1fr))}
.tools input, .tools button{border-radius:10px;border:1px solid var(--border);padding:8px;background:#0b1426;color:var(--text)}
.out{max-height:160px;overflow:auto;background:#0b1324;border:1px solid var(--border);padding:8px;border-radius:10px}

/* Light alt */
[data-theme="light"]{
  --bg:#0f1730;--panel:#111c3c;--panel2:#0f1a36;--text:#eef3ff;--muted:#a2b3d2;--border:rgba(130,170,210,.35);
}
.footer{display:flex;justify-content:center;padding:12px}
.tagline{color:var(--muted)}
CSS

# 3) main.js (export toast + wire actu/score + thème)
cat > main.js <<'JS'
export function toast(msg){
  const t=document.createElement('div');
  t.className='toast';
  t.textContent=msg;
  Object.assign(t.style,{position:'fixed',bottom:'20px',left:'50%',transform:'translateX(-50%)',
    background:'rgba(15,25,50,.85)',border:'1px solid rgba(130,170,210,.35)',padding:'10px 12px',
    borderRadius:'10px',backdropFilter:'blur(8px)',zIndex:9999});
  document.body.appendChild(t); setTimeout(()=>t.remove(),1800);
}

const THEME_KEY='sentinel-theme', body=document.body;
// boot thème
(function(){
  const t=localStorage.getItem(THEME_KEY)||'dark';
  body.setAttribute('data-theme',t);
})();
document.getElementById('themeBtn')?.addEventListener('click',()=>{
  const next=body.getAttribute('data-theme')==='dark'?'light':'dark';
  body.setAttribute('data-theme',next); localStorage.setItem(THEME_KEY,next);
});

// horloge
(function tick(){
  const el=document.getElementById('clock');
  if(el) el.textContent=new Date().toLocaleString('fr-FR',{weekday:'long',day:'2-digit',month:'long',hour:'2-digit',minute:'2-digit'});
  setTimeout(tick,30000);
})();

// score (démo)
(function score(){
  const s=92+Math.floor(Math.random()*6);
  const n=document.getElementById('scoreNum'); const b=document.getElementById('scoreBar');
  if(n) n.textContent=String(s); if(b) b.style.width=s+'%';
})();

// actus (démo statique)
const feed=[
 {t:"Nouvelle attaque Zero-Day détectée (CVE-2025-5433) ciblant routeurs TP-Link", m:"Vulnérabilités · CERT EU · 5 min"},
 {t:"Propagande IA détectée sur réseaux sociaux en Europe de l’Est", m:"VPN · Cloudflare Radar · 1 h"},
 {t:"Restrictions VPN en Iran : hausse de la censure Internet", m:"IA · The Hacker News · 9 h"},
 {t:"Ransomware ciblant 4200 hôpitaux aux États-Unis", m:"IA · The Hacker News · 9 h"}
];
(function news(){
  const ul=document.getElementById('newsList'); if(!ul) return;
  feed.forEach(n=>{ const li=document.createElement('li'); li.innerHTML=`<div class="t">• ${n.t}</div><div class="m">${n.m}</div>`; ul.appendChild(li); });
})();

// charge les modules (liaisons boutons + outils)
import './modules.js';
JS

# 4) modules.js (outils branchés)
cat > modules.js <<'JS'
import { toast } from "./main.js";
const out = document.getElementById('toolOut');
const write = (o) => { out.textContent = (typeof o==="string"?o:JSON.stringify(o,null,2)); };

// IP publique (ipify)
async function publicIP(){
  try{
    const r = await fetch('https://api.ipify.org?format=json',{cache:'no-store'});
    const j = await r.json(); write(j); toast(`IP publique: ${j.ip}`);
  }catch(e){ write(String(e)); toast('IP: erreur'); }
}

// DNS Cloudflare (application/dns-json)
async function dnsQuery(name){
  const q = name?.trim(); if(!q) return write("Entrez un nom de domaine.");
  try{
    const url=`https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(q)}&type=A`;
    const r = await fetch(url,{headers:{'accept':'application/dns-json'}}); const j=await r.json();
    write(j); toast(`DNS ${q} → ${j?.Answer?.[0]?.data||'—'}`);
  }catch(e){ write(String(e)); toast('DNS: erreur'); }
}

// Latence vers 1.1.1.1
async function latency(){
  try{
    const t0=performance.now();
    await fetch('https://1.1.1.1/cdn-cgi/trace',{cache:'no-store'});
    const ms=Math.round(performance.now()-t0);
    write({latency_ms:ms}); toast(`Latence ~ ${ms} ms`);
  }catch(e){ write(String(e)); toast('Latence: erreur'); }
}

// Fingerprint léger (local)
function fingerprint(){
  const d=window.devicePixelRatio||1;
  const fp={
    ua:navigator.userAgent,
    lang:navigator.language,
    tz:Intl.DateTimeFormat().resolvedOptions().timeZone,
    mem:navigator.deviceMemory??'n/a',
    cores:navigator.hardwareConcurrency??'n/a',
    screen:{w:screen.width,h:screen.height,dpr:d}
  };
  write(fp); toast("Fingerprint local généré");
}

// Bind
document.getElementById('btnIP')   ?.addEventListener('click', publicIP);
document.getElementById('btnDNS')  ?.addEventListener('click', ()=>dnsQuery(document.getElementById('domainInput')?.value));
document.getElementById('btnPing') ?.addEventListener('click', latency);
document.getElementById('btnFP')   ?.addEventListener('click', fingerprint);

// Démos “modules” (clics tuiles)
function bindDemo(id,label){ document.getElementById(id)?.addEventListener('click',()=>toast(`${label} (démo)`)); }
bindDemo('btnCF','Cognitive Firewall'); bindDemo('btnOSINT','OSINT Intelligence');
bindDemo('btnPrivacy','Confidentialité Renforcée'); bindDemo('btnVisualFW','Pare-feu Visuel');
bindDemo('btnIR','Réponse Incident'); bindDemo('btnAPT','Détection APT / Pegasus');
bindDemo('btnNetGuard','Garde Réseau'); bindDemo('btnAuto','Mises à jour Automatiques');
bindDemo('btnQP','Quantum Protector'); bindDemo('btnVault','Coffre-fort');
bindDemo('btnLauncher','Lanceur sécurisé'); bindDemo('btnLog','Journal IA temps réel');
JS

# 5) mini preview local (évite les conflits Vite)
cat > preview.sh <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
PORT="${1:-5520}"
# stop précédent
[ -f .http.pid ] && kill $(cat .http.pid) 2>/dev/null || true
nohup python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 & echo $! > .http.pid
echo "✅ Serveur prêt: http://127.0.0.1:$PORT/"
command -v termux-open-url >/dev/null 2>&1 && termux-open-url "http://127.0.0.1:$PORT/" || true
BASH

chmod +x preview.sh
# 6) déploiement via GitHub → Cloudflare Pages
cat > deploy_github.sh <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
# Prérequis: GH_TOKEN (PAT), CF_API_TOKEN (Pages:Edit), CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_PROJECT_NAME
: "${GH_TOKEN:?GH_TOKEN manquant}"
: "${CF_API_TOKEN:?CF_API_TOKEN manquant}"
: "${CLOUDFLARE_ACCOUNT_ID:?CLOUDFLARE_ACCOUNT_ID manquant}"
: "${CLOUDFLARE_PROJECT_NAME:?CLOUDFLARE_PROJECT_NAME manquant}"
GH_USER="${GH_USER:-$(whoami)}"
REPO_NAME="${REPO_NAME:-sentinel-fusion}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"

mkdir -p .github/workflows
cat > .github/workflows/deploy-cloudflare.yml <<'YAML'
name: Deploy to Cloudflare Pages
on: { push: { branches: ["main"] } }
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: 'npm' }
      - name: Detect & Build
        id: b
        run: |
          if [ -f package.json ] && jq -e '.scripts.build?!=null' package.json >/dev/null 2>&1; then
            npm ci --omit=dev || npm i
            npm run build
            echo "dist=dist" >> "$GITHUB_OUTPUT"
          else
            echo "dist=." >> "$GITHUB_OUTPUT"
          fi
      - name: Deploy
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CF_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: ${{ secrets.CLOUDFLARE_PROJECT_NAME }}
          directory: ${{ steps.b.outputs.dist }}
          branch: ${{ secrets.CLOUDFLARE_PAGES_BRANCH || 'main' }}
YAML

cat > .gitignore <<'GIT'
node_modules/
dist/
.http.pid
GIT

git init -q
git config user.email "ci@example" ; git config user.name "Sentinel Bot"
git checkout -b "$DEFAULT_BRANCH"
git add -A && git commit -m "feat(ui): Fusion PS5 + Futur-Cyber"
# crée repo si besoin
REMOTE_URL="https://github.com/${GH_USER}/${REPO_NAME}.git"
curl -fsS -H "Authorization: token ${GH_TOKEN}" \
  -H "Content-Type: application/json" \
  -X POST "https://api.github.com/user/repos" \
  -d "{\"name\":\"${REPO_NAME}\",\"private\":false}" >/dev/null 2>&1 || true
git remote add origin "$REMOTE_URL" 2>/dev/null || git remote set-url origin "$REMOTE_URL"
git push -u origin "$DEFAULT_BRANCH" --force

echo "👉 Rendez-vous dans GitHub > Settings > Secrets and variables > Actions et ajoute:"
echo "   CF_API_TOKEN, CLOUDFLARE_ACCOUNT_ID, CLOUDFLARE_PROJECT_NAME, (optionnel) CLOUDFLARE_PAGES_BRANCH"
echo "Puis fais un commit/push pour déclencher le déploiement."
BASH

chmod +x deploy_github.sh
# 7) lance un preview
./preview.sh 5520
echo "✅ Pack prêt dans: $(pwd)"
export GH_TOKEN="TON_PAT_GITHUB"
export GH_USER="TonUserGithub"
export CLOUDFLARE_ACCOUNT_ID="xxx"
export CF_API_TOKEN="xxx"
export CLOUDFLARE_PROJECT_NAME="sentinel-fusion"
./deploy_github.sh
# 1) Te placer sur main (la créer si elle n’existe pas)
git checkout main 2>/dev/null || git checkout -b main
# 2) Ajouter / committer (le commit est tolérant s’il n’y a rien à committer)
git add -A
git commit -m "chore: sync deploy" || true
# 3) S'assurer du remote puis pousser
REMOTE_URL="https://github.com/${GH_USER:-TonUserGithub}/sentinel-fusion.git"
git remote get-url origin >/dev/null 2>&1 || git remote add origin "$REMOTE_URL"
git push -u origin main
#!/usr/bin/env bash
set -euo pipefail
: "${GH_TOKEN:?GH_TOKEN manquant}"
: "${CF_API_TOKEN:?CF_API_TOKEN manquant}"
: "${CLOUDFLARE_ACCOUNT_ID:?CLOUDFLARE_ACCOUNT_ID manquant}"
: "${CLOUDFLARE_PROJECT_NAME:?CLOUDFLARE_PROJECT_NAME manquant}"
GH_USER="${GH_USER:-$(whoami)}"
REPO_NAME="${REPO_NAME:-sentinel-fusion}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
mkdir -p .github/workflows
cat > .github/workflows/deploy-cloudflare.yml <<'YAML'
name: Deploy to Cloudflare Pages
on: { push: { branches: ["main"] } }
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: 'npm' }
      - name: Detect & Build
        id: b
        run: |
          if [ -f package.json ] && jq -e '.scripts.build?!=null' package.json >/dev/null 2>&1; then
            npm ci --omit=dev || npm i
            npm run build
            echo "dist=dist" >> "$GITHUB_OUTPUT"
          else
            echo "dist=." >> "$GITHUB_OUTPUT"
          fi
      - name: Deploy
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CF_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: ${{ secrets.CLOUDFLARE_PROJECT_NAME }}
          directory: ${{ steps.b.outputs.dist }}
          branch: ${{ secrets.CLOUDFLARE_PAGES_BRANCH || 'main' }}
YAML

cat > .gitignore <<'GIT'
node_modules/
dist/
.http.pid
GIT

# --- Git idempotent ---
if [ ! -d .git ]; then git init -q; fi
git config user.email "ci@example" ; git config user.name "Sentinel Bot"
if git show-ref --verify --quiet "refs/heads/$DEFAULT_BRANCH"; then   git checkout "$DEFAULT_BRANCH"; else   git checkout -b "$DEFAULT_BRANCH"; fi
git add -A
git commit -m "feat(ui): Fusion PS5 + Futur-Cyber" || true
REMOTE_URL="https://github.com/${GH_USER}/${REPO_NAME}.git"
# Créer le repo si besoin (silencieux si déjà présent)
curl -fsS -H "Authorization: token ${GH_TOKEN}"   -H "Content-Type: application/json"   -X POST "https://api.github.com/user/repos"   -d "{\"name\":\"${REPO_NAME}\",\"private\":false}" >/dev/null 2>&1 || true
git remote get-url origin >/dev/null 2>&1 || git remote add origin "$REMOTE_URL"
git push -u origin "$DEFAULT_BRANCH"
