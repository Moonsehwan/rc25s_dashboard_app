#!/usr/bin/env python3
import requests, json, os, sys

CURSOR_API = os.getenv("CURSOR_API", "https://api.cursor.sh/composer")
API_KEY = os.getenv("CURSOR_API_KEY")
PROMPT = " ".join(sys.argv[1:]) or "Generate optimized backend code for FastAPI."

def run_cursor(prompt: str):
    try:
        res = requests.post(
            CURSOR_API,
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json={"prompt": prompt}
        )
        if res.status_code != 200:
            print(f"❌ Cursor API Error: {res.status_code}")
            return None
        data = res.json()
        print("🧠 Cursor Composer Output:")
        print(json.dumps(data, indent=2))
        return data
    except Exception as e:
        print("⚠️ Cursor call failed:", e)
        return None

if __name__ == "__main__":
    run_cursor(PROMPT)
