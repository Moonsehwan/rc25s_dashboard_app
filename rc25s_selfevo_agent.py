import os, time, json, psutil, subprocess, datetime, requests

LOG_PATH = "/srv/repo/vibecoding/logs/selfevo_agent.log"
MEMORY_FILE = "/srv/repo/vibecoding/memory_store/memory_vector.json"
REFLECTION_FILE = "/srv/repo/vibecoding/memory_store/reflection.json"

def log(msg):
    t = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_PATH, "a") as f:
        f.write(f"[{t}] {msg}\n")
    print(f"🧩 {msg}")

def get_system_status():
    return {
        "cpu": psutil.cpu_percent(interval=1),
        "mem": psutil.virtual_memory().percent,
        "time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }

def get_service_status(name):
    try:
        res = subprocess.run(["systemctl", "is-active", name], capture_output=True, text=True)
        return res.stdout.strip()
    except Exception:
        return "unknown"

def save_memory(event, data):
    try:
        existing = []
        if os.path.exists(MEMORY_FILE):
            with open(MEMORY_FILE, "r") as f:
                existing = json.load(f)
        existing.append({"time": datetime.datetime.now().isoformat(), "event": event, "data": data})
        with open(MEMORY_FILE, "w") as f:
            json.dump(existing[-100:], f, indent=2)
    except Exception as e:
        log(f"❌ Memory 저장 실패: {e}")

def call_llm(prompt):
    try:
        res = requests.post("http://127.0.0.1:4545/llm", json={"prompt": prompt}, timeout=60)
        return res.json().get("output", "")
    except Exception as e:
        return f"❌ LLM 호출 실패: {e}"

def auto_fix_check():
    bad = []
    for svc in ["agi-memory.service", "agi-reflection.service", "agi-autofix.service"]:
        if get_service_status(svc) != "active":
            bad.append(svc)
    if bad:
        log(f"⚠️ 비활성 서비스 감지: {bad}")
        fix_code = call_llm(f"서비스 {bad} 가 비활성 상태야. 재시작 코드나 원인 분석해줘.")
        log(f"💡 LLM 제안: {fix_code}")
        save_memory("auto_fix", {"services": bad, "suggestion": fix_code})
        for svc in bad:
            subprocess.run(["systemctl", "restart", svc])
        log("🔁 서비스 재시작 완료.")

def reflection_cycle():
    summary = call_llm("최근 로그와 상태를 기반으로 AGI 자기성찰 보고서를 만들어줘.")
    with open(REFLECTION_FILE, "w") as f:
        json.dump({"time": datetime.datetime.now().isoformat(), "reflection": summary}, f, indent=2)
    log("🧠 자기성찰 저장 완료.")

def main():
    log("🚀 RC25S Self-Evo Agent 시작.")
    while True:
        status = get_system_status()
        save_memory("status", status)
        auto_fix_check()
        if datetime.datetime.now().minute % 10 == 0:
            reflection_cycle()
        time.sleep(60)

if __name__ == "__main__":
    main()
