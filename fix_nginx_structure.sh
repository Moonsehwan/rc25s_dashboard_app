#!/bin/bash
CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP="/etc/nginx/sites-enabled/codex_console.conf.bak.$(date +%s)"
FRONT_ROOT="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"

echo "🧩 [RC25S] Fixing Nginx config structure..."
echo "📦 Target: $CONF"
echo "📦 Backup: $BACKUP"

# 백업
cp "$CONF" "$BACKUP"

# server 블록 감지 후 올바른 구조로 재구성
awk -v FRONT="$FRONT_ROOT" '
BEGIN {
  inside_server = 0
}
{
  if ($1 == "server" && $2 == "{") {
    inside_server = 1
    print $0
    next
  }
  if (inside_server && $0 ~ /^}/) {
    print "    # ✅ Auto-fixed /agi/ block"
    print "    location /agi/ {"
    print "        root " FRONT ";"
    print "        try_files $uri $uri/ /index.html;"
    print "    }"
    print ""
    inside_server = 0
  }
  print $0
}' "$CONF" > /tmp/codex_console_fixed.conf

# 적용
mv /tmp/codex_console_fixed.conf "$CONF"

# 문법 테스트
echo "🔍 Testing Nginx configuration..."
nginx -t
if [ $? -eq 0 ]; then
  echo "✅ Nginx configuration valid."
  systemctl reload nginx
  echo "🚀 Reloaded Nginx successfully."
else
  echo "❌ Configuration test failed. Restoring backup..."
  cp "$BACKUP" "$CONF"
  nginx -t
fi
