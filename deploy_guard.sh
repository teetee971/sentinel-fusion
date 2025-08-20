#!/usr/bin/env bash
set -euo pipefail

DIR_DEFAULT="sentinel_app/public"
WORKFLOW_FILE=".github/workflows/deploy-cloudflare.yml"

usage(){ echo "Usage: $0 [CHEMIN_PUBLIC] [--create]"; }

# Args
DIR="${1:-$DIR_DEFAULT}"
CREATE=0
[[ "${*:-}" == *"--create"* ]] && CREATE=1
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { usage; exit 0; }

# Charge .env.ci (facultatif) pour afficher des avertissements utiles
[ -f ./.env.ci ] && set -a && . ./.env.ci && set +a

# 1) Vérifie la présence du workflow
if [[ ! -f "$WORKFLOW_FILE" ]]; then
  echo "❌ Workflow GitHub '$WORKFLOW_FILE' introuvable."; exit 1
fi

# 2) Vérifie le dossier public
if [[ ! -d "$DIR" ]]; then
  echo "❌ Dossier '$DIR' introuvable."
  echo "   Ex: $0 $DIR_DEFAULT  ou  $0 ton/autre/chemin"
  exit 1
fi

# 3) Vérifie/Génère index.html
if [[ ! -f "$DIR/index.html" ]]; then
  if (( CREATE )); then
    mkdir -p "$DIR"
    cat >"$DIR/index.html" <<'HTML'
<!doctype html>
<meta charset="utf-8">
<title>Sentinel Fusion</title>
<h1>It works 🎉</h1>
<p>Déploiement Cloudflare Pages prêt.</p>
HTML
    echo "🆕 '$DIR/index.html' créé."
  else
    echo "❌ '$DIR/index.html' manquant."
    echo "   Relance avec --create pour générer un index minimal :"
    echo "   $0 '$DIR' --create"
    exit 1
  fi
fi

# (Optionnel) Avertit si les vars locales ne sont pas chargées.
for v in CF_API_TOKEN CLOUDFLARE_ACCOUNT_ID CLOUDFLARE_PROJECT_NAME; do
  eval "val=\${$v:-}"
  [[ -z "${val}" ]] && echo "ℹ️  $v non défini localement (ok si présent dans Secrets GitHub)."
done

# 4) Commit & push si nécessaire
git add -A
git diff --cached --quiet || git commit -m "deploy: guard + assets"
git push

# 5) Déclenche le workflow et affiche le dernier run
gh workflow run deploy-cloudflare.yml
gh run list --workflow=deploy-cloudflare.yml -L 1
