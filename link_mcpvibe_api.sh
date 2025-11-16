#!/bin/bash
set -e
echo "🌐 [RC25S-AGI] api.mcpvibe.org ↔ 5.104.87.232 AGI 통합 구성중 ..."

# 1️⃣ Nginx 리버스 프록시 설정
sudo apt-get install -y nginx
cat <<'NGINXEOF' | sudo tee /etc/nginx/sites-available/mcpvibe.conf > /dev/null
server {
    listen 80;
    server_name api.mcpvibe.org;

    location / {
        proxy_pass http://127.0.0.1:8000;  # MCP Core API
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /agi/ {
        proxy_pass http://127.0.0.1:4545/; # Dashboard
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /llm/ {
        proxy_pass http://127.0.0.1:8011/; # Local LLM
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /ws/ {
        proxy_pass http://127.0.0.1:4545/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
NGINXEOF

sudo ln -sf /etc/nginx/sites-available/mcpvibe.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx

# 2️⃣ SSL (Certbot)
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.mcpvibe.org --non-interactive --agree-tos -m admin@mcpvibe.org || true

# 3️⃣ 포트 상태 점검
curl -s http://127.0.0.1:4545/health || echo "⚠️ Dashboard not responding"
curl -s http://127.0.0.1:8011/health || echo "⚠️ LLM not responding"
curl -s http://127.0.0.1:8000/health || echo "⚠️ MCP not responding"

echo "✅ api.mcpvibe.org 도메인이 AGI 대시보드, LLM, MCP 전체와 통합되었습니다."
