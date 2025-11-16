#!/usr/bin/env bash
FILE="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/src/App.tsx"

echo "🧩 Fixing misplaced brace in App.tsx..."

# 잘못된 단독 닫는 중괄호 제거
sudo sed -i '/fetch(.*\/llm/,/method: "POST"/{
/^ *}/d
}' "$FILE"

echo "✅ Misplaced brace removed. Verifying nearby fetch block..."
grep -n "fetch(" -A 8 "$FILE" | head -10
