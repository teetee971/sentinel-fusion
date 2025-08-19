#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

HOST="${HOST:-127.0.0.1}"
BASE_PORT="${PORT:-5173}"
SESSION="${SESSION:-sentinel_preview}"
USE_TMUX="${USE_TMUX:-0}"   # export USE_TMUX=1 pour tmux

say(){ printf "\033[1;32m[✓]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[!]\033[0m %s\n" "$*"; }
err(){ printf "\033[1;31m[x]\033[0m %s\n" "$*" >&2; }

pick_free_port(){
  local p=$BASE_PORT
  while ss -ltn | awk '{print $4}' | grep -q ":$p$"; do
    p=$((p+1))
    [ $p -le $((BASE_PORT+50)) ] || { err "Aucun port libre trouvé."; exit 2; }
  done
  echo "$p"
}

open_url(){
  local url="$1"
  command -v termux-open-url >/dev/null && termux-open-url "$url" || true
  echo "$url"
}

ensure_build(){
  if [ -f package.json ]; then
    if [ ! -d dist ]; then
      say "Build npm (npm run build)…"
      npm run build
    fi
  fi
}

start_vite(){
  local port="$1"
  if npx --yes vite -v >/dev/null 2>&1; then
    if [ "$USE_TMUX" = "1" ] && command -v tmux >/dev/null 2>&1; then
      tmux kill-session -t "$SESSION" 2>/dev/null || true
      tmux new -ds "$SESSION" "bash -lc 'npx vite preview --host $HOST --port $port --strictPort=false'"
      say "Vite preview lancé dans tmux ($SESSION)"
    else
      say "Start: npx vite preview --host $HOST --port $port"
      npx vite preview --host "$HOST" --port "$port" --strictPort=false
    fi
  else
    return 1
  fi
}

start_python(){
  local port="$1" dir="$2"
  nohup python -m http.server "$port" --directory "$dir" >/dev/null 2>&1 &
  echo $! > .preview.pid
  say "Serveur Python lancé (PID $(cat .preview.pid))"
}

main(){
  # 1) Dossier projet (arg1) ou ~/sentinel_app
  cd "${1:-$HOME/sentinel_app}" || { err "Dossier introuvable"; exit 1; }
  say "Dossier: $(pwd)"

  # 2) Choix du port libre
  PORT="$(pick_free_port)"
  URL="http://$HOST:$PORT/"
  say "Port choisi: $PORT"
  open_url "$URL" >/dev/null

  # 3) Build si projet Vite
  ensure_build

  # 4) Lancement serveur
  if [ -d dist ]; then
    start_vite "$PORT" || { warn "Vite indisponible → fallback Python"; start_python "$PORT" "dist"; open_url "$URL"; }
  elif [ -f index.html ]; then
    warn "Pas de /dist : service du dossier courant en Python"
    start_python "$PORT" "."
    open_url "$URL"
  else
    err "Rien à servir (ni dist/ ni index.html)."; exit 3
  fi

  say "URL: $URL"
  if [ "$USE_TMUX" = "1" ] && command -v tmux >/dev/null 2>&1; then
    say "Logs: tmux attach -t $SESSION   (détache: Ctrl+b puis d)"
  else
    [ -f .preview.pid ] && say "Stop: kill \$(cat .preview.pid)"
  fi
}
main "$@"
