#!/bin/bash
# ============================================================
# 🔧 RC25S Dashboard Nginx root 경로 자동 수정 스크립트
# - 기존 CRA build 경로 → Vite dashboard/dist 경로로 변경
# - codex_console.conf 에서만 동작
# ============================================================

set -e

CONF="/etc/nginx/sites-enabled/codex_console.conf"
OLD_ROOT="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/build"
NEW_ROOT="/srv/repo/vibecoding/dashboard/dist"

echo "[fix-nginx] Target conf: $CONF"

if [ ! -f "$CONF" ]; then
  echo "[fix-nginx] ❌ Nginx conf not found: $CONF"
  exit 1
fi

if ! grep -q "$OLD_ROOT" "$CONF"; then
  echo "[fix-nginx] ℹ️ OLD_ROOT not found in conf (already migrated?): $OLD_ROOT"
else
  echo "[fix-nginx] 🛠 Rewriting root from:"
  echo "           $OLD_ROOT"
  echo "           → $NEW_ROOT"
  sed -i "s#$OLD_ROOT#$NEW_ROOT#g" "$CONF"
fi

echo "[fix-nginx] ✅ Updated conf. Testing nginx..."
if nginx -t; then
  echo "[fix-nginx] ✅ nginx -t OK. Reloading..."
  systemctl reload nginx
  echo "[fix-nginx] ✅ Nginx reloaded."
else
  echo "[fix-nginx] ❌ nginx -t failed. Please check the config manually."
  exit 1
fi


