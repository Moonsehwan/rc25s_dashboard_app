#!/usr/bin/env bash
set -euo pipefail

DASH_DIR="/srv/repo/vibecoding/dashboard"
NGINX_CONF="/etc/nginx/sites-available/api_mcpvibe_rc25s.conf"

echo "🔧 updating vite.config.js"
cat <<'VCONF' >"$DASH_DIR/vite.config.js"
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  root: './',
  base: '/',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
})
VCONF

echo "🔧 updating index.html base href"
cat <<'HTML' >"$DASH_DIR/index.html"
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <base href="/" />
    <title>AGI Dashboard</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
HTML

echo "🔧 ensuring nginx root points to dashboard/dist"
sudo sed -i 's#/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build#/srv/repo/vibecoding/dashboard/dist#g' "$NGINX_CONF"

echo "🧱 rebuilding dashboard..."
cd "$DASH_DIR"
npm run build

echo "✅ nginx reload"
sudo nginx -t
sudo systemctl reload nginx

echo "🎉 done. open https://api.mcpvibe.org/ 새로고침!"
