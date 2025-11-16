#!/bin/bash
# 🧠 RC25S AUTOHEAL + HYBRID LLM INTEGRATION SYSTEM (v2.0)
# ============================================================

APP_DIR="/srv/repo/vibecoding/rc25s_dashboard_app"
BACKUP_DIR="/srv/repo/vibecoding/backup_$(date +%s)"
LOGFILE="/var/log/rc25s-autoheal.log"

mkdir -p "$BACKUP_DIR"
touch "$LOGFILE"

echo "🚀 [RC25S] Full Auto-Integration Started at $(date)"
echo "📦 Backing up current state → $BACKUP_DIR"
cp -r "$APP_DIR" "$BACKUP_DIR" 2>/dev/null

# ============================================================
# STEP 1. Dependencies
# ============================================================
echo "📦 Installing dependencies..."
source /srv/repo/vibecoding/venv/bin/activate 2>/dev/null || python3 -m venv /srv/repo/vibecoding/venv && source /srv/repo/vibecoding/venv/bin/activate
pip install --upgrade requests aiohttp websockets openai >/dev/null 2>&1

# ============================================================
# STEP 2. Cursor Composer Client
# ============================================================
echo "🧠 Integrating Cursor Composer..."
cat > "$APP_DIR/backend/cursor_client.py" << "PYEOF"
import os, requests
CURSOR_API = "https://api.cursor.sh/composer"
CURSOR_KEY = os.getenv("CURSOR_API_KEY")

def query_cursor(prompt: str):
    if not CURSOR_KEY:
        return {"output": "[Cursor Composer inactive - no key configured]"}
    try:
        res = requests.post(CURSOR_API,
            json={"prompt": prompt, "mode": "code"},
            headers={"Authorization": f"Bearer {CURSOR_KEY}"}, timeout=30)
        return res.json()
    except Exception as e:
        return {"error": str(e)}
PYEOF

# ============================================================
# STEP 3. Hybrid LLM Router (FastAPI)
# ============================================================
echo "🤖 Updating /llm hybrid route..."
cat > "$APP_DIR/backend/routes/llm.py" << "PYEOF"
from fastapi import APIRouter
from pydantic import BaseModel
import os, openai
from ..cursor_client import query_cursor

router = APIRouter()

OPENAI_KEY = os.getenv("OPENAI_API_KEY")
if OPENAI_KEY:
    openai.api_key = OPENAI_KEY

class Prompt(BaseModel):
    prompt: str

@router.post("/llm")
async def llm_route(req: Prompt):
    prompt = req.prompt
    try:
        cursor_res = query_cursor(prompt)
        if cursor_res and "output" in cursor_res:
            return {"model": "CursorComposer", "output": cursor_res["output"]}
        elif OPENAI_KEY:
            res = openai.ChatCompletion.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}],
                temperature=0.4,
            )
            return {"model": "OpenAI", "output": res["choices"][0]["message"]["content"]}
        else:
            return {"error": "No active LLM configured."}
    except Exception as e:
        return {"error": str(e)}
PYEOF
# ============================================================
# STEP 4. Apidog Sync Utility
# ============================================================
echo "🔗 Setting up Apidog integration..."
cat > "$APP_DIR/backend/utils/apidog_sync.py" << "PYEOF"
import os, requests
APIDOG_KEY = os.getenv("APIDOG_API_KEY")
APIDOG_URL = "https://api.apidog.com/v1/api-docs/sync"

def sync_apidog():
    if not APIDOG_KEY:
        print("⚠️ Apidog API key missing.")
        return
    res = requests.post(APIDOG_URL, json={"project": "RC25S", "description": "Auto-synced dashboard"},
                        headers={"Authorization": f"Bearer {APIDOG_KEY}"})
    print("Apidog sync:", res.status_code)
PYEOF

# ============================================================
# STEP 5. Auto-Heal Watcher (Part 1)
# ============================================================
echo "🩹 Deploying RC25S Auto-Heal Watcher..."
cat > /srv/repo/vibecoding/rc25s-autoheal-master.sh << "BASH"
#!/bin/bash
APP_DIR="/srv/repo/vibecoding/rc25s_dashboard_app"
LOGFILE="/var/log/rc25s-autoheal.log"
NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"

