#!/usr/bin/env bash
set -euo pipefail

SITE="${SITE:-https://sentinel-fusion.pages.dev}"        # override possible: SITE=https://ton-domaine.tld
ROOT=sentinel_app/public
CSS="$ROOT/style.css"
JS="$ROOT/app.js"

has(){ grep -qF "$1" "$2" 2>/dev/null; }
trim(){ sed -E 's/^[[:space:]]+|[[:space:]]+$//g'; }
txt(){ sed -E 's/<[^>]+>//g' | sed -E 's/[[:space:]]+/ /g' | trim; }

# -------------------------------------------
# 1) SEO++ : title+description automatiques + canonical + hreflang
# -------------------------------------------
TAG_SEO='<!-- seo:pack++ v1 -->'
for f in "$ROOT"/*.html; do
  bn="$(basename "$f")"
  [[ "$bn" == "index.html" ]] && canon="$SITE/" || canon="$SITE/$bn"

  # h1 -> title si possible
  h1="$(awk 'BEGIN{IGNORECASE=1} /<h1[ >]/{p=1} p{print} /<\/h1>/{exit}' "$f" 2>/dev/null | txt | head -n1)"
  [[ -z "$h1" ]] && h1="$(grep -oPm1 '(?<=<title>).*?(?=</title>)' "$f" 2>/dev/null || true)"
  new_title="$(printf "%s – Sentinel Quantum Vanguard AI Pro" "${h1:-Sentinel Quantum Vanguard AI Pro}")"

  # description : <p class="lead"> sinon 1er <p> après h1
  lead="$(awk 'BEGIN{IGNORECASE=1}
    /class="lead"/,/<\/p>/{print}
  ' "$f" 2>/dev/null | txt | head -n1)"
  if [[ -z "$lead" ]]; then
    lead="$(awk 'BEGIN{IGNORECASE=1} /<h1[ >]/{h=1} h&&/<p[ >]/{p=1} p{print} /<\/p>/{exit}' "$f" 2>/dev/null | txt | head -n1)"
  fi
  desc="$(printf "%s" "${lead:-Suite de cyberdéfense intégrée : IA locale, EDR/XDR, OSINT/DarkWeb, bouclier mobile, traçabilité.}" \
         | cut -c1-180 | sed 's/[[:space:]]+$//')"

  # <title> (remplace ou crée)
  if grep -q '</title>' "$f"; then
    sed -i -E "s|<title>.*</title>|<title>${new_title//|/\\|}</title>|" "$f"
  else
    sed -i -E "s|</head>|  <title>${new_title//|/\\|}</title>\n</head>|" "$f"
  fi

  # <meta name="description">
  if grep -qi '<meta name="description"' "$f"; then
    sed -i -E "s|<meta name=\"description\" content=\"[^\"]*\" ?/?>|<meta name=\"description\" content=\"${desc//|/\\|}\">|I" "$f"
  else
    sed -i -E "s|</head>|  <meta name=\"description\" content=\"${desc//|/\\|}\">\n</head>|" "$f"
  fi

  # bloc canonical + hreflang + og/twitter si pas déjà posé par un pack précédent
  if ! has "$TAG_SEO" "$f"; then
    tmp="$(mktemp)"
    awk -v C="$canon" -v T="$new_title" -v D="$desc" -v TAG="$TAG_SEO" '
      BEGIN{IGNORECASE=1}
      /<\/head>/ && !done{
        print "  " TAG
        print "  <link rel=\"canonical\" href=\"" C "\">"
        print "  <link rel=\"alternate\" hreflang=\"fr\" href=\"" C "\">"
        print "  <link rel=\"alternate\" hreflang=\"x-default\" href=\"" C "\">"
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

# sitemap + robots
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
echo -e "User-agent: *\nAllow: /\nSitemap: $SITE/sitemap.xml" > "$ROOT/robots.txt"

# -------------------------------------------
# 2) Section Contact & démo (+ CSS + JS)
# -------------------------------------------
TAG_FORM_HTML='<!-- contact-pack v1 -->'
TAG_FORM_CSS='/* == contact-pack v1 == */'
TAG_FORM_JS='/* == contact-pack v1 == */'

# CSS (léger, responsive)
if ! has "$TAG_FORM_CSS" "$CSS"; then
cat >> "$CSS" <<'CSS'
/* == contact-pack v1 == */
.form{max-width:820px;margin:0 auto;}
.form .row{display:flex;gap:14px;flex-wrap:wrap;}
.form .field{flex:1 1 240px;display:flex;flex-direction:column;}
.form label{font-weight:600;margin:6px 2px;}
.form input,.form textarea{background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.10);
  border-radius:10px;color:inherit;padding:12px 12px;}
.form textarea{min-height:120px;resize:vertical;}
.form .hp{position:absolute!important;left:-9999px;top:-9999px;height:0;width:0;opacity:0}
.form .actions{display:flex;align-items:center;gap:12px;margin-top:10px;flex-wrap:wrap;}
.form .msg{opacity:.9}
@media(max-width:720px){ .form input,.form textarea{padding:11px 10px} }
CSS
fi

