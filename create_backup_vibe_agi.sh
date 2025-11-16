#!/bin/bash
set -e
BACKUP_FILE="/srv/repo/vibe_agi_snapshot_$(date +%Y%m%d_%H%M).tar.gz"
echo "🧠 [RC25S] AGI 시스템 전체 백업 생성 중..."
echo "📦 백업 파일: $BACKUP_FILE"

INCLUDE_PATHS=(
  "/srv/repo/vibecoding"
  "/srv/repo/agi-core"
  "/srv/repo/vibecoding/rc25s_dashboard_app"
  "/srv/repo/venv"
  "/etc/vibecoding"
  "/etc/openai_api_key.txt"
)

ARGS=()
for path in "\${INCLUDE_PATHS[@]}"; do
  if [ -e "\$path" ]; then
    ARGS+=("\$path")
  else
    echo "⚠️ 경로 누락 (skip): \$path"
  fi
done

SYSTEMD_DIR="/etc/systemd/system"
if [ -d "\$SYSTEMD_DIR" ]; then
  find "\$SYSTEMD_DIR" -maxdepth 1 -type f -name "agi-*.service" -print0 | xargs -0 tar -rf "\$BACKUP_FILE" 2>/dev/null || true
fi

tar -czf "\$BACKUP_FILE" "\${ARGS[@]}" || {
  echo "❌ tar 백업 중 오류 발생"
  exit 1
}

echo "✅ AGI 시스템 전체 백업 완료: \$BACKUP_FILE"
