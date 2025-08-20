export const onRequest = async ({ request }) => {
  return new Response(JSON.stringify({ ok: true, method: request.method }), {
    headers: { 'content-type': 'application/json' }
  });
};
