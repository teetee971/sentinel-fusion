#!/data/data/com.termux/files/usr/bin/bash
# Usage: GITHUB_USER=tonuser REPO=sentinel-fusion GITHUB_PAT=ghp_xxx ./push_github.sh
set -euo pipefail
: "${GITHUB_USER:?Missing}"; : "${REPO:?Missing}"; : "${GITHUB_PAT:?Missing}"
branch="${BRANCH:-main}"
git init -q
git config user.email "${GITHUB_USER}@users.noreply.github.com"
git config user.name  "${GITHUB_USER}"
git add -A
git commit -m "Sentinel Fusion initial"
git branch -M "$branch"
git remote add origin "https://${GITHUB_USER}:${GITHUB_PAT}@github.com/${GITHUB_USER}/${REPO}.git"
git push -u origin "$branch" --force
echo "Poussé vers https://github.com/${GITHUB_USER}/${REPO}"
echo "Active ensuite l'action GitHub (elle déploiera sur Cloudflare Pages)."
