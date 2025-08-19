#!/usr/bin/env bash
set -Eeuo pipefail

tok="${1-}"
# Si pas d'argument, on lit sur l'entrée standard (utile: echo TOKEN | ~/cf_save_token.sh -)
if [[ "${tok:-}" == "-" || -z "${tok:-}" ]]; then
  read -rsp "Colle le token Cloudflare puis Entrée: " tok; echo
fi

# Nettoyage espaces/CR/LF
tok="${tok//$'\r'/}"; tok="${tok//$'\n'/}"

# Vérification côté Cloudflare
if ! curl -sS -H "Authorization: Bearer $tok" \
  https://api.cloudflare.com/client/v4/user/tokens/verify \
  | jq -e '.success==true' >/dev/null; then
  echo "❌ Token invalide." >&2
  exit 1
fi

# Écrit/Met à jour dans ~/.env
touch ~/.env
chmod 600 ~/.env
if grep -q '^CF_API_TOKEN=' ~/.env; then
  sed -i "s|^CF_API_TOKEN=.*|CF_API_TOKEN=$tok|" ~/.env
else
  printf '\nCF_API_TOKEN=%s\n' "$tok" >> ~/.env
fi

echo "✅ Token enregistré dans ~/.env (prefix=${tok:0:6}…, len=${#tok})."
