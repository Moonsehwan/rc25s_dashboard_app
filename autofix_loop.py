"""
호환용 AutoFix 루프 래퍼.

RC25H_CentralCore 및 기존 스크립트가 기대하는 `from autofix_loop import auto_fix`
형태를 유지하기 위해, 실제 구현이 들어있는 `agi_autofix_loop.run_autofix`
를 감싸는 thin wrapper를 제공한다.
"""

from agi_autofix_loop import run_autofix


def auto_fix():
    """RC25H_CentralCore에서 호출하는 엔트리포인트."""
    return run_autofix()


