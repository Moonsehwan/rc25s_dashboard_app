#!/bin/bash
echo "🧠 [RC25S] 자동 Nginx 복구 및 AGI 대시보드 재설정 시작..."

NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP_PATH="${NGINX_CONF}.bak_$(date +%s)"

# 백업
cp "$NGINX_CONF" "$BACKUP_PATH"
echo "📦 백업 완료: $BACKUP_PATH"

# 올바른 설정으로 재작성
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

    ### Codex Console (포트 444)
    location /chat {
        proxy_pass http://127.0.0.1:444;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    ### MCP Backend (포트 8000)
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    ### Default Static
    location / {
        root /var/www/html;
        index index.html;
    }
}
CONF

# 문법 검사
echo "🔎 Nginx 설정 검사 중..."
if sudo nginx -t; then
    echo "✅ 설정 검사 통과!"
    sudo systemctl restart nginx
    echo "🔁 Nginx 재시작 완료"
else
    echo "❌ 설정 오류: 복구 실패 (백업파일 유지됨: $BACKUP_PATH)"
    exit 1
fi

# 상태 확인
sleep 2
echo "🌐 /agi/ 엔드포인트 테스트:"
curl -s https://api.mcpvibe.org/agi/ | head -n 20

echo "🎯 RC25S AGI Dashboard 복구 완료!"
