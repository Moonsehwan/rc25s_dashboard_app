import os, subprocess, time, json, datetime
import sys; sys.path.append("/srv/repo/vibecoding")

BASE = "/srv/repo/vibecoding"
LOG = f"{BASE}/logs/selfevo_bridge.log"
REF_FILE = f"{BASE}/memory_store/reflection.json"

def log(msg):
    with open(LOG, "a") as f:
        f.write(f"[{datetime.datetime.now():%Y-%m-%d %H:%M:%S}] {msg}\n")
    print(msg)

def run(cmd):
    subprocess.run(cmd, shell=True, check=False, env={**os.environ, "PYTHONPATH": "/srv/repo"})

def main():
    log("🚀 Reflection-Autofix Bridge started.")
    last_mod = None
    while True:
        if os.path.exists(REF_FILE):
            mod = os.path.getmtime(REF_FILE)
            if last_mod != mod:
                last_mod = mod
                log("🪞 Detected new reflection output.")
                log("🔧 Triggering AGI AutoFix...")
                run(f"{BASE}/rc25h_env/bin/python -m vibecoding.agi_autofix_loop >> {LOG} 2>&1")
                log("✅ AutoFix executed after reflection.")
        time.sleep(300)  # 5분마다 감시
if __name__ == "__main__":
    main()
