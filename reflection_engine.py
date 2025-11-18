from rc25s_openai_wrapper import rc25s_chat

#!/usr/bin/env python3
# =======================================================
# RC25H Hybrid Kernel | Reflection Engine v3.x
# - rc25s_openai_wrapper 기반 하이브리드 LLM 호출
# - world_state와 연동하여 자기평가 결과를 공유 상태에 반영
# =======================================================

import os
import json
import datetime
import re
import traceback
import sys

sys.path.append("/srv/repo/vibecoding")

from world_state import load_world_state, update_reflection_memory


LOG_PATH = "/srv/repo/vibecoding/logs/agi_reflection.log"
MEMORY_PATH = "/srv/repo/vibecoding/memory_store/memory_vector.json"
REFLECTION_PATH = "/srv/repo/vibecoding/memory_store/reflection.json"

os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
os.makedirs(os.path.dirname(MEMORY_PATH), exist_ok=True)


def log(msg: str) -> None:
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line, flush=True)
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def safe_parse_json(text: str) -> dict:
    """LLM 응답을 최대한 안전하게 JSON으로 파싱."""
    if not text or not isinstance(text, str) or len(text.strip()) == 0:
        log("⚠️ Empty LLM response detected — using fallback JSON.")
        return {
            "insight": "No reflection generated",
            "improvement_goal": "Investigate API response issue",
            "confidence": 0.0,
            "long_term_goals": [],
            "weekly_summary": {},
            "failures_learned": [],
        }
    text = re.sub(r"[\u200B-\u200D\uFEFF]", "", text)
    text = re.sub(r"```[a-zA-Z]*", "", text).replace("```", "").strip()
    match = re.search(r"\{[\s\S]*\}", text)
    if match:
        text = match.group(0).strip()
    try:
        parsed = json.loads(text)
        log("✅ JSON successfully parsed.")
        # 누락된 필드는 기본값으로 채워서 world_state와의 호환성을 유지
        if "long_term_goals" not in parsed:
            parsed["long_term_goals"] = []
        if "weekly_summary" not in parsed:
            parsed["weekly_summary"] = {}
        if "failures_learned" not in parsed:
            parsed["failures_learned"] = []
        return parsed
    except json.JSONDecodeError as e:
        log(f"⚠️ JSONDecodeError: {e} | text snippet: {text[:200]}")
        return {
            "insight": "Failed to decode LLM reflection",
            "improvement_goal": "Improve parsing resilience",
            "confidence": 0.0,
            "long_term_goals": [],
            "weekly_summary": {},
            "failures_learned": [],
        }


def run_reflection() -> None:
    """
    - memory_vector.json + world_state(planner/last_actions)를 읽어서
    - rc25s_chat(하이브리드 LLM)을 통해 자기 평가를 수행하고
    - reflection.json 및 world_state.reflection에 반영한다.
    """
    log("🚀 AGI Reflection Engine started.")

    # OPENAI_API_KEY 없으면 /etc/openai_api_key.txt에서 한 번 더 시도
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key or "$(" in api_key:
        key_path = "/etc/openai_api_key.txt"
        if os.path.exists(key_path):
            api_key = open(key_path).read().strip()
            os.environ["OPENAI_API_KEY"] = api_key
            log("✅ Loaded API key from /etc/openai_api_key.txt")
        else:
            log("❌ No valid API key found for rc25s_chat.")
            return

    if not os.path.exists(MEMORY_PATH):
        log("⚠️ No memory file found.")
        return

    try:
        memory = json.load(open(MEMORY_PATH, encoding="utf-8"))
        log("✅ Memory loaded successfully.")
    except Exception as e:
        log(f"❌ Memory load failed: {e}")
        return

    # world_state에서 planner / last_actions 가져오기 (프롬프트 강화용)
    try:
        ws = load_world_state()
    except Exception as e:
        log(f"⚠️ load_world_state failed: {e}")
        ws = {}

    planner = ws.get("planner") or {}
    last_actions = ws.get("last_actions") or []

    prompt = f"""
You are the RC25S AGI Reflection Engine.
Analyze the following memory and world state, then output ONLY valid JSON.

## Memory (long-term/context)
{json.dumps(memory, ensure_ascii=False, indent=2)}

## Planner state (goals/tasks/signals)
{json.dumps(planner, ensure_ascii=False, indent=2)}

## Recent actions
{json.dumps(last_actions, ensure_ascii=False, indent=2)}

Return JSON with the following structure (Korean is allowed/preferred in text fields):
{{
  "insight": "short Korean summary of current system situation",
  "improvement_goal": "1-2 concrete next improvement directions (Korean allowed)",
  "confidence": 0.0-1.0,
  "long_term_goals": [
    {{
      "id": "ltg_2025_agi",
      "title": "장기적인 시스템 개선 목표 (예: RC25S AGI 상용 수준 안정화)",
      "description": "이 목표가 왜 중요한지, 어떤 방향으로 개선해야 하는지에 대한 짧은 설명 (한국어 가능)",
      "horizon": "3-6 months",
      "priority": 0-100,
      "status": "active|paused|completed"
    }}
  ],
  "weekly_summary": {{
    "week_of": "YYYY-MM-DD (이번 주 시작 날짜)",
    "summary": "이번 주에 RC25S 시스템이 어떤 변화/개선을 했는지 한 줄 요약 (한국어)",
    "key_wins": ["주요 성공 1", "주요 성공 2"],
    "key_issues": ["문제/장애 1", "문제/장애 2"]
  }},
  "failures_learned": [
    {{
      "time": "ISO8601 datetime (예: 2025-11-18T12:34:56Z)",
      "context": "어떤 상황/기능에서 실패가 발생했는지",
      "root_cause": "추정되는 근본 원인 (간단히)",
      "lesson": "다음에 같은 문제가 안 나도록 배우게 된 교훈 (한국어)"
    }}
  ]
}}
"""

    try:
        llm_result = rc25s_chat(prompt)
        text = (llm_result or {}).get("response", "")
        if not text:
            log("⚠️ LLM returned empty content. Check API key or server.")
            return

        log(f"🧠 Raw reflection text:\n{text[:1000]}")
        reflection = safe_parse_json(text)

        # 파일로 저장
        with open(REFLECTION_PATH, "w", encoding="utf-8") as f:
            json.dump(reflection, f, indent=2, ensure_ascii=False)
        log("📘 Reflection saved successfully.")
        log(f"🪞 Insight: {reflection.get('insight')}")
        log(f"🎯 Goal: {reflection.get('improvement_goal')}")
        log(f"🔹 Confidence: {reflection.get('confidence')}")

        # world_state에도 반영 (memory와 함께)
        try:
            update_reflection_memory(reflection, memory)
        except Exception as e:
            log(f"⚠️ update_reflection_memory failed: {e}")
    except Exception as e:
        tb = traceback.format_exc()
        log(f"❌ Reflection failed: {e}\n{tb}")


if __name__ == "__main__":
    run_reflection()
