#!/bin/bash
echo "🧠 [RC25S] Nginx 완전 자동 복구 (AGI Dashboard 포함)"

NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP_PATH="${NGINX_CONF}.bak_$(date +%s)"

# 백업
if [ -f "$NGINX_CONF" ]; then
    cp "$NGINX_CONF" "$BACKUP_PATH"
    echo "📦 기존 설정 백업됨 → $BACKUP_PATH"
fi

# 완전 재작성 (문법 100% 보장)
cat > "$NGINX_CONF" <<'CONF'
server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    ### RC25S AGI DASHBOARD ###
    location /agi/ {
        proxy_pass http://127.0.0.1:4545/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    ### Codex Console ###
    location /chat {
        proxy_pass http://127.0.0.1:444;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    ### MCP Backend ###
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    ### Static Default ###
    location / {
        root /var/www/html;
        index index.html;
    }
}
CONF

# 문법 검사
echo "🔎 nginx 문법 검사 중..."
if sudo nginx -t; then
    echo "✅ 문법 통과!"
    sudo systemctl restart nginx
    echo "🔁 Nginx 재시작 완료"
else
    echo "❌ 문법 오류 발생 — 백업 파일 유지됨: $BACKUP_PATH"
    exit 1
fi

# 테스트
sleep 2
echo "🌐 테스트: https://api.mcpvibe.org/agi/"
curl -s https://api.mcpvibe.org/agi/ | head -n 20
echo "🎯 완료!"
