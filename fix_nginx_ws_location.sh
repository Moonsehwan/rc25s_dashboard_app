#!/bin/bash
echo "🧠 [RC25S] Fixing misplaced Nginx location /agi/ block..."

CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP="${CONF}.bak_$(date +%s)"

# 백업
cp "$CONF" "$BACKUP"
echo "📦 백업됨: $BACKUP"

# server 블록 내부 마지막 '}' 바로 위에 /agi/ 블록 삽입
sudo awk '
/^}$/ && in_server == 1 {
    print "    ### RC25S AGI DASHBOARD ###"
    print "    location /agi/ {"
    print "        proxy_pass http://127.0.0.1:4545/;"
    print "        proxy_http_version 1.1;"
    print "        proxy_set_header Upgrade $http_upgrade;"
    print "        proxy_set_header Connection $connection_upgrade;"
    print "        proxy_set_header Host $host;"
    print "        proxy_set_header X-Real-IP $remote_addr;"
    print "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"
    print "        proxy_set_header X-Forwarded-Proto $scheme;"
    print "    }"
    in_server = 0
}
{ print }
/server {/ { in_server = 1 }
' "$BACKUP" > "$CONF"

# 중복 블록 제거 (server 바깥쪽)
sudo sed -i '/^location \/agi\//,/^}/d' "$CONF"

sudo nginx -t && sudo systemctl restart nginx && echo "✅ Nginx WebSocket proxy fixed successfully!"
