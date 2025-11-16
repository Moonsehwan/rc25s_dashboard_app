#!/usr/bin/env bash
# =========================================================
# RC25H Hybrid Kernel Unified Deployment Script (Final)
# =========================================================
# 설치 목적: 모든 RC25H 모듈을 하나의 완전한 FastAPI 서버로 통합.
# 이 스크립트는 MCP Server + Codex Console + CentralCore + Kernel 모듈을 결합합니다.

set -e
DOMAIN="api.mcpvibe.org"
APPDIR="/srv/repo/vibecoding"
LOGFILE="$APPDIR/logs/rc25h_fullsystem.log"

echo "[RC25H] 통합 서버 구축 시작..." | tee -a $LOGFILE

# 1. 기존 프로세스 정리
sudo pkill -f mcp_codex_console.py || true
sudo pkill -f mcp_server.py || true

# 2. 중앙두뇌 통합 파일 생성
cat << 'PYEOF' > $APPDIR/RC25H_CentralCore.py
import os, json, subprocess, datetime, time
from rc25_kernel_pro_R3 import ProKernel
from reflection_engine import run_reflection
from memory_engine import update_memory
from autofix_loop import auto_fix

class RC25H_CentralCore:
    def __init__(self):
        self.kernel = ProKernel(llm=None)
        self.state_path = "/srv/repo/vibecoding/reflection.json"
        self.mem_path = "/srv/repo/vibecoding/memory_vector.json"
        self.log = "/srv/repo/vibecoding/logs/centralcore.log"

    def read_state(self):
        try:
            reflection = json.load(open(self.state_path))
            memory = json.load(open(self.mem_path))
            return reflection, memory
        except Exception:
            return None, None

    def analyze_and_decide(self, reflection, memory):
        if not reflection or not memory:
            return "INIT"
        conf = reflection.get("confidence", 0)
        errors = reflection.get("error_count", 0)
        memlen = len(memory)
        if conf < 0.6: return "REFLECT"
        if memlen < 5: return "MEMORY"
        if errors > 0: return "AUTOFIX"
        return "CREATIVE"

    def execute(self, decision, context=""):
        with open(self.log, "a") as f:
            f.write(f"[{datetime.datetime.now()}] Decision: {decision}\n")
        if decision == "REFLECT":
            run_reflection()
        elif decision == "MEMORY":
            update_memory()
        elif decision == "AUTOFIX":
            auto_fix()
        elif decision == "CREATIVE":
            self.kernel.run_turn(context, "새 아이디어 생성", mode="creative")

    def loop(self):
        while True:
            ref, mem = self.read_state()
            decision = self.analyze_and_decide(ref, mem)
            self.execute(decision)
            time.sleep(300)

if __name__ == "__main__":
    core = RC25H_CentralCore()
    core.loop()
PYEOF

# 3. FastAPI 통합 서버 생성
cat << 'PYEOF' > $APPDIR/RC25H_UnifiedServer.py
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
import subprocess, json
from RC25H_CentralCore import RC25H_CentralCore

app = FastAPI(title="RC25H Unified Kernel Server")
core = RC25H_CentralCore()

@app.get("/health")
async def health():
    return {"status":"ok","message":"RC25H Unified Kernel active"}

@app.get("/chat", response_class=HTMLResponse)
async def chat_ui():
    html = """
    <html><body style='background:#0e0e0e;color:#ccc;font-family:monospace'>
    <h2>🧠 RC25H Unified Console</h2>
    <div id='out' style='white-space:pre;height:70vh;overflow:auto;background:#111;padding:10px;'></div>
    <input id='cmd' style='width:80%;background:#222;color:#0f0;border:none;padding:8px;' placeholder='명령 입력...'>
    <button onclick='send()' style='background:#333;color:#fff;border:none;padding:8px;'>Run</button>
    <script>
      async function send(){
        let c=document.getElementById('cmd').value;
        document.getElementById('out').innerText += "\\n> "+c+"\\n";
        let r=await fetch('/exec',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({cmd:c})});
        let t=await r.text();
        document.getElementById('out').innerText += t + "\\n";
        document.getElementById('cmd').value='';
      }
    </script></body></html>"""
    return HTMLResponse(html)

@app.post("/exec")
async def exec_command(request: Request):
    data = await request.json()
    cmd = data.get("cmd","")
    # 간단한 한글→명령 매핑
    mapping = {"리플렉션":"python3 reflection_engine.py","메모리":"python3 memory_engine.py","자동수정":"python3 autofix_loop.py"}
    for k,v in mapping.items():
        if k in cmd:
            cmd = v
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
        return JSONResponse({"cmd":cmd,"output":result.stdout + result.stderr})
    except Exception as e:
        return JSONResponse({"error":str(e)})

@app.post("/reflect/run")
async def reflect_run():
    core.execute("REFLECT")
    return {"status":"ok","action":"reflection"}

@app.post("/memory/update")
async def mem_update():
    core.execute("MEMORY")
    return {"status":"ok","action":"memory update"}
PYEOF

# 4. 서비스 등록
cat << 'SERVICE' | sudo tee /etc/systemd/system/rc25h.service > /dev/null
[Unit]
Description=RC25H Unified Kernel Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 /srv/repo/vibecoding/RC25H_UnifiedServer.py
WorkingDirectory=/srv/repo/vibecoding
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable rc25h.service
sudo systemctl restart rc25h.service

echo "[RC25H] 통합 서버 구축 완료!" | tee -a $LOGFILE
