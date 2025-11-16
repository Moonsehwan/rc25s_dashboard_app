#!/bin/bash
echo "🧠 [RC25S] Fixing AGI WebSocket backend (add response handler)..."

DASHBOARD_PY="/srv/repo/vibecoding/rc25s_dashboard/agi_status_dashboard.py"

cat > "$DASHBOARD_PY" <<'PYCODE'
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
import psutil, datetime, json

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {
        "status": "ok",
        "model": "RC25S",
        "cpu": psutil.cpu_percent(interval=0.5),
        "memory": psutil.virtual_memory().percent,
        "time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    await websocket.send_text("🧠 연결됨: AGI 실시간 스트림 활성화 완료.")
    try:
        while True:
            msg = await websocket.receive_text()
            print(f"📩 수신됨: {msg}")

            if msg.strip() == "상태보여줘":
                data = {
                    "cpu": psutil.cpu_percent(interval=0.5),
                    "mem": psutil.virtual_memory().percent,
                    "time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                }
                await websocket.send_text(f"📊 CPU: {data['cpu']}%, 메모리: {data['mem']}%, 시간: {data['time']}")
            elif msg.strip() == "ping":
                await websocket.send_text("🏓 pong")
            elif msg.strip().startswith("실행 "):
                code = msg.strip()[3:]
                try:
                    exec_locals = {}
                    exec(code, {}, exec_locals)
                    await websocket.send_text(f"✅ 실행 결과: {exec_locals}")
                except Exception as e:
                    await websocket.send_text(f"❌ 코드 실행 오류: {e}")
            else:
                await websocket.send_text(f"🤖 명령 '{msg}' 인식됨 (처리 준비 중...)")

    except Exception as e:
        print(f"⚠️ WebSocket 종료됨: {e}")
    finally:
        await websocket.close()
        print("🔌 연결 종료됨.")
PYCODE

echo "🔄 Restarting dashboard service..."
sudo systemctl restart rc25s-dashboard.service
sleep 2
sudo systemctl status rc25s-dashboard.service --no-pager | head -n 10
echo "✅ WebSocket 백엔드 수정 완료!"
