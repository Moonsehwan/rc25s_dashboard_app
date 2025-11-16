#!/bin/bash
set -e
LOG="/var/log/mcp_dashboard_fix.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TS] 🧩 Injecting <base href='/dashboard/'> into index.html..." | tee -a $LOG

INDEX="/srv/repo/vibecoding/dashboard/dist/index.html"

# ✅ index.html 존재 확인
if [ ! -f "$INDEX" ]; then
  echo "[$TS] ❌ ERROR: index.html not found at $INDEX" | tee -a $LOG
  exit 1
fi

# ✅ 이미 base 태그가 없으면 삽입
if ! grep -q "<base href=" "$INDEX"; then
  sudo sed -i '/<head>/a \ \ <base href="/dashboard/">' "$INDEX"
  echo "[$TS] ✅ base href inserted successfully." | tee -a $LOG
else
  echo "[$TS] ℹ️ base href already exists." | tee -a $LOG
fi

# ✅ gzip 캐시 제거
sudo rm -f /var/cache/nginx/* || true

# ✅ Nginx 테스트 및 재시작
sudo nginx -t && sudo systemctl restart nginx

echo "[$TS] 🚀 Dashboard HTML patched successfully. Visit: https://api.mcpvibe.org/dashboard" | tee -a $LOG
