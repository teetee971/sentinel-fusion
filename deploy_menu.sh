#!/usr/bin/env bash
set -e

SENTINEL_ID="sentinel-vanguard-ai-pro"
AKI_ID="a-ki-pri-sa-ye"

pick_firebase_dir() {
  local base="${1:-$HOME}"
  local f
  f=$(find "$base" -maxdepth 3 -type f -name firebase.json -print -quit 2>/dev/null)
  if [ -n "$f" ]; then
    dirname "$f"
  else
    echo "$PWD"
  fi
}

maybe_build() {
  if [ -f package.json ]; then
    if npm run | grep -qE ' build '; then
      echo "🧱 Build npm…"
      npm run build
    else
      echo "ℹ️ Pas de script 'build', on saute."
    fi
  else
    echo "ℹ️ Pas de package.json, on saute le build."
  fi
}

deploy_project() {
  local label="$1" proj="$2"
  echo "🔧 Projet: $label  (Firebase ID: $proj)"
  if [[ ! -f firebase.json ]]; then
    local dir
    dir="$(pick_firebase_dir "$HOME")"
    echo "📍 Dossier trouvé: $dir"
    cd "$dir" || { echo "❌ Impossible de cd dans $dir"; exit 1; }
  fi
  echo "🚀 Déploiement Firebase Hosting ($label) ..."
  firebase deploy --project "$proj" --only hosting
  echo "✅ Terminé pour $label."
}

echo "==============================="
echo "  Choisis le projet à déployer "
echo "==============================="
echo "1) Sentinel            ($SENTINEL_ID)"
echo "2) A KI PRI SA YÉ      ($AKI_ID)"
echo "3) Quitter"
read -rp "Ton choix [1-3] (défaut 1): " CH
CH="${CH:-1}"

case "$CH" in
  1) deploy_project "Sentinel" "$SENTINEL_ID" ;;
  2) deploy_project "A KI PRI SA YÉ" "$AKI_ID" ;;
  *) echo "👋 Bye"; exit 0 ;;
esac
