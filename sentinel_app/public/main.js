// Utilitaires
const $ = s => document.querySelector(s);
const out = $('#toolOut');
const print = v => out && (out.textContent = (typeof v === 'string' ? v : JSON.stringify(v, null, 2)));

// Thème (dark par défaut + toggle)
(function initTheme(){
  const saved = localStorage.getItem('theme') || 'dark';
  document.documentElement.setAttribute('data-theme', saved);
})();
$('#btnTheme')?.addEventListener('click', () => {
  const html = document.documentElement;
  const dark = html.getAttribute('data-theme') === 'dark';
  const next = dark ? 'light' : 'dark';
  html.setAttribute('data-theme', next);
  localStorage.setItem('theme', next);
});

// Outils démo
$('#btnIP')?.addEventListener('click', async () => {
  try {
    const t0 = performance.now();
    const txt = await fetch('https://1.1.1.1/cdn-cgi/trace', {cache:'no-store'}).then(r=>r.text());
    const ip = (txt.match(/ip=([^\n]+)/)||[])[1] || 'inconnu';
    const dt = Math.round(performance.now()-t0);
    print(`IP publique: ${ip}\n~${dt} ms`);
  } catch (e) { print('Erreur IP: ' + e.message); }
});

$('#btnDNS')?.addEventListener('click', async () => {
  try {
    const q = ($('#domainInput')?.value || 'cloudflare.com').trim();
    const url = `https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(q)}&type=A`;
    const data = await fetch(url, { headers: { accept: 'application/dns-json' } }).then(r=>r.json());
    print(data);
  } catch (e) { print('Erreur DNS: ' + e.message); }
});

$('#btnPing')?.addEventListener('click', async () => {
  try {
    const t0 = performance.now();
    await fetch('https://1.1.1.1/cdn-cgi/trace', {cache:'no-store'}).then(r=>r.text());
    const dt = Math.round(performance.now()-t0);
    print(`Latence vers 1.1.1.1: ~${dt} ms`);
  } catch (e) { print('Erreur ping: ' + e.message); }
});

$('#btnFP')?.addEventListener('click', () => {
  const fp = {
    ua: navigator.userAgent,
    lang: navigator.language,
    screen: `${screen.width}x${screen.height}@${window.devicePixelRatio}`,
    tz: Intl.DateTimeFormat().resolvedOptions().timeZone
  };
  print(fp);
});
