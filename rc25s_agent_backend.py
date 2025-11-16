from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse, JSONResponse
import asyncio, datetime, os, json, subprocess

app = FastAPI()
clients = []

@app.get("/health")
async def health():
    return {"status":"ok","model":"RC25S-Agent","time":datetime.datetime.now().isoformat()}

@app.get("/")
async def root():
    html = open("/srv/repo/vibecoding/rc25s_dashboard_app/ui.html","r",encoding="utf-8").read()
    return HTMLResponse(html)

@app.websocket("/agi/ws")
async def ws(websocket: WebSocket):
    await websocket.accept()
    clients.append(websocket)
    await websocket.send_text("🤖 RC25S Agent Dashboard 연결됨")
    try:
        while True:
            msg = await websocket.receive_text()
            ts = datetime.datetime.now().strftime("%H:%M:%S")
            # 단순 echo + 이벤트 로그 출력
            await websocket.send_text(f"[{ts}] 명령 수신: {msg}")
            if "로그" in msg or "상태" in msg:
                log = subprocess.getoutput("tail -n 15 /srv/repo/vibecoding/logs/agi_reflection.log")
                await websocket.send_text(f"[상태 로그]\n{log}")
            elif "코드" in msg or "행동" in msg:
                await websocket.send_text("💡 AGI 행동 루프 실행 중... (시뮬레이션 출력)")
    except WebSocketDisconnect:
        clients.remove(websocket)
