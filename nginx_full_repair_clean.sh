#!/bin/bash
echo "🧠 [RC25S] Nginx 완전 정리 및 복구 시작..."

CONF_DIR="/etc/nginx/sites-enabled"
CONF_FILE="$CONF_DIR/codex_console.conf"

echo "🧹 백업 파일 정리 중..."
find "$CONF_DIR" -type f -name "*.bak_*" -delete

BACKUP="${CONF_FILE}.bak_full_$(date +%s)"
cp "$CONF_FILE" "$BACKUP"

echo "🧩 중복 location 정리 중 (/agi/ + /ws)..."
awk '
/location \/(agi|ws)/ {
  key=$2
  count[key]++
  if (count[key] > 1) skip=1
}
skip && /\}/ { skip=0; next }
!skip { print }
' "$BACKUP" > "$CONF_FILE"

echo "🔎 nginx 설정 검사 중..."
if nginx -t; then
  systemctl restart nginx
  echo "✅ Nginx 클린 복구 완료!"
  echo "🌐 접속 테스트: https://api.mcpvibe.org/agi/"
else
  echo "❌ 오류 발생 — 백업 유지됨: $BACKUP"
fi
