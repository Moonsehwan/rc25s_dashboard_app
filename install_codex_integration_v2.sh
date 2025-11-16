#!/bin/bash
set -e
LOG="/srv/repo/vibecoding/logs/codex_integration_v2.log"
TS=$(date +"%Y-%m-%d %H:%M:%S")

echo "[$TS] 🚀 Installing Codex Integration v2 (Full Auto System)..." | tee -a $LOG

# ------------------------------------------------------------
# 1️⃣ 경로 및 로그 초기화
# ------------------------------------------------------------
mkdir -p /srv/repo/vibecoding/logs /srv/repo/vibecoding/config
touch /srv/repo/vibecoding/logs/codex_activity.log

# ------------------------------------------------------------
# 2️⃣ Codex 통합용 FastAPI 라우터 생성
# ------------------------------------------------------------
CODEx_FILE="/srv/repo/vibecoding/mcp_api_control.py"

cat << 'PYCODE' > $CODEx_FILE
from fastapi import APIRouter, HTTPException, Header
import subprocess, json, os, datetime, shutil, time

router = APIRouter(prefix="/codex", tags=["Codex Integration v2"])

API_TOKEN = os.getenv("CODEX_API_TOKEN", "YOUR_SECRET_TOKEN")
LOG_FILE = "/srv/repo/vibecoding/logs/codex_activity.log"

def log_event(message: str):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{ts}] {message}\n")

# ✅ 공통 실행 함수
def run_shell(cmd):
    try:
        result = subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.STDOUT)
        return {"ok": True, "output": result}
    except subprocess.CalledProcessError as e:
        return {"ok": False, "error": e.output}

# ✅ Codex 명령 실행
@router.post("/command")
async def run_command(data: dict, authorization: str = Header(None)):
    if authorization != f"Bearer {API_TOKEN}":
        log_event("❌ Unauthorized access attempt.")
        raise HTTPException(status_code=401, detail="Unauthorized")

    cmd = data.get("cmd")
    if not cmd:
        raise HTTPException(status_code=400, detail="Missing 'cmd' field")

    log_event(f"⚙️ Command: {cmd}")
    result = run_shell(cmd)
    log_event("✅ Success" if result["ok"] else f"❌ Failed: {result['error']}")
    return result

# ✅ 파일 수정 + 백업 + 자동 테스트 + 서버 재시작
@router.post("/edit")
async def edit_file(data: dict, authorization: str = Header(None)):
    if authorization != f"Bearer {API_TOKEN}":
        raise HTTPException(status_code=401, detail="Unauthorized")

    path = data.get("path")
    content = data.get("content")
    auto_restart = data.get("restart", False)

    if not path or content is None:
        raise HTTPException(status_code=400, detail="Missing 'path' or 'content'")

    # 🔒 백업
    backup_path = f"{path}.bak_{int(time.time())}"
    try:
        shutil.copy(path, backup_path)
        log_event(f"🧱 Backup created: {backup_path}")
    except Exception as e:
        log_event(f"⚠️ Backup failed: {str(e)}")

    # 📝 수정
    try:
        with open(path, "w") as f:
            f.write(content)
        log_event(f"📝 File updated: {path}")
    except Exception as e:
        log_event(f"❌ Update failed: {str(e)}")
        return {"ok": False, "error": str(e)}

    # 🧪 자동 테스트
    test_result = run_shell("pytest -q || echo '⚠️ Tests failed'")
    log_event(f"🧪 Test Result: {test_result['output'][:200]}")

    # 🔁 자동 재시작
    if auto_restart:
        run_shell("sudo systemctl restart mcp-server.service")
        log_event("🔄 MCP server restarted")

    return {"ok": True, "message": "Edit completed", "test": test_result}
PYCODE

# ------------------------------------------------------------
# 3️⃣ Codex 설정 파일 생성
# ------------------------------------------------------------
CODEX_CONFIG="/srv/repo/vibecoding/config/codex.json"

cat << 'JSONCONF' > $CODEX_CONFIG
{
  "workspace": {
    "type": "remote",
    "endpoint": "https://api.mcpvibe.org/codex/command",
    "auth": {
      "type": "bearer",
      "token": "YOUR_SECRET_TOKEN"
    }
  },
  "permissions": {
    "network_access": true,
    "workspace_write": true
  }
}
JSONCONF

# ------------------------------------------------------------
# 4️⃣ FastAPI에 Codex 라우터 등록
# ------------------------------------------------------------
MCP_FILE="/srv/repo/vibecoding/mcp_server_realtime.py"

if ! grep -q "from vibecoding.mcp_api_control import router as codex_router" $MCP_FILE; then
  echo "[$TS] 🧩 Injecting Codex router into MCP server..." | tee -a $LOG
  sed -i '/^app = FastAPI()/a\
from vibecoding.mcp_api_control import router as codex_router\
app.include_router(codex_router)' $MCP_FILE
fi

# ------------------------------------------------------------
# 5️⃣ MCP 서버 재시작
# ------------------------------------------------------------
echo "[$TS] 🔁 Restarting MCP server..." | tee -a $LOG
sudo systemctl restart mcp-server.service

sleep 2
sudo systemctl status mcp-server.service --no-pager | tee -a $LOG

echo "[$TS] ✅ Codex Integration v2 Installed Successfully!"
echo "🌐 Test API: curl -X POST https://api.mcpvibe.org/codex/command -H 'Authorization: Bearer YOUR_SECRET_TOKEN' -d '{\"cmd\":\"ls -lh /srv/repo\"}'"
