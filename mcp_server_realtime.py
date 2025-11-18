from fastapi import FastAPI, WebSocket, Request
from fastapi.responses import JSONResponse
import json
import datetime
import asyncio
import psutil
import subprocess
import socket
import os
from pathlib import Path

from world_state import load_world_state
from rc25s_planner import run_planner, PLANNER_STATE_PATH
from rc25s_task_executor import main as run_executor
from rc25s_openai_wrapper import rc25s_chat

app = FastAPI(title="MCP Realtime API", version="2.0.0")

# 연결된 클라이언트 저장용 (필요 시 broadcast 가능)
connected_clients = set()


@app.get("/")
async def root():
    return {"status": "ok", "message": "MCP Server is running"}


@app.get("/health")
def health():
    return JSONResponse(
        {
            "status": "ok",
            "message": "RC25S MCP Realtime API active",
            "server": socket.gethostname(),
            "time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        }
    )


@app.get("/rc25s/logs")
def get_rc25s_logs():
    """
    RC25S 관련 주요 로그들을 tail 해서 JSON으로 반환한다.
    - Autoheal, Self-Check, Reflection, Executor 로그 등을 모아서
      대시보드에서 한 번에 볼 수 있도록 한다.
    """
    log_files = {
        "autoheal": "/var/log/rc25s-autoheal.log",
        "autoheal_ai": "/var/log/rc25s-autoheal-ai.log",
        "centralcore": "/srv/repo/vibecoding/logs/centralcore.log",
        "reflection": "/srv/repo/vibecoding/logs/agi_reflection.log",
        "executor": "/srv/repo/vibecoding/logs/rc25s_executor.log",
    }
    logs = {}
    for name, path in log_files.items():
        try:
            if os.path.exists(path):
                # tail -n 40 정도만 보여준다.
                logs[name] = subprocess.getoutput(f"tail -n 40 {path}")
            else:
                logs[name] = f"Log file not found: {path}"
        except Exception as e:
            logs[name] = f"Failed to read log {path}: {e}"
    return JSONResponse(logs)


@app.post("/llm")
async def http_llm(request: Request):
    """
    HTTP 기반 LLM 엔드포인트.
    - 대시보드 프리 텍스트 입력이 이 경로로 POST를 보내며,
    - rc25s_openai_wrapper.rc25s_chat 을 사용해 답변을 생성한다.
    """
    body = await request.json()
    prompt = (body.get("prompt") or "").strip()
    if not prompt:
        return JSONResponse(
            {"error": "empty_prompt", "message": "프롬프트가 비어 있습니다."}, status_code=400
        )
    try:
        result = rc25s_chat(prompt)
        text = (result or {}).get("response") or ""
        return JSONResponse({"provider": "rc25s_openai", "output": text})
    except Exception as e:
        return JSONResponse(
            {"error": "llm_error", "message": str(e)}, status_code=500
        )


async def _run_executor_once() -> int:
    """
    rc25s_task_executor.main() 을 1회 실행하고 exit code를 정수로 반환.
    SystemExit 예외도 안전하게 처리한다.
    """

    def _inner():
        try:
            return run_executor()
        except SystemExit as se:
            return se.code if isinstance(se.code, int) else 0

    return await asyncio.to_thread(_inner)


async def _apply_llm_actions(actions, websocket: WebSocket):
    """
    rc25s_openai_wrapper 가 반환한 actions 배열을 해석해서
    실제 RC25S Planner / Executor / Self-Check 를 실행한다.
    """
    if not actions:
        return

    for action in actions:
        atype = (action or {}).get("type")
        if atype == "run_planner":
            await websocket.send_json(
                {"type": "event", "message": "🧠 LLM 요청: Planner 실행"}
            )
            await asyncio.to_thread(run_planner)
        elif atype == "run_executor":
            await websocket.send_json(
                {"type": "event", "message": "🧩 LLM 요청: Executor 1회 실행"}
            )
            exit_code = await _run_executor_once()
            await websocket.send_json(
                {
                    "type": "event",
                    "message": f"🧩 Executor 실행 종료 (exit_code={exit_code})",
                }
            )
        elif atype == "run_selfcheck":
            script = "/srv/repo/vibecoding/rc25s-selfcheck.sh"
            await websocket.send_json(
                {"type": "event", "message": "🩺 LLM 요청: Self-Check 실행"}
            )
            try:
                result = await asyncio.to_thread(
                    subprocess.run,
                    ["bash", script],
                    capture_output=True,
                    text=True,
                )
                await websocket.send_json(
                    {
                        "type": "event",
                        "message": "🩺 Self-Check 스크립트 실행 완료",
                        "stdout": result.stdout[-800:],
                        "stderr": result.stderr[-800:],
                        "returncode": result.returncode,
                    }
                )
            except Exception as e:
                await websocket.send_json(
                    {
                        "type": "error",
                        "message": f"Self-Check 실행 실패: {e}",
                    }
                )

    # 액션 실행 후 최신 world_state를 한 번 내려준다.
    try:
        state = load_world_state()
        await websocket.send_json(
            {
                "type": "world_state",
                "world_state": state,
                "timestamp": state.get("updated_at"),
            }
        )
    except Exception as e:
        await websocket.send_json(
            {"type": "error", "message": f"world_state 갱신 로드 실패: {e}"}
        )


@app.websocket("/ws/agi")
async def agi_ws(websocket: WebSocket):
    await websocket.accept()
    connected_clients.add(websocket)
    print("🔌 WebSocket client connected")

    try:
        while True:
            # 클라이언트 메시지 수신
            data = await websocket.receive_text()
            print(f"📩 Received: {data}")

            # JSON 파싱 시도
            try:
                payload = json.loads(data)
            except Exception:
                await websocket.send_json({"type": "error", "message": "Invalid JSON"})
                continue

            msg_type = payload.get("type")

            # 1) 핸드셰이크: 대시보드 최초 연결
            if msg_type == "handshake":
                await websocket.send_json(
                    {"type": "event", "message": "✅ 대시보드 클라이언트 핸드셰이크 완료"}
                )
                try:
                    state = load_world_state()
                    await websocket.send_json(
                        {
                            "type": "world_state",
                            "world_state": state,
                            "timestamp": state.get("updated_at"),
                        }
                    )
                except Exception as e:
                    await websocket.send_json(
                        {"type": "error", "message": f"world_state 로드 실패: {e}"}
                    )
                continue

            # 2) 명령 처리
            if msg_type == "command":
                command = payload.get("command") or ""
                cmd_payload = payload.get("payload") or {}

                # 2-1) 월드 상태 동기화
                if command == "request_world_state":
                    try:
                        state = load_world_state()
                        await websocket.send_json(
                            {
                                "type": "world_state",
                                "world_state": state,
                                "timestamp": state.get("updated_at"),
                            }
                        )
                    except Exception as e:
                        await websocket.send_json(
                            {"type": "error", "message": f"world_state 로드 실패: {e}"}
                        )
                    continue

                # 2-2) Planner 실행
                if command == "command_planner":
                    try:
                        await asyncio.to_thread(run_planner)
                        await websocket.send_json(
                            {"type": "event", "message": "🧠 Planner 실행 완료"}
                        )
                        state = load_world_state()
                        await websocket.send_json(
                            {
                                "type": "world_state",
                                "world_state": state,
                                "timestamp": state.get("updated_at"),
                            }
                        )
                    except Exception as e:
                        await websocket.send_json(
                            {"type": "error", "message": f"Planner 실행 실패: {e}"}
                        )
                    continue

                # 2-3) Executor 1회 실행
                if command == "command_executor":
                    try:
                        await websocket.send_json(
                            {
                                "type": "event",
                                "message": "🧩 Executor 1회 실행 요청 수신",
                            }
                        )
                        exit_code = await _run_executor_once()
                        await websocket.send_json(
                            {
                                "type": "event",
                                "message": f"🧩 Executor 실행 종료 (exit_code={exit_code})",
                            }
                        )
                        state = load_world_state()
                        await websocket.send_json(
                            {
                                "type": "world_state",
                                "world_state": state,
                                "timestamp": state.get("updated_at"),
                            }
                        )
                    except Exception as e:
                        await websocket.send_json(
                            {"type": "error", "message": f"Executor 실행 실패: {e}"}
                        )
                    continue

                # 2-3-확장) 특정 task_id를 지정한 실행 요청 (trigger_task)
                if command == "trigger_task":
                    task_id = cmd_payload.get("task_id")
                    try:
                        await websocket.send_json(
                            {
                                "type": "event",
                                "message": f"🧩 trigger_task 실행 요청 수신 (task_id={task_id})",
                            }
                        )
                        # 현재 rc25s_task_executor는 개별 task_id 실행을 직접 지원하지 않으므로,
                        # 우선순위가 가장 높은 pending task 1개를 실행하는 기존 로직을 재사용한다.
                        exit_code = await _run_executor_once()
                        await websocket.send_json(
                            {
                                "type": "event",
                                "message": f"🧩 trigger_task 실행 종료 (exit_code={exit_code}, task_id={task_id})",
                            }
                        )
                        state = load_world_state()
                        await websocket.send_json(
                            {
                                "type": "world_state",
                                "world_state": state,
                                "timestamp": state.get("updated_at"),
                            }
                        )
                    except Exception as e:
                        await websocket.send_json(
                            {"type": "error", "message": f"trigger_task 실행 실패: {e}"}
                        )
                    continue

                # 2-3-보완) 목표 승인 (approve_goal)
                if command == "approve_goal":
                    goal_id = cmd_payload.get("goal_id")
                    try:
                        # 로컬 플래너 상태 파일에서 해당 goal_id에 속한 작업을 approved=True로 표시
                        try:
                            with open(PLANNER_STATE_PATH, "r", encoding="utf-8") as f:
                                planner_state = json.load(f)
                        except FileNotFoundError:
                            planner_state = {}

                        changed = False
                        for t in planner_state.get("tasks", []):
                            if t.get("goal_id") == goal_id:
                                if not t.get("approved"):
                                    t["approved"] = True
                                    changed = True

                        if changed:
                            with open(PLANNER_STATE_PATH, "w", encoding="utf-8") as f:
                                json.dump(planner_state, f, ensure_ascii=False, indent=2)

                        await websocket.send_json(
                            {
                                "type": "event",
                                "message": f"✅ Goal 승인 처리 완료 (goal_id={goal_id}, changed={changed})",
                            }
                        )

                        # world_state도 최신 상태로 다시 내려준다.
                        state = load_world_state()
                        await websocket.send_json(
                            {
                                "type": "world_state",
                                "world_state": state,
                                "timestamp": state.get("updated_at"),
                            }
                        )
                    except Exception as e:
                        await websocket.send_json(
                            {"type": "error", "message": f"approve_goal 처리 실패: {e}"}
                        )
                    continue

                # 2-4) Self-Check 실행
                if command == "command_selfcheck":
                    script = "/srv/repo/vibecoding/rc25s-selfcheck.sh"
                    try:
                        result = await asyncio.to_thread(
                            subprocess.run,
                            ["bash", script],
                            capture_output=True,
                            text=True,
                        )
                        await websocket.send_json(
                            {
                                "type": "event",
                                "message": "🩺 Self-Check 스크립트 실행 완료",
                                "stdout": result.stdout[-1000:],
                                "stderr": result.stderr[-1000:],
                                "returncode": result.returncode,
                            }
                        )
                    except Exception as e:
                        await websocket.send_json(
                            {"type": "error", "message": f"Self-Check 실행 실패: {e}"}
                        )
                    continue

                # 2-5) 프리 텍스트 LLM 대화 + 액션 실행
                if command == "free_text":
                    message = (cmd_payload.get("message") or "").strip()
                    if not message:
                        await websocket.send_json(
                            {
                                "type": "error",
                                "message": "빈 메시지는 처리할 수 없습니다.",
                            }
                        )
                        continue
                    try:
                        llm_result = await asyncio.to_thread(rc25s_chat, message)
                        text = (llm_result or {}).get("response", "")
                        actions = (llm_result or {}).get("actions") or []
                        await websocket.send_json(
                            {
                                "type": "llm_response",
                                "message": text,
                                "timestamp": datetime.datetime.now().isoformat(),
                            }
                        )
                        # 선택적으로, LLM이 제안한 actions를 실제로 실행
                        await _apply_llm_actions(actions, websocket)
                    except Exception as e:
                        await websocket.send_json(
                            {"type": "error", "message": f"LLM 처리 실패: {e}"}
                        )
                    continue

                # 알 수 없는 명령
                await websocket.send_json(
                    {"type": "error", "message": f"Unknown command: {command}"}
                )
                continue

            # 3) 구 버전 호환용 ping
            if payload.get("message") == "ping":
                await websocket.send_json(
                    {"type": "heartbeat", "message": "pong"}
                )
                continue

            # 4) 기타는 단순 이벤트로 에코
            await websocket.send_json(
                {"type": "event", "message": f"✅ Received: {payload}"}
            )

    except Exception as e:
        print(f"⚠️ WebSocket error: {e}")
    finally:
        connected_clients.remove(websocket)
        print("❌ WebSocket client disconnected")


@app.websocket("/ws/system2")
async def system_ws(websocket: WebSocket):
    """
    시스템 상태 모니터링용 WebSocket 채널.
    - dashboard/src/App.jsx 에서 /ws/system2 으로 연결을 시도하며,
      type === "system_stats" 인 JSON을 기대한다.
    """
    await websocket.accept()
    try:
        while True:
            cpu = psutil.cpu_percent(interval=None)
            mem = psutil.virtual_memory().percent
            disk = psutil.disk_usage("/").percent
            payload = {
                "type": "system_stats",
                "cpu": cpu,
                "memory": mem,
                "disk": disk,
                "time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            }
            await websocket.send_text(json.dumps(payload, ensure_ascii=False))
            await asyncio.sleep(5)
    except Exception as e:
        print(f"⚠️ system WS error: {e}")
    finally:
        try:
            await websocket.close()
        except Exception:
            pass
