#!/usr/bin/env bash
set -Eeuo pipefail

############################
# CONFIG PAR DÉFAUT (éditables via .env)
############################
SITE_DIR_DEFAULT="${SITE_DIR_DEFAULT:-$HOME/sentinel_fusion}"
PROJECT_NAME_DEFAULT="${PROJECT_NAME_DEFAULT:-sentinelquantumvanguardiapro}"
ACCOUNT_ID_DEFAULT="${ACCOUNT_ID_DEFAULT:-78642e56f72fff94c78e1ef87cb589a7}"
BRANCH_NAME_DEFAULT="${BRANCH_NAME_DEFAULT:-main}"
ENV_HOME="$HOME/.cfpages"
ENV_FILE="$ENV_HOME/.env"
HOOK_FILE="$ENV_HOME/deploy_hook.txt"
LOG_DIR="$ENV_HOME/logs"; mkdir -p "$LOG_DIR"

############################
# UTILITAIRES
############################
log(){ printf "\033[36m[cf-pages]\033[0m %s\n" "$*"; }
die(){ printf "\033[31m[cf-pages][ERR]\033[0m %s\n" "$*" >&2; exit 1; }

need(){
  local c="$1" h="$2"
  if ! command -v "$c" >/dev/null 2>&1; then
    log "Installe $c … $h"
    case "$(uname -o 2>/dev/null || echo Linux)" in
      Android)  pkg update -y >/dev/null 2>&1 || true; pkg install -y "$c" || true ;;
      *)        ;;
    esac
  fi
  command -v "$c" >/dev/null 2>&1 || die "Commande introuvable: $c"
}

############################
# PRÉREQUIS
############################
need bash   "shell"
need curl   "pkg install curl"
need grep   "pkg install grep"
need sed    "pkg install sed"
need awk    "pkg install awk"

# jq (facultatif mais recommandé)
if ! command -v jq >/dev/null 2>&1; then
  log "jq non trouvé -> installation (Termux) si possible"
  if [ "$(uname -o 2>/dev/null || echo Linux)" = "Android" ]; then
    pkg install -y jq || true
  fi
fi

# Node & npm
if ! command -v node >/dev/null 2>&1; then
  log "Node non trouvé -> (Termux) pkg install nodejs-lts"
  if [ "$(uname -o 2>/dev/null || echo Linux)" = "Android" ]; then
    pkg install -y nodejs-lts || die "Installe nodejs-lts manuellement."
  fi
fi
need npm "npm est requis"

# Wrangler
if ! command -v wrangler >/dev/null 2>&1; then
  log "Wrangler non trouvé -> installation globale"
  npm install -g wrangler@latest || die "Échec npm i -g wrangler"
  hash -r
fi

############################
# CHARGER .env (global + local)
############################
mkdir -p "$ENV_HOME"
touch "$ENV_FILE"
# shellcheck disable=SC1090
[ -f "$ENV_FILE" ] && . "$ENV_FILE"
[ -f .env ] && . ./.env || true

SITE_DIR="${SITE_DIR:-$SITE_DIR_DEFAULT}"
PROJECT_NAME="${PROJECT_NAME:-$PROJECT_NAME_DEFAULT}"
ACCOUNT_ID="${ACCOUNT_ID:-$ACCOUNT_ID_DEFAULT}"
BRANCH_NAME="${BRANCH_NAME:-$BRANCH_NAME_DEFAULT}"

############################
# SAISIE/SAUVEGARDE SÉCURISÉE DU TOKEN
############################
save_env_key(){
  local key="$1" val="$2"
  grep -q "^${key}=" "$ENV_FILE" && sed -i "s|^${key}=.*|${key}=${val}|" "$ENV_FILE" || echo "${key}=${val}" >> "$ENV_FILE"
  chmod 600 "$ENV_FILE"
}

ensure_token(){
  if [ -z "${CF_API_TOKEN:-}" ]; then
    printf "Entre ton CF_API_TOKEN (non affiché) : "
    stty -echo; read -r CF_API_TOKEN; stty echo; printf "\n"
  fi
  [ -n "${CF_API_TOKEN:-}" ] || die "Pas de CF_API_TOKEN"
}

verify_token(){
  local out; out="$(curl -sS -H "Authorization: Bearer ${CF_API_TOKEN}" https://api.cloudflare.com/client/v4/user/tokens/verify)"
  if command -v jq >/dev/null 2>&1; then
    local ok; ok="$(printf '%s' "$out" | jq -r '.success')"
    [ "$ok" = "true" ] || { printf '%s\n' "$out" | sed 's/.*/[API] &/'; die "Token invalide"; }
    log "Token OK ($(printf '%s' "$out" | jq -r '.result.status'))"
  else
    echo "$out" | grep -q '"success":true' || { echo "$out"; die "Token invalide"; }
    log "Token OK"
  fi
}

