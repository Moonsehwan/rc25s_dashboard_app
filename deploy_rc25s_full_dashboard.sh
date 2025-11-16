#!/bin/bash
echo "🚀 [RC25S] Deploying full AGI Realtime Dashboard (UI + WS + LogSync)"

DASHBOARD_PATH="/srv/repo/vibecoding/rc25s_dashboard"
mkdir -p "$DASHBOARD_PATH"

#############################################
# 1️⃣ Backend: FastAPI + WebSocket + LogSync
#############################################
cat > "$DASHBOARD_PATH/agi_status_dashboard.py" <<'PYCODE'
from fastapi import FastAPI, WebSocket
from fastapi.responses import HTMLResponse
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import asyncio, datetime, threading, os

app = FastAPI()
clients = set()

@app.get("/")
def root():
    html_path = "/srv/repo/vibecoding/rc25s_dashboard/index.html"
    return HTMLResponse(open(html_path, encoding="utf-8").read())

@app.get("/health")
def health():
    return {"status": "ok", "model": "RC25S", "time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await ws.accept()
    clients.add(ws)
    await ws.send_text("💫 RC25S 대시보드 연결됨 — 실시간 상태 전송 시작")
    try:
        while True:
            msg = await ws.receive_text()
            timestamp = datetime.datetime.now().strftime("[%H:%M:%S]")
            log = f"{timestamp} 사용자 명령: {msg}"
            await ws.send_text(f"🤖 {log}")
    except Exception:
        clients.remove(ws)

class LogWatcher(FileSystemEventHandler):
    def on_modified(self, event):
        if event.is_directory or not event.src_path.endswith(".log"):
            return
        with open(event.src_path, "r", encoding="utf-8") as f:
            lines = f.readlines()[-3:]
            msg = "📄 로그 업데이트:\n" + "".join(lines)
            for ws in list(clients):
                asyncio.create_task(ws.send_text(msg))

def start_log_watcher():
    log_path = "/srv/repo/vibecoding/logs"
    os.makedirs(log_path, exist_ok=True)
    observer = Observer()
    observer.schedule(LogWatcher(), log_path, recursive=False)
    observer.start()

threading.Thread(target=start_log_watcher, daemon=True).start()
PYCODE

#############################################
# 2️⃣ Frontend: GPT-style Korean Agent UI
#############################################
cat > "$DASHBOARD_PATH/index.html" <<'HTML'
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
<title>🧠 RC25S AGI 실시간 대시보드</title>
<style>
body { margin:0; font-family:"Pretendard",sans-serif; background:#0b0b0b; color:#f1f1f1; display:flex; flex-direction:column; align-items:center; height:100vh; overflow:hidden; }
header { width:100%; text-align:center; padding:20px; background:#111; box-shadow:0 0 10px #00e0ff33; }
h1 { color:#7df9ff; font-size:1.8rem; }
#logbox { flex:1; width:90%; max-width:900px; background:#111; margin:15px; padding:15px; overflow-y:auto; border-radius:12px; box-shadow:0 0 10px #00f2ff33; }
.log-entry { margin-bottom:10px; padding:8px 12px; border-radius:8px; }
.sys { background:#0e3a3a; color:#aef; }
.user { background:#2a2a2a; color:#fff; }
.bot { background:#002f49; color:#7df9ff; }
footer { width:90%; max-width:900px; display:flex; margin-bottom:20px; }
input { flex:1; padding:12px; border:none; border-radius:8px; background:#1a1a1a; color:#fff; font-size:1rem; }
button { margin-left:8px; padding:12px 18px; background:#00e0ff; border:none; border-radius:8px; color:#000; font-weight:700; cursor:pointer; transition:0.2s; }
button:hover { background:#7df9ff; }
</style>
</head>
<body>
<header><h1>🧠 RC25S AGI 실시간 대시보드</h1></header>
<div id="logbox"><div class="log-entry sys">⏳ 실시간 로그 수신 대기중...</div></div>
<footer>
<input id="msg" placeholder="명령 입력..." onkeypress="if(event.key==='Enter')sendMsg()">
<button onclick="sendMsg()">전송</button>
</footer>
<script>
const logbox=document.getElementById('logbox');
const ws=new WebSocket("wss://"+location.host+"/ws");
function addLog(txt,cls){const e=document.createElement("div");e.className="log-entry "+cls;e.innerText=txt;logbox.appendChild(e);logbox.scrollTop=logbox.scrollHeight;}
ws.onopen=()=>addLog("✅ RC25S 연결됨","sys");
ws.onmessage=e=>addLog(e.data,"bot");
ws.onclose=()=>addLog("⚠️ 연결 종료됨","sys");
function sendMsg(){
 const val=document.getElementById('msg').value.trim();
 if(!val)return;
 addLog("🧠 "+val,"user");
 ws.send(val);
 document.getElementById('msg').value="";
}
</script>
</body>
</html>
HTML

#############################################
# 3️⃣ Systemd 서비스 등록
#############################################
cat > /etc/systemd/system/rc25s-dashboard.service <<'SERVICE'
[Unit]
Description=RC25S AGI 실시간 대시보드
After=network.target

[Service]
ExecStart=/srv/repo/vibecoding/rc25h_env/bin/python /srv/repo/vibecoding/rc25s_dashboard/agi_status_dashboard.py
Restart=always
WorkingDirectory=/srv/repo/vibecoding/rc25s_dashboard
Environment="PYTHONUNBUFFERED=1"

[Install]
WantedBy=multi-user.target
SERVICE

#############################################
# 4️⃣ Nginx 설정 보완 (/agi/ + /ws/)
#############################################
CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP="${CONF}.bak_full_$(date +%s)"
cp "$CONF" "$BACKUP"

sed -i '/server_name api.mcpvibe.org;/a \
    \n    location /agi/ {\n        proxy_pass http://127.0.0.1:4545/;\n        proxy_http_version 1.1;\n        proxy_set_header Upgrade $http_upgrade;\n        proxy_set_header Connection "upgrade";\n        proxy_set_header Host $host;\n    }\n\
    \n    location /ws {\n        proxy_pass http://127.0.0.1:4545/ws;\n        proxy_http_version 1.1;\n        proxy_set_header Upgrade $http_upgrade;\n        proxy_set_header Connection "upgrade";\n        proxy_set_header Host $host;\n    }\n' "$CONF"

nginx -t && systemctl reload nginx

#############################################
# 5️⃣ 서비스 구동
#############################################
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable rc25s-dashboard.service
systemctl restart rc25s-dashboard.service

echo "✅ RC25S AGI 실시간 대시보드 배포 완료!"
echo "🌐 접속: https://api.mcpvibe.org/agi/"
