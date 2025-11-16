#!/bin/bash
set -e

DASHBOARD="/srv/repo/vibecoding/agi_status_dashboard.py"

echo "🧠 [RC25S] Upgrading dashboard interface..."

cat > "$DASHBOARD" <<'PYCODE'
from fastapi import FastAPI
from fastapi.responses import HTMLResponse, JSONResponse
import datetime, socket

app = FastAPI()

@app.get("/health")
def health():
    return JSONResponse({
        "status": "ok",
        "model": "RC25S",
        "server": socket.gethostname(),
        "time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    })

@app.get("/", response_class=HTMLResponse)
def root():
    html = f"""
    <html lang='ko'>
    <head>
        <meta charset='UTF-8'>
        <title>🧠 RC25S AGI 실시간 대시보드</title>
        <style>
            body {{
                font-family: 'Pretendard', sans-serif;
                background: #0e0e0e;
                color: #f2f2f2;
                margin: 0; padding: 0;
                display: flex; flex-direction: column; align-items: center;
                justify-content: center; height: 100vh;
            }}
            h1 {{ color: #7df9ff; font-size: 2rem; }}
            .status {{
                background: #1a1a1a; padding: 20px; border-radius: 12px;
                box-shadow: 0 0 12px rgba(0,255,255,0.3);
                width: 80%; max-width: 600px; text-align: left;
            }}
            .ok {{ color: #00ffcc; }}
            .warn {{ color: #ffcc00; }}
        </style>
    </head>
    <body>
        <h1>🧠 RC25S AGI 실시간 대시보드</h1>
        <div class='status'>
            <p>서버: 5.104.87.232</p>
            <p>상태: <span class='ok'>ACTIVE</span></p>
            <p>모델: RC25S Kernel</p>
            <p>시간: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
            <p>대시보드 URL: <a href='https://api.mcpvibe.org/agi/' style='color:#7df9ff;'>api.mcpvibe.org/agi/</a></p>
        </div>
    </body>
    </html>
    """
    return HTMLResponse(html)
PYCODE

echo "✅ HTML dashboard applied. Restarting service..."
sudo systemctl restart rc25s-dashboard.service
sleep 2
curl -s http://127.0.0.1:4545/health
