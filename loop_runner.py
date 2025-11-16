#!/usr/bin/env python3
import os, subprocess, datetime
LOG_PATH = "/srv/repo/vibecoding/logs/agi_loop.log"
VENV_PYTHON = "/srv/repo/venv/bin/python3"

def log(msg):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line, flush=True)
    with open(LOG_PATH, "a", encoding="utf-8") as f: f.write(line + "\n")

def run(script, name):
    log(f"▶ Running {name} ...")
    try:
        subprocess.run([VENV_PYTHON, script], check=True)
        log(f"✅ {name} finished successfully.")
    except subprocess.CalledProcessError as e:
        log(f"❌ {name} failed: {e}")

if __name__ == "__main__":
    log("🚀 AGI Self-Evolution Loop started.")
    os.chdir("/srv/repo/vibecoding")
    run("reflection_engine.py", "Reflection Engine")
    run("memory_engine.py", "Memory Integration")
    run("agi_autofix_loop.py", "AutoFix Engine")
    log("🧠 AGI Self-Evolution Cycle Complete.")
