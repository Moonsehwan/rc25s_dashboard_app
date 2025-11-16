#!/bin/bash
set -e
echo "🧠 [RC25S] Full AGI Dashboard Auto Installer starting..."

# 1️⃣ 경로 및 변수
APP_DIR="/srv/repo/vibecoding/rc25s_dashboard"
FRONT_DIR="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"
ENV_DIR="/srv/repo/vibecoding/rc25h_env"

mkdir -p "$APP_DIR" "$FRONT_DIR"

# 2️⃣ Ollama 모델 준비
echo "📦 Checking Ollama and Qwen model..."
which ollama || (curl -fsSL https://ollama.com/install.sh | sh)
ollama pull qwen2.5:7b-instruct

# 3️⃣ FastAPI 백엔드 구성
cat > "$APP_DIR/agi_status_dashboard.py" <<'PYCODE'
from fastapi import FastAPI, WebSocket, Request
from fastapi.middleware.cors import CORSMiddleware
import psutil, datetime, subprocess, os, json

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status":"ok","model":"RC25S","cpu":psutil.cpu_percent(interval=0.5),
            "memory":psutil.virtual_memory().percent,"time":datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

@app.post("/llm")
async def llm(req: Request):
    data = await req.json()
    prompt = data.get("prompt", "")
    provider = data.get("provider", "local")

    if provider == "local":
        cmd = ["ollama", "run", "qwen2.5:7b-instruct", prompt]
        result = subprocess.run(cmd, capture_output=True, text=True)
        output = (result.stdout or "").strip()
        if not output:
            output = "⚠️ 모델이 응답하지 않았습니다. 입력을 조금 더 구체적으로 작성해보세요."
        return {"provider": "qwen2.5", "output": output}

    else:
        import openai
        openai.api_key = os.getenv("OPENAI_API_KEY")
        completion = openai.ChatCompletion.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}]
        )
        return {"provider": "openai", "output": completion.choices[0].message.content}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    await websocket.send_text("🧠 AGI 대시보드 WebSocket 연결됨.")
    try:
        while True:
            msg = await websocket.receive_text()
            if msg.strip() == "상태보여줘":
                await websocket.send_text(f"📊 CPU {psutil.cpu_percent()}%, RAM {psutil.virtual_memory().percent}%")
            else:
                await websocket.send_text(f"🤖 명령 '{msg}' 수신됨.")
    except Exception as e:
        print(f"⚠️ 연결 종료됨: {e}")
        await websocket.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("agi_status_dashboard:app", host="0.0.0.0", port=4545)
PYCODE

# 4️⃣ Nginx 설정
echo "🧩 Configuring Nginx..."
sudo tee /etc/nginx/sites-enabled/codex_console.conf > /dev/null <<'NGINX'
server {
    listen 80;
    server_name api.mcpvibe.org;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    root /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build;
    index index.html;

    location /health {
        proxy_pass http://127.0.0.1:4545/health;
    }

    location /ws {
        proxy_pass http://127.0.0.1:4545/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    location /llm {
        proxy_pass http://127.0.0.1:4545/llm;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /agi/ {
        try_files $uri /agi/index.html;
    }

    location / {
        try_files $uri /index.html;
    }
}
NGINX

sudo nginx -t && sudo systemctl reload nginx

# 5️⃣ 서비스 등록
echo "🛠️ Registering systemd service..."
sudo tee /etc/systemd/system/rc25s-dashboard.service > /dev/null <<'SERVICE'
[Unit]
Description=RC25S AGI 실시간 대시보드
After=network.target

[Service]
ExecStart=/srv/repo/vibecoding/rc25h_env/bin/python /srv/repo/vibecoding/rc25s_dashboard/agi_status_dashboard.py
Restart=always
RestartSec=2
User=root

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable rc25s-dashboard.service
sudo systemctl restart rc25s-dashboard.service

echo "✅ RC25S AGI Full Auto Installer complete!"
echo "🌐 접속: https://api.mcpvibe.org/agi/"
