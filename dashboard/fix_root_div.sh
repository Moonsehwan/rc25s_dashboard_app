#!/bin/bash
set -e
INDEX="/srv/repo/vibecoding/dashboard/dist/index.html"
LOG="/var/log/mcp_dashboard_fix.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')

if [ ! -f "$INDEX" ]; then
  echo "[$TS] ❌ index.html not found!" | tee -a $LOG
  exit 1
fi

if ! grep -q 'id="root"' "$INDEX"; then
  sudo sed -i '/<body>/a \ \ <div id="root"></div>' "$INDEX"
  echo "[$TS] ✅ Added <div id='root'></div> to index.html" | tee -a $LOG
else
  echo "[$TS] ℹ️ Root div already present." | tee -a $LOG
fi

sudo nginx -t && sudo systemctl restart nginx
echo "[$TS] 🚀 Root div check completed." | tee -a $LOG
