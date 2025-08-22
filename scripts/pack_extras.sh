#!/usr/bin/env bash
set -euo pipefail

ROOT=sentinel_app/public
CSS="$ROOT/style.css"
JS="$ROOT/app.js"
SITE="${SITE:-https://sentinel-fusion.pages.dev}"   # override possible: SITE=https://ton-domaine.tld

stamp(){ date -u +"%Y-%m-%dT%H:%M:%SZ"; }
has(){ grep -qF "$1" "$2" 2>/dev/null; }

# ---------- CSS: compact + secteurs ----------
TAG_CSS='/* == extras:compact+secteurs v1 == */'
if ! has "$TAG_CSS" "$CSS"; then
cat >> "$CSS" <<'CSS'
/* == extras:compact+secteurs v1 == */

/* Global compact on mobile */
@media (max-width:720px){
  body{ line-height:1.5; }
  .hero{ padding-block:18px; }
  .grid{ gap:16px; }
  .card{ padding:14px; border-radius:10px; }
  .card h3{ font-size:clamp(18px,3.8vw,20px); margin:.35em 0 .45em; }
  .lead{ font-size:clamp(15px,3.6vw,17px); opacity:.9; }
}

/* Listes plus denses (secteurs/architectures) */
.bullets li{ margin:6px 0; display:flex; gap:10px; align-items:flex-start; }
.bullets li::before{
  content:"✔"; font-weight:600; opacity:.85;
  transform:translateY(1px);
}

/* Tables compactes */
table.compare{ width:100%; border-collapse:separate; border-spacing:0; }
table.compare tr{ border:1px solid rgba(255,255,255,.12); border-left:none; border-right:none; }
table.compare th, table.compare td{ padding:8px 10px; vertical-align:top; }
table.compare td + td{ border-left:1px dashed rgba(255,255,255,.08); }

/* Mini badges optionnels (si .chip/.chips déjà en place) */
.chips{ gap:8px; }
.chip{ padding:6px 10px; border-radius:999px; white-space:nowrap; }
@media (max-width:720px){ .chip{ padding:5px 8px; font-size:13px; } }
CSS
fi

# ---------- SEO: meta OG/Twitter + canonical ----------
tag_html='<!-- seo:pack v1 -->'
for f in "$ROOT"/*.html; do
  bn="$(basename "$f")"
  page="${bn%.html}"
  [[ "$bn" == "index.html" ]] && canon="$SITE/" || canon="$SITE/$bn"

  if ! grep -qF "$tag_html" "$f"; then
    title="$(grep -oPm1 '(?<=<title>).*?(?=</title>)' "$f" || true)"
    desc="$(grep -oPm1 '(?<=<meta name="description" content=").*?(?=")' "$f" || true)"
    [[ -z "$title" ]] && title="Sentinel Quantum Vanguard AI Pro"
    [[ -z "$desc"  ]] && desc="Suite de cyberdéfense intégrée : IA locale, EDR/XDR, OSINT/DarkWeb, bouclier mobile, traçabilité."

    # insère juste avant </head>
    tmp="$(mktemp)"
    awk -v T="$title" -v D="$desc" -v C="$canon" -v TAG="$tag_html" '
      BEGIN{IGNORECASE=1}
      /<\/head>/ && !done{
        print "  " TAG
        print "  <link rel=\"canonical\" href=\"" C "\">"
        print "  <meta property=\"og:type\" content=\"website\">"
        print "  <meta property=\"og:site_name\" content=\"Sentinel Quantum Vanguard AI Pro\">"
        print "  <meta property=\"og:title\" content=\"" T "\">"
        print "  <meta property=\"og:description\" content=\"" D "\">"
        print "  <meta property=\"og:url\" content=\"" C "\">"
        print "  <meta name=\"twitter:card\" content=\"summary_large_image\">"
        print "  <meta name=\"twitter:title\" content=\"" T "\">"
        print "  <meta name=\"twitter:description\" content=\"" D "\">"
        done=1
      }
      {print}
    ' "$f" > "$tmp" && mv "$tmp" "$f"
  fi
done

# ---------- Sitemap + robots ----------
# liste des pages
mapfile -t PAGES < <(ls -1 "$ROOT"/*.html | xargs -n1 basename | sort)
sm="$ROOT/sitemap.xml"
{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
  for p in "${PAGES[@]}"; do
    [[ "$p" == "index.html" ]] && loc="$SITE/" || loc="$SITE/$p"
    printf '  <url><loc>%s</loc><lastmod>%s</lastmod><changefreq>weekly</changefreq></url>\n' "$loc" "$(date -u +%F)"
  done
  echo '</urlset>'
} > "$sm"

cat > "$ROOT/robots.txt" <<ROB
User-agent: *
Allow: /
Sitemap: $SITE/sitemap.xml
ROB

# ---------- Cache-bust + commit + déploiement ----------
ts=$(date +%s)
for f in "$ROOT"/*.html; do
  sed -i -E "s|(\\./style\\.css)(\\?v=[0-9]+)?|\\1?v=$ts|g; s|(app\\.js)(\\?v=[0-9]+)?|\\1?v=$ts|g" "$f"
done

if [[ -x ./deploy_now.sh ]]; then
  git add "$CSS" "$ROOT"/*.html "$sm" "$ROOT/robots.txt" || true
  git commit -m "ux(extras): SEO pack + compact mobile + polish secteurs + sitemap/robots + cache bust v$ts" || true
  ./deploy_now.sh
else
  echo "⚠️ deploy_now.sh non trouvé : commit/déploiement sautés."
fi

echo "✅ Pack EXTRAS appliqué."
