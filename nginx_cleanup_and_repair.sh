#!/bin/bash
echo "🧠 [RC25S] Nginx 설정 클린업 + 복구 시작..."

NGINX_PATH="/etc/nginx/sites-enabled"
BACKUP_DIR="/etc/nginx/disabled_backups_$(date +%s)"
mkdir -p "$BACKUP_DIR"

echo "📦 백업 디렉터리 생성됨: $BACKUP_DIR"

# 모든 .bak_* 파일을 백업 폴더로 이동
find "$NGINX_PATH" -type f -name "*.bak_*" -exec mv {} "$BACKUP_DIR" \;

echo "🧹 오래된 백업 구성 비활성화 완료."

# nginx 구문 검사
echo "🔎 nginx -t 검사 중..."
if sudo nginx -t; then
    echo "✅ 구문 문제 없음."
    sudo systemctl restart nginx
    echo "🔁 Nginx 재시작 완료."
else
    echo "❌ 여전히 구문 오류 — 남은 conf 파일 목록:"
    ls -l "$NGINX_PATH"
    exit 1
fi

# 최종 테스트
sleep 2
echo "🌐 https://api.mcpvibe.org/agi/ 테스트 중..."
curl -s https://api.mcpvibe.org/agi/ | head -n 20
echo "🎯 Nginx 클린 복구 완료!"
