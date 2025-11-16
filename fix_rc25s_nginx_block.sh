#!/usr/bin/env bash
set -e

echo "🧠 [RC25S] Nginx 자동 복구 스크립트 시작..."
NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP="/etc/nginx/sites-enabled/codex_console.conf.bak_fixblock_$(date +%s)"

# ────────────────────────────────
# 1️⃣ 백업
# ────────────────────────────────
if [ ! -f "$NGINX_CONF" ]; then
    echo "❌ Nginx 설정 파일이 없습니다: $NGINX_CONF"
    exit 1
fi

sudo cp "$NGINX_CONF" "$BACKUP"
echo "📦 백업 완료 → $BACKUP"

# ────────────────────────────────
# 2️⃣ 새로운 server 블록 생성
# ────────────────────────────────
sudo tee "$NGINX_CONF" > /dev/null <<'CONF'
server {
    listen 80;
    server_name api.mcpvibe.org;

    # HTTPS 리디렉션
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    # 🔹 React 정적 경로
    root /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build;
    index index.html;

    location / {
        try_files $uri /index.html;
    }

    # 🔹 FastAPI 백엔드 헬스체크
    location /health {
        proxy_pass http://127.0.0.1:4545/health;
        proxy_connect_timeout 5s;
        proxy_read_timeout 10s;
    }

    # 🔹 LLM 엔드포인트
    location /llm {
        proxy_pass http://127.0.0.1:4545/llm;
        proxy_connect_timeout 60s;
        proxy_send_timeout 180s;
        proxy_read_timeout 180s;
        send_timeout 180s;
    }

    # 🔹 WebSocket
    location /ws {
        proxy_pass http://127.0.0.1:4545/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # 🔹 에러 페이지
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
CONF

echo "✅ 기본 server 블록 재작성 완료"

# ────────────────────────────────
# 3️⃣ 문법 검사 및 재시작
# ────────────────────────────────
echo "🔍 Nginx 설정 문법 검사 중..."
if sudo nginx -t; then
    echo "✅ 문법 OK — Nginx 재시작 중..."
    sudo systemctl restart nginx
    echo "🚀 Nginx 정상 복구 완료!"
else
    echo "❌ 문법 오류 — 백업 파일로 복구하세요: $BACKUP"
    exit 1
fi

# ────────────────────────────────
# 4️⃣ 테스트 요청
# ────────────────────────────────
echo "🌐 테스트 중..."
curl -s -o /dev/null -w "%{http_code}" https://api.mcpvibe.org/health || echo "❌ 연결 실패"
echo ""
echo "✅ [완료] Nginx 자동 복구 및 타임아웃 최적화 완료!"
