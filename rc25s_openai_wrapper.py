import os, time, json
from pathlib import Path

import psutil
from openai import OpenAI
from rc25_kernel_RC25S import RC25SKernel

kernel = RC25SKernel()


def _get_openai_client() -> OpenAI:
    """
    항상 /etc/openai_api_key.txt 를 우선 사용해 OpenAI 클라이언트를 생성한다.
    - 순서:
      1) /etc/openai_api_key.txt가 있으면 그 값을 사용
      2) 없을 때만 환경변수 OPENAI_API_KEY 사용
    """
    api_key = None
    key_path = "/etc/openai_api_key.txt"
    if os.path.exists(key_path):
        try:
            api_key = open(key_path).read().strip()
        except Exception:
            api_key = None

    if not api_key:
        api_key = os.getenv("OPENAI_API_KEY")

    if not api_key or "$(" in str(api_key):
        raise RuntimeError("No valid OPENAI_API_KEY or /etc/openai_api_key.txt found")

    # 환경변수도 최신 값으로 맞춰 둔다 (다른 코드 호환용)
    os.environ["OPENAI_API_KEY"] = api_key
    return OpenAI(api_key=api_key)


def _load_world_state_snapshot() -> str:
    """
    world_state.json에서 LLM이 이해하기 쉬운 요약만 뽑아서 JSON 문자열로 반환한다.
    파일이 없거나 파싱에 실패해도 에러를 내지 않고 빈 객체를 돌려준다.
    """
    try:
        ws_path = Path("/srv/repo/vibecoding/world_state.json")
        if not ws_path.exists():
            return "{}"
        data = json.loads(ws_path.read_text(encoding="utf-8"))
        # 너무 장황하지 않게 핵심만 요약
        summary = {
            "updated_at": data.get("updated_at"),
            "core": data.get("core"),
            "last_reflection": data.get("reflection"),
            "planner": {
                "generated_at": (data.get("planner") or {}).get("generated_at"),
                "goals_count": len((data.get("planner") or {}).get("goals") or []),
                "tasks_count": len((data.get("planner") or {}).get("tasks") or []),
            },
        }
        return json.dumps(summary, ensure_ascii=False)
    except Exception:
        return "{}"


def _get_system_stats_summary() -> str:
    """
    현재 서버의 간단한 상태 요약을 문자열로 반환한다.
    psutil 사용이 실패해도 안전하게 빈 문자열을 돌려준다.
    """
    try:
        cpu = psutil.cpu_percent(interval=None)
        mem = psutil.virtual_memory().percent
        disk = psutil.disk_usage("/").percent
        return f"CPU={cpu}%, MEM={mem}%, DISK={disk}%"
    except Exception:
        return ""


def rc25s_chat(prompt, history=None, model="gpt-4o-mini"):
    """
    RC25S용 LLM 래퍼:
    - RC25S Kernel 메타컨트롤(mode, self_reflect)을 먼저 적용
    - world_state 스냅샷과 서버 상태 요약을 system 프롬프트에 포함
    - 항상 한국어로 답변하고, 자신을 'RC25S Self-Improvement 시스템의 LLM 모듈'로 인식하도록 안내
    """
    start = time.time()
    mode = kernel.detect_mode(prompt)
    reflection = kernel.self_reflect(prompt)
    meta_prompt = f"[MODE:{mode}] [REFLECT:{reflection}]\n{prompt}"

    world_state_json = _load_world_state_snapshot()
    system_stats = _get_system_stats_summary()

    system_message = (
        "너는 'RC25S Self-Improvement System'의 일부인 LLM 모듈이다. "
        "사용자는 이 서버의 소유자이며, 너는 RC25S의 현재 상태와 기능을 이해하고 설명하는 역할을 한다.\n"
        "\n"
        "### 현재 서버/세계 상태 스냅샷\n"
        f"- world_state 요약(JSON): {world_state_json}\n"
        f"- 서버 리소스 상태: {system_stats}\n"
        "\n"
        "### 출력 형식 (매우 중요)\n"
        "반드시 아래 JSON 형식 **한 줄**로만 답한다. 자연어 문장을 JSON 바깥에 추가하지 마라.\n"
        '{\"answer\": \"사용자에게 보여 줄 한국어 답변\", \"actions\": [{\"type\": \"run_planner\"}]} 형태이다.\n"
        "\n"
        "허용되는 action.type 값은 다음만 가능하다:\n"
        "- \"run_planner\" : rc25s_planner를 1회 실행하여 goals/tasks를 갱신\n"
        "- \"run_executor\" : Executor 1회 실행 (가장 우선순위 높은 pending task)\n"
        "- \"run_selfcheck\" : rc25s-selfcheck.sh 실행 (헬스체크/Autoheal 점검)\n"
        "- 다른 값을 넣지 말 것. 아무 것도 실행하지 않을 때는 actions를 빈 배열([])로 둔다.\n"
        "\n"
        "### 답변 규칙\n"
        "- 항상 한국어로 답변한다 (answer 필드).\n"
        "- 자신을 '일반적인 ChatGPT'가 아니라 'RC25S 시스템 내부의 LLM 컴포넌트'로 소개한다.\n"
        "- '너 AGI야?' 같은 질문에는, 완전한 자율 AGI는 아니지만 "
        "'Reflection ↔ Planner ↔ Executor 루프를 가진 자기개선 시스템의 두뇌 모듈'이라는 식으로 설명한다.\n"
        "- 서버 상태를 묻는 질문에는 world_state와 위의 서버 리소스 요약을 참고해서, "
        "현재 파악 가능한 범위 내에서 솔직하게 설명한다 (모르는 값은 모른다고 말한다).\n"
        "- RC25S가 가진 기능(리플렉션, 목표/작업 관리, 실행 프리뷰, Self-Check, 로그 확인 등)을 잘 알고 있는 엔지니어처럼 답한다.\n"
        "- 사용자의 프리텍스트 안에 'Planner 실행', 'Executor 1회 실행', 'Self-Check' 등과 같이 "
        "실제 AGI 루프 동작을 요구하는 표현이 있으면, 적절한 action들을 actions 배열에 추가한다.\n"
    )

    client = _get_openai_client()
    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": system_message},
            {"role": "user", "content": meta_prompt},
        ],
    )

    raw = response.choices[0].message.content

    # LLM이 JSON으로 잘 응답했는지 파싱 시도
    answer = raw
    actions = []
    try:
        data = json.loads(raw)
        if isinstance(data, dict):
            if isinstance(data.get("answer"), str):
                answer = data["answer"]
            if isinstance(data.get("actions"), list):
                # action 객체는 그대로 전달 (type 키만 사용)
                actions = data["actions"]
    except Exception:
        # 파싱 실패 시 raw 전체를 사용자에게 보여주고, actions는 빈 배열로 둔다.
        answer = raw
        actions = []

    elapsed = round(time.time() - start, 3)
    metrics = kernel.report_kpi()
    metrics["response_time"] = elapsed
    return {"response": answer, "actions": actions, "raw": raw, "metrics": metrics}
