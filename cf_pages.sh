#!/usr/bin/env bash
set -euo pipefail

# 0) Charge l'env (HOME puis local)
set -a; [ -f "$HOME/.env" ] && . "$HOME/.env"; [ -f ./.env ] && . ./.env; set +a
: "${CF_API_TOKEN:?CF_API_TOKEN manquant}"
: "${ACCOUNT_ID:?ACCOUNT_ID manquant}"

# 1) API nettoyée (pas de CR/LF, pas de slash final)
API=$'https://api.cloudflare.com/client/v4'
API=${API//$'\r'/}; API=${API//$'\n'/}; API=${API%/}
HDR=(-H "Authorization: Bearer $CF_API_TOKEN")

# 2) Parsing options
mode="status"; pn="${PROJECT_NAME:-}"
while (($#)); do
  case "$1" in
    -p|--project) pn="${2:-}"; shift 2;;
    --status) mode="status"; shift;;
    --watch)  mode="watch";  shift;;
    *) shift;;
  esac
done
[ -n "$pn" ] || { echo "Donne un projet (-p) ou mets PROJECT_NAME dans ~/.env"; exit 1; }

# 3) Résout le nom exact (insensible à la casse, accepte préfixe)
json="$(curl -fsS "${HDR[@]}" "$API/accounts/$ACCOUNT_ID/pages/projects")"
pn_exact="$(
  jq -r --arg n "$pn" '
    .result[]? | .name? // empty | strings as $nm
    | select( ($nm|ascii_downcase) == ($n|ascii_downcase)
           or ($nm|ascii_downcase | startswith($n|ascii_downcase)) )
    | $nm' <<<"$json" | head -1
)"
[ -n "$pn_exact" ] || { echo "Projet introuvable: $pn. Projets :"; jq -r '.result[]?.name' <<<"$json"; exit 1; }

# 4) Actions
if [[ "$mode" == "status" ]]; then
  curl -fsS "${HDR[@]}" \
    "$API/accounts/$ACCOUNT_ID/pages/projects/$pn_exact/deployments?order=desc&per_page=1" |
  jq -r 'first(.result[]?) | "id=\(.id)  status=\(.latest_stage.status // "unknown")  url=\(.deployment_url // (.urls[0]? // "n/a"))"'
  exit 0
fi

echo "Suivi du projet $pn_exact (Ctrl-C pour arrêter)…"
while :; do
  dep="$(curl -fsS "${HDR[@]}" "$API/accounts/$ACCOUNT_ID/pages/projects/$pn_exact/deployments?order=desc&per_page=1")"
  st="$(jq -r 'first(.result[]?) | .latest_stage.status // "unknown"' <<<"$dep")"
  url="$(jq -r 'first(.result[]?) | (.deployment_url // (.urls[0]? // "n/a"))' <<<"$dep")"
  echo "$(date +%H:%M:%S) status=$st url=$url"
  case "$st" in
    success)            echo "✅ Déploiement terminé."; exit 0;;
    failure|canceled)   echo "❌ Terminé avec état: $st"; exit 1;;
  esac
  sleep 5
done
