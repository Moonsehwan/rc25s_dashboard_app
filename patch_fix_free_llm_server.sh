#!/bin/bash
set -e
echo "🧠 [RC25H-AGI] Repairing free_llm_server.py syntax & preserving kernel integration..."

TARGET="/srv/repo/vibecoding/free_llm_server.py"
BACKUP="/srv/repo/vibecoding/free_llm_server_broken_$(date +%s).py"

# 1️⃣ 백업
sudo cp "$TARGET" "$BACKUP"
echo "📦 Backup created at $BACKUP"

# 2️⃣ 안전한 재작성
cat <<'PYEOF' | sudo tee "$TARGET" > /dev/null
from fastapi import FastAPI, Request
from pydantic import BaseModel
from rc25_kernel_pro_R3 import ProKernel, DummyLLM
from dataclasses import asdict
import uvicorn

app = FastAPI(title="Free LLM Server (RC25H Brain)")
kernel = ProKernel(DummyLLM())

class GenerateRequest(BaseModel):
    prompt: str
    history: list = []

@app.get("/health")
async def health():
    return {"status": "ok", "model": "rc25_kernel_pro_R3", "port": 8011}

@app.post("/generate")
async def generate(req: GenerateRequest):
    try:
        reply, metrics = kernel.run_turn(req.history, req.prompt)
        return {"response": reply, "metrics": asdict(metrics)}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8011)
PYEOF

echo "✅ free_llm_server.py repaired successfully."

# 3️⃣ 서비스 재시작
echo "🔁 Restarting free-llm.service ..."
sudo systemctl restart free-llm.service
sleep 3

# 4️⃣ 상태 확인
echo "🩺 Testing endpoints ..."
curl -s http://127.0.0.1:8011/health
echo
curl -s -X POST http://127.0.0.1:8011/generate -H "Content-Type: application/json" -d '{"prompt":"What is your current cognitive state?"}'
echo
echo "✅ [RC25H] Brain Kernel server fixed and running."
