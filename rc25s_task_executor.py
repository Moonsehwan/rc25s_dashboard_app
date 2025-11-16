#!/usr/bin/env python3
"""
🧩 RC25S Task Executor (v0.1)

- 목적:
  - `rc25s_planner.py`가 생성한 `memory_store/rc25s_planner_state.json`을 읽고
  - status == "pending" 인 작업들 중, RC25S가 실제로 수행할 수 있는 작업을 실행한다.
  - 실행이 끝나면 해당 task를 "done" 으로 표시하고 state 파일을 갱신한다.

- v0.1에서 지원하는 작업:
  - goal_self_improvement_sync_apidog_spec
    → Apidog에 최신 OpenAPI 스펙 동기화
"""

from __future__ import annotations

import json
import subprocess
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List


ROOT = Path(__file__).resolve().parent
PLANNER_STATE_PATH = ROOT / "memory_store" / "rc25s_planner_state.json"


@dataclass
class Task:
    id: str
    goal_id: str
    title: str
    description: str
    priority: int
    status: str


def load_planner_state() -> Dict[str, Any]:
    if not PLANNER_STATE_PATH.exists():
        raise FileNotFoundError(f"Planner state not found: {PLANNER_STATE_PATH}")
    with open(PLANNER_STATE_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def save_planner_state(state: Dict[str, Any]) -> None:
    state["generated_at"] = datetime.utcnow().isoformat() + "Z"
    PLANNER_STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
    PLANNER_STATE_PATH.write_text(
        json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8"
    )


def find_pending_tasks(state: Dict[str, Any]) -> List[Task]:
    tasks_raw = state.get("tasks") or []
    tasks: List[Task] = []
    for t in tasks_raw:
        try:
            if t.get("status") != "pending":
                continue
            tasks.append(
                Task(
                    id=t["id"],
                    goal_id=t["goal_id"],
                    title=t.get("title", t["id"]),
                    description=t.get("description", ""),
                    priority=int(t.get("priority", 0)),
                    status=t.get("status", "pending"),
                )
            )
        except Exception:
            continue
    # 우선순위 높은 순서로 정렬
    tasks.sort(key=lambda x: x.priority, reverse=True)
    return tasks


def execute_task(task: Task) -> bool:
    """
    단일 task를 실행한다.
    - 성공하면 True, 실패/스킵하면 False.
    """
    # Apidog 스펙 동기화 작업
    if task.id.endswith("sync_apidog_spec"):
        script = ROOT / "rc25s_dashboard_app" / "backend" / "utils" / "apidog_sync.py"
        if not script.exists():
            print(f"⚠️ Apidog sync script not found: {script}")
            return False
        try:
            # rc25h_env 또는 venv는 systemd 단에서 활성화된 상태라고 가정하고,
            # 여기서는 단순 python3 호출만 사용한다.
            result = subprocess.run(
                ["python3", str(script)],
                capture_output=True,
                text=True,
            )
            print("📡 Apidog sync stdout:")
            print(result.stdout)
            if result.stderr:
                print("⚠️ Apidog sync stderr:")
                print(result.stderr)
            return result.returncode == 0
        except Exception as e:
            print("❌ Failed to run Apidog sync task:", e)
            return False

    # 아직 매핑이 안 된 작업은 스킵
    print(f"ℹ️ No executor mapped for task: {task.id}")
    return False


def main() -> int:
    try:
        state = load_planner_state()
    except FileNotFoundError as e:
        print(f"❌ {e}")
        return 1

    pending_tasks = find_pending_tasks(state)
    if not pending_tasks:
        print("✅ No pending tasks to execute.")
        return 0

    # 우선순위가 가장 높은 작업 하나만 처리 (v0.1)
    task = pending_tasks[0]
    print(f"🧩 Executing task: {task.id} (priority={task.priority})")

    success = execute_task(task)

    # state에서 해당 task 상태 갱신
    for t in state.get("tasks", []):
        if t.get("id") == task.id:
            t["status"] = "done" if success else t.get("status", "pending")
            t["last_executed_at"] = datetime.utcnow().isoformat() + "Z"
            t["last_result"] = "success" if success else "failed"
            break

    save_planner_state(state)
    print("📄 Planner state updated.")

    return 0 if success else 2


if __name__ == "__main__":
    raise SystemExit(main())


