#!/bin/bash
set -e
LOG="/var/log/mcp_dashboard_fix.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TS] 🚀 Fixing Dashboard build (absolute JS paths)..." | tee -a $LOG

# 1️⃣ vite.config.js 절대 경로로 수정
cat << 'JS' > /srv/repo/vibecoding/dashboard/vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/dashboard/', // ✅ 절대 경로
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
  },
})
JS

# 2️⃣ index.html base 태그 강제 삽입
cd /srv/repo/vibecoding/dashboard
sed -i '/<head>/a <base href="/dashboard/">' src/index.html || true

# 3️⃣ 빌드 실행
echo "[$TS] 🧱 Rebuilding React app..." | tee -a $LOG
rm -rf dist
npm run build --silent

# 4️⃣ Nginx 캐시 비우기 및 재시작
echo "[$TS] 🔁 Restarting Nginx..." | tee -a $LOG
sudo nginx -t && sudo systemctl restart nginx

echo "[$TS] ✅ Dashboard fully rebuilt and deployed at https://api.mcpvibe.org/dashboard" | tee -a $LOG
