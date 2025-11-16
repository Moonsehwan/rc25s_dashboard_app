#!/bin/bash
DASHBOARD="/srv/repo/vibecoding/agi_status_dashboard.py"
echo "🧠 [RC25S] Fixing missing uvicorn.run() in dashboard..."

# run()이 없을 경우 자동 추가
if ! grep -q "uvicorn.run" "$DASHBOARD"; then
cat <<'PYCODE' >> "$DASHBOARD"

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=4545)
PYCODE
echo "✅ uvicorn.run() added to $DASHBOARD"
else
echo "ℹ️ uvicorn.run() already exists, skipping"
fi

sudo systemctl daemon-reload
sudo systemctl restart rc25s-dashboard.service
sleep 3
sudo systemctl status rc25s-dashboard.service --no-pager
