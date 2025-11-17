#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Fixing Nginx for api.mcpvibe.org (/agi → 8011)..."

CONF_DIR="/etc/nginx"
SITES_AVAILABLE="$CONF_DIR/sites-available"
SITES_ENABLED="$CONF_DIR/sites-enabled"
SITES_DISABLED="$CONF_DIR/sites-disabled"
TARGET_CONF="api_mcpvibe_rc25s.conf"

mkdir -p "$SITES_AVAILABLE" "$SITES_ENABLED" "$SITES_DISABLED"

echo "📦 Backing up existing api.mcpvibe.org server blocks in sites-enabled → sites-disabled..."
for f in "$SITES_ENABLED"/*; do
  if [ -f "$f" ] && grep -q "api.mcpvibe.org" "$f"; then
    ts=$(date +%s)
    mv "$f" "$SITES_DISABLED/$(basename "$f").bak_${ts}"
    echo "  → moved $(basename "$f") to sites-disabled (bak_${ts})"
  fi
done

echo "📝 Writing new $SITES_AVAILABLE/$TARGET_CONF ..."
cat << 'NGINX_EOF' >"$SITES_AVAILABLE/$TARGET_CONF"
server {
    listen 80;
    server_name api.mcpvibe.org;

    # HTTP → HTTPS 리다이렉트
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate     /etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.mcpvibe.org/privkey.pem;

    # /agi → /agi/ 리다이렉트
    location = /agi {
        return 301 /agi/;
    }

    # /agi/ → FastAPI 대시보드 백엔드 (127.0.0.1:8011)
    location /agi/ {
        rewrite ^/agi/(.*)$ /$1 break;
        proxy_pass http://127.0.0.1:8011/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 기본 루트: RC25S 대시보드 프론트엔드 (React/Vite build)
    location / {
        root /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    # 헬스 체크용
    location /health {
        return 200 "RC25S Dashboard Nginx OK";
        add_header Content-Type text/plain;
    }

    access_log /var/log/nginx/rc25s_dashboard_access.log;
    error_log  /var/log/nginx/rc25s_dashboard_error.log;
}
NGINX_EOF

echo "🔗 Enabling site $TARGET_CONF ..."
ln -sf "$SITES_AVAILABLE/$TARGET_CONF" "$SITES_ENABLED/$TARGET_CONF"

echo "✅ Testing Nginx configuration..."
nginx -t

echo "🔁 Reloading Nginx..."
systemctl reload nginx

echo "🎉 Done. Try:  curl -vk https://api.mcpvibe.org/agi/health"
