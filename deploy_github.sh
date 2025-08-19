#!/usr/bin/env bash
set -euo pipefail

say(){ printf "\033[1;36m[cf-pages]\033[0m %s\n" "$*"; }
die(){ printf "\033[1;31m[ERR]\033[0m %s\n" "$*" >&2; exit 1; }

# --- Vérifs PAT GitHub ---
: "${GH_TOKEN:?GH_TOKEN manquant (export GH_TOKEN=...)}"
: "${GH_USER:?GH_USER manquant (export GH_USER=...)}"

REPO_NAME="${REPO_NAME:-sentinel-fusion}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"

# --- Prépare fichiers CI ---
mkdir -p .github/workflows

cat > .github/workflows/deploy-cloudflare.yml <<'YAML'
name: Deploy to Cloudflare Pages
on:
  push:
    branches: [ "main" ]
  workflow_dispatch:
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '22'

      - name: Detect & Build (if package.json)
        id: build
        shell: bash
        run: |
          if [ -f package.json ] && jq -e '.scripts.build!=null' package.json >/dev/null 2>&1; then
            echo "Building with npm…"
            npm ci
            npm run build
            echo "dir=dist" >> "$GITHUB_OUTPUT"
          else
            echo "Static site — no build."
            echo "dir=." >> "$GITHUB_OUTPUT"
          fi

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: ${{ secrets.CLOUDFLARE_PROJECT_NAME }}
          directory: ${{ steps.build.outputs.dir }}
          branch: ${{ secrets.CLOUDFLARE_PAGES_BRANCH || 'main' }}
          wranglerVersion: '3'
YAML

# README rapide
cat > README.md <<'MD'
# Sentinel Fusion (PS5 + Futur Cyber + Dark Pro)

Déploiement automatique vers **Cloudflare Pages** via GitHub Actions.

## Secrets GitHub à ajouter (Repository → Settings → Secrets and variables → Actions)
- `CLOUDFLARE_API_TOKEN`  (Pages:Edit)
- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_PROJECT_NAME`
- `CLOUDFLARE_PAGES_BRANCH` = main

Un simple `git push` sur `main` déclenchera le déploiement.
MD

# .gitignore simple
cat > .gitignore <<'GIT'
node_modules/
dist/
.env
GIT

# --- Init git / commit / push ---
if [ ! -d .git ]; then
  say "Init git"
  git init
  git config user.name  "Sentinel Bot"
  git config user.email "bot@sentinel.local"
fi

# branche main
git checkout -B "$DEFAULT_BRANCH"

# add/commit
git add -A
git commit -m "Initial push: site + workflow CF Pages"

# Crée le repo s'il n'existe pas
say "Vérifie/crée le repo $GH_USER/$REPO_NAME"
if ! curl -fsS -H "Authorization: token $GH_TOKEN" "https://api.github.com/repos/$GH_USER/$REPO_NAME" >/dev/null 2>&1; then
  curl -fsS -X POST "https://api.github.com/user/repos" \
    -H "Authorization: token $GH_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$REPO_NAME\",\"private\":false}" >/dev/null
  say "Repo créé."
else
  say "Repo déjà existant."
fi

# remote + push (utilise le PAT dans l'URL)
REMOTE_URL="https://${GH_TOKEN}@github.com/${GH_USER}/${REPO_NAME}.git"
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi

say "Push vers GitHub…"
git push -u origin "$DEFAULT_BRANCH"

say "OK. Va ajouter les 4 secrets dans :"
say "https://github.com/${GH_USER}/${REPO_NAME}/settings/secrets/actions"
say "Ensuite, re-push (ou clique sur 'Run workflow') pour déployer."
