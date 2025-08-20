#!/usr/bin/env bash
set -euo pipefail
say(){ printf "\033[1;96m%s\033[0m\n" "$*"; }

cd "$HOME/sentinel_fusion"
command -v jq >/dev/null 2>&1 || pkg install -y jq >/dev/null

# 1) Essaie d'abord de lire le presse-papiers (si Termux:API dispo)
RAW=""
if command -v termux-clipboard-get >/dev/null 2>&1; then
  RAW="$(termux-clipboard-get || true)"
fi

# 2) Sinon demande en mode silencieux (rien ne s'affiche quand tu colles)
if [ -z "$RAW" ]; then
  stty -echo; printf "Colle le CF_API_TOKEN (rien ne s'affiche) : "
  read -r CF_API_TOKEN; stty echo; echo
else
  CF_API_TOKEN="$RAW"
fi

# 3) Nettoyage (supprime CR/LF)
CF_API_TOKEN="$(printf %s "$CF_API_TOKEN" | tr -d '\r\n')"

# 4) Contrôles rapides
[ ${#CF_API_TOKEN} -ge 40 ] || { echo "✗ Token trop court/vidé"; exit 1; }

STATUS="$(curl -fsS -H "Authorization: Bearer $CF_API_TOKEN" \
  https://api.cloudflare.com/client/v4/user/tokens/verify | jq -r '.result.status')"
[ "$STATUS" = "active" ] || { echo "✗ Token non actif ($STATUS)"; exit 1; }

# 5) Persiste dans .env.ci (propre) et recharge
ENV="$HOME/sentinel_fusion/.env.ci"
touch "$ENV"; chmod 600 "$ENV"
sed -i '/^CF_API_TOKEN=/d' "$ENV"
printf 'CF_API_TOKEN=%s\n' "$CF_API_TOKEN" >> "$ENV"

set -a; . "$ENV"; set +a
echo "✓ CF_API_TOKEN enregistré et actif."
