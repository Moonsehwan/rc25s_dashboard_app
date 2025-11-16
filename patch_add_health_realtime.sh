#!/bin/bash
set -e

echo "🔧 [RC25H] MCP Realtime Health Patch 시작..."

TARGET_FILE="/srv/repo/vibecoding/mcp_server_realtime.py"

# 이미 health 함수가 존재하면 건너뜀
if grep -q "def health" "$TARGET_FILE"; then
  echo "✅ 이미 /health 엔드포인트가 존재합니다. 패치 생략."
else
  echo "🩺 /health 엔드포인트 추가 중..."
  cat <<'PYCODE' >> "$TARGET_FILE"

# ================================
# ✅ Health Check Endpoint 추가
# ================================
from fastapi.responses import JSONResponse
import socket, datetime

@app.get("/health")
def health():
    return JSONResponse({
        "status": "ok",
        "message": "RC25H MCP Realtime API active",
        "server": socket.gethostname(),
        "time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    })
PYCODE
  echo "✅ 코드 추가 완료."
fi

echo "🚀 MCP 서비스 재시작 중..."
sudo systemctl stop mcp.service
sudo pkill -f 'uvicorn' || true
sudo lsof -ti :8000 | xargs -r sudo kill -9
sudo systemctl daemon-reload
sudo systemctl restart mcp.service

sleep 3
STATUS=$(curl -s http://127.0.0.1:8000/health || true)
echo "------------------------------------------"
echo "🧩 Health 응답:"
echo "$STATUS"
echo "------------------------------------------"

if echo "$STATUS" | grep -q '"status": "ok"'; then
  echo "✅ MCP Realtime 서버가 정상적으로 작동 중입니다!"
else
  echo "❌ 헬스체크 실패 — 로그 확인 필요"
  sudo tail -n 20 /srv/repo/vibecoding/logs/mcp_server.log
fi

echo "🎯 패치 완료."
