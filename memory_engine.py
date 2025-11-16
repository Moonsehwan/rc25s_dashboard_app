from rc25s_openai_wrapper import rc25s_chat
from rc25_kernel_RC25S import RC25SKernel
kernel = RC25SKernel()

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
