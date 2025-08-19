#!/data/data/com.termux/files/usr/bin/bash
set -e
cd ~/SentinelQuantumVanguardAiPro
npm run build
tmux kill-session -t web 2>/dev/null || true
tmux new -ds web 'bash -lc "cd ~/SentinelQuantumVanguardAiPro && npx vite preview --host 127.0.0.1 --port 4173 --strictPort 2>&1 | tee vite.log"'
termux-open-url "http://127.0.0.1:4173/"
