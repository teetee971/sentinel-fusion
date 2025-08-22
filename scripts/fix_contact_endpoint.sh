#!/usr/bin/env bash
set -euo pipefail

ROOT=sentinel_app/public
EP="${1:-}"   # optionnel: ./scripts/fix_contact_endpoint.sh https://formspree.io/f/XXXXXXX

# Tente de récupérer la première valeur trouvée si non fournie
detect_ep(){
  local file="$1"
  grep -oE 'window\.CONTACT_ENDPOINT\s*=\s*"[^"]+"' "$file" \
    | head -1 | sed -E 's/.*="([^"]*)".*/\1/' || true
}

for f in "$ROOT"/*.html; do
  [[ -z "$EP" ]] && EP="$(detect_ep "$f")"
done
: "${EP:?Aucune valeur CONTACT_ENDPOINT détectée. Relance avec: ./scripts/fix_contact_endpoint.sh https://formspree.io/f/XXXXXXX}"

echo ">> CONTACT_ENDPOINT = $EP"

for f in "$ROOT"/*.html; do
  # 1) Supprime tout ce qui ressemble à l'ancienne injection (texte brut ou script)
  sed -i -E 's/window\.CONTACT_ENDPOINT\s*=\s*"[^"]*"\s*;?//g' "$f"
  sed -i -E '/<script[^>]*id="contact-endpoint"[^>]*>[^<]*<\/script>/Id' "$f"

  # Nettoyage d'interlignes en trop
  sed -i -E ':a;N;$!ba;s/\n{3,}/\n\n/g' "$f"

  # 2) Réinsère proprement UNE SEULE balise juste avant </body>
  if ! grep -qi 'id="contact-endpoint"' "$f"; then
    sed -i -E "s|</body>|<script id=\"contact-endpoint\">window.CONTACT_ENDPOINT=\"${EP}\";<\/script></body>|I" "$f"
  fi
done

# 3) Cache-bust + commit + deploy
ts=$(date +%s)
for f in "$ROOT"/*.html; do
  sed -i -E "s|(\\./style\\.css)(\\?v=[0-9]+)?|\\1?v=$ts|g; s|(app\\.js)(\\?v=[0-9]+)?|\\1?v=$ts|g" "$f"
done
git add "$ROOT"/*.html || true
git commit -m "fix(contact): injection unique <script id=contact-endpoint> + purge duplicates + cache bust v$ts" || true
[[ -x ./deploy_now.sh ]] && ./deploy_now.sh || echo "⚠️ deploy_now.sh non trouvé : déploiement sauté."
echo "✅ CONTACT_ENDPOINT corrigé."
