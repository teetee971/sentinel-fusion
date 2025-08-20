#!/usr/bin/env bash
set -euo pipefail
say(){ printf "\033[1;96m%s\033[0m\n" "$*"; }

# 0) Charge l'env local si présent
set -a; . ./.env.ci 2>/dev/null || true; set +a

# 1) Vérifie le token Cloudflare
status=$(curl -fsS -H "Authorization: Bearer ${CF_API_TOKEN:-}" \
         https://api.cloudflare.com/client/v4/user/tokens/verify \
         | jq -r '.result.status' 2>/dev/null || echo "")
[ "$status" = "active" ] || { echo "❌ CF_API_TOKEN invalide/absent"; exit 1; }
say "✅ CF token actif"

# 2) Récupère le 1er compte accessible (ou garde celui déjà défini)
if [ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
  line=$(curl -fsS -H "Authorization: Bearer $CF_API_TOKEN" \
         https://api.cloudflare.com/client/v4/accounts \
         | jq -r '.result[] | "\(.id)\t\(.name)"' | head -n1)
  acc="${line%%$'\t'*}"
  [ -n "$acc" ] || { echo "❌ Aucun compte Cloudflare accessible"; exit 1; }
  CLOUDFLARE_ACCOUNT_ID="$acc"
fi
say "✅ Account ID: $CLOUDFLARE_ACCOUNT_ID"

# 3) Paramètres Pages
CLOUDFLARE_PROJECT_NAME="${CLOUDFLARE_PROJECT_NAME:-sentinel-fusion}"
CLOUDFLARE_PAGES_BRANCH="${CLOUDFLARE_PAGES_BRANCH:-main}"
DEST_DIR="sentinel_app/public"
ROOT_DIR="."

# 4) Écrit/MAJ .env.ci + recharge
sed -i '/^CLOUDFLARE_ACCOUNT_ID=/d' .env.ci 2>/dev/null || true
sed -i '/^CLOUDFLARE_PROJECT_NAME=/d' .env.ci 2>/dev/null || true
sed -i '/^CLOUDFLARE_PAGES_BRANCH=/d' .env.ci 2>/dev/null || true
{
  echo "CLOUDFLARE_ACCOUNT_ID=$CLOUDFLARE_ACCOUNT_ID"
  echo "CLOUDFLARE_PROJECT_NAME=$CLOUDFLARE_PROJECT_NAME"
  echo "CLOUDFLARE_PAGES_BRANCH=$CLOUDFLARE_PAGES_BRANCH"
} >> .env.ci
chmod 600 .env.ci
set -a; . ./.env.ci; set +a
say "💾 .env.ci mis à jour"

# 5) Met aussi les secrets côté GitHub
gh secret set CLOUDFLARE_ACCOUNT_ID   -b"$CLOUDFLARE_ACCOUNT_ID" >/dev/null
gh secret set CLOUDFLARE_PROJECT_NAME -b"$CLOUDFLARE_PROJECT_NAME" >/dev/null
gh secret set CLOUDFLARE_PAGES_BRANCH -b"$CLOUDFLARE_PAGES_BRANCH" >/dev/null
say "🔒 Secrets GitHub mis à jour"

# 6) Crée le projet Pages si besoin (capture propre du code HTTP)
BODY=$(jq -n \
  --arg name  "$CLOUDFLARE_PROJECT_NAME" \
  --arg branch "$CLOUDFLARE_PAGES_BRANCH" \
  --arg dir   "$DEST_DIR" \
  --arg root  "$ROOT_DIR" \
  '{name:$name,production_branch:$branch,build_config:{destination_dir:$dir,root_dir:$root}}')

TMP=$(mktemp)
HTTP=$(curl -sS -o "$TMP" -w "%{http_code}" -X POST \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/pages/projects" \
  -d "$BODY" || true)

# Interprétation des retours
if [ "$HTTP" = "200" ] || [ "$HTTP" = "201" ]; then
  say "📦 Projet Pages créé"
elif [ "$HTTP" = "409" ] || grep -qi 'already exists' "$TMP"; then
  say "📦 Projet Pages déjà existant (OK)"
else
  say "❌ Création Pages a échoué (HTTP $HTTP)"
  jq -r '.errors // empty' "$TMP" 2>/dev/null || cat "$TMP"
  exit 1
fi
rm -f "$TMP"

say "✅ Projet Pages vérifié/ok"
