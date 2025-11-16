#!/bin/bash
CONF="/etc/nginx/sites-enabled/codex_console.conf"
FRONT="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"

echo "🧩 Fixing Nginx /agi/ static mapping in: $CONF"

# server 블록 안에서만 /agi/ 설정 유지
awk '
/server_name api.mcpvibe.org/ {in_server=1}
in_server && /location \/agi\// {
  print "        location /agi/ {\n            root " FRONT ";\n            try_files $uri $uri/ /index.html;\n        }";
  skip=1; next
}
in_server && /}/ && skip { skip=0 }
!skip
' FRONT="$FRONT" "$CONF" > /tmp/fixed_conf

if grep -q "root $FRONT" /tmp/fixed_conf; then
  cp /tmp/fixed_conf "$CONF"
  echo "✅ Injected correct /agi/ block inside server {}"
else
  echo "❌ Could not inject /agi/ block, please check manually"
  exit 1
fi

nginx -t && systemctl reload nginx && echo "✅ Nginx reloaded successfully"
