#!/usr/bin/env bash
# =========================================================
# RC25S MCP Port Conflict Auto-Fix Script
# Author: VibeCoding AGI Recovery Unit
# Created: 2025-11-16
# =========================================================

PORT=4545
echo "🧩 Checking for existing MCP server on port $PORT..."
PID=$(sudo lsof -ti :$PORT)

if [ -n "$PID" ]; then
  echo "⚠️  Existing process detected on port $PORT (PID=$PID)"
  echo "🧩 Stopping process..."
  sudo kill -9 $PID
  sleep 1
else
  echo "✅ No conflicting process found."
fi

echo "🧩 Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "🧩 Restarting MCP server..."
sudo systemctl restart mcp-server.service
sleep 2

echo "🧩 MCP server status:"
sudo systemctl status mcp-server.service | grep Active

echo "🧩 Testing health endpoint..."
curl -s http://127.0.0.1:$PORT/health || echo "⚠️ Health endpoint not responding yet."
