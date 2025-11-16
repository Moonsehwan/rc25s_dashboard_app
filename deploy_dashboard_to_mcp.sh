#!/usr/bin/env bash
set -e
SRC="/srv/repo/vibecoding/dashboard/dist"
DEST="root@api.mcpvibe.org:/var/www/html/dashboard"
LOG="/srv/repo/vibecoding/logs/dashboard_deploy.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TS] 🚀 Deploying RC25H Dashboard to api.mcpvibe.org..." | tee -a $LOG

# 1️⃣ 빌드 확인
if [ ! -d "$SRC" ]; then
  echo "[$TS] ❌ Dashboard build not found at $SRC" | tee -a $LOG
  exit 1
fi

# 2️⃣ rsync로 파일 전송 (자동 동기화)
rsync -avz --delete $SRC/ $DEST/ >> $LOG 2>&1

# 3️⃣ 원격 권한 조정 및 nginx reload
ssh root@api.mcpvibe.org "chown -R www-data:www-data /var/www/html/dashboard && systemctl reload nginx"

echo "[$TS] ✅ Dashboard deployed successfully to https://api.mcpvibe.org/dashboard" | tee -a $LOG
