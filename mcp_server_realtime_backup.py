from fastapi import FastAPI, WebSocket
import json

app = FastAPI(title="MCP Realtime API")

@app.get("/")
async def root():
    return {"status": "ok", "message": "MCP Realtime Server is Running"}

# ✅ WebSocket (AGI Realtime)
@app.websocket("/ws/agi")
async def agi_ws(websocket: WebSocket):
    await websocket.accept()
    print("🔌 Client connected")

    try:
        while True:
            data = await websocket.receive_text()
            print(f"📩 Received: {data}")

            try:
                payload = json.loads(data)
                if payload.get("message") == "ping":
                    await websocket.send_json({"type": "heartbeat", "message": "pong"})
                else:
                    await websocket.send_json({"type": "echo", "message": payload})
            except Exception as e:
                await websocket.send_json({"type": "error", "message": str(e)})

    except Exception as e:
        print("❌ Connection closed:", e)
    finally:
        await websocket.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("vibecoding.mcp_server_realtime:app", host="0.0.0.0", port=8000)
from fastapi import WebSocket

@app.websocket("/ws/test")
async def test_ws(websocket: WebSocket):
    await websocket.accept()
    await websocket.send_json({"status": "ok", "message": "test websocket active"})
    await websocket.close()
