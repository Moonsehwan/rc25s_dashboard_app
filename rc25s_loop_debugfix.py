#!/usr/bin/env python3
import os, json, subprocess, time

BASE = "/srv/repo/vibecoding"
STORE = f"{BASE}/memory_store"

def ensure_memory_store():
    os.makedirs(STORE, exist_ok=True)
    for name in ["memory_vector.json", "reflection.json"]:
        path = f"{STORE}/{name}"
        if not os.path.exists(path):
            open(path, "w").write("{}")
            print(f"✅ Created missing file: {path}")
        else:
            try:
                json.load(open(path))
            except Exception:
                open(path, "w").write("{}")
                print(f"⚠️ Reset corrupted file: {path}")

def ensure_pythonpath():
    envfile = "/etc/environment"
    content = open(envfile).read()
    if "PYTHONPATH=" not in content:
        with open(envfile, "a") as f:
            f.write("\nPYTHONPATH=/srv/repo\n")
        print("✅ Added PYTHONPATH to /etc/environment")
        os.environ["PYTHONPATH"] = "/srv/repo"
    else:
        os.environ["PYTHONPATH"] = "/srv/repo"

def restart_loops():
    for svc in ["agi-memory.service", "agi-reflection.service", "agi-autofix.service"]:
        subprocess.run(["systemctl", "restart", svc])
        time.sleep(2)
    print("♻️ Restarted AGI loop services")

if __name__ == "__main__":
    print("🧩 Running RC25S loop integrity fix...")
    ensure_memory_store()
    ensure_pythonpath()
    restart_loops()
    time.sleep(3)
    print(subprocess.getoutput("systemctl status agi-memory.service agi-reflection.service agi-autofix.service | grep Active"))
