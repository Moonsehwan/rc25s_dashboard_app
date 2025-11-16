#!/bin/bash
echo "🧩 [RC25S] 중복된 /agi/ location 블록 정리 중..."

CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP="${CONF}.bak_clean_$(date +%s)"
cp "$CONF" "$BACKUP"

# 중복 /agi/ 블록 제거 (첫 번째만 유지)
awk '
/location \/agi\// {
  count++
  if (count > 1) skip=1
}
skip && /\}/ { skip=0; next }
!skip { print }
' "$BACKUP" > "$CONF"

echo "🔎 Nginx 설정 검사 중..."
if nginx -t; then
  systemctl reload nginx
  echo "✅ Nginx 클린 재시작 완료!"
  echo "🌐 접속 테스트: https://api.mcpvibe.org/agi/"
else
  echo "❌ 오류: 설정 검사 실패. 백업 유지됨: $BACKUP"
fi
