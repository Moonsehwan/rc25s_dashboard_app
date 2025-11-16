#!/bin/bash
set -e

echo "🧩 RC25S Frontend Path Auto-Fix Started..."

FRONTEND_DIR="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend"
NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"
SERVICE="rc25s-dashboard.service"

# 1️⃣ Homepage 경로 수정
echo "🛠️  Fixing React homepage path..."
if grep -q '"homepage":' "$FRONTEND_DIR/package.json"; then
    sed -i 's#"homepage":.*#"homepage": ".",#' "$FRONTEND_DIR/package.json"
else
    sed -i '1a\  "homepage": ".",\' "$FRONTEND_DIR/package.json"
fi
echo "✅ homepage set to '.'"

# 2️⃣ React rebuild
echo "⚙️  Rebuilding React project..."
cd "$FRONTEND_DIR"
rm -rf build
npm install --silent
npm run build

# 3️⃣ Nginx config patch
echo "🧱 Checking Nginx configuration..."
if ! grep -q "/agi/" "$NGINX_CONF"; then
    echo "⚠️  /agi/ block missing — inserting now..."
    cat <<'NGINX_BLOCK' >> "$NGINX_CONF"

location /agi/ {
    root /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build;
    try_files $uri /index.html;
}
NGINX_BLOCK
else
    echo "✅ /agi/ location block already exists."
fi

# 4️⃣ Restart services
echo "♻️  Restarting Nginx and dashboard service..."
sudo nginx -t && sudo systemctl reload nginx
sudo systemctl restart "$SERVICE"

# 5️⃣ Clear caches
echo "🧹 Clearing system and browser cache..."
rm -rf "$FRONTEND_DIR"/node_modules/.cache 2>/dev/null || true
rm -rf "$FRONTEND_DIR"/build/static/js/*.map 2>/dev/null || true

# 6️⃣ Verify
echo "🧪 Verifying response..."
sleep 2
curl -Is https://api.mcpvibe.org/agi/ | head -n 5
echo "✅ RC25S Frontend Auto-Fix Completed!"
