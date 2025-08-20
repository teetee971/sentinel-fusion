#!/usr/bin/env bash
set -euo pipefail
say(){ printf "\033[1;96m%s\033[0m\n" "$*"; }

cd "$HOME/sentinel_fusion"

# Outils
command -v jq >/dev/null 2>&1 || pkg install -y jq >/dev/null

ENV_FILE=".env.ci"; touch "$ENV_FILE"; chmod 600 "$ENV_FILE"

# Charge l'existant (silencieux)
set +u; set -a; . "./$ENV_FILE" 2>/dev/null || true; set +a; set -u

strip(){ printf %s "$1" | tr -d '\r\n ' ; }

# Récupère une valeur: 1) déjà chargée 2) var d'env 3) presse-papiers (Termux API)
getval(){
  local current="$1" name="$2" v=""
  if   [ -n "${current:-}" ];   then v="$current"
  elif [ -n "${!name:-}"   ];   then v="${!name}"
  elif command -v termux-clipboard-get >/dev/null 2>&1; then
       v="$(termux-clipboard-get 2>/dev/null || true)"
  fi
  strip "${v:-}"
}

GH_TOKEN="$(getval "${GH_TOKEN:-}" GH_TOKEN)"
CF_API_TOKEN="$(getval "${CF_API_TOKEN:-}" CF_API_TOKEN)"

######## Vérif GitHub (tolérante)
ME=""
if [ -n "$GH_TOKEN" ]; then
  ME="$(curl -sS -H "Authorization: token $GH_TOKEN" https://api.github.com/user 2>/dev/null \
        | jq -r .login 2>/dev/null || echo "")"
  [ "$ME" = "null" ] && ME=""
  if [ -z "$ME" ]; then say "✗ GH_TOKEN invalide"; GH_TOKEN=""; fi
else
  say "• GH_TOKEN manquant (ok si déjà poussé plus tôt)"
fi

######## Vérif Cloudflare (tolérante)
CF_STATUS=""
if [ -n "$CF_API_TOKEN" ]; then
  CF_STATUS="$(curl -sS -H "Authorization: Bearer $CF_API_TOKEN" \
    https://api.cloudflare.com/client/v4/user/tokens/verify 2>/dev/null \
    | jq -r '.result.status' 2>/dev/null || echo "")"
  if [ "$CF_STATUS" != "active" ]; then say "✗ CF_API_TOKEN invalide"; CF_API_TOKEN=""; CF_STATUS=""; fi
else
  say "• CF_API_TOKEN manquant"
fi

# Réécrit .env.ci proprement (sans dupliquer)
TMP="$(mktemp)"
grep -vE '^(GH_TOKEN|CF_API_TOKEN)=' "$ENV_FILE" 2>/dev/null > "$TMP" || true
[ -n "$GH_TOKEN"     ] && printf 'GH_TOKEN=%s\n'      "$GH_TOKEN"     >> "$TMP"
[ -n "$CF_API_TOKEN" ] && printf 'CF_API_TOKEN=%s\n'  "$CF_API_TOKEN" >> "$TMP"
mv "$TMP" "$ENV_FILE"; chmod 600 "$ENV_FILE"

# Recharge pour la session
set -a; . "./$ENV_FILE"; set +a

say "✓ .env.ci synchronisé. GitHub: ${ME:-inconnu} | Cloudflare token: ${CF_STATUS:-absent}"
