#!/bin/bash
set -e
LOG="/srv/repo/vibecoding/dashboard/add_favicon.log"
TS=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$TS] 🧩 Adding missing favicon.ico..." | tee -a $LOG

# 1️⃣ favicon.ico 생성 (간단한 Vite용 기본 아이콘)
cat << 'ICO' | base64 --decode > /srv/repo/vibecoding/dashboard/dist/favicon.ico
AAABAAEAEBAAAAAAIABoBAAAFgAAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8AAP8A
ICO

# 2️⃣ 퍼미션 정리
chmod 644 /srv/repo/vibecoding/dashboard/dist/favicon.ico

# 3️⃣ Nginx 재시작
sudo nginx -t && sudo systemctl restart nginx

echo "[$TS] ✅ favicon.ico added successfully and Nginx reloaded." | tee -a $LOG
