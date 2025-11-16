#!/usr/bin/env python3
import os, re, subprocess, time

BASE = "/srv/repo/vibecoding"
VENV = "/srv/repo/venv/bin/python"

MAP = {
    "agi-memory.service": f"{BASE}/memory_engine.py",
    "agi-reflection.service": f"{BASE}/reflection_engine.py",
    "agi-autofix.service": f"{BASE}/agi_autofix_loop.py",
    "ai-react-loop.service": f"{BASE}/ai_react_autoloop.py",
    "rc25s-dashboard.service": f"{BASE}/rc25s_dashboard/agi_status_dashboard.py",
    "mcp-server.service": f"{BASE}/agi_core/agi_status_web.py"
}

def run(cmd):
    return subprocess.getoutput(cmd)

def fix_unit(name, correct_path):
    path = f"/etc/systemd/system/{name}"
    if not os.path.exists(path):
        path = f"/lib/systemd/system/{name}"
    if not os.path.exists(path):
        print(f"⚠️  {name}: unit file not found")
        return

    text = open(path).read()
    new = re.sub(r"ExecStart=.*", f"ExecStart={VENV} {correct_path}", text)
    if text != new:
        open(path, "w").write(new)
        print(f"✅ {name} fixed → {correct_path}")
    else:
        print(f"✅ {name} already correct")

def restart_all():
    run("systemctl daemon-reload")
    for s in MAP.keys():
        run(f"systemctl restart {s}")
        time.sleep(2)
    run("systemctl reset-failed")
    print("♻️ All services restarted.\n")
    print(run("systemctl --no-pager --type=service | grep agi-"))

if __name__ == "__main__":
    print("🧩 Fixing ExecStart paths for all AGI services...")
    for name, path in MAP.items():
        fix_unit(name, path)
    restart_all()
