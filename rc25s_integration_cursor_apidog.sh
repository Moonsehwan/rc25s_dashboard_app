#!/bin/bash
REPO_DIR="/srv/repo/vibecoding/rc25s_dashboard_app"
LOGFILE="/var/log/rc25s-integration.log"

log() {
  echo "$(date +%F\ %T) [INTEGRATION] $*" | tee -a "$LOGFILE"
}

log "🧠 Starting Cursor Composer + Apidog Integration Flow..."

# Run Cursor Composer client
python3 "$REPO_DIR/backend/cursor_client.py" "Optimize FastAPI endpoints for Apidog sync"
if [ $? -ne 0 ]; then
  log "❌ Cursor Composer failed"
  exit 1
fi

# Run Apidog sync
python3 "$REPO_DIR/backend/utils/apidog_sync.py"
if [ $? -ne 0 ]; then
  log "❌ Apidog sync failed"
  exit 1
fi

log "✅ Integration flow completed successfully."
