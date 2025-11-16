#!/usr/bin/env bash
# =========================================================
# RC25H Unified Kernel Full Auto Setup Script
# =========================================================
set -e

APPDIR="/srv/repo/vibecoding"
DOMAIN="api.mcpvibe.org"
NGINX_CONF="/etc/nginx/sites-available/codex_console.conf"
LOGFILE="$APPDIR/logs/setup_fullsystem.log"

echo "[RC25H] 시작: 전체 시스템 자동 구성" | tee -a $LOGFILE

# 1️⃣ FastAPI 서버 중지
sudo pkill -f RC25H_UnifiedServer.py || true
sudo pkill -f mcp_server.py || true
sudo pkill -f mcp_codex_console.py || true

# 2️⃣ Nginx 설정 재작성
sudo bash -c "cat > $NGINX_CONF" <<NGINX
server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # Codex 콘솔 라우팅
    location /chat {
        proxy_pass http://127.0.0.1:444;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /exec {
        proxy_pass http://127.0.0.1:444;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # MCP 헬스체크
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Static Fallback
    location / {
        root /var/www/html;
        index index.html;
    }
}
NGINX

echo "[RC25H] ✅ Nginx 설정 완료" | tee -a $LOGFILE

# 3️⃣ Nginx 테스트 및 재시작
sudo nginx -t && sudo systemctl restart nginx
echo "[RC25H] ✅ Nginx 정상 작동 확인" | tee -a $LOGFILE

# 4️⃣ RC25H 중앙 두뇌(CentralCore) 서비스 등록
cat << 'SERVICE' | sudo tee /etc/systemd/system/rc25h_core.service > /dev/null
[Unit]
Description=RC25H CentralCore Decision Loop
After=network.target

[Service]
ExecStart=/usr/bin/python3 /srv/repo/vibecoding/RC25H_CentralCore.py
WorkingDirectory=/srv/repo/vibecoding
Restart=always
StandardOutput=append:/srv/repo/vibecoding/logs/centralcore.log
StandardError=append:/srv/repo/vibecoding/logs/centralcore.log

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable rc25h_core.service
sudo systemctl restart rc25h_core.service
echo "[RC25H] ✅ CentralCore 두뇌 루프 활성화 완료" | tee -a $LOGFILE

# 5️⃣ 서비스 상태 요약
echo "--------------------------------------"
echo "[RC25H] 모든 구성 완료!"
echo "Nginx 라우팅: /chat(444) /health(8000)"
echo "중앙 두뇌: rc25h_core.service 실행 중"
echo "확인: curl -s https://$DOMAIN/health"
echo "--------------------------------------"
