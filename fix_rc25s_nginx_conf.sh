#!/bin/bash
echo "🧠 [RC25S] Nginx 자동 복구 + AGI Dashboard 통합 설정 시작..."

NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACK_PORT=4545
FRONT_DIR="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"

# 백업
cp "$NGINX_CONF" "${NGINX_CONF}.bak_$(date +%s)"

# server 블록 내부 확인
if ! grep -q "server_name api.mcpvibe.org" "$NGINX_CONF"; then
  echo "❌ server 블록이 감지되지 않음. 수동 점검 필요."
  exit 1
fi

# 기존 /agi/ 또는 /ws 블록 삭제
sed -i '/location \/agi\//,/}/d' "$NGINX_CONF"
sed -i '/location \/ws\//,/}/d' "$NGINX_CONF"

# 올바른 위치(443 서버 내부)에 삽입
awk -v front="$FRONT_DIR" -v port="$BACK_PORT" '
/listen 443 ssl;/ && !done {
  print;
  print "    ### RC25S AGI DASHBOARD ###";
  print "    location /agi/ {";
  print "        root " front ";";
  print "        try_files \\$uri /index.html;";
  print "    }";
  print "";
  print "    location /ws {";
  print "        proxy_pass http://127.0.0.1:" port "/ws;";
  print "        proxy_http_version 1.1;";
  print "        proxy_set_header Upgrade \\$http_upgrade;";
  print "        proxy_set_header Connection \"Upgrade\";";
  print "    }";
  done=1; next
}
{print}
' "$NGINX_CONF" > /tmp/nginx_fixed.conf && mv /tmp/nginx_fixed.conf "$NGINX_CONF"

# 테스트 및 재시작
nginx -t && systemctl reload nginx && echo "✅ Nginx 복구 완료! 접속: https://api.mcpvibe.org/agi/" || echo "❌ 테스트 실패 — 백업 확인 필요"
