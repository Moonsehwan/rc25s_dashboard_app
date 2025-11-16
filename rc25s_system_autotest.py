#!/usr/bin/env python3
# =========================================================
# RC25S / RC25V AGI 전체 자동 진단 스크립트
# Author : VibeCoding AI Core
# Created: 2025-11-16
# =========================================================

import os, json, requests, subprocess, time
from datetime import datetime

REPORT_FILE = "/srv/repo/vibecoding/rc25s_autotest_report.json"
TIMEOUT = 8

# 컬러 출력
class Color:
    G = "\033[92m"
    Y = "\033[93m"
    R = "\033[91m"
    B = "\033[94m"
    E = "\033[0m"

results = {}

def log(status, label, info=""):
    color = Color.G if status == "✅ OK" else Color.Y if "⚠️" in status else Color.R
    print(f"{color}[{status}] {label}{Color.E} → {info}")
    results[label] = {"status": status, "info": info}

def check_endpoint(url, name):
    import requests
    try:
        res = requests.get(url, timeout=TIMEOUT)
        if res.status_code == 200:
            log("✅ OK", name, f"{len(res.text)} bytes")
        else:
            log("⚠️ FAIL", name, f"{res.status_code} {res.text[:80]}")
    except Exception as e:
        log("❌ ERROR", name, str(e))

def check_post(url, name, payload=None):
    import requests
    try:
        res = requests.post(url, json=payload or {}, timeout=TIMEOUT)
        if res.status_code == 200:
            log("✅ OK", name, f"{len(res.text)} bytes")
        else:
            log("⚠️ FAIL", name, f"{res.status_code} {res.text[:80]}")
    except Exception as e:
        log("❌ ERROR", name, str(e))

def check_file(path, name):
    if os.path.exists(path):
        size = os.path.getsize(path)
        log("✅ OK", name, f"{size} bytes")
    else:
        log("⚠️ FAIL", name, f"File not found: {path}")

def check_service(name):
    try:
        res = subprocess.run(["systemctl", "is-active", name], capture_output=True, text=True)
        if "active" in res.stdout:
            log("✅ OK", f"Service {name}", res.stdout.strip())
        else:
            log("⚠️ FAIL", f"Service {name}", res.stdout.strip())
    except Exception as e:
        log("❌ ERROR", f"Service {name}", str(e))

def run_all():
    print("\n🧠 [RC25S] AGI SYSTEM AUTO TEST START\n")
    results["timestamp"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # FastAPI / MCP Health
    check_endpoint("http://127.0.0.1:4545/health", "FastAPI Health")
    check_post("http://127.0.0.1:4545/llm", "LLM Backend (POST)", {"prompt": "서버 상태를 요약해줘"})

    # Core Memory / Reflection / Autofix
    check_file("/srv/repo/vibecoding/memory_store/memory_vector.json", "Memory Vector")
    check_file("/srv/repo/vibecoding/memory_store/reflection.json", "Reflection Memory")
    check_file("/srv/repo/vibecoding/logs/agi_autofix.log", "Autofix Log")
    check_file("/srv/repo/vibecoding/logs/agi_reflection.log", "Reflection Log")

    # Web / Dashboard
    check_endpoint("http://127.0.0.1:4545", "Dashboard Root")
    check_endpoint("http://127.0.0.1:8000/health", "MCP Health")

    # LLM Local Models
    try:
        res = subprocess.run(["ollama", "list"], capture_output=True, text=True)
        if res.returncode == 0:
            models = [l.split()[0] for l in res.stdout.splitlines() if ":" in l]
            log("✅ OK", "Ollama Models", ", ".join(models))
        else:
            log("⚠️ FAIL", "Ollama Models", res.stderr.strip())
    except Exception as e:
        log("❌ ERROR", "Ollama Models", str(e))

    # System Services
    for svc in [
        "agi-memory.service",
        "agi-reflection.service",
        "agi-autofix.service",
        "ai-react-loop.service",
        "rc25s-dashboard.service",
        "mcp-server.service",
    ]:
        check_service(svc)

    with open(REPORT_FILE, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    passed = len([k for k,v in results.items() if "✅" in str(v)])
    total = len(results) - 1
    print(f"\n📄 Report saved → {REPORT_FILE}")
    print(f"--- SUMMARY ---\nTotal: {total}, Passed: {passed}\n")

if __name__ == "__main__":
    run_all()
