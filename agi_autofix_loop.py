from rc25s_openai_wrapper import rc25s_chat
from rc25_kernel_RC25S import RC25SKernel
kernel = RC25SKernel()

#!/usr/bin/env python3
# =======================================================
# RC25H Hybrid Kernel | AutoFix Loop v2.0
# Reads reflection goal → proposes and applies code updates
# =======================================================
import os, json, datetime, subprocess, re, traceback
import sys; sys.path.append("/srv/repo/vibecoding")
from openai import OpenAI

BASE = "/srv/repo/vibecoding"
LOG_PATH = f"{BASE}/logs/agi_autofix.log"
REFLECTION_PATH = f"{BASE}/memory_store/reflection.json"

def log(msg):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line, flush=True)
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(line + "\n")

def run_autofix():
    log("🚀 AutoFix Loop started.")
    if not os.path.exists(REFLECTION_PATH):
        log("⚠️ No reflection.json found.")
        return
    try:
        reflection = json.load(open(REFLECTION_PATH, encoding="utf-8"))
        goal = reflection.get("improvement_goal", "")
        if not goal:
            log("⚠️ No improvement_goal found in reflection.json")
            return
        log(f"🧩 Improvement goal: {goal}")

        api_key = os.getenv("OPENAI_API_KEY") or ""
        if not api_key and os.path.exists("/etc/openai_api_key.txt"):
            api_key = open("/etc/openai_api_key.txt").read().strip()
        if not api_key:
            log("❌ No API key found.")
            return

#        client = OpenAI(api_key=api_key)
        prompt = f"""
You are an autonomous AGI AutoFix agent.
Analyze the following improvement goal and propose a minimal safe code patch (in JSON):

Goal: "{goal}"

Output JSON only:
{{
  "target_file": "filename.py",
  "change_summary": "short description",
  "code_patch": "replacement Python code"
}}
"""
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
        )
        text = getattr(response.choices[0].message, "content", "").strip()
        match = re.search(r"\{[\s\S]*\}", text)
        if not match:
            log("⚠️ No valid JSON returned.")
            return
        patch = json.loads(match.group(0))
        path = os.path.join(BASE, patch.get("target_file", ""))
        code = patch.get("code_patch", "")
        if not os.path.exists(path):
            log(f"⚠️ Target file not found: {path}")
            return
        backup = path + ".bak"
        os.system(f"cp {path} {backup}")
        open(path, "w", encoding="utf-8").write(code)
        log(f"✅ Patch applied to {path}")
        log(f"📘 Summary: {patch.get('change_summary')}")
        subprocess.run(["systemctl", "restart", "mcp-server.service"], check=False)
        log("🔁 Restarted MCP server after patch.")
    except Exception as e:
        tb = traceback.format_exc()
        log(f"❌ AutoFix failed: {e}\n{tb}")

if __name__ == "__main__":
    run_autofix()
