#!/bin/bash
set -e
echo "🧠 [RC25S] Smart Auto Fix System Starting..."

NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"
REACT_PATH="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"

echo "🔍 Checking nginx.conf syntax..."
if ! sudo nginx -t 2>&1 | grep -q "syntax is ok"; then
  echo "❌ Nginx configuration syntax error. Aborting."
  exit 1
fi

echo "🔎 Checking React build path..."
if [ ! -f "$REACT_PATH/index.html" ]; then
  echo "⚠️ React build not found, attempting rebuild..."
  cd "$(dirname "$REACT_PATH")/rc25s_frontend"
  npm run build || echo "❌ React build failed."
fi

echo "📦 Backing up nginx config..."
sudo cp "$NGINX_CONF" "${NGINX_CONF}.bak_$(date +%s)"

echo "🧩 Updating /agi/ alias routing..."
sudo sed -i '/location \/agi\//,/}/d' "$NGINX_CONF"

sudo tee -a "$NGINX_CONF" > /dev/null <<'BLOCK'
    location /agi/ {
        alias /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build/;
        index index.html;
        try_files $uri $uri/ /agi/index.html;
    }
BLOCK

echo "🧩 Ensuring /llm and /ws routing..."
grep -q "location /llm" "$NGINX_CONF" || cat <<'BLOCK' | sudo tee -a "$NGINX_CONF" > /dev/null
    location /llm {
        proxy_pass http://127.0.0.1:4545/llm;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /ws {
        proxy_pass http://127.0.0.1:4545/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
BLOCK

echo "🔁 Reloading Nginx..."
sudo nginx -t && sudo systemctl reload nginx

echo "🌐 Testing endpoint..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://api.mcpvibe.org/agi/)
if [ "$HTTP_STATUS" == "200" ]; then
  echo "✅ AGI dashboard successfully served (HTTP 200 OK)"
else
  echo "⚠️ Still not OK — HTTP status: $HTTP_STATUS"
  echo "🧪 Trying to diagnose..."
  case $HTTP_STATUS in
    500) echo "💥 500 Internal Server Error → alias misroute fixed, reload again";;
    502) echo "🚫 502 Bad Gateway → FastAPI not running or port 4545 blocked";;
    404) echo "📂 404 Not Found → React build missing or homepage path error";;
    *) echo "❔ Unexpected code $HTTP_STATUS";;
  esac
fi

echo "🧠 [RC25S] Smart Auto Fix Complete!"
