#!/usr/bin/env python3
"""
🧪 RC25S AutoTest Runner

- 목적:
  - 핵심 RC25S 파이썬 모듈들이 문법적으로 문제 없는지(컴파일 테스트)
  - 로컬 FastAPI 백엔드(대시보드)의 /health, /llm 엔드포인트가 정상 응답하는지
  를 빠르게 점검한다.

- 사용:
  cd /srv/repo/vibecoding
  rc25h_env/bin/python rc25s_autotest_runner.py
"""

from __future__ import annotations

import json
import subprocess
import sys
from dataclasses import dataclass, asdict
from typing import List

import requests


@dataclass
class TestStep:
    name: str
    passed: bool
    detail: str = ""


def run_compile_tests() -> TestStep:
    files: List[str] = [
        "RC25H_CentralCore.py",
        "rc25s_planner.py",
        "rc25s_task_executor.py",
        "rc25s_agent_backend.py",
        "rc25s_dashboard/agi_status_dashboard.py",
    ]
    cmd = [sys.executable, "-m", "py_compile", *files]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            return TestStep(name="compile_core_modules", passed=True)
        return TestStep(
            name="compile_core_modules",
            passed=False,
            detail=result.stderr.strip() or result.stdout.strip(),
        )
    except Exception as e:
        return TestStep(name="compile_core_modules", passed=False, detail=str(e))


def run_health_tests() -> TestStep:
    base = "http://127.0.0.1:4545"
    try:
        health = requests.get(f"{base}/health", timeout=5)
        llm = requests.post(
            f"{base}/llm",
            json={"prompt": "ping", "provider": "local"},
            timeout=10,
        )
        ok = health.status_code == 200 and llm.status_code < 400
        detail = f"/health={health.status_code}, /llm={llm.status_code}"
        return TestStep(name="fastapi_health_llm", passed=ok, detail=detail)
    except Exception as e:
        return TestStep(name="fastapi_health_llm", passed=False, detail=str(e))


def main() -> int:
    steps = [
        run_compile_tests(),
        run_health_tests(),
    ]
    summary = {
        "steps": [asdict(s) for s in steps],
        "all_passed": all(s.passed for s in steps),
    }
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0 if summary["all_passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())


