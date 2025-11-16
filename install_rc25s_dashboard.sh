#!/bin/bash
set -e
echo "🚀 [RC25S-AGI] 실시간 대시보드 + 프리뷰 + 양방향 대화 환경 설치중 ..."

APP_DIR="/srv/repo/vibecoding"
ENV_PATH="/srv/repo/vibecoding/rc25h_env/bin/python"
DASHBOARD="$APP_DIR/agi_status_dashboard.py"

# 1️⃣ FastAPI 대시보드 생성
cat <<'PYEOF' | sudo tee "$DASHBOARD" > /dev/null
import os, json, time, asyncio
from fastapi import FastAPI, WebSocket
from fastapi.responses import HTMLResponse
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
from rc25_kernel_RC25S import RC25SKernel
from rc25s_openai_wrapper import rc25s_chat

app = FastAPI()
kernel = RC25SKernel()

state = {
    "mode": kernel.mode,
    "reflection": None,
    "last_response": None,
    "metrics": kernel.report_kpi(),
    "updated": time.strftime("%H:%M:%S")
}

# 실시간 미리보기 감시
class PreviewWatcher(FileSystemEventHandler):
    def on_modified(self, event):
        if event.src_path.endswith("App.jsx"):
            state["updated"] = time.strftime("%H:%M:%S")

observer = Observer()
observer.schedule(PreviewWatcher(), path="/srv/repo/vibecoding/static/preview", recursive=False)
observer.start()

@app.get("/")
async def home():
    html = open("/srv/repo/vibecoding/templates/dashboard.html","r").read()
    return HTMLResponse(html)

@app.websocket("/ws")
async def ws_endpoint(ws: WebSocket):
    await ws.accept()
    await ws.send_json({"type":"init","msg":"🧠 RC25S-AGI 실시간 대화 세션이 시작되었습니다."})
    while True:
        data = await ws.receive_text()
        reasoning, metrics = kernel.run_turn([], data)
        state["mode"] = kernel.mode
        state["reflection"] = kernel.last_reflection
        state["metrics"] = metrics
        state["last_response"] = reasoning
        msg = rc25s_chat(data)
        await ws.send_json({
            "type":"reply",
            "user":data,
            "agi":msg["response"],
            "metrics":msg["metrics"],
            "time":time.strftime("%H:%M:%S")
        })

@app.get("/status")
async def status():
    return state

@app.get("/health")
async def health():
    return {"status":"ok","model":"RC25S","time":time.strftime("%H:%M:%S")}

PYEOF

# 2️⃣ 템플릿 (한글 UI)
mkdir -p /srv/repo/vibecoding/templates
cat <<'HTMLEOF' | sudo tee /srv/repo/vibecoding/templates/dashboard.html > /dev/null
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8"/>
<title>RC25S AGI 실시간 대시보드</title>
<style>
body {font-family:Pretendard, sans-serif; background:#111; color:#eee; margin:0; padding:0;}
#log {height:70vh; overflow-y:auto; background:#000; padding:1em; border-radius:12px; margin:1em;}
input {width:80%; padding:10px; border-radius:8px; border:none;}
button {padding:10px 20px; border:none; border-radius:8px; background:#1e90ff; color:#fff;}
</style>
</head>
<body>
<h2 style="text-align:center;">🧠 RC25S-AGI 실시간 대시보드</h2>
<div id="log"></div>
<div style="text-align:center;">
<input id="msg" placeholder="AGI에게 한글로 무엇이든 물어보세요..." />
<button onclick="send()">보내기</button>
</div>
<script>
const ws = new WebSocket("ws://" + location.host + "/ws");
ws.onmessage = (ev)=>{
 const d = JSON.parse(ev.data);
 const log=document.getElementById("log");
 if(d.type==="reply"){
   log.innerHTML += `<p><b>👤 사용자:</b> ${d.user}</p><p><b>🤖 AGI:</b> ${d.agi}</p><hr/>`;
 } else log.innerHTML += `<p>${d.msg}</p>`;
 log.scrollTop=log.scrollHeight;
};
function send(){
 const v=document.getElementById("msg").value;
 ws.send(v);
 document.getElementById("msg").value="";
}
</script>
</body>
</html>
HTMLEOF

# 3️⃣ systemd 서비스
cat <<'SYEOF' | sudo tee /etc/systemd/system/rc25s-dashboard.service > /dev/null
[Unit]
Description=RC25S AGI 실시간 대시보드
After=network.target

[Service]
ExecStart=/srv/repo/vibecoding/rc25h_env/bin/python /srv/repo/vibecoding/agi_status_dashboard.py
WorkingDirectory=/srv/repo/vibecoding
Restart=always
Environment=PYTHONPATH=/srv/repo/vibecoding

[Install]
WantedBy=multi-user.target
SYEOF

# 4️⃣ 서비스 등록
sudo systemctl daemon-reload
sudo systemctl enable rc25s-dashboard.service
sudo systemctl restart rc25s-dashboard.service
sleep 3
echo "✅ RC25S 대시보드가 실행 중입니다 → http://<서버IP>:4545"
