#!/usr/bin/env bash
# =========================================================
# RC25S Dashboard Frontend Auto Patch Script
# Fixes invalid const placement inside fetch() in App.tsx
# =========================================================
FILE="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/src/App.tsx"

if grep -q 'const text = await res.text();' "$FILE"; then
  echo "🧩 Patching App.tsx..."
  sudo sed -i 's/fetch(\/llm", {[^}]*}/fetch(\"\/llm\");\n    const text = await res.text();/g' "$FILE"
else
  echo "✅ App.tsx already fixed or pattern not found."
fi

echo "🧩 Verifying..."
grep -n "await res.text" "$FILE" | head -3
