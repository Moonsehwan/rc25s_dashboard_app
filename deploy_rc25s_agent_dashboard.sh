#!/bin/bash
set -e
echo "🚀 [RC25S] Sentient Kernel Agent Dashboard — Full System Deploy"

# 1️⃣ 환경 준비
mkdir -p /srv/repo/vibecoding/rc25s_dashboard_app
cd /srv/repo/vibecoding
source /srv/repo/vibecoding/rc25h_env/bin/activate
pip install fastapi uvicorn websockets aiofiles watchdog requests openai python-dotenv --quiet

# 2️⃣ 백엔드 (FastAPI + WebSocket + AGI 통합)
cat > /srv/repo/vibecoding/rc25s_agent_backend.py <<'PYEOF'
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

@app.websocket("/ws")
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
PYEOF

# 3️⃣ 간단한 HTML UI 파일 생성
cat > /srv/repo/vibecoding/rc25s_dashboard_app/ui.html <<'HTMLEOF'
<html lang="ko">
<head>
<meta charset="utf-8">
<title>🧠 RC25S Agent Dashboard</title>
<style>
body{background:#0e0e0e;color:#eee;font-family:Pretendard,sans-serif;text-align:center;padding-top:40px}
#log{background:#111;padding:12px;border-radius:10px;width:80%;max-width:900px;margin:20px auto;text-align:left;white-space:pre-wrap;overflow-y:auto;max-height:70vh}
button,input{padding:10px;border-radius:8px;margin:4px;border:none}
button{background:#00ffc8;color:#000;font-weight:bold}
</style>
</head>
<body>
<h1>🧠 RC25S Sentient AGI 실시간 Agent Dashboard</h1>
<div id="log">📡 연결 대기 중...</div>
<input id="msg" placeholder="명령 입력..." style="width:60%"><button onclick="send()">전송</button>
<script>
const ws = new WebSocket("wss://" + location.host + "/agi/ws");
const log = document.getElementById("log");
ws.onmessage = e => {log.innerHTML += "\\n" + e.data;log.scrollTop=log.scrollHeight;}
ws.onopen = ()=>log.innerHTML="✅ AGI 대시보드 연결됨. 명령을 입력하세요.";
function send(){const v=document.getElementById("msg").value;ws.send(v);document.getElementById("msg").value="";}
</script>
</body>
</html>
HTMLEOF

# 4️⃣ 서비스 파일 생성
cat > /etc/systemd/system/rc25s-agent-dashboard.service <<'SYSEO'
[Unit]
Description=RC25S Agent Dashboard WebSocket Server
After=network.target

[Service]
ExecStart=/srv/repo/vibecoding/rc25h_env/bin/python /srv/repo/vibecoding/rc25s_agent_backend.py
WorkingDirectory=/srv/repo/vibecoding
Restart=always

[Install]
WantedBy=multi-user.target
SYSEO

# 5️⃣ Nginx 프록시 업데이트
CONF="/etc/nginx/sites-enabled/codex_console.conf"
if ! grep -q "location /agi/" "$CONF"; then
sudo tee -a "$CONF" > /dev/null <<'NGX'
### RC25S AGI DASHBOARD ###
location /agi/ {
    proxy_pass http://127.0.0.1:4545/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
NGX
fi

sudo nginx -t && sudo systemctl restart nginx

# 6️⃣ 서비스 시작
sudo systemctl daemon-reload
sudo systemctl enable rc25s-agent-dashboard.service
sudo systemctl restart rc25s-agent-dashboard.service

echo "✅ [RC25S] Agent Dashboard 배포 완료!"
echo "🌐 접속 URL: https://api.mcpvibe.org/agi/"
