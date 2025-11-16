import time
import random
from vibecoding.vibecore import fetch_chat_context, save_chat_message, run_code

def extract_goal(context):
    return "print('자동 실행 루프 테스트 중입니다')"

def run_goal(goal_code):
    result = run_code(goal_code)
    return result["stdout"] if result["passed"] else result["stderr"]

def agi_loop():
    while True:
        print("\n🔁 AGI 루프 실행 중...")
        context = fetch_chat_context()
        goal = extract_goal(context)

        save_chat_message("user", f"[AGI GOAL] {goal}")

        result = run_goal(goal)
        print("🤖 실행 결과:", result)
        save_chat_message("assistant", result)

        time.sleep(random.randint(10, 20))

if __name__ == "__main__":
    agi_loop()