log() { echo "$(date +%F

# ============================================================
# STEP 4. Apidog Sync Utility
# ============================================================
echo "🔗 Setting up Apidog integration..."
mkdir -p "$APP_DIR/backend/utils"

cat > "$APP_DIR/backend/utils/apidog_sync.py" << "PYEOF"
import os, requests

APIDOG_KEY = os.getenv("APIDOG_API_KEY")
APIDOG_URL = "https://api.apidog.com/v1/api-docs/sync"

def sync_apidog():
    if not APIDOG_KEY:
        print("⚠️ Apidog API key missing.")
        return
    res = requests.post(APIDOG_URL, json={
        "project": "RC25S",
        "description": "Auto-synced dashboard"
    }, headers={"Authorization": f"Bearer {APIDOG_KEY}"})
    print("Apidog sync:", res.status_code)
PYEOF

# ============================================================
# STEP 4. Apidog Sync Utility
# ============================================================
echo "🔗 Setting up Apidog integration..."
mkdir -p "$APP_DIR/backend/utils"

cat > "$APP_DIR/backend/utils/apidog_sync.py" << "PYEOF"
import os, requests

APIDOG_KEY = os.getenv("APIDOG_API_KEY")
APIDOG_URL = "https://api.apidog.com/v1/api-docs/sync"

def sync_apidog():
    if not APIDOG_KEY:
        print("⚠️ Apidog API key missing.")
        return
    res = requests.post(APIDOG_URL, json={
        "project": "RC25S",
        "description": "Auto-synced dashboard"
    }, headers={"Authorization": f"Bearer {APIDOG_KEY}"})
    print("Apidog sync:", res.status_code)
PYEOF

# ============================================================
# STEP 5. Auto-Heal Watcher (Part 1)
# ============================================================
echo "🩹 Deploying RC25S Auto-Heal Watcher..."

cat > /srv/repo/vibecoding/rc25s-autoheal-master.sh << "BASH"
#!/bin/bash
APP_DIR="/srv/repo/vibecoding/rc25s_dashboard_app"
LOGFILE="/var/log/rc25s-autoheal.log"
NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"

log() { echo "\$(date +%F

# ============================================================
# STEP 5. Auto-Heal Watcher (Part 2)
# ============================================================
cat >> /srv/repo/vibecoding/rc25s-autoheal-master.sh << "BASH"
optimize() {
  CPU=\$(awk "{print \$1}" /proc/loadavg)
  FREE=\$(free -m | awk "/Mem/ {print \$4}")
  (( FREE < 500 )) && { sync; echo 3 > /proc/sys/vm/drop_caches; log "🧹 Cleared cache (Low mem)"; }
}

while true; do
  detect
  optimize
  sleep 60
done
BASH

chmod +x /srv/repo/vibecoding/rc25s-autoheal-master.sh

# ============================================================
# STEP 6. Systemd Service & Timer Setup
# ============================================================
echo "⚙️ Setting up systemd auto-heal watcher..."

cat > /etc/systemd/system/rc25s-autoheal-master.service << "SERVICE"
[Unit]
Description=RC25S Auto-Heal Master Watcher
After=network.target

[Service]
ExecStart=/srv/repo/vibecoding/rc25s-autoheal-master.sh
Restart=always
RestartSec=30
StandardOutput=append:/var/log/rc25s-autoheal.log
StandardError=append:/var/log/rc25s-autoheal.log

[Install]
WantedBy=multi-user.target
SERVICE

# 🔁 Timer for periodic auto-validation
cat > /etc/systemd/system/rc25s-autoheal-master.timer << "TIMER"
[Unit]
Description=RC25S Auto-Heal periodic timer

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Unit=rc25s-autoheal-master.service

[Install]
WantedBy=timers.target
TIMER

# Enable and start
systemctl daemon-reload
systemctl enable --now rc25s-autoheal-master.timer
systemctl start rc25s-autoheal-master.service


# ============================================================
# STEP 6. Systemd Service & Timer Setup (Recreate)
# ============================================================
echo "⚙️ Recreating systemd auto-heal watcher..."

# 🩹 서비스 유닛 생성
cat > /etc/systemd/system/rc25s-autoheal-master.service << "SERVICE"
[Unit]
Description=RC25S Auto-Heal Master Watcher
After=network.target

[Service]
ExecStart=/srv/repo/vibecoding/rc25s-autoheal-master.sh
Restart=always
RestartSec=30
StandardOutput=append:/var/log/rc25s-autoheal.log
StandardError=append:/var/log/rc25s-autoheal.log

[Install]
WantedBy=multi-user.target
SERVICE

# 🔁 타이머 유닛 생성
cat > /etc/systemd/system/rc25s-autoheal-master.timer << "TIMER"
[Unit]
Description=RC25S Auto-Heal periodic timer

[Timer]
OnBootSec=1min
OnUnitActiveSec=3min
Unit=rc25s-autoheal-master.service

[Install]
WantedBy=timers.target
TIMER

# 🔁 적용 및 실행
systemctl daemon-reload
systemctl enable --now rc25s-autoheal-master.timer
systemctl start rc25s-autoheal-master.service


# ============================================================
# STEP 7. Self-Diagnostics & Integration Validation
# ============================================================
echo "🧠 Setting up full-stack diagnostics..."

cat > /srv/repo/vibecoding/rc25s-selfcheck.sh << "BASH"
#!/bin/bash
LOGFILE="/var/log/rc25s-autoheal.log"

log() { echo "$(date +%F
