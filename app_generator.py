#!/usr/bin/env python3
"""
RC25H Hybrid Kernel | AGI App Generator v1.0
Generates and deploys full-stack applications (FastAPI + React)
"""
import os, json, subprocess, datetime
from openai import OpenAI

BASE = "/srv/repo/vibecoding"
GEN_PATH = f"{BASE}/generated_apps"
LOG_PATH = f"{BASE}/logs/agi_appgen.log"

os.makedirs(GEN_PATH, exist_ok=True)
os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)

def log(msg):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line, flush=True)
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(line + "\n")

def generate_app(app_name, description=""):
    log(f"🚀 App generation requested: {app_name}")
    api_key = os.getenv("OPENAI_API_KEY") or ""
    if not api_key and os.path.exists("/etc/openai_api_key.txt"):
        api_key = open("/etc/openai_api_key.txt").read().strip()
    if not api_key:
        log("❌ No API key found.")
        return {"error": "No API key"}

    client = OpenAI(api_key=api_key)
    prompt = f"""
You are an autonomous AGI App Builder.
Build a complete production-ready FastAPI + React app based on the following idea:
Name: {app_name}
Description: {description}

Respond with a JSON structure:
{{
  "backend_code": "FastAPI backend Python code (as a string)",
  "frontend_code": "React code (as a string)",
  "summary": "short overview of the app"
}}
"""
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
    )
    content = response.choices[0].message.content
    start = content.find("{")
    end = content.rfind("}")
    if start == -1 or end == -1:
        log("⚠️ Could not parse JSON from GPT output.")
        return
    result = json.loads(content[start:end+1])
    app_dir = os.path.join(GEN_PATH, app_name.replace(" ", "_"))
    os.makedirs(app_dir, exist_ok=True)
    backend_path = os.path.join(app_dir, "backend.py")
    frontend_path = os.path.join(app_dir, "frontend.jsx")
    with open(backend_path, "w", encoding="utf-8") as f:
        f.write(result["backend_code"])
    with open(frontend_path, "w", encoding="utf-8") as f:
        f.write(result["frontend_code"])
    log(f"✅ App generated at {app_dir}")
    log(f"📘 Summary: {result.get('summary', '')}")
    return result

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python3 app_generator.py 'App Name' [description]")
    else:
        name = sys.argv[1]
        desc = sys.argv[2] if len(sys.argv) > 2 else ""
        generate_app(name, desc)
