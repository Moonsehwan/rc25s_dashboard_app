#!/bin/bash
set -e
LOG="/srv/repo/vibecoding/dashboard/fix_dashboard.log"
TS=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$TS] 🚀 Starting Dashboard base path fix..." | tee -a $LOG

# 1️⃣ vite.config.js 수정 (자동 생성 또는 교체)
cat << 'JS' > /srv/repo/vibecoding/dashboard/vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/dashboard/', // ✅ 서브경로 고정
  build: {
    outDir: 'dist',
  },
})
JS

echo "[$TS] ✅ vite.config.js updated to use base '/dashboard/'" | tee -a $LOG

# 2️⃣ 빌드 실행
cd /srv/repo/vibecoding/dashboard
echo "[$TS] ⚙️ Building React Dashboard..." | tee -a $LOG
npm run build --silent

# 3️⃣ Nginx 테스트 및 재시작
echo "[$TS] 🔍 Testing Nginx configuration..." | tee -a $LOG
sudo nginx -t

echo "[$TS] 🔁 Restarting Nginx..." | tee -a $LOG
sudo systemctl restart nginx

# 4️⃣ 완료 메시지
echo "[$TS] ✅ Dashboard rebuilt and deployed successfully at https://api.mcpvibe.org/dashboard" | tee -a $LOG
