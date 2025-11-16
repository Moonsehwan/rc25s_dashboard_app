#!/usr/bin/env bash
# =========================================================
# RC25H Health Agent + Nginx Integration Setup Script
# Safe for Production: Keeps existing 8000 MCP intact
# =========================================================
set -e

APPDIR="/srv/repo/vibecoding"
LOGFILE="$APPDIR/logs/setup_healthagent.log"
DOMAIN="api.mcpvibe.org"

echo "[RC25H] Health Agent (8001) 설치 시작..." | tee -a $LOGFILE

# 1️⃣ 필요한 패키지 설치
echo "[RC25H] FastAPI 및 Uvicorn 설치 중..."
pip install fastapi uvicorn --quiet

# 2️⃣ 헬스 에이전트 파일 생성
cat << 'PYEOF' > $APPDIR/RC25H_health_agent.py
from fastapi import FastAPI
import datetime, os, psutil, platform

app = FastAPI(title="RC25H Health Agent")

@app.get("/health")
async def health():
    # 시스템 상태 요약
    uptime = os.popen("uptime -p").read().strip()
    mem = psutil.virtual_memory()
    cpu = psutil.cpu_percent(interval=0.5)
    return {
        "status": "ok",
        "message": "RC25H Health Agent active",
        "system": platform.node(),
        "uptime": uptime,
        "cpu": f"{cpu}%",
        "memory": f"{mem.percent}%",
        "timestamp": str(datetime.datetime.now())
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
PYEOF

# 3️⃣ systemd 서비스 등록
cat << 'SERVICE' | sudo tee /etc/systemd/system/rc25h_health.service > /dev/null
[Unit]
Description=RC25H Health Agent (8001)
After=network.target

[Service]
ExecStart=/usr/bin/python3 /srv/repo/vibecoding/RC25H_health_agent.py
WorkingDirectory=/srv/repo/vibecoding
Restart=always
StandardOutput=append:/srv/repo/vibecoding/logs/health_agent.log
StandardError=append:/srv/repo/vibecoding/logs/health_agent.log

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable rc25h_health.service
sudo systemctl restart rc25h_health.service

# 4️⃣ Nginx 라우팅 업데이트
sudo sed -i '/location \/health {/,/}/c\
    location /health {\n        proxy_pass http://127.0.0.1:8001/health;\n        proxy_set_header Host $host;\n        proxy_set_header X-Real-IP $remote_addr;\n    }' /etc/nginx/sites-available/codex_console.conf

sudo nginx -t
sudo systemctl restart nginx

echo "[RC25H] ✅ Health Agent (8001) 구동 완료!" | tee -a $LOGFILE
echo "[RC25H] 확인: curl -s http://127.0.0.1:8001/health"
echo "[RC25H] 외부 확인: curl -s https://$DOMAIN/health"
