#!/bin/bash
set -e

echo "🧠 [RC25S] Self-Update AGI Agent 설치 시작..."

# --- 1️⃣ 코드 파일 생성 ---
cat > /srv/repo/vibecoding/rc25s_selfupdate_agent.py <<'PYCODE'
import os, json, subprocess, time, datetime, requests, psutil, difflib

LOG = "/srv/repo/vibecoding/logs/selfupdate_agent.log"
SRC_PATH = "/srv/repo/vibecoding"
MEM_FILE = "/srv/repo/vibecoding/memory_store/memory_vector.json"

def log(msg):
    t = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG, "a") as f:
        f.write(f"[{t}] {msg}\n")
    print(f"🧠 {msg}")

def list_python_files():
    result = []
    for root, _, files in os.walk(SRC_PATH):
        for f in files:
            if f.endswith(".py"):
                result.append(os.path.join(root, f))
    return result

def call_llm(prompt):
    try:
        r = requests.post("http://127.0.0.1:4545/llm", json={"prompt": prompt}, timeout=120)
        return r.json().get("output", "")
    except Exception as e:
        return f"❌ LLM 호출 실패: {e}"

def backup_file(path):
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{path}.bak_{ts}"
    subprocess.run(["cp", path, backup_path])
    log(f"💾 백업 완료: {backup_path}")
    return backup_path

def analyze_and_refactor(path):
    with open(path, "r") as f:
        code = f.read()

    log(f"🔍 {path} 코드 분석 중...")
    prompt = f"""
다음 Python 코드를 리팩토링해줘. 
- 구조 개선
- 불필요한 중복 제거
- 명확한 예외 처리
- 주석 추가
출력은 반드시 전체 코드만 포함해야 해.

코드:
{code}
"""
    new_code = call_llm(prompt)
    if "def " not in new_code and "import " not in new_code:
        log(f"⚠️ LLM 결과가 코드 형식이 아님 — 변경 건너뜀.")
        return

    backup_file(path)
    with open(path, "w") as f:
        f.write(new_code)
    log(f"✅ {path} 리팩토링 적용 완료.")

def save_memory(event, data):
    mem = []
    if os.path.exists(MEM_FILE):
        with open(MEM_FILE, "r") as f:
            mem = json.load(f)
    mem.append({"time": datetime.datetime.now().isoformat(), "event": event, "data": data})
    with open(MEM_FILE, "w") as f:
        json.dump(mem[-100:], f, indent=2)

def restart_services():
    services = ["agi-memory.service", "agi-reflection.service", "agi-autofix.service"]
    for s in services:
        subprocess.run(["systemctl", "restart", s])
    log("🔁 주요 AGI 서비스 재시작 완료.")

def main():
    log("🚀 RC25S Self-Update Agent 시작.")
    while True:
        files = list_python_files()
        log(f"📂 총 {len(files)}개 Python 파일 검사 중.")
        for f in files:
            analyze_and_refactor(f)
        restart_services()
        save_memory("self_update", {"updated_files": len(files)})
        log("🧩 코드 리팩토링 사이클 완료. 6시간 대기 중...")
        time.sleep(21600)  # 6시간 간격
PYCODE

chmod +x /srv/repo/vibecoding/rc25s_selfupdate_agent.py

# --- 2️⃣ systemd 등록 ---
cat > /etc/systemd/system/rc25s-selfupdate.service <<'UNIT'
[Unit]
Description=RC25S Self-Update Agent (자기개선 루프)
After=rc25s-selfevo.service

[Service]
ExecStart=/srv/repo/vibecoding/rc25h_env/bin/python /srv/repo/vibecoding/rc25s_selfupdate_agent.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable rc25s-selfupdate.service
systemctl restart rc25s-selfupdate.service

echo "✅ RC25S Self-Update Agent 설치 및 실행 완료."
