#!/usr/bin/env bash
# =========================================================
# RC25S Dashboard Frontend App.tsx Syntax Auto-Fix
# =========================================================
FILE="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/src/App.tsx"

echo "🧩 Cleaning broken fetch() syntax in App.tsx..."

# 1️⃣ 기존 잘못된 fetch 구조 제거
sudo sed -i '/fetch(.*\/llm/,/setMessages(/c\
    const res = await fetch("/llm", {\
      method: "POST",\
      headers: { "Content-Type": "application/json" },\
      body: JSON.stringify({ prompt: input, provider }),\
    });\
    const text = await res.text();\
    try {\
      const json = JSON.parse(text);\
      setMessages([...messages, { sender: "ai", text: json.output }]);\
    } catch (e) {\
      setMessages([...messages, { sender: "system", text: "⚠️ 서버 응답 오류 (504 Timeout 또는 HTML 에러)" }]);\
    }\
    setLoading(false);' "$FILE"

echo "✅ App.tsx syntax corrected successfully."
grep -n "fetch(" -A 10 "$FILE" | head -15
