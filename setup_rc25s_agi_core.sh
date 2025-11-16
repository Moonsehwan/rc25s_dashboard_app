#!/usr/bin/env bash
# ============================================================
# RC25S AGI Core systemd 서비스 설치 스크립트
# - RC25H_CentralCore.py 를 rc25h_env 파이썬으로 24/7 실행
# - 부팅 시 자동 시작 + 비정상 종료 시 자동 재시작
# ============================================================

set -e

APPDIR="/srv/repo/vibecoding"
UNIT_SRC="$APPDIR/_systemd/rc25s-agi-core.service"
UNIT_DST="/etc/systemd/system/rc25s-agi-core.service"

echo "[RC25S] AGI Core systemd 서비스 설치 시작..."

if [ ! -f "$UNIT_SRC" ]; then
  echo "❌ 유닛 파일을 찾을 수 없습니다: $UNIT_SRC"
  exit 1
fi

sudo cp "$UNIT_SRC" "$UNIT_DST"
echo "✅ 유닛 파일 복사 완료 → $UNIT_DST"

sudo systemctl daemon-reload
sudo systemctl enable rc25s-agi-core.service
sudo systemctl restart rc25s-agi-core.service

echo "✅ rc25s-agi-core.service 활성화 및 즉시 시작 완료"
echo "ℹ️ 상태 확인:"
echo "    sudo systemctl status rc25s-agi-core.service"
echo "    tail -n 50 $APPDIR/logs/centralcore.log"


