#!/bin/bash
set -e

echo "🌐 [RC25S] WebSearch Agent 설치 중..."

# --- 1️⃣ Python 모듈 설치 ---
/srv/repo/vibecoding/rc25h_env/bin/pip install requests beautifulsoup4 duckduckgo-search google-search-results wikipedia > /dev/null 2>&1

# --- 2️⃣ WebSearch Agent 생성 ---
cat > /srv/repo/vibecoding/rc25s_websearch_agent.py <<'PYCODE'
import json, time, datetime, requests, traceback
from duckduckgo_search import DDGS

LOG_PATH = "/srv/repo/vibecoding/logs/websearch_agent.log"
REFLECTION_PATH = "/srv/repo/vibecoding/memory_store/reflection.json"

def log(msg):
    t = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_PATH, "a") as f:
        f.write(f"[{t}] {msg}\n")
    print(f"🌐 {msg}")

def search_web(query):
    try:
        log(f"🔍 검색 요청: {query}")
        results = []
        with DDGS() as ddgs:
            for r in ddgs.text(query, max_results=5):
                results.append({"title": r.get("title"), "href": r.get("href"), "body": r.get("body")})
        return results
    except Exception as e:
        log(f"❌ 검색 오류: {e}")
        return []

def summarize_results(results):
    summary = "\n".join([f"- {r['title']}: {r['href']}" for r in results])
    return f"검색 결과 요약:\n{summary}"

def main_loop():
    log("🚀 WebSearch Agent 시작.")
    while True:
        try:
            with open(REFLECTION_PATH, "r") as f:
                reflection = json.load(f)
            latest_ref = reflection.get("reflection", "")
            if "검색" in latest_ref or "찾아봐" in latest_ref or "reference" in latest_ref.lower():
                query = latest_ref.split("검색")[-1].strip()[:100]
                results = search_web(query)
                summary = summarize_results(results)
                with open(REFLECTION_PATH, "w") as f:
                    json.dump({"time": datetime.datetime.now().isoformat(), "reflection": summary}, f, indent=2)
                log(f"🧠 검색 결과 저장 완료 ({len(results)}건)")
        except Exception:
            log(traceback.format_exc())
        time.sleep(600)  # 10분 간격
PYCODE

chmod +x /srv/repo/vibecoding/rc25s_websearch_agent.py

# --- 3️⃣ systemd 등록 ---
cat > /etc/systemd/system/rc25s-websearch.service <<'UNIT'
[Unit]
Description=RC25S WebSearch Agent
After=rc25s-selfevo.service

[Service]
ExecStart=/srv/repo/vibecoding/rc25h_env/bin/python /srv/repo/vibecoding/rc25s_websearch_agent.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable rc25s-websearch.service
systemctl restart rc25s-websearch.service

echo "✅ WebSearch Agent 설치 및 실행 완료."
