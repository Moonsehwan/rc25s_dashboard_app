#!/usr/bin/env bash
FILE="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/src/App.tsx"

echo "🧩 Cleaning duplicate broken fetch() code blocks..."

# 1️⃣ 중복된 fetch 호출 제거
sudo sed -i '/method: "POST",/,+5d' "$FILE"

# 2️⃣ 잔여 닫힘 괄호 중복 제거
sudo sed -i '/^ *});/d' "$FILE"

echo "✅ Duplicate fetch blocks cleaned."
grep -n "fetch(" -A 8 "$FILE" | head -10
