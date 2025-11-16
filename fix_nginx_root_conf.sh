#!/bin/bash
echo "🧠 [RC25S] Fixing root /etc/nginx/nginx.conf structure..."

CONF="/etc/nginx/nginx.conf"
BACKUP="$CONF.bak_root_$(date +%s)"
cp "$CONF" "$BACKUP"
echo "📦 백업 완료 → $BACKUP"

cat > "$CONF" <<'BLOCK'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    sendfile on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
BLOCK

echo "🔍 Testing nginx.conf syntax..."
if nginx -t; then
    echo "✅ nginx.conf 구조 복원 완료!"
else
    echo "❌ 여전히 오류 발생 — /etc/nginx/nginx.conf 직접 확인 필요."
fi
