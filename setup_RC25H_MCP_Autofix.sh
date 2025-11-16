#!/bin/bash
echo "==============================================="
echo "🧠 RC25H Unified Kernel - MCP Auto-Fix Installer"
echo "==============================================="

LOG_DIR="/srv/repo/vibecoding/logs"
PY_ENV="/srv/repo/vibecoding/rc25h_env"
PY_BIN="$PY_ENV/bin/python"
SERVICE_PATH="/etc/systemd/system/mcp.service"

echo "▶ [1/5] MCP systemd 서비스 구성 중..."
sudo tee $SERVICE_PATH > /dev/null <<EOT
[Unit]
Description=MCP Realtime Backend Server (8000)
After=network.target

[Service]
ExecStart=$PY_BIN -m uvicorn vibecoding.mcp_server_realtime:app --host 0.0.0.0 --port 8000
WorkingDirectory=/srv/repo/vibecoding
Restart=always
StandardOutput=append:$LOG_DIR/mcp_server_realtime.log
StandardError=append:$LOG_DIR/mcp_server_realtime.log

[Install]
WantedBy=multi-user.target
EOT

echo "✅ MCP 서비스 파일 등록 완료: $SERVICE_PATH"

echo "▶ [2/5] 로그 디렉토리 생성 확인..."
sudo mkdir -p $LOG_DIR
echo "✅ 로그 디렉토리: $LOG_DIR"

echo "▶ [3/5] systemd 등록 및 재시작..."
sudo systemctl daemon-reload
sudo systemctl enable mcp.service
sudo systemctl restart mcp.service

echo "▶ [4/5] MCP 서비스 상태 확인..."
sudo systemctl status mcp.service --no-pager -l | head -n 12

echo "▶ [5/5] RC25H CentralCore 루프 재시작..."
sudo systemctl restart rc25h_core.service
sleep 2

echo "==============================================="
echo "✅ RC25H MCP Auto-Fix Complete!"
echo "📡 MCP 상태:"
sudo systemctl status mcp.service --no-pager | grep Active
echo "-----------------------------------------------"
echo "📊 CentralCore 로그 미리보기:"
sudo tail -n 5 /srv/repo/vibecoding/logs/centralcore.log
echo "==============================================="
