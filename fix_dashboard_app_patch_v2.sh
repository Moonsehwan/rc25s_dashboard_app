#!/usr/bin/env bash
FILE="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/src/App.tsx"

echo "🧩 Fixing syntax in App.tsx..."

sudo sed -i '/fetch(.*\/llm/,/setMessages/{
s/const res = await fetch(.*{/const res = await fetch("\/llm");/
s/const text = await res.text();//g
}' "$FILE"

sudo sed -i '/const res = await fetch("\/llm");/a\
    const text = await res.text();' "$FILE"

echo "✅ Fixed App.tsx."
grep -n "fetch(" -A 5 "$FILE" | head -10
