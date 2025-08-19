#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ---------- helpers ----------
trim()       { sed -E 's/^[[:space:]]+|[[:space:]]+$//g' | tr -d '\r'; }
lower()      { tr '[:upper:]' '[:lower:]'; }
normalize()  {
  # minuscule + suppression des caractères non alphanum (tue espaces, -, _, etc.)
  # essaie de désaccentuer si iconv est dispo (sinon on continue sans)
  if command -v iconv >/dev/null 2>&1; then
    iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null | lower | sed -E 's/[^a-z0-9]+//g'
  else
    lower | sed -E 's/[^a-z0-9]+//g'
  fi
}

color() { printf "\033[%sm%s\033[0m\n" "$1" "$2"; }
ok()    { color "32;1" "✅ $*"; }
info()  { color "36;1" "ℹ️  $*"; }
warn()  { color "33;1" "⚠️  $*"; }
die()   { color "31;1" "❌ $*"; exit 1; }

# ---------- charge .env ----------
set -a; [ -f .env ] && . ./.env; set +a
CF_API_TOKEN="${CF_API_TOKEN#Bearer }"  # au cas où
: "${ACCOUNT_ID:?ACCOUNT_ID manquant dans .env}"

# ---------- modes --list / --watch ----------
if [[ "${1:-}" == "--list" ]]; then
  plist="$(curl -sS "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects" \
          -H "Authorization: Bearer $CF_API_TOKEN")"
  [[ "$(jq -r '.success' <<<"$plist")" == "true" ]] || { echo "$plist" | jq -C .; exit 1; }
  jq -r '.result[].name' <<<"$plist"
  exit 0
fi

if [[ "${1:-}" == "--watch" ]]; then
  interval="${2:-10}"
  target="${3:-${PROJECT_NAME:-}}"
  [[ -n "$target" ]] || die "Usage: $0 --watch [interval] [projet]  (ou définir PROJECT_NAME dans .env)"
  while :; do
    "$0" "$target" | jq -C .
    sleep "$interval"
  done
fi

# ---------- résolution du projet ----------
needle="${1:-${PROJECT_NAME:-}}"
[[ -n "$needle" ]] || die "Usage: $0 <projet>  (ou définir PROJECT_NAME dans .env)"

# nettoie et normalise l'aiguille
needle_raw="$(printf '%s' "$needle" | trim)"
needle_norm="$(printf '%s' "$needle_raw" | normalize)"

# récupère la liste des projets
plist="$(curl -sS "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects" \
        -H "Authorization: Bearer $CF_API_TOKEN")"
[[ "$(jq -r '.success' <<<"$plist")" == "true" ]] || { echo "$plist" | jq -C .; exit 1; }

mapfile -t names < <(jq -r '.result[].name' <<<"$plist")

# 1) exact (après trim)
project=""
for n in "${names[@]}"; do
  n_trim="$(printf '%s' "$n" | trim)"
  [[ "$n_trim" == "$needle_raw" ]] && project="$n_trim" && break
done
# 2) fuzzy normalisé (contains)
if [[ -z "$project" ]]; then
  for n in "${names[@]}"; do
    n_norm="$(printf '%s' "$n" | trim | normalize)"
    [[ "$n_norm" == *"$needle_norm"* ]] && project="$n" && break
  done
fi
# 3) pas trouvé → aide + debug
if [[ -z "$project" ]]; then
  warn "Projet introuvable: «$needle_raw»"
  printf "Projets disponibles :\n"; printf " - %s\n" "${names[@]}"
  printf "\nDebug rapide de ton entrée (hexdump) :\n"
  printf '%s' "$needle" | hexdump -C
  exit 1
fi

ok "Projet « $project » sélectionné."

# ---------- dernier déploiement ----------
resp="$(curl -sS \
  "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/$project/deployments?order=desc&per_page=1" \
  -H "Authorization: Bearer $CF_API_TOKEN")"

[[ "$(jq -r '.success' <<<"$resp")" == "true" ]] || { die "Erreur API:\n$(echo "$resp" | jq -C .)"; }

if [[ "$(jq -r '.result | length' <<<"$resp")" == "0" ]]; then
  info "Aucun déploiement trouvé pour «$project»."
  exit 0
fi

jq -r --arg project "$project" '
  .result[0] as $d
  | {
      project: $project,
      id: $d.id,
      created_on: $d.created_on,
      environment: $d.environment,
      status: ($d.latest_stage.status // "unknown"),
      deployment_url: (
        $d.deployment_url
        // $d.url
        // ( ($d.urls | select(type=="array" and length>0)) | .[0] )
      )
    }
' <<<"$resp"
