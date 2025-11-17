#!/usr/bin/env bash
set -euo pipefail

DASH_DIR="/srv/repo/vibecoding/dashboard"
NGINX_CONF="/etc/nginx/sites-available/api_mcpvibe_rc25s.conf"
MCP_SERVICE="/etc/systemd/system/mcp.service"
LOG_DIR="/srv/repo/vibecoding/logs"

echo "🔧 1) Vite 설정/기본 HTML 정리"
cat <<'VCONF' >"$DASH_DIR/vite.config.js"
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  root: './',
  base: '/',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
})
VCONF

cat <<'HTML' >"$DASH_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <base href="/" />
    <title>AGI Dashboard</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
HTML

echo "🔧 2) Nginx conf 재작성"
cat <<'NGINX' | sudo tee "$NGINX_CONF" >/dev/null
server {
    listen 80;
    server_name api.mcpvibe.org;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate     /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    location = /agi { return 301 /agi/; }

    location /agi/ {
        rewrite ^/agi/(.*)$ /$1 break;
        proxy_pass http://127.0.0.1:8011/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        root /srv/repo/vibecoding/dashboard/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    location /ws/agi {
        proxy_pass http://127.0.0.1:8000/ws/agi;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }

    location /ws/system {
        proxy_pass http://127.0.0.1:8000/ws/system;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }

    location /health {
        return 200 "RC25S Dashboard Nginx OK";
        add_header Content-Type text/plain;
    }

    access_log /var/log/nginx/rc25s_dashboard_access.log;
    error_log  /var/log/nginx/rc25s_dashboard_error.log;
}
NGINX

echo "🔧 3) mcp.service (WS 백엔드) 환경변수 정리"
sudo mkdir -p "$LOG_DIR"
cat <<'SERVICE' | sudo tee "$MCP_SERVICE" >/dev/null
[Unit]
Description=MCP Realtime Backend Server (8000)
After=network.target

[Service]
Type=simple
WorkingDirectory=/srv/repo/vibecoding
Environment="PYTHONPATH=/srv/repo"
ExecStart=/srv/repo/vibecoding/rc25h_env/bin/python -m uvicorn vibecoding.mcp_server_realtime:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
StandardOutput=append:/srv/repo/vibecoding/logs/mcp_server_realtime.log
StandardError=append:/srv/repo/vibecoding/logs/mcp_server_realtime.log

[Install]
WantedBy=multi-user.target
SERVICE

echo "🧱 4) 대시보드 빌드"
cd "$DASH_DIR"
npm run build

echo "🔁 5) nginx & mcp 서비스 재시작"
sudo nginx -t
sudo systemctl reload nginx
sudo systemctl daemon-reload
sudo systemctl restart mcp.service

echo "✅ 완료! 브라우저에서 https://api.mcpvibe.org/ 새로고침하세요."
