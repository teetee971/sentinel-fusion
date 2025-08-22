export async function onRequest(context){
  const { request, env } = context;
  const url = new URL(request.url);
  const path = url.pathname.replace(/^\/api\/vpn\/?/, ""); // status, peers, peers/:id/enable
  const upstream = (suffix="") => `${env.VPN_API.replace(/\/$/,'')}/${suffix.replace(/^\//,'')}`;

  // Sécurité: exiger token côté Worker
  const AUTH = `Bearer ${env.VPN_TOKEN}`;
  const stdHeaders = { 'Authorization': AUTH, 'Content-Type':'application/json' };

  // Helper: proxy JSON
  const proxy = async (method, target, body=null) => {
    const res = await fetch(target, { method, headers: stdHeaders, body: body?JSON.stringify(body):undefined });
    const text = await res.text();
    let data; try{ data = JSON.parse(text); } catch{ data = { raw:text }; }
    return new Response(JSON.stringify(data), { status: res.status, headers: { 'Content-Type':'application/json' }});
  };

  // Routes de base (adapte-les à ton orchestrateur)
  if (request.method === 'GET' && (path === '' || path === 'status')) {
    return proxy('GET', upstream('status'));
  }
  if (request.method === 'GET' && path === 'peers') {
    return proxy('GET', upstream('peers'));
  }
  // Toggle peer: POST /api/vpn/peers/:id/enable {enable:true|false}
  if (request.method === 'POST' && /^peers\/[^/]+\/enable$/.test(path)) {
    const id = path.split('/')[1];
    const body = await request.json().catch(()=>({}));
    // Exemples d'upstream à adapter:
    // - wg-easy: POST /clients/:id/enable {enabled:true|false}
    // - headscale: POST /api/machines/:id/route
    // - tailscale: POST /api/v2/tailnet/.../devices/:id/disable
    return proxy('POST', upstream(`peers/${id}/enable`), { enable: !!body.enable });
  }

  return new Response(JSON.stringify({ error:'Not found', path }), { status: 404, headers:{'Content-Type':'application/json'}});
}
