#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
say(){ printf "\033[1;96m%s\033[0m\n" "$*"; }

# Outils
command -v jq >/dev/null 2>&1 || { say "Installe jq…"; pkg install -y jq >/dev/null; }

say "1) Vérif GH_TOKEN…"
u=$(curl -fsS -H "Authorization: token ${GH_TOKEN:-}" https://api.github.com/user | jq -r .login 2>/dev/null || true)
[ -n "${u:-}" ] && say "   ✔ GitHub OK : $u" || { echo "✖ GH_TOKEN invalide/absent"; exit 1; }

say "2) Vérif CF_API_TOKEN…"
st=$(curl -fsS -H "Authorization: Bearer ${CF_API_TOKEN:-}" \
  https://api.cloudflare.com/client/v4/user/tokens/verify | jq -r '.result.status' 2>/dev/null || true)
[ "$st" = "active" ] && say "   ✔ Cloudflare token actif" || { echo "✖ CF token KO"; exit 1; }

say "3) Résumé variables clefs"
printf "   GH_USER=%s\n   REPO_NAME=%s\n   CLOUDFLARE_ACCOUNT_ID=%s\n   CLOUDFLARE_PROJECT_NAME=%s\n" \
  "${GH_USER:-?}" "${REPO_NAME:-?}" "${CLOUDFLARE_ACCOUNT_ID:-?}" "${CLOUDFLARE_PROJECT_NAME:-?}"

say "OK ✅"