# HTML (ajout dans index.html, avant le footer)
IDX="$ROOT/index.html"
if [[ -f "$IDX" ]] && ! has "$TAG_FORM_HTML" "$IDX"; then
  # insère avant </footer> si présent, sinon avant </body>
  insert_point='</footer>'
  if ! grep -q '</footer>' "$IDX"; then insert_point='</body>'; fi

  tmp="$(mktemp)"
  awk -v TAG="$TAG_FORM_HTML" -v SITE="$SITE" -v IP="$insert_point" '
    BEGIN{IGNORECASE=1}
    index(tolower($0),tolower(IP)) && !done{
      print "  " TAG
      print "  <section id=\"contact\" class=\"section\">"
      print "    <h2>Contact & démo</h2>"
      print "    <p class=\"lead\">Dites-nous en plus sur votre contexte ; nous revenons vers vous rapidement.</p>"
      print "    <form id=\"contact-form\" class=\"form\" novalidate>"
      print "      <div class=\"row\">"
      print "        <div class=\"field\"><label for=\"cf-name\">Nom</label><input id=\"cf-name\" name=\"name\" required autocomplete=\"name\"></div>"
      print "        <div class=\"field\"><label for=\"cf-company\">Organisation</label><input id=\"cf-company\" name=\"company\" autocomplete=\"organization\"></div>"
      print "      </div>"
      print "      <div class=\"row\">"
      print "        <div class=\"field\"><label for=\"cf-email\">E-mail</label><input id=\"cf-email\" type=\"email\" name=\"email\" required autocomplete=\"email\"></div>"
      print "        <div class=\"field\"><label for=\"cf-phone\">Téléphone (optionnel)</label><input id=\"cf-phone\" type=\"tel\" name=\"phone\" autocomplete=\"tel\"></div>"
      print "      </div>"
      print "      <div class=\"row\"><div class=\"field\" style=\"flex-basis:100%\">"
      print "        <label for=\"cf-msg\">Message</label><textarea id=\"cf-msg\" name=\"message\" required placeholder=\"Votre besoin, périmètre, délais…\"></textarea>"
      print "      </div></div>"
      print "      <input class=\"hp\" type=\"text\" name=\"website\" tabindex=\"-1\" autocomplete=\"off\" aria-hidden=\"true\">"
      print "      <div class=\"actions\">"
      print "        <button class=\"btn\" type=\"submit\">Envoyer la demande</button>"
      print "        <span class=\"msg\" role=\"status\" aria-live=\"polite\"></span>"
      print "      </div>"
      print "    </form>"
      print "    <p class=\"note\">En soumettant, vous acceptez le traitement de vos données pour répondre à votre demande. Voir la page <a href=\"/confidentialite.html\">Confidentialité</a>.</p>"
      print "    <script>window.CONTACT_ENDPOINT = window.CONTACT_ENDPOINT || \"\"; /* Renseignez un endpoint (Formspree/Worker) si dispo */</script>"
      print "  </section>"
      done=1
    }
    {print}
  ' "$IDX" > "$tmp" && mv "$tmp" "$IDX"
fi

# JS (validation + envoi + anti-bot + rate limit + fallback démo)
if ! has "$TAG_FORM_JS" "$JS"; then
cat >> "$JS" <<'JS'
/* == contact-pack v1 == */
(function(){
  const form=document.querySelector('#contact-form'); if(!form) return;
  const msg=form.querySelector('.msg');
  const ok=t=>{ msg.textContent=t; msg.style.opacity=.95; };
  const bad=t=>{ msg.textContent=t; msg.style.opacity=.95; };
  const endpoint=(window.CONTACT_ENDPOINT||'').trim();

  const emailRx=/^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  form.addEventListener('submit', async (e)=>{
    e.preventDefault();
    const fd=new FormData(form);
    if(fd.get('website')){ ok('Merci !'); form.reset(); return; } // honeypot
    const payload={
      name:(fd.get('name')||'').toString().trim(),
      company:(fd.get('company')||'').toString().trim(),
      email:(fd.get('email')||'').toString().trim(),
      phone:(fd.get('phone')||'').toString().trim(),
      message:(fd.get('message')||'').toString().trim(),
      page: location.href,
      t: new Date().toISOString()
    };
    if(!payload.name || !emailRx.test(payload.email) || payload.message.length<5){
      bad('Vérifiez les champs requis.'); return;
    }
    const last=+localStorage.getItem('sqv_contact_last')||0;
    if(Date.now()-last < 60000){ bad('Trop de demandes. Réessayez dans une minute.'); return; }
    localStorage.setItem('sqv_contact_last', Date.now());

    ok('Envoi en cours…');
    if(!endpoint){
      console.info('[Contact DEMO]', payload);
      ok('Merci ! Votre demande est enregistrée (mode démo).');
      form.reset();
      return;
    }
    try{
      const r=await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)});
      if(r.ok){ ok('Merci ! Nous revenons vers vous rapidement.'); form.reset(); }
      else{ bad('Envoi impossible. Essayez encore ou contactez-nous directement.'); }
    }catch(err){
      bad('Réseau indisponible. Réessayez.');
    }
  });
})();
JS
fi

# -------------------------------------------
# 3) Cache-bust + commit + déploiement
# -------------------------------------------
ts=$(date +%s)
for f in "$ROOT"/*.html; do
  sed -i -E "s|(\\./style\\.css)(\\?v=[0-9]+)?|\\1?v=$ts|g; s|(app\\.js)(\\?v=[0-9]+)?|\\1?v=$ts|g" "$f"
done

if [[ -x ./deploy_now.sh ]]; then
  git add "$ROOT"/*.html "$CSS" "$JS" "$ROOT/sitemap.xml" "$ROOT/robots.txt" || true
  git commit -m "pack: SEO++ + Contact & démo + cache bust v$ts" || true
  ./deploy_now.sh
else
  echo "⚠️ deploy_now.sh non trouvé : commit/déploiement sautés."
fi

echo "✅ PACK SEO++ + CONTACT appliqué."
