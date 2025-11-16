#!/bin/bash
echo "🧩 [RC25S] 중복된 /ws location 블록 자동 정리 중..."

CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP="${CONF}.bak_ws_$(date +%s)"
cp "$CONF" "$BACKUP"

# 중복된 /ws 블록 제거 (첫 번째만 유지)
awk '
/location \/ws/ {
  count++
  if (count > 1) skip=1
}
skip && /\}/ { skip=0; next }
!skip { print }
' "$BACKUP" > "$CONF"

echo "🔎 Nginx 설정 검사 중..."
if nginx -t; then
  systemctl reload nginx
  echo "✅ Nginx WebSocket 설정 클린 완료!"
  echo "🌐 접속: https://api.mcpvibe.org/agi/"
else
  echo "❌ 오류: 설정 검사 실패. 백업 유지됨: $BACKUP"
fi
