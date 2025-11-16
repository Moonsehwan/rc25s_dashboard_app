#!/bin/bash
echo "🧠 [RC25S] Checking port 4545..."
PID=$(sudo lsof -t -i :4545)
if [ -n "$PID" ]; then
  echo "⚙️ Killing process using port 4545 (PID: $PID)"
  sudo kill -9 $PID
else
  echo "✅ No process using 4545"
fi

echo "🚀 Restarting rc25s-dashboard.service..."
sudo systemctl restart rc25s-dashboard.service
sleep 3
sudo systemctl status rc25s-dashboard.service --no-pager | grep Active
echo "🌐 Testing FastAPI health..."
curl -s http://127.0.0.1:4545/health || echo "❌ Backend not responding"
