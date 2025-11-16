#!/usr/bin/env python3
import os, requests, json

APIDOG_KEY = os.getenv("APIDOG_API_KEY")
APIDOG_URL = "https://api.apidog.com/v1/api-docs/sync"

def sync_apidog():
    if not APIDOG_KEY:
        print("⚠️ Missing Apidog API key.")
        return
    payload = {"project": "RC25S", "description": "Cursor-Generated API sync"}
    headers = {"Authorization": f"Bearer {APIDOG_KEY}", "Content-Type": "application/json"}
    try:
        res = requests.post(APIDOG_URL, headers=headers, json=payload)
        print(f"📡 Apidog Sync Status: {res.status_code}")
        print(res.text)
    except Exception as e:
        print("❌ Apidog sync failed:", e)

if __name__ == "__main__":
    sync_apidog()
