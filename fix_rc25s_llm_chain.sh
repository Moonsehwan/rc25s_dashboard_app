#!/bin/bash
set -e
echo "🧠 [RC25S] LLM Chain Smart AutoFix Started..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"
REACT_PATH="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"
SERVICE="rc25s-dashboard.service"

# 1️⃣ FastAPI 서비스 상태 확인
echo "🔍 Checking FastAPI service status..."
if ! systemctl is-active --quiet $SERVICE; then
  echo "⚙️ Restarting FastAPI service ($SERVICE)..."
  sudo systemctl restart $SERVICE
  sleep 3
fi
systemctl is-active --quiet $SERVICE && echo "✅ FastAPI is running."

# 2️⃣ Ollama 상태 확인
echo "🔍 Checking Ollama status..."
if ! pgrep -x "ollama" > /dev/null; then
  echo "⚙️ Restarting Ollama..."
  sudo systemctl restart ollama
  sleep 3
fi
pgrep -x "ollama" > /dev/null && echo "✅ Ollama process is active."

# 3️⃣ Nginx 설정 점검 및 타임아웃 보정
echo "🔧 Checking Nginx timeout settings..."
if ! grep -q "proxy_read_timeout 300" "$NGINX_CONF"; then
  echo "🧩 Adding extended timeout for /llm route..."
  sudo sed -i '/location \/llm/,+5 {/proxy_pass/ a\
        proxy_read_timeout 300;\
        proxy_connect_timeout 300;\
        proxy_send_timeout 300;' "$NGINX_CONF"
fi

echo "🔁 Reloading Nginx..."
sudo nginx -t && sudo systemctl reload nginx && echo "✅ Nginx reloaded successfully."

# 4️⃣ React 정적 파일 경로 확인
if [ ! -f "$REACT_PATH/index.html" ]; then
  echo "⚠️ React build not found, attempting rebuild..."
  cd "$(dirname "$REACT_PATH")/rc25s_frontend"
  npm run build || echo "❌ React build failed."
fi

# 5️⃣ FastAPI /llm 응답 테스트
echo "🧪 Testing FastAPI /llm endpoint..."
RESPONSE=$(curl -s -m 20 -X POST http://127.0.0.1:4545/llm \
  -H "Content-Type: application/json" \
  -d '{"prompt":"서버 상태를 한 문장으로 요약해줘."}' | jq -r '.output' 2>/dev/null || echo "❌ No JSON response")

if [[ "$RESPONSE" == "❌ No JSON response" || -z "$RESPONSE" ]]; then
  echo "💥 FastAPI responded incorrectly."
else
  echo "✅ FastAPI LLM Response: $RESPONSE"
fi

# 6️⃣ Nginx 외부 /llm 확인
echo "🌐 Testing Nginx proxy endpoint (/llm)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST https://api.mcpvibe.org/llm \
  -H "Content-Type: application/json" \
  -d '{"prompt":"상태 점검"}')

if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ External API /llm working correctly (HTTP 200 OK)"
else
  echo "⚠️ External API returned HTTP $HTTP_CODE (will recheck Nginx alias)"
  echo "🧩 Patching /agi alias if missing..."
  if ! grep -q "location /agi/" "$NGINX_CONF"; then
    sudo tee -a "$NGINX_CONF" > /dev/null <<'BLOCK'
    location /agi/ {
        alias /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build/;
        index index.html;
        try_files $uri $uri/ /agi/index.html;
    }
BLOCK
    sudo nginx -t && sudo systemctl reload nginx && echo "✅ Alias patched successfully."
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ [RC25S] LLM Chain Smart AutoFix Complete!"
