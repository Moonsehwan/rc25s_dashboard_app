#!/usr/bin/env bash
set -e

BASE=/srv/repo/vibecoding
LOG=$BASE/logs/agi_loop.log
MEM=$BASE/memory_store/memory_vector.json
REFL=$BASE/memory_store/reflection.json

mkdir -p $BASE/logs $BASE/memory_store

echo "=== RC25H AGI Loop Setup Started ==="

# 1️⃣ memory_engine.py
cat << 'PY' > $BASE/memory_engine.py
#!/usr/bin/env python3
import json, os, datetime

MEMORY_PATH = "/srv/repo/vibecoding/memory_store/memory_vector.json"
REFLECTION_PATH = "/srv/repo/vibecoding/memory_store/reflection.json"
LOG_PATH = "/srv/repo/vibecoding/logs/agi_memory.log"

def log(msg):
    t = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{t}] {msg}"
    print(line, flush=True)
    with open(LOG_PATH, "a", encoding="utf-8") as f: f.write(line + "\n")

def update_memory():
    if not os.path.exists(REFLECTION_PATH):
        log("⚠️ No reflection file found.")
        return
    try:
        reflection = json.load(open(REFLECTION_PATH, encoding="utf-8"))
        memory = {}
        if os.path.exists(MEMORY_PATH):
            memory = json.load(open(MEMORY_PATH, encoding="utf-8"))
        memory["last_reflection"] = reflection
        memory["updated_at"] = datetime.datetime.now().isoformat()
        json.dump(memory, open(MEMORY_PATH, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
        log("✅ Memory updated with latest reflection.")
    except Exception as e:
        log(f"❌ Memory update failed: {e}")

if __name__ == "__main__":
    update_memory()
PY

# 2️⃣ loop_runner.py
cat << 'PY' > $BASE/loop_runner.py
#!/usr/bin/env python3
import os, subprocess, datetime

LOG_PATH = "/srv/repo/vibecoding/logs/agi_loop.log"

def log(msg):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line, flush=True)
    with open(LOG_PATH, "a", encoding="utf-8") as f: f.write(line + "\n")

def run(cmd, name):
    log(f"▶ Running {name} ...")
    try:
        subprocess.run(["python3", cmd], check=True)
        log(f"✅ {name} finished successfully.")
    except subprocess.CalledProcessError as e:
        log(f"❌ {name} failed: {e}")

if __name__ == "__main__":
    log("🚀 AGI Self-Evolution Loop started.")
    os.chdir("/srv/repo/vibecoding")
    run("reflection_engine.py", "Reflection Engine")
    run("memory_engine.py", "Memory Integration")
    log("🧠 AGI Self-Evolution Cycle Complete.")
PY

# 3️⃣ systemd service + timer
cat << 'SERVICE' > /etc/systemd/system/agi-loop.service
[Unit]
Description=RC25H AGI Self-Evolution Loop
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 /srv/repo/vibecoding/loop_runner.py
StandardOutput=append:/srv/repo/vibecoding/logs/agi_loop.log
StandardError=append:/srv/repo/vibecoding/logs/agi_loop.log
User=root

[SERVICE]
Restart=no
SERVICE

cat << 'TIMER' > /etc/systemd/system/agi-loop.timer
[Unit]
Description=Run AGI Loop every 10 minutes

[Timer]
OnBootSec=30s
OnUnitActiveSec=10min
Persistent=true

[Install]
WantedBy=timers.target
TIMER

# 4️⃣ 활성화
systemctl daemon-reload
systemctl enable agi-loop.timer
systemctl start agi-loop.timer

echo "=== RC25H AGI Auto Loop Fully Configured ==="
