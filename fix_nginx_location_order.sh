#!/bin/bash
echo "🧠 [RC25S] Fixing Nginx location block nesting issue..."

NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP="$NGINX_CONF.bak_fix_$(date +%s)"

# 1️⃣ 백업
cp "$NGINX_CONF" "$BACKUP"
echo "📦 백업 완료: $BACKUP"

# 2️⃣ server 블록 내부로 올바른 위치 재정렬
awk '
/server_name api\.mcpvibe\.org/ {
    print;
    print "    # === RC25S AGI Dashboard (React frontend) ===";
    print "    location /agi/ {";
    print "        root /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build;";
    print "        index index.html;";
    print "        try_files $uri $uri/ /agi/index.html;";
    print "    }";
    print "";
    print "    # === Static resources fix ===";
    print "    location ~ ^/(favicon\\.ico|manifest\\.json|logo192\\.png|logo512\\.png|asset-manifest\\.json)$ {";
    print "        root /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build;";
    print "    }";
    next
}
{ print }
' "$BACKUP" > "$NGINX_CONF"

# 3️⃣ 문법 점검 및 Reload
echo "🔍 Nginx 문법 검사 중..."
if nginx -t; then
    systemctl reload nginx
    echo "✅ 구조 복구 및 Reload 완료!"
    echo "🌐 대시보드 접속: https://api.mcpvibe.org/agi/"
else
    echo "❌ Nginx 문법 오류. 백업으로 복원 가능: $BACKUP"
fi
