#!/bin/bash
echo "🧠 [RC25S] Nginx 중복 location 블록 전체 정리 시작 (/agi/ & /ws)..."

CONF="/etc/nginx/sites-enabled/codex_console.conf"
BACKUP="${CONF}.bak_fullclean_$(date +%s)"
cp "$CONF" "$BACKUP"

clean_conf() {
  local infile="$1"
  local tmpfile="${infile}.tmp"
  awk '
  /location \/(agi|ws)/ {
    key=$2
    count[key]++
    if (count[key] > 1) skip=1
  }
  skip && /\}/ { skip=0; next }
  !skip { print }
  ' "$infile" > "$tmpfile"
  mv "$tmpfile" "$infile"
}

clean_conf "$CONF"

echo "🔎 nginx 설정 검사 중..."
if nginx -t; then
  systemctl reload nginx
  echo "✅ Nginx 중복 location 클린 완료!"
  echo "🌐 접속 테스트: https://api.mcpvibe.org/agi/"
else
  echo "❌ 오류 발생 — 백업 유지됨: $BACKUP"
fi
