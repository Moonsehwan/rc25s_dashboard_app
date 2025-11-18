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

# ✅ 3. Frontend /agi/ 라우팅 헬스 체크
# - 기준: https://api.mcpvibe.org/agi/ 에 대한 HTTP 상태코드가 2xx/3xx 이면 OK
# - 세부 정적 리소스(main.js, manifest.json)는 Autoheal/빌드 단계에서 별도로 검증

FRONT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://api.mcpvibe.org/agi/)
if [[ "$FRONT_STATUS" =~ ^2|3 ]]; then
  log "✅ Frontend /agi/ responding (status=$FRONT_STATUS)."
else
  log "❌ Frontend /agi/ bad status (status=$FRONT_STATUS). Reloading Nginx..."
  systemctl reload nginx
fi

log "✅ Self-diagnostic completed successfully."
