#!/bin/bash
LOGFILE="/var/log/rc25s-autoheal.log"
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"

log() { echo "$(date "+%F %T") [SELF-CHECK] $*" | tee -a "$LOGFILE"; }

# ✅ 1. FastAPI /health check
if curl -s http://127.0.0.1:4545/health | grep -q "ok"; then
  log "✅ FastAPI backend responding correctly."
else
  log "❌ FastAPI backend not responding. Restarting..."
  systemctl restart rc25s-dashboard.service
fi

# ✅ 2. LLM backend mock check
LLM_RESP=$(curl -s -X POST http://127.0.0.1:4545/llm -H "Content-Type: application/json" -d "{\"prompt\": \"ping\"}" | grep -o "ok")
if [[ "$LLM_RESP" == "ok" ]]; then
  log "✅ LLM integration healthy."
else
  log "❌ LLM check failed. Will retry after heal cycle."
fi

# ✅ 3. Frontend JS & Manifest
if curl -sI https://api.mcpvibe.org/agi/static/js/main.ffd914ce.js | grep -q "200"; then
  log "✅ Frontend static JS accessible."
else
  log "❌ Frontend static files missing. Reloading Nginx..."
  systemctl reload nginx
fi

if curl -sI https://api.mcpvibe.org/agi/manifest.json | grep -q "200"; then
  log "✅ Manifest OK."
else
  log "⚠️ Manifest not reachable."
fi

log "✅ Self-diagnostic completed successfully."
