const json = (obj, status = 200) =>
  new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json' }
  });

const esc = s => String(s ?? '').replace(/[&<>"']/g, c =>
  ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])
);

export const onRequestPost = async ({ request, env }) => {
  // 1) Lire le corps (JSON ou x-www-form-urlencoded)
  let body = {}, ct = request.headers.get('content-type') || '';
  try {
    if (ct.includes('application/json')) body = await request.json();
    else if (ct.includes('application/x-www-form-urlencoded'))
      body = Object.fromEntries(await request.formData());
  } catch (_) {}

  const name    = (body.name||'').toString().slice(0,100).trim();
  const email   = (body.email||'').toString().slice(0,200).trim();
  const message = (body.message||'').toString().slice(0,5000).trim();
  if (!name || !email || !message) return json({ error:'Paramètres manquants' }, 400);

  // 2) Vérif Turnstile (sauf bypass)
  if (env.TURNSTILE_BYPASS !== '1') {
    const token = body['cf-turnstile-response'] || body.turnstile_token || '';
    if (!token) return json({ error:'Captcha requis' }, 400);
    const vr = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', {
      method: 'POST',
      body: new URLSearchParams({ secret: env.TURNSTILE_SECRET || '', response: token })
    }).then(r => r.json()).catch(() => ({ success:false }));
    if (!vr.success) return json({ error:'Captcha invalide' }, 403);
  }

  // 3) Envoi via MailChannels
  const to      = env.MAIL_TO;
  const from    = env.MAIL_FROM || 'no-reply@' + (new URL(request.url)).hostname;
  const subject = env.MAIL_SUBJECT || 'Nouveau message';
  if (!to) return json({ error:'MAIL_TO manquant côté env' }, 500);

  const payload = {
    personalizations: [{ to: [{ email: to }] }],
    from: { email: from, name: 'Sentinel Fusion' },
    subject,
    content: [
      { type: 'text/plain', value: `Nom: ${name}\nEmail: ${email}\n\n${message}` },
      { type: 'text/html',  value: `<p><b>Nom:</b> ${esc(name)}<br/><b>Email:</b> ${esc(email)}</p><pre>${esc(message)}</pre>` }
    ]
  };

  const resp = await fetch('https://api.mailchannels.net/tx/v1/send', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(payload)
  });

  if (!resp.ok) return json({ error:`MailChannels ${resp.status}` }, 502);
  return json({ ok:true });
};
