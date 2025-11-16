from fastapi import FastAPI, WebSocket
import json

app = FastAPI(title="MCP Realtime API", version="1.0.0")

# 연결된 클라이언트 저장용 (필요 시 broadcast 가능)
connected_clients = set()

@app.get("/")
async def root():
    return {"status": "ok", "message": "MCP Server is running"}

@app.websocket("/ws/agi")
async def agi_ws(websocket: WebSocket):
    await websocket.accept()
    connected_clients.add(websocket)
    print("🔌 WebSocket client connected")

    try:
        while True:
            # 클라이언트 메시지 수신
            data = await websocket.receive_text()
            print(f"📩 Received: {data}")

            # JSON 파싱 시도
            try:
                payload = json.loads(data)
            except Exception:
                await websocket.send_json({"type": "error", "message": "Invalid JSON"})
                continue

            # 기본 핑/퐁 처리
            if payload.get("message") == "ping":
                await websocket.send_json({"type": "heartbeat", "message": "pong"})
                continue

            # 일반 응답
            await websocket.send_json({
                "type": "ack",
                "message": f"✅ Received: {payload}"
            })

    except Exception as e:
        print(f"⚠️ WebSocket error: {e}")
    finally:
        connected_clients.remove(websocket)
        print("❌ WebSocket client disconnected")

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
