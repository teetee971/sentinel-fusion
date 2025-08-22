#!/usr/bin/env bash
set -euo pipefail

EP="${1:?Usage: $0 https://formspree.io/f/xxxxxxx}"
ROOT=sentinel_app/public
ts=$(date +%s)

# 0) Nettoie l'ancien format et injecte UNE SEULE balise juste avant </body>
for f in "$ROOT"/*.html; do
  # vire les vieilles lignes window.CONTACT_ENDPOINT "en vrac"
  sed -i -E 's/window\.CONTACT_ENDPOINT\s*=\s*\"[^"]*\";?//g' "$f"
  # supprime d'anciennes balises script id=contact-endpoint dupliquées
  sed -i -E 's#<script id="contact-endpoint">[^<]*</script>##g' "$f"
  # réinsère proprement 1 balise
  sed -i -E "s#</body>#<script id=\"contact-endpoint\">window.CONTACT_ENDPOINT=\"$EP\";</script>\n</body>#g" "$f"
done

# 1) Honeypot CSS (anti-spam) si absent
if ! grep -q '/* == contact: honeypot v1 == */' "$ROOT/style.css"; then
  cat >> "$ROOT/style.css" <<'CSS'
/* == contact: honeypot v1 == */
.hp{position:absolute !important; left:-9999px !important; opacity:0 !important;}
CSS
fi

# 2) Cache-bust CSS/JS
for f in "$ROOT"/*.html; do
  sed -i -E "s|(style\.css)(\?v=[0-9]+)?|\1?v=$ts|g; s|(app\.js)(\?v=[0-9]+)?|\1?v=$ts|g" "$f"
done

git add "$ROOT/style.css" "$ROOT"/*.html || true
git commit -m "ux(contact): finish pack (honeypot) + endpoint unique + cache bust v$ts" || true
[[ -x ./deploy_now.sh ]] && ./deploy_now.sh || echo "⚠ deploy_now.sh non trouvé : pas de déploiement auto."
