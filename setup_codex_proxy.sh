#!/usr/bin/env bash
# =========================================================
# RC25H Codex HTTPS Proxy Installer (v1.0)
# =========================================================
# 목적: FastAPI Codex Console(444)을 Nginx(443)로 연결
# ---------------------------------------------------------
DOMAIN="api.mcpvibe.org"
NGINX_CONF="/etc/nginx/sites-available/codex_console.conf"
LOG_FILE="/srv/repo/vibecoding/logs/codex_proxy_install.log"

echo "[RC25H] Codex Proxy 설치 시작..." | tee -a $LOG_FILE

# 1. Nginx 설치 (없을 시)
if ! command -v nginx &> /dev/null; then
  echo "[RC25H] Nginx 설치 중..." | tee -a $LOG_FILE
  sudo apt update -y && sudo apt install -y nginx
fi

# 2. 인증서 존재 확인
if [ ! -d "/etc/letsencrypt/live/$DOMAIN" ]; then
  echo "[오류] SSL 인증서가 없습니다. Certbot으로 발급 후 재실행하세요." | tee -a $LOG_FILE
  exit 1
fi

# 3. Nginx 설정 작성
echo "[RC25H] Nginx 설정 생성 중..." | tee -a $LOG_FILE
sudo bash -c "cat > $NGINX_CONF" << CONF
server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # 기존 MCP API 유지
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # Codex Console UI
    location /chat {
        proxy_pass http://127.0.0.1:444/chat;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # 명령 실행 API
    location /exec {
        proxy_pass http://127.0.0.1:444/exec;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    # 로그 조회 API
    location /logs {
        proxy_pass http://127.0.0.1:444/logs;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
CONF

# 4. 심볼릭 링크 연결
sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/codex_console.conf

# 5. 설정 문법 테스트
echo "[RC25H] Nginx 설정 테스트 중..." | tee -a $LOG_FILE
sudo nginx -t && sudo systemctl restart nginx

if [ $? -eq 0 ]; then
  echo "[✅ RC25H] Codex 콘솔 프록시 활성화 완료!" | tee -a $LOG_FILE
  echo "→ 접속: https://$DOMAIN/chat" | tee -a $LOG_FILE
else
  echo "[❌ 오류] Nginx 재시작 실패, 로그를 확인하세요: $LOG_FILE"
fi
