#!/usr/bin/env python3
"""
🌐 RC25S World State Core

RC25S 전체 시스템이 공유하는 단일 상태 파일을 관리한다.

- 파일 경로: /srv/repo/vibecoding/world_state.json
- 주요 섹션:
  - core: 중앙 루프(결정 기록 등)
  - reflection: 최근 reflection.json 내용
  - memory: 최근 memory_vector.json 내용
  - planner: rc25s_planner 상태(goals/tasks/signals)
  - last_actions: 최근 실행된 액션(Task) 기록
  - system: 기타 헬스/버전 정보
"""

from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List


ROOT = Path(__file__).resolve().parent
STATE_PATH = ROOT / "world_state.json"


def _now_iso() -> str:
    return datetime.utcnow().isoformat() + "Z"


def _default_state() -> Dict[str, Any]:
    return {
        "updated_at": _now_iso(),
        "core": {
            "last_decision": None,
            "last_decision_time": None,
        },
        "reflection": {},
        "memory": [],
        "planner": {
            "generated_at": None,
            "signals": {},
            "goals": [],
            "tasks": [],
        },
        "last_actions": [],  # [{id, goal_id, title, status, result, time}]
        "system": {},
    }


def load_world_state() -> Dict[str, Any]:
    if not STATE_PATH.exists():
        return _default_state()
    try:
        data = json.loads(STATE_PATH.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            return _default_state()
        return data
    except Exception:
        return _default_state()


def save_world_state(state: Dict[str, Any]) -> None:
    state["updated_at"] = _now_iso()
    STATE_PATH.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")


def update_reflection_memory(reflection: Any, memory: Any) -> None:
    """reflection.json / memory_vector.json 내용을 world_state에 반영."""
    state = load_world_state()
    state["reflection"] = reflection or {}
    state["memory"] = memory or []
    save_world_state(state)


def update_core_decision(decision: str) -> None:
    """중앙 코어의 최근 결정 기록."""
    state = load_world_state()
    core = state.get("core") or {}
    core["last_decision"] = decision
    core["last_decision_time"] = _now_iso()
    state["core"] = core
    save_world_state(state)


def update_planner(planner_state: Dict[str, Any]) -> None:
    """rc25s_planner 상태를 world_state.planner에 반영."""
    state = load_world_state()
    state["planner"] = {
        "generated_at": planner_state.get("generated_at"),
        "signals": planner_state.get("signals") or {},
        "goals": planner_state.get("goals") or [],
        "tasks": planner_state.get("tasks") or [],
    }
    save_world_state(state)


def append_action_log(action: Dict[str, Any]) -> None:
    """
    최근 실행된 액션(Task)를 world_state.last_actions에 추가.
    action 예시:
      {
        "id": "...",
        "goal_id": "...",
        "title": "...",
        "status": "done|failed",
        "result": "success|failed",
        "time": iso8601,
      }
    """
    state = load_world_state()
    actions: List[Dict[str, Any]] = state.get("last_actions") or []
    actions.append(action)
    # 너무 길어지지 않도록 최근 50개만 유지
    state["last_actions"] = actions[-50:]
    save_world_state(state)


