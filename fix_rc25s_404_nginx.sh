#!/bin/bash
echo "🧠 [RC25S] Fixing 404 for React AGI Dashboard..."

FRONT_DIR="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"
CONF="/etc/nginx/sites-enabled/codex_console.conf"

if ! grep -q "/agi/" "$CONF"; then
cat <<BLOCK >> "$CONF"

# === RC25S AGI Dashboard Frontend ===
location /agi/ {
    alias $FRONT_DIR/;
    index index.html;
    try_files \$uri \$uri/ /index.html;
}
BLOCK
fi

# favicon 경로 보완
if ! grep -q "location = /favicon.ico" "$CONF"; then
cat <<'BLOCK' >> "$CONF"

# === favicon fix ===
location = /favicon.ico {
    root /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build;
}
BLOCK
fi

sudo nginx -t && sudo systemctl reload nginx && echo "✅ Nginx 404 fix applied successfully!" || echo "❌ Failed to reload nginx."
