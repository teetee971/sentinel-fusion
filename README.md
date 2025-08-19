# Sentinel Fusion (PS5 + Futur Cyber + Dark Pro)

Déploiement automatique vers **Cloudflare Pages** via GitHub Actions.

## Secrets GitHub à ajouter (Repository → Settings → Secrets and variables → Actions)
- `CLOUDFLARE_API_TOKEN`  (Pages:Edit)
- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_PROJECT_NAME`
- `CLOUDFLARE_PAGES_BRANCH` = main

Un simple `git push` sur `main` déclenchera le déploiement.
