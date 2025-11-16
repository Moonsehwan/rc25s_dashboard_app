#!/bin/bash
echo "🧠 [RC25S] Fixing AGI Dashboard Backend (FastAPI Rebuild)..."

DASH_DIR="/srv/repo/vibecoding/rc25s_dashboard"
mkdir -p $DASH_DIR

cat <<'PYCODE' > ${DASH_DIR}/agi_status_dashboard.py
from fastapi import FastAPI, WebSocket
import uvicorn, datetime

app = FastAPI(title="RC25S AGI Dashboard")

@app.get("/")
def root():
    return {
        "RC25S": "AGI 실시간 대시보드 활성화됨",
        "server": "5.104.87.232",
        "dashboard_url": "https://api.mcpvibe.org/agi/",
        "status": "ACTIVE"
    }

@app.get("/health")
def health():
    return {"status": "ok", "model": "RC25S", "time": str(datetime.datetime.now())}

@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await ws.accept()
    await ws.send_text("🧠 RC25S 실시간 연결 성공!")
    while True:
        try:
            msg = await ws.receive_text()
            now = datetime.datetime.now().strftime("%H:%M:%S")
            await ws.send_text(f"[{now}] 수신됨 → {msg}")
        except Exception as e:
            print("WebSocket 종료:", e)
            break

if __name__ == "__main__":
    print("🚀 RC25S AGI 실시간 대시보드 백엔드 시작 중...")
    uvicorn.run(app, host="0.0.0.0", port=4545)
PYCODE

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart rc25s-dashboard.service
sleep 3
curl -s http://127.0.0.1:4545/health || echo "⚠️ 서버 응답 없음. 로그 확인 필요: journalctl -u rc25s-dashboard.service -n 30"
