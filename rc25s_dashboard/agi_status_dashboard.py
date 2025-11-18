from fastapi import FastAPI, WebSocket, Request
from fastapi.middleware.cors import CORSMiddleware
import psutil, datetime, subprocess, os, json

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status":"ok","model":"RC25S","cpu":psutil.cpu_percent(interval=None),
            "memory":psutil.virtual_memory().percent,"time":datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

@app.post("/llm")
async def llm(req: Request):
    data = await req.json()
    prompt = data.get("prompt", "")
    provider = data.get("provider", "local")

    if provider == "local":
        cmd = ["ollama", "run", "qwen2.5:7b-instruct", prompt]
        result = subprocess.run(cmd, capture_output=True, text=True)
        output = (result.stdout or "").strip()
        if not output:
            output = "⚠️ 모델이 응답하지 않았습니다. 입력을 조금 더 구체적으로 작성해보세요."
        return {"provider": "qwen2.5", "output": output}

    else:
        import openai
        openai.api_key = os.getenv("OPENAI_API_KEY")
        completion = openai.ChatCompletion.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}]
        )
        return {"provider": "openai", "output": completion.choices[0].message.content}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    await websocket.send_text("🧠 AGI 대시보드 WebSocket 연결됨.")
    try:
        while True:
            msg = await websocket.receive_text()
            if msg.strip() == "상태보여줘":
                await websocket.send_text(f"📊 CPU {psutil.cpu_percent()}%, RAM {psutil.virtual_memory().percent}%")
            else:
                await websocket.send_text(f"🤖 명령 '{msg}' 수신됨.")
    except Exception as e:
        print(f"⚠️ 연결 종료됨: {e}")
        await websocket.close()

if __name__ == "__main__":
    import uvicorn
    # Nginx에서 /agi/ → 127.0.0.1:8011 으로 프록시하므로 여기서는 8011 포트 사용
    uvicorn.run("agi_status_dashboard:app", host="0.0.0.0", port=8011)
