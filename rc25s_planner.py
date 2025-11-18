#!/usr/bin/env python3
"""
🧠 RC25S Planner Core (v0.1)

- 목적:
  - Autoheal / Self-Check / 시스템 로그를 읽어서
  - 현재 상태 요약 + 목표(goals) + 작업(tasks) + 우선순위(priorities)를 계산하고
  - JSON 파일로 저장하는 코어 모듈.

- 현재 버전 (v0.1) 특징:
  - LLM 없이 규칙 기반으로만 플래너를 구성 (안전한 MVP)
  - 나중에 LLM 통합 시, `generate_goals_from_signals` 부분에 하이브리드 로직만 추가하면 됨.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any

from world_state import update_planner, load_world_state

ROOT = Path(__file__).resolve().parent
AUTOHEAL_AI_LOG = Path("/var/log/rc25s-autoheal-ai.log")
SELF_CHECK_LOG = Path("/var/log/rc25s-autoheal.log")
PLANNER_STATE_PATH = ROOT / "memory_store" / "rc25s_planner_state.json"


@dataclass
class Goal:
  id: str
  title: str
  description: str
  priority: int  # 1~100 (높을수록 중요)
  status: str  # "active" | "completed" | "paused"


@dataclass
class Task:
  id: str
  goal_id: str
  title: str
  description: str
  priority: int  # 1~100
  status: str  # "pending" | "in_progress" | "done"


@dataclass
class PlannerState:
  generated_at: str
  signals: Dict[str, Any]
  goals: List[Goal]
  tasks: List[Task]

  def to_dict(self) -> Dict[str, Any]:
    return {
      "generated_at": self.generated_at,
      "signals": self.signals,
      "goals": [asdict(g) for g in self.goals],
      "tasks": [asdict(t) for t in self.tasks],
    }


def tail_lines(path: Path, n: int = 200) -> List[str]:
  if not path.exists():
    return []
  try:
    data = path.read_text(encoding="utf-8", errors="ignore").splitlines()
    return data[-n:]
  except Exception:
    return []


def analyze_signals() -> Dict[str, Any]:
  """Autoheal / Self-Check 로그를 기반으로 간단한 신호 요약을 만든다."""
  ai_lines = tail_lines(AUTOHEAL_AI_LOG)
  sc_lines = tail_lines(SELF_CHECK_LOG)

  # 카운트 및 최근 상태 감지
  def count_contains(lines: List[str], keyword: str) -> int:
    return sum(1 for l in lines if keyword in l)

  signals: Dict[str, Any] = {
    "autoheal_cycles": count_contains(ai_lines, "Autoheal cycle started"),
    "autoheal_rebuilds": count_contains(ai_lines, "Rebuilt and reloaded nginx"),
    "autoheal_frontend_issues": count_contains(ai_lines, "Frontend static files missing")
    + count_contains(ai_lines, "bad status"),
    "selfcheck_runs": count_contains(sc_lines, "[SELF-CHECK]"),
    "selfcheck_frontend_issues": count_contains(sc_lines, "Frontend static files missing")
    + count_contains(sc_lines, "dashboard bad status"),
    "selfcheck_manifest_warnings": count_contains(sc_lines, "Manifest not reachable"),
    "raw_preview": {
      "autoheal_tail": ai_lines[-10:],
      "selfcheck_tail": sc_lines[-10:],
    },
  }
  return signals


def generate_goals_from_signals(signals: Dict[str, Any]) -> List[Goal]:
  """규칙 기반으로 목표를 생성 (나중에 LLM 통합 여지 남김)."""
  goals: List[Goal] = []

  # 1) world_state.long_term_goals를 우선 Goal 리스트로 주입 (Step 1: Long-term goals)
  try:
    ws = load_world_state()
    lt_goals = ws.get("long_term_goals") or []
  except Exception:
    lt_goals = []

  for idx, g in enumerate(lt_goals):
    if not isinstance(g, dict):
      continue
    gid = str(g.get("id") or f"ltg_{idx}")
    title = g.get("title") or f"장기 목표 {idx + 1}"
    desc = g.get("description") or ""
    try:
      priority = int(g.get("priority") or 60)
    except Exception:
      priority = 60
    status = g.get("status") or "active"
    goals.append(
      Goal(
        id=gid,
        title=title,
        description=desc,
        priority=priority,
        status=status,
      )
    )

  frontend_issues = signals.get("autoheal_frontend_issues", 0) + signals.get("selfcheck_frontend_issues", 0)

  # 기본 목표: 서비스 안정성 유지
  goals.append(
    Goal(
      id="goal_stability",
      title="RC25S 서비스 안정성 유지",
      description="FastAPI, LLM, 프론트 대시보드(/agi/)가 오류 없이 지속적으로 응답하도록 유지한다.",
      priority=95,
      status="active",
    )
  )

  # 프론트엔드가 자주 깨질 경우, 별도 목표 생성
  if frontend_issues > 0:
    goals.append(
      Goal(
        id="goal_frontend_reliability",
        title="프론트엔드 /agi 대시보드 안정화",
        description=f"최근 로그에서 프론트엔드 관련 오류 {frontend_issues}건 감지됨. "
        f"Nginx 라우팅, Vite 빌드, SelfCheck 기준을 점검해 404/재빌드 빈도를 줄인다.",
        priority=90,
        status="active",
      )
    )

  # 향후: LLM/AGI 자율개선 목표도 추가 가능
  goals.append(
    Goal(
      id="goal_self_improvement",
      title="RC25S Self-Improvement 루프 고도화",
      description="Self-Check/Autoheal/대시보드 로그를 바탕으로 RC25S가 스스로 개선 포인트를 제안하고 실행하는 루프를 확장한다.",
      priority=70,
      status="active",
    )
  )

  return goals


def generate_tasks(goals: List[Goal], signals: Dict[str, Any]) -> List[Task]:
  tasks: List[Task] = []

  def add_task(goal_id: str, suffix: str, title: str, desc: str, priority: int):
    tasks.append(
      Task(
        id=f"{goal_id}_{suffix}",
        goal_id=goal_id,
        title=title,
        description=desc,
        priority=priority,
        status="pending",
      )
    )

  # goal_stability 관련 기본 작업들
  if any(g.id == "goal_stability" for g in goals):
    gid = "goal_stability"
    add_task(
      gid,
      "check_health_endpoints",
      "헬스 엔드포인트 정합성 점검",
      "rc25s-selfcheck.sh와 RC25S_AI_Autoheal.sh에서 사용하는 /health, /llm, /agi URL들이 실제 서비스와 일치하는지 검증한다.",
      90,
    )

  # 프론트엔드 이슈가 있을 때 작업들
  if any(g.id == "goal_frontend_reliability" for g in goals):
    gid = "goal_frontend_reliability"
    add_task(
      gid,
      "review_nginx",
      "Nginx /agi 라우팅 재점검",
      "rc25s_dashboard.conf에서 /agi location이 /srv/repo/vibecoding/dashboard/dist 를 정확히 가리키는지, "
      "try_files 설정이 Vite SPA에 적절한지 다시 확인한다.",
      85,
    )
    add_task(
      gid,
      "align_selfcheck_autoheal",
      "SelfCheck와 Autoheal 기준 완전 정렬",
      "rc25s-selfcheck.sh와 RC25S_AI_Autoheal.sh가 동일한 URL(/agi/)과 성공 기준(2xx/3xx)을 사용하도록 유지한다.",
      80,
    )

  # self-improvement 관련 작업
  if any(g.id == "goal_self_improvement" for g in goals):
    gid = "goal_self_improvement"
    add_task(
      gid,
      "expose_logs_in_dashboard",
      "대시보드에 Autoheal / Self-Check 로그 노출",
      "FastAPI에 /rc25s/logs 엔드포인트를 추가하고, Vite 대시보드에서 해당 로그를 주기적으로 읽어 카드 형태로 표시한다.",
      75,
    )
    add_task(
      gid,
      "plan_llm_integration",
      "LLM 기반 플래너 통합 설계",
      "rc25s_planner.py의 규칙 기반 플래너에 LLM을 통합하기 위한 프롬프트/안전장치/실행 정책을 설계한다.",
      60,
    )

  return tasks


def apply_reflection_to_goals(goals: List[Goal]) -> None:
  """
  world_state.reflection 내용을 읽어서 목표 우선순위를 약간 조정한다.
  - insight / improvement_goal 안의 키워드 기반으로 관련 goal priority를 +5.
  """
  try:
    ws = load_world_state()
  except Exception:
    return

  reflection = ws.get("reflection") or {}
  text = (reflection.get("insight") or "") + " " + (reflection.get("improvement_goal") or "")
  text_lower = text.lower()

  for g in goals:
    # 헬스/엔드포인트/health 관련이면 안정성 목표에 가중치
    if g.id == "goal_stability" and (
      "헬스" in text or "엔드포인트" in text or "health" in text_lower
    ):
      g.priority = min(100, g.priority + 5)

    # 프론트/대시보드/frontend 관련이면 프론트 안정화 목표에 가중치
    if g.id == "goal_frontend_reliability" and (
      "프론트" in text or "대시보드" in text or "frontend" in text_lower
    ):
      g.priority = min(100, g.priority + 5)

    # self-improvement / 자기분석 같은 키워드는 self_improvement 목표에 가중치
    if g.id == "goal_self_improvement" and (
      "self" in text_lower or "자가" in text or "self-improvement" in text_lower
    ):
      g.priority = min(100, g.priority + 5)


def run_planner() -> PlannerState:
  signals = analyze_signals()
  goals = generate_goals_from_signals(signals)
  # 최근 리플렉션 결과를 반영해 goal priority를 미세 조정
  apply_reflection_to_goals(goals)
  tasks = generate_tasks(goals, signals)
  state = PlannerState(
    generated_at=datetime.utcnow().isoformat() + "Z",
    signals=signals,
    goals=goals,
    tasks=tasks,
  )
  # world_state 및 로컬 플래너 상태 동기화
  state_dict = state.to_dict()
  update_planner(state_dict)
  PLANNER_STATE_PATH.parent.mkdir(parents=True, exist_ok=True)
  PLANNER_STATE_PATH.write_text(json.dumps(state_dict, ensure_ascii=False, indent=2), encoding="utf-8")
  return state


def main(argv: List[str]) -> int:
  state = run_planner()
  # 요약 출력
  print("🧠 RC25S Planner State")
  print(f"  generated_at: {state.generated_at}")
  print(f"  autoheal_frontend_issues: {state.signals.get('autoheal_frontend_issues')}")
  print(f"  selfcheck_frontend_issues: {state.signals.get('selfcheck_frontend_issues')}")
  print()
  print("🎯 Goals:")
  for g in state.goals:
    print(f"  - [{g.status}] ({g.priority}) {g.id}: {g.title}")
  print()
  print("🧩 Tasks:")
  for t in state.tasks:
    print(f"  - [{t.status}] ({t.priority}) {t.id}: {t.title} (goal={t.goal_id})")
  print()
  print(f"📄 State saved to: {PLANNER_STATE_PATH}")
  return 0


if __name__ == "__main__":
  raise SystemExit(main(sys.argv[1:]))
