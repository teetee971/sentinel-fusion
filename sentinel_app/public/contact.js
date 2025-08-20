const form = document.querySelector('#contact');
const out  = document.querySelector('#out');

form.addEventListener('submit', async (e) => {
  e.preventDefault();
  out.textContent = 'Envoi…';

  const fd = new FormData(form); // contient automatiquement cf-turnstile-response
  try {
    const r = await fetch('/api/contact', { method: 'POST', body: fd });
    const j = await r.json().catch(() => ({}));
    if (r.ok && j.ok) {
      out.textContent = '✅ Message envoyé';
      form.reset();
      if (window.turnstile) turnstile.reset();
    } else {
      out.textContent = `❌ ${j.error || 'Erreur ' + r.status}`;
      if (window.turnstile) turnstile.reset();
    }
  } catch (err) {
    out.textContent = '❌ Réseau indisponible';
  }
});
