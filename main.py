import os
import json
import datetime
import requests
from typing import List

BASE_URL = "https://api.mcpvibe.org"

# ✅ 대화 로그 관리

def fetch_chat_context(limit: int = 20) -> List[dict]:
    try:
        res = requests.get(f"{BASE_URL}/log/chat")
        if res.status_code != 200:
            return []
        return res.json()[-limit:]
    except Exception:
        return []

def format_context(chatlog: List[dict]) -> str:
    return "\n".join(f"{entry['sender']}: {entry['text']}" for entry in chatlog)

def save_chat_message(sender: str, text: str) -> bool:
    try:
        payload = {"sender": sender, "text": text}
        res = requests.post(f"{BASE_URL}/log/chat", json=payload)
        return res.status_code == 200
    except Exception:
        return False

# ✅ 코드 실행기 (로컬 테스트용)
def run_code(code: str) -> dict:
    import subprocess, tempfile
    start = datetime.datetime.now(datetime.UTC)
    with tempfile.NamedTemporaryFile(delete=False, suffix=".py") as f:
        f.write(code.encode("utf-8"))
        f.flush()
        result = subprocess.run(["python3", f.name], capture_output=True, text=True)
    duration = (datetime.datetime.now(datetime.UTC) - start).total_seconds() * 1000
    return {
        "passed": result.returncode == 0,
        "stdout": result.stdout,
        "stderr": result.stderr,
        "exit_code": result.returncode,
        "duration_ms": int(duration)
    }

# ✅ 파일 유틸

def read_file(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def write_file(path: str, content: str):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

# ✅ 예시 실행
if __name__ == "__main__":
    context = fetch_chat_context()
    print("🔁 최근 대화 기록:")
    print(format_context(context))

    # 사용자 메시지
    user_msg = "GPT와 대화 저장 테스트 중입니다."
    save_chat_message("user", user_msg)

    # GPT 응답 시뮬레이션
    assistant_response = "네, 대화는 정상적으로 저장되고 있습니다."
    print("🤖 GPT 응답:", assistant_response)
    save_chat_message("assistant", assistant_response)

    # 코드 실행 예시
    code = "print('Hello from VibeCoding!')"
    result = run_code(code)
    print("\n✅ 실행 결과:", result)
