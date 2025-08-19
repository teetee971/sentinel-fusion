#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# --- Your persistent secrets (you can change later in ~/.sentinel/.env) ---
mkdir -p ~/.sentinel
cat > ~/.sentinel/.env <<'ENVEOF'
CF_API_TOKEN=-zg2dEd778dlAv3l0M-kF59pLCmnAfBOpEANY5ei
ACCOUNT_ID=78642e56f72fff94c78e1ef87cb589a7
PROJECT_NAME=sentinelquantumvanguardiapro
BRANCH_NAME=main
ENVEOF

# Sanity: remove CRLF if pasted from phone clipboard
sed -i 's/\r$//' ~/.sentinel/.env

# Load env
set -a; . ~/.sentinel/.env; set +a

# Helpers
ensure_cmd() { command -v "$1" >/dev/null 2>&1 || pkg install -y "$1"; }
say() { printf "\n\033[1;96m[%s]\033[0m %s\n" "$1" "${2:-}"; }

say "SETUP" "Updating & installing dependencies..."
yes | pkg update -y >/dev/null 2>&1 || true
ensure_cmd curl
ensure_cmd jq
ensure_cmd unzip
ensure_cmd python
ensure_cmd nodejs
ensure_cmd git
# storage access
if [ ! -d "$HOME/storage" ]; then termux-setup-storage || true; fi

say "SECRETS" "Verifying Cloudflare token..."
if ! curl -fsS -H "Authorization: Bearer $CF_API_TOKEN" https://api.cloudflare.com/client/v4/user/tokens/verify | jq -e '.success==true' >/dev/null; then
  echo "Token invalid. Edit ~/.sentinel/.env and rerun."; exit 1
fi
say "OK" "Token looks valid."

APP_DIR="$HOME/sentinel_app"
ZIP_NAME="sentinel_full_patch.zip"

# Try to fetch ZIP from phone Downloads if present
say "FILES" "Looking for $ZIP_NAME in ~/storage/downloads/"
if [ -f "$HOME/storage/downloads/$ZIP_NAME" ]; then
  rm -rf "$APP_DIR"
  mkdir -p "$APP_DIR"
  cp "$HOME/storage/downloads/$ZIP_NAME" "$HOME/$ZIP_NAME"
  unzip -o "$HOME/$ZIP_NAME" -d "$APP_DIR" >/dev/null
  say "FILES" "Unzipped into $APP_DIR"
else
  say "WARN" "Place $ZIP_NAME in your Downloads, then rerun this script."
  exit 2
fi

# Local preview server (kill previous if any)
say "LOCAL" "Starting local preview at http://127.0.0.1:5173 ..."
pkill -f "http.server 5173" >/dev/null 2>&1 || true
( cd "$APP_DIR" && nohup python -m http.server 5173 >/dev/null 2>&1 & echo $! > "$HOME/.sentinel/http.pid" )
sleep 1
termux-open-url "http://127.0.0.1:5173/" >/dev/null 2>&1 || true

# Wrangler for direct upload to Cloudflare Pages
say "CLOUDFLARE" "Installing Wrangler..."
npm i -g wrangler@3 >/dev/null

export CLOUDFLARE_ACCOUNT_ID="$ACCOUNT_ID"
export CF_API_TOKEN

say "PAGES" "Creating project (idempotent) $PROJECT_NAME ..."
wrangler pages project create "$PROJECT_NAME" --production-branch="$BRANCH_NAME" >/dev/null || true

say "PAGES" "Deploying static content (no build step) from $APP_DIR ..."
wrangler pages deploy "$APP_DIR" --project-name="$PROJECT_NAME" --branch="$BRANCH_NAME"

say "DONE" "If no errors above: https://$PROJECT_NAME.pages.dev should be updating shortly."
echo "Next time, just run:  bash ~/termux_sentinel_deploy.sh"
