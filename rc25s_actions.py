"""
RC25S Action Metadata

- 각 Task(id)에 대한 위험 등급 / 설명 / 테스트 전략 등을 정의한다.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class ActionMeta:
    id: str
    risk: str  # "L0" | "L1" | "L2"
    description: str
    post_tests: bool = False  # 실행 후 자동 테스트 여부


ACTIONS = {
    "goal_stability_check_health_endpoints": ActionMeta(
        id="goal_stability_check_health_endpoints",
        risk="L1",
        description="FastAPI /health, /llm 엔드포인트 헬스 검사",
        post_tests=False,
    ),
    "goal_frontend_reliability_review_nginx": ActionMeta(
        id="goal_frontend_reliability_review_nginx",
        risk="L2",
        description="RC25S 대시보드용 Nginx /agi 라우팅 복구 스크립트 실행",
        post_tests=True,
    ),
    "goal_frontend_reliability_align_selfcheck_autoheal": ActionMeta(
        id="goal_frontend_reliability_align_selfcheck_autoheal",
        risk="L2",
        description="SelfCheck 및 Autoheal 스크립트를 실행하여 기준을 정렬",
        post_tests=True,
    ),
    "goal_self_improvement_sync_apidog_spec": ActionMeta(
        id="goal_self_improvement_sync_apidog_spec",
        risk="L1",
        description="Apidog에 최신 OpenAPI 스펙 동기화",
        post_tests=True,
    ),
}


