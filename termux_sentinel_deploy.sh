#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

say(){ printf "\033[1;32m[✓]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[!]\033[0m %s\n" "$*"; }
die(){ printf "\033[1;31m[x]\033[0m %s\n" "$*"; exit 1; }

ENV_FILE="$HOME/.sentinel/.env"
APP_DIR="$HOME/sentinel_app"
ZIP_NAME="sentinel_full_patch.zip"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-5173}"

# Pré-requis discrets (ne casse pas si déjà ok)
pkg install -y python unzip jq rsync >/dev/null 2>&1 || true
command -v node >/dev/null 2>&1 || pkg install -y nodejs >/dev/null 2>&1 || true
termux-setup-storage >/dev/null 2>&1 || true

# Secrets
mkdir -p "$(dirname "$ENV_FILE")"
if [ -f "$ENV_FILE" ]; then . "$ENV_FILE"; else
  warn "Pas de $ENV_FILE : déploiement Cloudflare sauté (preview local seulement)."
fi
PROJECT_NAME="${PROJECT_NAME:-sentinel-qv-ai}"
BRANCH_NAME="${BRANCH_NAME:-main}"

# Nettoyage preview précédent
pkill -f "http.server $PORT" >/dev/null 2>&1 || true

# Récupération des fichiers (ZIP dans Téléchargements > sinon dossier courant)
rm -rf "$APP_DIR"; mkdir -p "$APP_DIR"
if [ -f "$HOME/storage/downloads/$ZIP_NAME" ]; then
  say "Utilisation du ZIP depuis Téléchargements."
  cp "$HOME/storage/downloads/$ZIP_NAME" "$HOME/$ZIP_NAME"
  unzip -oq "$HOME/$ZIP_NAME" -d "$APP_DIR"
  rm -f "$HOME/$ZIP_NAME"
elif [ -f "$PWD/index.html" ]; then
  say "Copie depuis le dossier courant : $PWD"
  rsync -a --exclude 'node_modules' --exclude '.git' --exclude 'dist' . "$APP_DIR" 2>/dev/null || cp -r . "$APP_DIR"
else
  die "Aucun $ZIP_NAME dans ~/storage/downloads et pas d'index.html ici."
fi

# Build si projet Vite/packagé
if [ -f "$APP_DIR/package.json" ] && jq -e '.scripts.build?!=null' "$APP_DIR/package.json" >/dev/null 2>&1; then
  say "Build npm (npm run build)…"
  (cd "$APP_DIR" && (npm ci --omit=dev >/dev/null 2>&1 || npm i >/dev/null 2>&1) && npm run build)
  [ -d "$APP_DIR/dist" ] && APP_DIR="$APP_DIR/dist"
fi

# Preview local
say "Preview local : http://$HOST:$PORT/"
nohup python -m http.server "$PORT" --directory "$APP_DIR" >/dev/null 2>&1 &
sleep 1
termux-open-url "http://$HOST:$PORT/" >/dev/null 2>&1 || true

# Déploiement Cloudflare Pages (si secrets présents)
if [ -n "${CF_API_TOKEN:-}" ] && [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
  say "Vérification du token Cloudflare…"
  if curl -fsS -H "Authorization: Bearer $CF_API_TOKEN" \
      https://api.cloudflare.com/client/v4/user/tokens/verify | jq -e '.success==true' >/dev/null 2>&1; then
    say "Token OK."
  else
    warn "Token invalide — déploiement sauté."; exit 0
  fi
  # Wrangler
  command -v wrangler >/dev/null 2>&1 || npm i -g wrangler@3 >/dev/null 2>&1
  export CF_API_TOKEN CLOUDFLARE_ACCOUNT_ID
  wrangler pages project create "$PROJECT_NAME" --production-branch "$BRANCH_NAME" >/dev/null 2>&1 || true
  say "Déploiement vers Cloudflare Pages…"
  wrangler pages deploy "$APP_DIR" --project-name="$PROJECT_NAME" --branch "$BRANCH_NAME"
  say "Fini. URL: https://$PROJECT_NAME.pages.dev/"
else
  warn "CF_API_TOKEN/CLOUDFLARE_ACCOUNT_ID absents — preview local uniquement."
fi
