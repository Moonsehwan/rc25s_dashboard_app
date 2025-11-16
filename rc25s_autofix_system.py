#!/usr/bin/env python3
# =========================================================
# RC25S AGI SYSTEM AUTO-RECOVERY SCRIPT
# Author : VibeCoding AI Core
# Created: 2025-11-16
# =========================================================
import os, subprocess, time, json
from datetime import datetime

BASE = "/srv/repo/vibecoding"
SERVICES = [
    "agi-memory.service",
    "agi-reflection.service",
    "agi-autofix.service",
    "ai-react-loop.service",
    "rc25s-dashboard.service",
    "mcp-server.service"
]

REPORT = f"{BASE}/rc25s_autofix_report.json"
BACKUP = f"{BASE}/logs/systemd_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
VENV_PY = "/srv/repo/venv/bin/python"

def run(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, text=True).strip()
    except subprocess.CalledProcessError as e:
        return e.output

def log(msg):
    print(f"🧩 {msg}")

def fix_service(service):
    unit_file = f"/etc/systemd/system/{service}"
    if not os.path.exists(unit_file):
        unit_file = f"/lib/systemd/system/{service}"
    if not os.path.exists(unit_file):
        log(f"⚠️ {service} → unit file not found, skipping")
        return

    with open(unit_file) as f:
        content = f.read()

    # 백업
    with open(BACKUP, "a") as b:
        b.write(f"\n\n===== {service} =====\n{content}\n")

    # 경로 및 환경 수정
    if "WorkingDirectory" not in content:
        content += f"\nWorkingDirectory={BASE}\n"
    if "ExecStart=" in content:
        lines = []
        for line in content.splitlines():
            if line.strip().startswith("ExecStart="):
                script_name = line.split()[-1]
                if not script_name.startswith(BASE):
                    line = f"ExecStart={VENV_PY} {BASE}/{os.path.basename(script_name)}"
            lines.append(line)
        content = "\n".join(lines)
    if "After=network-online.target" not in content:
        content += "\nAfter=network-online.target\n"

    with open(unit_file, "w") as f:
        f.write(content)

    log(f"✅ Fixed {service}")

def restart_services():
    log("♻️ Reloading systemd daemon...")
    run("systemctl daemon-reload")
    for s in SERVICES:
        run(f"systemctl restart {s}")
        time.sleep(2)
    run("systemctl reset-failed")

def check_env():
    envfile = "/etc/environment"
    changed = False
    with open(envfile, "r") as f:
        content = f.read()
    if "OPENAI_API_KEY=" not in content:
        key = input("🔑 Enter your OPENAI_API_KEY (or leave blank to skip): ").strip()
        if key:
            with open(envfile, "a") as f:
                f.write(f"\nOPENAI_API_KEY={key}\n")
            changed = True
    if changed:
        log("✅ Updated environment variables, reloading shell environment.")
        run("systemctl daemon-reexec")

def service_status():
    summary = {}
    for s in SERVICES:
        status = run(f"systemctl is-active {s}")
        summary[s] = status
        log(f"{'✅' if status=='active' else '⚠️'} {s} → {status}")
    return summary

def main():
    log("🚀 Starting RC25S System Auto-Recovery Process")
    os.makedirs(f"{BASE}/logs", exist_ok=True)
    check_env()
    for svc in SERVICES:
        fix_service(svc)
    restart_services()
    time.sleep(5)
    summary = service_status()
    with open(REPORT, "w") as f:
        json.dump(summary, f, indent=2)
    log(f"📄 Report saved → {REPORT}")
    log("✅ Auto-recovery completed successfully")

if __name__ == "__main__":
    main()
