#!/usr/bin/env python3
"""
🧾 RC25S LogRCAAgent (v0.1)

- 목적:
  - Autoheal / Self-Check / Nginx / Reflection / Executor 로그를 모아서
  - LLM에게 "로그 패턴 → 원인 규칙(rule)"과 "incident별 RCA 결과"를 JSON으로 생성하게 하고
  - world_state.log_rules / world_state.rca_history 에 저장한다.

- 특징:
  - v0.1에서는 "읽기 + 규칙/incident 기록"까지만 구현하고, 실제 자동조치와는 분리한다.
  - 규칙/incident는 나중에 Planner / Executor / Dashboard에서 재사용 가능한 형태로 남긴다.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List

from rc25s_openai_wrapper import rc25s_chat
from world_state import load_world_state, save_world_state


ROOT = Path(__file__).resolve().parent

LOG_FILES = {
    "autoheal": Path("/var/log/rc25s-autoheal.log"),
    "autoheal_ai": Path("/var/log/rc25s-autoheal-ai.log"),
    "nginx_error": Path("/var/log/nginx/error.log"),
    "reflection": ROOT / "logs" / "agi_reflection.log",
    "executor": ROOT / "logs" / "rc25s_executor.log",
}


def _tail_lines(path: Path, n: int = 200) -> List[str]:
    if not path.exists():
        return []
    try:
        return path.read_text(encoding="utf-8", errors="ignore").splitlines()[-n:]
    except Exception:
        return []


def _collect_log_snapshot() -> Dict[str, Any]:
    """
    주요 로그 파일들의 tail을 모아서 LLM에 줄 수 있는 스냅샷으로 만든다.
    """
    snapshot: Dict[str, Any] = {"logs": {}, "meta": {}}
    for name, path in LOG_FILES.items():
        snapshot["logs"][name] = _tail_lines(path, n=120)
    # world_state 일부도 같이 전달 (signals / last_actions / system)
    try:
        ws = load_world_state()
    except Exception:
        ws = {}
    snapshot["meta"]["planner_signals"] = (ws.get("planner") or {}).get("signals") or {}
    snapshot["meta"]["last_actions"] = ws.get("last_actions") or []
    snapshot["meta"]["system"] = ws.get("system") or {}
    return snapshot


def _build_prompt(snapshot: Dict[str, Any]) -> str:
    """
    LogRules / OpenRCA 스타일을 참고한 RCA 분석 프롬프트를 생성한다.
    """
    logs_json = json.dumps(snapshot, ensure_ascii=False, indent=2)
    prompt = f"""
You are RC25S LogRCAAgent.

Your job:
- Read recent system logs and signals.
- Induce rules that map log patterns to likely root causes.
- Perform root cause analysis (RCA) for recent incidents.
- Output ONLY valid JSON with the schema below.

## Input snapshot
{logs_json}

## Output JSON schema
{{
  "rules": [
    {{
      "id": "rule_nginx_404_agi",
      "pattern": "Nginx /agi/ 404 or bad status in Self-Check/Autoheal logs",
      "source": "autoheal,selfcheck,nginx_error",
      "match_examples": ["간단한 한국어/영어 예시 1-2줄"],
      "root_cause": "가장 가능성 높은 원인 설명 (한국어, 1-2문장)",
      "confidence": 0.0-1.0
    }}
  ],
  "incidents": [
    {{
      "id": "incident_2025_agi_404",
      "time_range": "대략적인 발생 시간대 (예: 2025-11-18T12:00:00Z~2025-11-18T13:00:00Z)",
      "severity": "low|medium|high|critical",
      "services": ["nginx", "dashboard", "fastapi"],
      "likely_root_cause": "요약된 원인 설명 (한국어, 1-2문장)",
      "evidence": ["어떤 로그 라인이 근거인지 간단히 인용"],
      "suggested_actions": [
        "이 incident를 줄이기 위해 어떤 액션(task)이 필요한지 간단히 나열"
      ]
    }}
  ]
}}

규칙 설명과 incident 설명은 한국어 중심으로 작성해도 된다.
단, JSON 바깥에 자연어를 추가하지 말고, 위 schema에 맞는 하나의 JSON만 출력하라.
"""
    return prompt


def _safe_parse_response(text: str) -> Dict[str, Any]:
    """
    LLM 응답을 최대한 안전하게 JSON으로 파싱한다.
    """
    if not text or not isinstance(text, str):
        return {"rules": [], "incidents": []}
    # 가장 바깥쪽 { ... } 블록만 추출
    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1 or end <= start:
        return {"rules": [], "incidents": []}
    try:
        obj = json.loads(text[start : end + 1])
        if not isinstance(obj, dict):
            return {"rules": [], "incidents": []}
        if "rules" not in obj or not isinstance(obj.get("rules"), list):
            obj["rules"] = []
        if "incidents" not in obj or not isinstance(obj.get("incidents"), list):
            obj["incidents"] = []
        return obj
    except Exception:
        return {"rules": [], "incidents": []}


def run_log_rca_agent() -> Dict[str, Any]:
    """
    LogRCAAgent 메인 엔트리:
    - 로그 스냅샷 수집 → LLM 호출 → rules/incidents 파싱 → world_state에 저장.
    """
    snapshot = _collect_log_snapshot()
    prompt = _build_prompt(snapshot)

    llm_result = rc25s_chat(prompt)
    raw = (llm_result or {}).get("response", "")
    parsed = _safe_parse_response(raw)

    rules = parsed.get("rules") or []
    incidents = parsed.get("incidents") or []

    # world_state에 반영
    ws = load_world_state()
    existing_rules: List[Dict[str, Any]] = ws.get("log_rules") or []
    existing_incidents: List[Dict[str, Any]] = ws.get("rca_history") or []

    now_iso = datetime.now(timezone.utc).isoformat()

    # rule / incident에 created_at 필드 보강
    def _ensure_created_at(items: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        out: List[Dict[str, Any]] = []
        for item in items:
            if not isinstance(item, dict):
                continue
            if "created_at" not in item:
                item["created_at"] = now_iso
            out.append(item)
        return out

    rules = _ensure_created_at(rules)
    incidents = _ensure_created_at(incidents)

    # 너무 길어지지 않도록 최근 N개만 유지
    ws["log_rules"] = (existing_rules + rules)[-100:]
    ws["rca_history"] = (existing_incidents + incidents)[-100:]

    save_world_state(ws)

    return {"rules_added": len(rules), "incidents_added": len(incidents)}


def main() -> int:
    result = run_log_rca_agent()
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