persist_profile(){
  save_env_key CF_API_TOKEN "$CF_API_TOKEN"
  save_env_key ACCOUNT_ID "$ACCOUNT_ID"
  save_env_key PROJECT_NAME "$PROJECT_NAME"
  save_env_key BRANCH_NAME "$BRANCH_NAME"
  # Export auto dans shell (non intrusif si déjà présent)
  local shrc
  for shrc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$shrc" ] || continue
    if ! grep -q 'source ~/.cfpages/.env' "$shrc"; then
      printf '\n# Cloudflare Pages env\n[ -f "$HOME/.cfpages/.env" ] && . "$HOME/.cfpages/.env"\n' >> "$shrc"
    fi
  done
}

############################
# VÉRIFICATIONS DOSSIER
############################
[ -d "$SITE_DIR" ] || die "SITE_DIR introuvable: $SITE_DIR"
[ -f "$SITE_DIR/index.html" ] || die "index.html absent dans $SITE_DIR"

############################
# WRANGLER.TOML (optionnel)
############################
gen_wrangler(){
  cat > "$SITE_DIR/wrangler.toml" <<TOML
name = "${PROJECT_NAME}"
account_id = "${ACCOUNT_ID}"
pages_build_output_dir = "."
TOML
  log "wrangler.toml généré"
}

############################
# PROJET PAGES : création si absent
############################
ensure_project(){
  log "Vérifie le projet Pages: ${PROJECT_NAME}"
  local list out
  out="$(wrangler pages project list --account-id "$ACCOUNT_ID" --output json 2>/dev/null || true)"
  if printf '%s' "$out" | grep -q "\"name\":\"${PROJECT_NAME}\""; then
    log "Projet déjà présent."
    return
  fi
  log "Création du projet Pages ${PROJECT_NAME}"
  wrangler pages project create "$PROJECT_NAME" \
    --production-branch "$BRANCH_NAME" \
    --account-id "$ACCOUNT_ID" \
    --compatibility-flags nodejs_compat \
    --skip-deployment || die "Échec création projet"
}

############################
# BUILD (si package.json) OU STATIQUE
############################
build_if_needed(){
  if [ -f "$SITE_DIR/package.json" ]; then
    log "package.json détecté -> build"
    ( cd "$SITE_DIR" && npm ci && npm run build )
    # Si build sort dans dist, adapte ici :
    if [ -d "$SITE_DIR/dist" ]; then
      export BUILD_DIR="$SITE_DIR/dist"
    else
      export BUILD_DIR="$SITE_DIR"
    fi
  else
    export BUILD_DIR="$SITE_DIR"
  fi
  log "Dossier à déployer: $BUILD_DIR"
}

############################
# DÉPLOIEMENT
############################
deploy(){
  log "Déploiement Pages…"
  local outfile="$LOG_DIR/deploy_$(date +%s).log"
  ( cd "$BUILD_DIR" && wrangler pages deploy . \
      --project-name "$PROJECT_NAME" \
      --branch "$BRANCH_NAME" \
      --commit-hash "$(date +%s)" \
      --commit-message "auto-deploy $(date -Is)" \
      --output json ) | tee "$outfile"

  local preview prod
  if command -v jq >/dev/null 2>&1; then
    preview="$(jq -r '.[].url // empty' "$outfile" | head -n1)"
  else
    preview="$(grep -Eo 'https://[^ ]+\.pages\.dev' "$outfile" | head -n1)"
  fi

  log "URL (preview ou prod) : ${preview:-inconnue}"
  [ -n "${preview:-}" ] && { command -v termux-open-url >/dev/null 2>&1 && termux-open-url "$preview" || true; }
}

############################
# HOOK DE DEPLOIEMENT (CI auto)
############################
ensure_deploy_hook(){
  if [ -s "$HOOK_FILE" ]; then
    log "Deploy hook déjà présent: $(cat "$HOOK_FILE")"
    return
  fi
  log "Création d’un deploy hook (Pages API)"
  local resp hook
  resp="$(curl -sS -X POST \
     -H "Authorization: Bearer ${CF_API_TOKEN}" \
     -H "Content-Type: application/json" \
     "https://api.cloudflare.com/client/v4/accounts/${ACCOUNT_ID}/pages/projects/${PROJECT_NAME}/deploy_hooks")"
  if command -v jq >/dev/null 2>&1; then
    hook="$(printf '%s' "$resp" | jq -r '.result.deploy_hook' 2>/dev/null || true)"
  else
    hook="$(printf '%s' "$resp" | grep -Eo 'https://api\.cloudflare\.com/client/v4/pages/webhooks/deploy_hooks/[a-f0-9-]+' | head -n1)"
  fi
  [ -n "${hook:-}" ] || { echo "$resp"; die "Impossible d’obtenir un hook"; }
  printf '%s\n' "$hook" > "$HOOK_FILE"
  chmod 600 "$HOOK_FILE"
  log "Hook créé: $hook"
}

############################
# MAIN
############################
log "=== Cloudflare Pages MAXI ==="
ensure_token
verify_token
persist_profile
gen_wrangler
ensure_project
build_if_needed
deploy
ensure_deploy_hook
log "OK. Hook dispo dans: $HOOK_FILE"
