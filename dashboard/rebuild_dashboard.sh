#!/bin/bash
set -e
LOG="/srv/repo/vibecoding/dashboard/rebuild_dashboard.log"
TS=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$TS] 🚀 Rebuilding AGI Dashboard from scratch..." | tee -a $LOG

# 1️⃣ Vite 설정 재작성
cat << 'JS' > /srv/repo/vibecoding/dashboard/vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  base: '/dashboard/',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
})
JS
echo "[$TS] ✅ vite.config.js rewritten." | tee -a $LOG

# 2️⃣ 이전 빌드 삭제 및 새 빌드
cd /srv/repo/vibecoding/dashboard
rm -rf dist
echo "[$TS] ⚙️ Running Vite build..." | tee -a $LOG
npm run build --silent

# 3️⃣ JS 링크 검증
ASSET=$(grep -o '/dashboard/assets/[^"]*' dist/index.html || true)
if [[ -z "$ASSET" ]]; then
  echo "[$TS] ❌ Build missing /dashboard/assets link. Something failed." | tee -a $LOG
  exit 1
fi
echo "[$TS] ✅ Build JS reference detected: $ASSET" | tee -a $LOG

# 4️⃣ Nginx 재시작
sudo nginx -t && sudo systemctl restart nginx
echo "[$TS] ✅ Nginx restarted successfully." | tee -a $LOG

# 5️⃣ 완료 메시지
echo "[$TS] 🎯 Dashboard rebuild complete. Visit: https://api.mcpvibe.org/dashboard" | tee -a $LOG
