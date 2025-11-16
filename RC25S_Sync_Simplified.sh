#!/bin/bash
# ============================================================
# 🚀 RC25S FULL AUTO SYNC SYSTEM (Cursor + GitHub + Server)
# Simplified Version by GPT-5 (v1.2 - Safe heredoc version)
# ============================================================

REPO_DIR="/srv/repo/vibecoding"
APP_DIR="$REPO_DIR/rc25s_dashboard_app"
FRONTEND_SRC="$REPO_DIR/dashboard"
FRONTEND_DST="$APP_DIR/rc25s_frontend"
GIT_REPO="https://github.com/Moonsehwan/rc25s_dashboard_app.git"
LOGFILE="/var/log/rc25s-sync.log"

log() {
  echo "$(date '+%F %T') [SYNC] $*" | tee -a "$LOGFILE"
}

echo "============================================================"
echo "🧠 RC25S AUTO SYNC & DEPLOY STARTED"
echo "============================================================"

# ------------------------------------------------------------
# STEP 1. Git Sync
# ------------------------------------------------------------
log "🔄 Pulling latest code from GitHub..."
if [ ! -d "$REPO_DIR/.git" ]; then
  cd "$REPO_DIR" && git init && git remote add origin "$GIT_REPO"
fi
cd "$REPO_DIR" && git fetch origin main && git reset --hard origin/main

# ------------------------------------------------------------
# STEP 2. Frontend Sync (React/Vite)
# ------------------------------------------------------------
log "🧩 Syncing dashboard → rc25s_frontend..."
mkdir -p "$FRONTEND_DST"
rsync -av --delete "$FRONTEND_SRC/" "$FRONTEND_DST/" >/dev/null 2>&1

# TypeScript 변환 및 설정 복원
cd "$FRONTEND_DST"
if [ ! -f "tsconfig.json" ]; then
  cat > tsconfig.json << 'JSON'
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "jsx": "react-jsx",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src"]
}
JSON
fi

# ------------------------------------------------------------
# STEP 3. Build Frontend
# ------------------------------------------------------------
log "🏗️ Building frontend..."
npm install >/dev/null 2>&1
npm run build >/dev/null 2>&1 || { log "❌ Build failed"; exit 1; }

# ------------------------------------------------------------
# STEP 4. Deploy Backend (FastAPI)
# ------------------------------------------------------------
log "🚀 Restarting backend service..."
systemctl restart rc25s-dashboard.service 2>/dev/null || \
uvicorn rc25s_dashboard.agi_status_dashboard:app --host 0.0.0.0 --port 4545 --daemon

# ------------------------------------------------------------
# STEP 5. AutoHeal / SelfCheck Ensure
# ------------------------------------------------------------
log "🩹 Ensuring AutoHeal and SelfCheck services..."
systemctl enable --now rc25s-autoheal-master.timer 2>/dev/null
systemctl enable --now rc25s-selfcheck.timer 2>/dev/null

# ------------------------------------------------------------
# STEP 6. Push changes (optional)
# ------------------------------------------------------------
log "📦 Committing local changes..."
cd "$REPO_DIR"
git add .
COMMIT_MSG="Auto-synced on $(date '+%F %T')"
git commit -m "$COMMIT_MSG" >/dev/null 2>&1
git push origin main >/dev/null 2>&1 && log "✅ GitHub sync complete" || log "⚠️ Git push skipped"

log "============================================================"
log "✅ RC25S SYNC COMPLETED SUCCESSFULLY"
log "============================================================"
