#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
say(){ printf '\033[1;32m[✓]\033[0m %s\n' "$*"; }

# 1) CSS affiné (nav propre, pas de violet "visited")
cat > style.css <<'CSS'
:root{--bg:#fafafa;--surface:#fff;--text:#111827;--muted:#6b7280;--border:#e5e7eb;--accent:#0ea5e9;--success:#22c55e;--danger:#ef4444;--warning:#f59e0b}
:root.dark{--bg:#0f172a;--surface:#0b1220;--text:#e6edf3;--muted:#94a3b8;--border:#1f2937;--accent:#7dd3fc;--success:#34d399;--danger:#f87171;--warning:#fbbf24}
*{box-sizing:border-box}html,body{height:100%}body{margin:0;background:var(--bg);color:var(--text);font-family:ui-sans-serif,system-ui,"Segoe UI",Roboto,Arial,sans-serif}
.topbar{background:var(--surface);border-bottom:1px solid var(--border);padding:.75rem}
.brand{display:flex;align-items:center;gap:.5rem}.logo{filter:drop-shadow(0 0 4px color-mix(in srgb,var(--accent) 12%,transparent))}
.nav{display:flex;gap:.5rem;flex-wrap:wrap;margin-top:.5rem}
.nav a{color:var(--text);text-decoration:none;opacity:.8;padding:.25rem .5rem;border-radius:.375rem}
.nav a:visited{color:var(--text)}.nav a:hover{background-color:color-mix(in srgb,var(--surface) 60%,var(--accent));opacity:1}
.nav a.active{opacity:1;text-decoration:underline}
main{display:flex;flex-direction:column;gap:1rem;max-width:980px;margin:1rem auto;padding:0 1rem}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:1rem}
.card{background:var(--surface);border:1px solid var(--border);border-radius:.5rem;padding:1rem}.kpis{display:flex;gap:.75rem}
.value{font-size:1.8rem;font-weight:700}.hint{opacity:.7;font-size:.9rem}
.toolbar{display:flex;flex-wrap:wrap;gap:.5rem}
.btn{padding:.5rem .8rem;border:1px solid var(--border);border-radius:.5rem;background:var(--surface);cursor:pointer}
.btn:hover{filter:brightness(1.05)}.btn-primary{border-color:var(--accent)}
.alerts{list-style:none;margin:0;padding:0;display:grid;gap:.5rem}
.alerts li{display:flex;justify-content:space-between;align-items:center;border:1px solid var(--border);background:var(--surface);padding:.5rem .8rem;border-radius:.5rem}
.sev-high .hint{color:var(--danger)}.sev-medium .hint{color:var(--warning)}.sev-low .hint{color:var(--success)}
.table{width:100%;border-collapse:collapse}.table th,.table td{padding:.5rem;border-bottom:1px solid var(--border)}
.form-row{display:flex;align-items:center;gap:.75rem;padding:.5rem 0}
.footer{text-align:center;color:var(--muted);padding:2rem 1rem}
.view{display:none}.view.show{display:block}
CSS
say "CSS mis à jour"

# 2) JS : libellé bouton thème + reste
cat > main.js <<'JS'
"use strict";
// Thème
const THEME_KEY="sentinelle-theme";const root=document.documentElement;
function applyTheme(name){root.classList.toggle('dark',name==='dark');}
applyTheme(localStorage.getItem(THEME_KEY)||"light");
const toggleBtn=document.getElementById('toggleTheme');
const setThemeLabel=()=>{ if(toggleBtn){ toggleBtn.textContent=root.classList.contains('dark')?'Mode clair':'Mode sombre'; } };
setThemeLabel();
toggleBtn?.addEventListener('click',()=>{const next=root.classList.contains('dark')?'light':'dark';localStorage.setItem(THEME_KEY,next);applyTheme(next);setThemeLabel();});

// Navigation
document.querySelectorAll('.nav a').forEach(a=>{
  a.addEventListener('click',e=>{e.preventDefault();
    document.querySelectorAll('.nav a').forEach(x=>x.classList.remove('active'));a.classList.add('active');
    const id="view-"+a.dataset.view;document.querySelectorAll('.view').forEach(v=>v.classList.remove('show'));
    document.getElementById(id)?.classList.add('show');
    document.title="Sentinelle – "+a.textContent;
  });
});

// KPI + uptime
let start=Date.now();
setInterval(()=>{
  const det=Math.floor(Math.random()*7);
  document.getElementById('detectionsToday')?.replaceChildren(document.createTextNode(String(det)));
  document.getElementById('filesScanned')?.replaceChildren(document.createTextNode((1200+Math.floor(Math.random()*800)).toLocaleString('fr-FR')));
  const s=Math.floor((Date.now()-start)/1000),h=String(Math.floor(s/3600)).padStart(2,'0'),m=String(Math.floor((s%3600)/60)).padStart(2,'0'),ss=String(s%60).padStart(2,'0');
  document.getElementById('uptime')?.replaceChildren(document.createTextNode(`${h}:${m}:${ss}`));
},1000);

// Alertes démo
const alertsUL=document.getElementById('alerts')||document.getElementById('alerts2');
[{text:'Processus suspect bloqué',severity:'high'},{text:'Nouvelle règle appliquée',severity:'low'},{text:'Scan terminé (rapide)',severity:'medium'}]
.forEach(a=>{ if(!alertsUL) return; const li=document.createElement('li'); li.className=`sev-${a.severity}`; li.innerHTML=`<span>${a.text}</span><span class="hint">${a.severity}</span>`; alertsUL.appendChild(li);});

// Détections démo
const tbody=document.getElementById('detectionsTable');
[{time:'08:01',file:'/system/bin/app',type:'heuristique',severity:'high'},
 {time:'08:15',file:'/sdcard/Download/x.apk',type:'signature',severity:'low'},
 {time:'08:57',file:'/data/app/SoOn',type:'comportement',severity:'medium'}]
.forEach(r=>{ if(!tbody) return; const tr=document.createElement('tr'); tr.innerHTML=`<td>${r.time}</td><td>${r.file}</td><td>${r.type}</td><td>${r.severity}</td>`; tbody.appendChild(tr);});

// Scan manuel
document.getElementById('scanNow')?.addEventListener('click',()=>{
  const hhmm=new Date().toTimeString().slice(0,5);
  if(tbody){const tr=document.createElement('tr');tr.innerHTML=`<td>${hhmm}</td><td>/scan/manual</td><td>manual</td><td>info</td>`;tbody.prepend(tr);}
  if(alertsUL){const li=document.createElement('li');li.className='sev-medium';li.innerHTML='<span>Scan manuel lancé</span><span class="hint">info</span>';alertsUL.prepend(li);}
});

// Mini chart (sans lib)
const canvas=document.getElementById('chart');if(canvas){const ctx=canvas.getContext('2d');const W=canvas.width,H=canvas.height,M=20;const data=[3,5,2,4,1,6,4];const max=Math.max(...data);const sx=(W-2*M)/data.length,k=(H-2*M)/max;
  ctx.clearRect(0,0,W,H);ctx.strokeStyle='#888';ctx.beginPath();ctx.moveTo(M,H-M);ctx.lineTo(W-M,H-M);ctx.moveTo(M,H-M);ctx.lineTo(M,M);ctx.stroke();
  data.forEach((v,i)=>{const x=M+i*sx+6,y=H-M-v*k,h=v*k;ctx.fillRect(x,y,sx-12,h);});
}
JS
say "JS mis à jour"

# 3) Scripts npm (build & preview)
npm pkg set scripts.build="vite build" >/dev/null
npm pkg set scripts.preview="vite preview --host \${HOST:-127.0.0.1} --port \${PORT:-5173} --strictPort" >/dev/null
say "Scripts npm ajoutés (build & preview)"

# 4) Lanceur preview en tmux
cat > ~/start_sentinelle_preview.sh <<'BOOT'
#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
HOST="${HOST:-127.0.0.1}"; PORT="${PORT:-5173}"; SESSION="${SESSION:-web}"
tmux kill-session -t "$SESSION" 2>/dev/null || true
npm run build >/dev/null
tmux new -ds "$SESSION" "bash -lc 'HOST=$HOST PORT=$PORT npm run preview 2>&1 | tee -a vite-preview.log'"
URL="http://$HOST:$PORT/"; printf '\033[1;32m[✓]\033[0m Preview : %s\n' "$URL"
command -v termux-open-url >/dev/null 2>&1 && termux-open-url "$URL" || true
printf '[i] Logs: tmux attach -t %s (Ctrl+b puis d pour détacher)\n' "$SESSION"
BOOT
chmod +x ~/start_sentinelle_preview.sh
say "Lanceur preview prêt"
