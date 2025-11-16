#!/bin/bash
CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP="${CONF}.bak_$(date +%s)"
echo "🧠 Backing up Nginx config to $BACKUP"
cp "$CONF" "$BACKUP"

# 기존 잘못된 블록 제거
sed -i '/### RC25S AGI DASHBOARD ###/,+6d' "$CONF"

# server 블록 내부에 정상 삽입
sudo awk '
/server\s*{/ && !added {
    print;
    print "    ### RC25S AGI DASHBOARD ###";
    print "    location /agi/ {";
    print "        proxy_pass         http://127.0.0.1:4545/;";
    print "        proxy_set_header   Host $host;";
    print "        proxy_set_header   X-Real-IP $remote_addr;";
    print "        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;";
    print "        proxy_set_header   X-Forwarded-Proto $scheme;";
    print "    }";
    added=1;
    next;
}
{ print }
' "$BACKUP" > "$CONF"

echo "✅ Fixed location block inside server{}."
nginx -t && systemctl reload nginx && echo "🚀 Nginx reloaded successfully!"
