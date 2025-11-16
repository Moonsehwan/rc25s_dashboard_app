from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse, JSONResponse
import os, json, datetime, asyncio

app = FastAPI()

@app.get("/health")
async def health():
    return {"status":"ok","model":"RC25S","time":datetime.datetime.now().isoformat()}

@app.get("/")
async def dashboard_root():
    html = f"""
    <html lang='ko'><head><meta charset='utf-8'><title>🧠 RC25S AGI 실시간 대시보드</title>
    <style>
        body {{ font-family: Pretendard,sans-serif; background:#0e0e0e; color:#f2f2f2; text-align:center; padding-top:80px; }}
        h1 {{ color:#7df9ff; }} .log{{background:#111;padding:12px;border-radius:10px;margin:20px auto;width:80%;max-width:800px;text-align:left}}
    </style></head><body>
    <h1>🧠 RC25S AGI 실시간 대시보드</h1>
    <div id='log' class='log'>⏳ 실시간 로그 수신 대기중...</div>
    <input id='msg' placeholder='명령 입력...' style='width:60%;padding:8px;'/><button onclick='send()'>전송</button>
    <script>
        const ws = new WebSocket("wss://" + location.host + "/ws");
        ws.onmessage = e => document.getElementById('log').innerHTML += "<br>🧠 " + e.data;
        function send() {{ const val=document.getElementById('msg').value; ws.send(val); document.getElementById('msg').value=""; }}
    </script></body></html>
    """
    return HTMLResponse(content=html)

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    await websocket.send_text("RC25S 대시보드 연결됨 ✅")
    try:
        while True:
            data = await websocket.receive_text()
            # 단순히 명령을 로그처럼 반환
            ts = datetime.datetime.now().strftime("%H:%M:%S")
            await websocket.send_text(f"[{ts}] 명령 수신: {data}")
            # 나중에 free-llm 또는 AGI 루프와 연동 (여기서 확장 가능)
    except WebSocketDisconnect:
        print("클라이언트 연결 종료")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=4545)
