#!/usr/bin/env bash
set -e

PROJECT_ID="sentinel-vanguard-ai-pro"

echo "🔧 Projet: $PROJECT_ID"

if [ -f package.json ]; then
  if npm run | grep -qE ' build '; then
    echo "🏗️  Build npm…"
    npm run build
  else
    echo "ℹ️  Pas de script 'build', on saute."
  fi
else
  echo "ℹ️  Pas de package.json, on saute le build."
fi

echo "🚀 Déploiement Firebase Hosting (Sentinel)…"
firebase deploy --project "$PROJECT_ID" --only hosting

echo "✅ Terminé pour Sentinel."
