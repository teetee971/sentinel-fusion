#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# ---------- mini helpers (couleurs + die) ----------
red()   { printf "\033[1;31m%s\033[0m\n" "$*" >&2; }
green() { printf "\033[1;32m%s\033[0m\n" "$*"; }
cyan()  { printf "\033[1;36m%s\033[0m\n" "$*"; }
die()   { red "$*"; exit 1; }

# ---------- args ----------
AUTO=0
WANT_PROJECT=""
WANT_BRANCH=""
for a in "$@"; do
  case "$a" in
    --auto) AUTO=1 ;;
    --project=*) WANT_PROJECT="${a#*=}" ;;
    --branch=*)  WANT_BRANCH="${a#*=}" ;;
    *) die "Option inconnue: $a" ;;
  esac
done

# ---------- trim/normalize ----------
trim() { sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' <<<"$1" | tr -d '\r'; }
# normalise: minuscules + supprime tout sauf a-z0-9
norm() { tr '[:upper:]' '[:lower:]' <<<"$1" | sed -E 's/[^a-z0-9]+//g'; }

# ---------- charge .env s'il existe ----------
if [[ -f .env ]]; then
  # charge comme du shell (plus sûr que xargs si valeurs contiennent des espaces)
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

CF_API_TOKEN="${CF_API_TOKEN:-${TOKEN:-}}"
ACCOUNT_ID="${ACCOUNT_ID:-}"
PROJECT_NAME="${WANT_PROJECT:-${PROJECT_NAME:-}}"
BRANCH_NAME="${WANT_BRANCH:-${BRANCH_NAME:-main}}"

# ---------- nettoyage du token ----------
CF_API_TOKEN="$(trim "${CF_API_TOKEN:-}")"
CF_API_TOKEN="${CF_API_TOKEN#Bearer }"   # enlève "Bearer " si présent
[[ -n "$CF_API_TOKEN" ]] || die "CF_API_TOKEN manquant (.env ou --env)."
[[ -n "$ACCOUNT_ID"  ]] || die "ACCOUNT_ID manquant (.env)."

# ---------- prérequis ----------
command -v curl >/dev/null || die "curl manquant (pkg install curl)."
command -v jq   >/dev/null || die "jq manquant (pkg install jq)."

# ---------- vérifie le token ----------
cyan "🔎 Vérification du token…"
if ! curl -sS https://api.cloudflare.com/client/v4/user/tokens/verify \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  | jq -e '.success==true' >/dev/null
then
  die "Jeton invalide/expiré."
fi
green "✅ Jeton valide et actif."

# ---------- récupère la liste des projets ----------
cyan "ℹ️  Récupération des projets Pages du compte ${ACCOUNT_ID:0:8}…"
plist="$(curl -sS "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects" \
         -H "Authorization: Bearer $CF_API_TOKEN")"
jq -e '.success==true' <<<"$plist" >/dev/null || {
  printf "%s\n" "$plist" | jq . >&2 || true
  die "Impossible de lister les projets."
}

# tableau bash avec tous les noms
mapfile -t NAMES < <(jq -r '.result[].name' <<<"$plist")

[[ "${#NAMES[@]}" -gt 0 ]] || die "Aucun projet Pages dans ce compte."

# ---------- choix du projet (auto robuste ou interactif) ----------
choose_best() {
  local want="$1"; want="$(norm "$want")"
  local best=""; local best_score=-1
  for n in "${NAMES[@]}"; do
    local nn; nn="$(norm "$n")"
    local s=0
    if [[ "$nn" == "$want" ]]; then s=100
    elif [[ "$nn" == *"$want"* || "$want" == *"$nn"* ]]; then s=80
    else
      # score rudimentaire = longueur du préfixe commun
      local i=0; local minlen=${#nn}; [[ ${#want} -lt $minlen ]] && minlen=${#want}
      while (( i<minlen )) && [[ "${nn:i:1}" == "${want:i:1}" ]]; do ((i++)); done
      s=$i
    fi
    if (( s > best_score )); then best="$n"; best_score=$s; fi
  done
  printf '%s\n' "$best"
}

if [[ -n "$PROJECT_NAME" ]]; then
  if ! printf '%s\n' "${NAMES[@]}" | grep -qx -- "$PROJECT_NAME"; then
    # auto-correction vers le meilleur match
    best="$(choose_best "$PROJECT_NAME")"
    if [[ -n "$best" ]]; then
      cyan "ℹ️  « $PROJECT_NAME » introuvable, sélection auto ➜ « $best »."
      PROJECT_NAME="$best"
    fi
  fi
fi

if [[ -z "$PROJECT_NAME" ]]; then
  if (( AUTO )); then
    PROJECT_NAME="${NAMES[0]}"
    cyan "ℹ️  Mode --auto : sélection par défaut ➜ « $PROJECT_NAME »."
  else
    cyan "📋 Projets disponibles :"
    local i=1
    for n in "${NAMES[@]}"; do printf "  %2d) %s\n" "$i" "$n"; ((i++)); done
    while : ; do
      read -rp "Numéro du projet : " choice
      if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice>=1 && choice<=${#NAMES[@]} )); then
        PROJECT_NAME="${NAMES[choice-1]}"; break
      fi
      red "Choix invalide. Réessaie."
    done
  fi
fi

# sécurité finale
if ! printf '%s\n' "${NAMES[@]}" | grep -qx -- "$PROJECT_NAME"; then
  if (( AUTO )); then
    red "Projet introuvable en mode auto."
    printf "Projets existants: %s\n" "${NAMES[*]}" >&2
    exit 1
  else
    die "Projet « $PROJECT_NAME » introuvable."
  fi
fi
green "✅ Projet « $PROJECT_NAME » sélectionné."
cyan  "🚀 Déploiement de « $PROJECT_NAME » (branche $BRANCH_NAME)…"

# ---------- déclenche le déploiement ----------
data_json="$(cat <<JSON
{"deployment_trigger":{"type":"ad_hoc"},"production_branch":"$BRANCH_NAME"}
JSON
)"

resp="$(curl -sS -X POST \
  "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects/$PROJECT_NAME/deployments" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "$data_json")" || die "Échec appel déploiement."

jq -e '.success==true' <<<"$resp" >/dev/null || {
  die "Échec du déclenchement.$(printf '\n%s\n' "$resp" | jq .)"
}

deploy_id="$(jq -r '.result.id' <<<"$resp")"
preview_url="$(jq -r '.result.deployment_url // empty' <<<"$resp")"
green "✅ Déploiement déclenché (id: $deploy_id)."
if [[ -n "$preview_url" && "$preview_url" != "null" ]]; then
  cyan  "👀 Aperçu : $preview_url"
fi

# ---------- journalisation ----------
log_file="deploy_pages.log"
ts="$(date '+%Y-%m-%d %H:%M:%S')"
{
  echo "[$ts] project=$PROJECT_NAME branch=$BRANCH_NAME id=$deploy_id preview=${preview_url:-}"
} >> "$log_file"

exit 0
