// functions/api/contact.js — Cloudflare Pages Functions (ESM)

const json = (obj, status = 200) =>
  new Response(JSON.stringify(obj), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });

const esc = (s = "") =>
  String(s).replace(/[&<>"']/g, c => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  }[c]));

const isEmail = v => /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(v || "");

async function readBody(request) {
  const ct = request.headers.get("content-type") || "";
  if (ct.includes("application/json")) {
    return await request.json().catch(() => ({}));
  }
  if (ct.includes("application/x-www-form-urlencoded")) {
    const fd = await request.formData();
    return Object.fromEntries(fd.entries());
  }
  return {};
}

async function verifyTurnstile(token, secret) {
  const r = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
    method: "POST",
    body: new URLSearchParams({ secret, response: token }),
  });
  const d = await r.json().catch(() => ({}));
  return !!d.success;
}

export const onRequestPost = async ({ request, env }) => {
  try {
    // 1) Corps + validations
    const body = await readBody(request);
    const name = (body.name || "").toString().slice(0, 100).trim();
    const email = (body.email || "").toString().slice(0, 200).trim();
    const message = (body.message || "").toString().slice(0, 5000).trim();

    if (!name || !email || !message) return json({ error: "Paramètres manquants" }, 400);
    if (!isEmail(email)) return json({ error: "Email invalide" }, 400);

    // 2) Turnstile (désactivable en Preview)
    const bypass = (env.TURNSTILE_BYPASS || "0") === "1";
    if (!bypass) {
      const ts =
        body["cf-turnstile-response"] ||
        body.turnstile_token ||
        body["turnstile_token"] ||
        "";
      if (!ts) return json({ error: "Captcha requis" }, 400);
      const ok = await verifyTurnstile(ts, env.TURNSTILE_SECRET || "");
      if (!ok) return json({ error: "Captcha invalide" }, 403);
    }

    // 3) Email via MailChannels
    const to = env.MAIL_TO;
    const fromEmail = env.MAIL_FROM || ("no-reply@" + new URL(request.url).hostname);
    const subject = env.MAIL_SUBJECT || "Nouveau message";
    if (!to) return json({ error: "MAIL_TO manquant côté env" }, 500);

    const text = `Nom: ${name}\nEmail: ${email}\n\n${message}\n`;
    const html = `<p><b>Nom:</b> ${esc(name)}<br/><b>Email:</b> ${esc(email)}</p><pre>${esc(message)}</pre>`;

    const payload = {
      personalizations: [{ to: [{ email: to }] }],
      from: { email: fromEmail, name: "Sentinel Fusion" },
      reply_to: { email, name },
      subject,
      content: [
        { type: "text/plain", value: text },
        { type: "text/html", value: html },
      ],
    };

    const resp = await fetch("https://api.mailchannels.net/tx/v1/send", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(payload),
    });
    if (!resp.ok) return json({ error: `MailChannels ${resp.status}` }, 502);

    return json({ ok: true, method: "POST" });
  } catch (e) {
    return json({ error: "Erreur serveur" }, 500);
  }
};
