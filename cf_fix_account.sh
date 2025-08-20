#!/usr/bin/env bash
set -euo pipefail
say(){ printf "\033[1;96m%s\033[0m\n" "$*"; }

cd "$HOME/sentinel_fusion"
set -a; [ -f ./.env.ci ] && . ./.env.ci; set +a

# 0) Token présent ?
: "${CF_API_TOKEN:?CF_API_TOKEN manquant — lance d’abord ./set_cf_token.sh}"

# 1) Récupère l’Account ID accessible avec CE token (puis nettoie CR/LF)
ACC="$(curl -fsS -H "Authorization: Bearer $CF_API_TOKEN" \
  https://api.cloudflare.com/client/v4/accounts \
  | jq -r '.result[0].id')"
ACC="$(printf %s "$ACC" | tr -d '\r\n')"

if [ -z "$ACC" ] || [ "$ACC" = "null" ]; then
  echo "x Aucun compte accessible avec ce token (ACC=null)"; exit 1
fi

# 2) Vérifie que ça ressemble à un ID Cloudflare (32 hex)
LEN="$(echo -n "$ACC" | wc -c)"
if ! echo "$ACC" | grep -Eq '^[a-f0-9]{32}$'; then
  echo "x Account ID invalide: '$ACC' (len=$LEN)"; exit 1
fi
say "✓ Account ID: $ACC (len=$LEN)"

# 3) Enregistre proprement dans .env.ci
sed -i '/^CLOUDFLARE_ACCOUNT_ID=/d' .env.ci 2>/dev/null || true
printf 'CLOUDFLARE_ACCOUNT_ID=%s\n' "$ACC" >> .env.ci
chmod 600 .env.ci
set -a; . ./.env.ci; set +a
say "✓ .env.ci mis à jour"

# 4) Teste l’endpoint Pages avec CET ID (doit renvoyer success=true)
RES="$(curl -fsS -H "Authorization: Bearer $CF_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/pages/projects")"

echo "$RES" | jq -r '.success' | grep -q true || {
  echo "$RES" | jq .
  echo "x L’endpoint Pages ne répond pas 'success:true' — ID ou permissions KO"; exit 1; }

say "✓ Endpoint Pages OK (success:true)"
