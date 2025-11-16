#!/bin/bash
echo "🧠 [RC25S] FastAPI /health 블로킹 수정 시작..."
FILE="/srv/repo/vibecoding/rc25s_dashboard/agi_status_dashboard.py"
if grep -q "interval=0.5" $FILE; then
    sed -i 's/interval=0.5/interval=None/g' $FILE
    echo "✅ psutil interval 수정 완료"
fi
systemctl restart rc25s-dashboard.service && echo "🚀 FastAPI 재시작 완료"
sleep 2
curl -s http://127.0.0.1:4545/health && echo -e "\n✅ /health 응답 정상화 완료!"
