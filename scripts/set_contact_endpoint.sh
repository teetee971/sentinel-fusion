#!/usr/bin/env bash
set -euo pipefail
ROOT=sentinel_app/public
F="$ROOT/index.html"
EP="${1:-}"
[[ -z "$EP" ]] && { echo "Usage: $0 <endpoint-url>"; exit 1; }

# 1) Remplace la ligne injectée par le pack contact, ou ajoute le <script> si absent
if grep -q 'window.CONTACT_ENDPOINT' "$F"; then
  sed -i -E "s|window\.CONTACT_ENDPOINT\s*=\s*window\.CONTACT_ENDPOINT\s*\|\|\s*\"\"|window.CONTACT_ENDPOINT=\"$EP\"|" "$F"
  sed -i -E "s|window\.CONTACT_ENDPOINT\s*=\s*\"[^\"]*\"|window.CONTACT_ENDPOINT=\"$EP\"|" "$F"
else
  sed -i -E "s|</body>|  <script>window.CONTACT_ENDPOINT=\"$EP\";</script>\n</body>|" "$F"
fi

# 2) Cache-bust CSS/JS sur toutes les pages
ts=$(date +%s)
for h in "$ROOT"/*.html; do
  sed -i -E "s|(\\./style\\.css)(\\?v=[0-9]+)?|\\1?v=$ts|g; s|(app\\.js)(\\?v=[0-9]+)?|\\1?v=$ts|g" "$h"
done

# 3) Commit + déploiement (si script dispo)
git add "$F" "$ROOT"/*.html || true
git commit -m "chore(contact): set CONTACT_ENDPOINT -> $EP + cache bust v$ts" || true
[[ -x ./deploy_now.sh ]] && ./deploy_now.sh || echo "⚠️ deploy_now.sh non trouvé : déploiement sauté."
echo "✅ CONTACT_ENDPOINT = $EP"
