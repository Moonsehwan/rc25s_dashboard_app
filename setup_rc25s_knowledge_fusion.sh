#!/bin/bash
set -e
echo "🧠 [RC25S] Knowledge Fusion Agent 설치 중..."

# --- 1️⃣ Python 코드 생성 ---
cat > /srv/repo/vibecoding/rc25s_knowledge_fusion.py <<'PYCODE'
import os, json, time, datetime, requests, subprocess, traceback

REFLECTION_PATH = "/srv/repo/vibecoding/memory_store/reflection.json"
MEMORY_PATH = "/srv/repo/vibecoding/memory_store/memory_vector.json"
LOG_PATH = "/srv/repo/vibecoding/logs/knowledge_fusion.log"
SRC_PATH = "/srv/repo/vibecoding"

def log(msg):
    t = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[🧠Fusion {t}] {msg}")
    with open(LOG_PATH, "a") as f:
        f.write(f"[{t}] {msg}\n")

def call_llm(prompt):
    try:
        r = requests.post("http://127.0.0.1:4545/llm", json={"prompt": prompt}, timeout=180)
        return r.json().get("output", "")
    except Exception as e:
        return f"❌ LLM 호출 실패: {e}"

def fuse_knowledge():
    try:
        # 1️⃣ 최신 reflection 불러오기
        if not os.path.exists(REFLECTION_PATH):
            log("⚠️ reflection.json 없음 — 건너뜀.")
            return
        with open(REFLECTION_PATH, "r") as f:
            reflection = json.load(f)
        ref_text = reflection.get("reflection", "")

        # 2️⃣ 웹검색 요약 내용 감지
        if "검색 결과 요약:" not in ref_text:
            log("🔎 검색 결과 없음 — 대기.")
            return

        # 3️⃣ memory_vector.json 불러오기
        if os.path.exists(MEMORY_PATH):
            with open(MEMORY_PATH, "r") as f:
                memory = json.load(f)
        else:
            memory = []

        # 4️⃣ LLM에 코드개선 요청
        prompt = f"""
다음은 RC25S AGI 시스템의 최근 검색 결과 및 내부 기억입니다.
이 정보를 기반으로 코드 품질, 보안, 효율성 개선 아이디어를 제안하고 
필요한 Python 코드 조각을 출력하세요.

검색 및 기억:
{ref_text[:10000]}

출력 형식:
- 개선 요약
- 적용 가능한 코드 (전체 코드 또는 함수 단위)
"""
        result = call_llm(prompt)

        # 5️⃣ 결과 저장
        ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        output_path = f"/srv/repo/vibecoding/knowledge_fusion_output_{ts}.txt"
        with open(output_path, "w") as f:
            f.write(result)
        log(f"✅ 지식 융합 결과 저장: {output_path}")

        # 6️⃣ 결과 요약을 memory_vector에 기록
        memory.append({
            "time": datetime.datetime.now().isoformat(),
            "event": "knowledge_fusion",
            "summary": result[:2000]
        })
        with open(MEMORY_PATH, "w") as f:
            json.dump(memory[-200:], f, indent=2)

    except Exception as e:
        log(f"❌ 오류: {traceback.format_exc()}")

def main():
    log("🚀 Knowledge Fusion Agent 시작.")
    while True:
        fuse_knowledge()
        log("💤 다음 사이클까지 30분 대기...")
        time.sleep(1800)
PYCODE

chmod +x /srv/repo/vibecoding/rc25s_knowledge_fusion.py

# --- 2️⃣ systemd 등록 ---
cat > /etc/systemd/system/rc25s-knowledge-fusion.service <<'UNIT'
[Unit]
Description=RC25S Knowledge Fusion Agent (지식 융합 루프)
After=rc25s-websearch.service

[Service]
ExecStart=/srv/repo/vibecoding/rc25h_env/bin/python /srv/repo/vibecoding/rc25s_knowledge_fusion.py
Restart=always
RestartSec=15

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable rc25s-knowledge-fusion.service
systemctl restart rc25s-knowledge-fusion.service

echo "✅ RC25S Knowledge Fusion Agent 설치 및 실행 완료."
