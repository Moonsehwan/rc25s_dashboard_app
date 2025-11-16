#!/bin/bash
echo "🧩 [RC25S] Fixing WebSocket bridge for AGI dashboard..."

# 1️⃣ FastAPI 백엔드 수정
sed -i 's@app.websocket("/ws")@app.websocket("/agi/ws")@g' /srv/repo/vibecoding/rc25s_agent_backend.py

# 2️⃣ HTML 경로 수정
sed -i 's@new WebSocket("wss://" .* "/ws")@new WebSocket("wss://" + location.host + "/agi/ws")@g' /srv/repo/vibecoding/rc25s_dashboard_app/ui.html

# 3️⃣ Nginx 프록시 설정 강화
CONF="/etc/nginx/sites-enabled/codex_console.conf"
if ! grep -q "proxy_set_header Upgrade" "$CONF"; then
sudo tee -a "$CONF" > /dev/null <<'NGX'
# WebSocket 업그레이드 헤더 추가
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

### RC25S AGI DASHBOARD ###
location /agi/ {
    proxy_pass http://127.0.0.1:4545/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
NGX
fi

# 4️⃣ 서비스 재시작
sudo nginx -t && sudo systemctl restart nginx
sudo systemctl restart rc25s-agent-dashboard.service

echo "✅ WebSocket bridge fully synchronized!"
echo "🌐 테스트: https://api.mcpvibe.org/agi/"
