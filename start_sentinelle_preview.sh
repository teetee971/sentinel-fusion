#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
HOST="${HOST:-127.0.0.1}"; PORT="${PORT:-5173}"; SESSION="${SESSION:-web}"
tmux kill-session -t "$SESSION" 2>/dev/null || true
npm run build >/dev/null
tmux new -ds "$SESSION" "bash -lc 'HOST=$HOST PORT=$PORT npm run preview 2>&1 | tee -a vite-preview.log'"
URL="http://$HOST:$PORT/"; printf '\033[1;32m[✓]\033[0m Preview : %s\n' "$URL"
command -v termux-open-url >/dev/null 2>&1 && termux-open-url "$URL" || true
printf '[i] Logs: tmux attach -t %s (Ctrl+b puis d pour détacher)\n' "$SESSION"
