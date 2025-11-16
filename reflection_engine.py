from rc25s_openai_wrapper import rc25s_chat
from rc25_kernel_RC25S import RC25SKernel
kernel = RC25SKernel()

#!/usr/bin/env python3
# =======================================================
# RC25H Hybrid Kernel | Reflection Engine v3.0 (Synced)
# Unified with MCP Server Reflection Logic
# =======================================================

import os, json, datetime, re, traceback
import sys; sys.path.append("/srv/repo/vibecoding")
from openai import OpenAI

LOG_PATH = "/srv/repo/vibecoding/logs/agi_reflection.log"
MEMORY_PATH = "/srv/repo/vibecoding/memory_store/memory_vector.json"
REFLECTION_PATH = "/srv/repo/vibecoding/memory_store/reflection.json"

os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
os.makedirs(os.path.dirname(MEMORY_PATH), exist_ok=True)

def log(msg):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line, flush=True)
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(line + "\n")

def safe_parse_json(text):
    if not text or not isinstance(text, str) or len(text.strip()) == 0:
        log("⚠️ Empty GPT response detected — using fallback JSON.")
        return {
            "insight": "No reflection generated",
            "improvement_goal": "Investigate API response issue",
            "confidence": 0.0
        }
    text = re.sub(r"[\u200B-\u200D\uFEFF]", "", text)
    text = re.sub(r"```[a-zA-Z]*", "", text).replace("```", "").strip()
    match = re.search(r"\{[\s\S]*\}", text)
    if match:
        text = match.group(0).strip()
    try:
        parsed = json.loads(text)
        log("✅ JSON successfully parsed.")
        return parsed
    except json.JSONDecodeError as e:
        log(f"⚠️ JSONDecodeError: {e} | text snippet: {text[:200]}")
        return {
            "insight": "Failed to decode GPT reflection",
            "improvement_goal": "Improve parsing resilience",
            "confidence": 0.0
        }

def extract_message_content(response):
    try:
        choice = response.choices[0]
        message = getattr(choice, "message", None)
        if isinstance(message, dict):
            return message.get("content", "")
        elif hasattr(message, "content"):
            return message.content
        elif hasattr(choice, "text"):
            return choice.text
        else:
            return ""
    except Exception as e:
        log(f"⚠️ extract_message_content failed: {e}")
        return ""

def run_reflection():
    log("🚀 AGI Reflection Engine started.")
    api_key = os.getenv("OPENAI_API_KEY")
    project_id = os.getenv("OPENAI_PROJECT_ID")

    if not api_key or "$(" in api_key:
        key_path = "/etc/openai_api_key.txt"
        if os.path.exists(key_path):
            api_key = open(key_path).read().strip()
            log("✅ Loaded API key from /etc/openai_api_key.txt")
        else:
            log("❌ No valid API key found.")
            return

#    client = OpenAI(api_key=api_key, project=project_id)

    if not os.path.exists(MEMORY_PATH):
        log("⚠️ No memory file found.")
        return

    try:
        memory = json.load(open(MEMORY_PATH, encoding="utf-8"))
        log("✅ Memory loaded successfully.")
    except Exception as e:
        log(f"❌ Memory load failed: {e}")
        return

    prompt = f"""
You are an AGI Reflection Engine.
Analyze the following memory and output ONLY valid JSON.

Memory:
{json.dumps(memory, ensure_ascii=False, indent=2)}

Format:
{{
  "insight": "...",
  "improvement_goal": "...",
  "confidence": 0.0~1.0
}}
"""

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
        )
        text = extract_message_content(response)
        if not text:
            log("⚠️ GPT returned empty content. Check API key or quota.")
            return
        log(f"🧠 Raw reflection text:\n{text[:1000]}")
        reflection = safe_parse_json(text)
        with open(REFLECTION_PATH, "w", encoding="utf-8") as f:
            json.dump(reflection, f, indent=2, ensure_ascii=False)
        log("📘 Reflection saved successfully.")
        log(f"🪞 Insight: {reflection.get('insight')}")
        log(f"🎯 Goal: {reflection.get('improvement_goal')}")
        log(f"🔹 Confidence: {reflection.get('confidence')}")
    except Exception as e:
        tb = traceback.format_exc()
        log(f"❌ Reflection failed: {e}\n{tb}")

if __name__ == "__main__":
    run_reflection()
