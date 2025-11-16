#!/bin/bash
set -e
echo "🚀 [RC25H-AGI] Installing rc25_kernel_pro_R3 (Brain Kernel) ..."

# 1️⃣ 커널 파일 생성
cat <<'PYEOF' | sudo tee /srv/repo/vibecoding/rc25_kernel_pro_R3.py > /dev/null
import random, time, json
from dataclasses import dataclass, asdict
from typing import List, Tuple, Any

@dataclass
class KernelMetrics:
    token_count: int
    response_time: float
    creativity_score: float
    consistency_score: float

class DummyLLM:
    def generate(self, prompt: str) -> str:
        ideas = [
            "Innovative synthesis achieved through self-consistency.",
            "Exploring reflective optimization of core processes.",
            "Emergent reasoning identified new code pathways.",
            "System stability improved by adaptive evolution.",
        ]
        return random.choice(ideas) + " 🧠"

class ProKernel:
    def __init__(self, llm: Any):
        self.llm = llm
        self.history = []

    def run_turn(self, history: List[str], user_input: str, stakes="auto", mode="auto") -> Tuple[str, KernelMetrics]:
        t0 = time.time()
        # Step 1. Multi-pass reasoning simulation
        drafts = [self.llm.generate(user_input) for _ in range(3)]
        # Step 2. Self-consistency voting
        result = max(set(drafts), key=drafts.count)
        # Step 3. Metric simulation
        metrics = KernelMetrics(
            token_count=random.randint(80, 200),
            response_time=round(time.time() - t0, 3),
            creativity_score=random.uniform(0.7, 0.95),
            consistency_score=random.uniform(0.8, 0.98),
        )
        # Step 4. Save history
        self.history.append({"input": user_input, "output": result, "metrics": asdict(metrics)})
        return result, metrics
PYEOF

echo "✅ rc25_kernel_pro_R3.py created."

# 2️⃣ free_llm_server.py 수정 및 백업
TARGET="/srv/repo/vibecoding/free_llm_server.py"
BACKUP="/srv/repo/vibecoding/free_llm_server_backup_$(date +%s).py"

if [ -f "$TARGET" ]; then
    sudo cp "$TARGET" "$BACKUP"
    echo "🧩 Backup created at $BACKUP"
else
    echo "❌ Error: $TARGET not found!"
    exit 1
fi

# 3️⃣ 통합 로직 주입
sudo sed -i '/^from fastapi import /i from rc25_kernel_pro_R3 import ProKernel, DummyLLM\nkernel = ProKernel(DummyLLM())' "$TARGET"

sudo sed -i '/def generate(/,/return {/c\
@app.post("/generate")\n\
async def generate(req: dict):\n\
    user_input = req.get("prompt", "")\n\
    history = req.get("history", [])\n\
    reply, metrics = kernel.run_turn(history, user_input)\n\
    return {"response": reply, "metrics": asdict(metrics)}' "$TARGET"

# 4️⃣ 서비스 재시작
echo "🔁 Restarting free-llm.service ..."
sudo systemctl restart free-llm.service
sleep 3

# 5️⃣ 상태 확인
echo "🧠 Testing /health ..."
curl -s http://127.0.0.1:8011/health || echo "⚠️ /health endpoint not responding."
echo
echo "🧠 Testing /generate ..."
curl -s -X POST http://127.0.0.1:8011/generate -H "Content-Type: application/json" \
     -d '{"prompt": "How can I enhance my self-reflection cycle?"}'
echo
echo "✅ RC25H Brain Kernel Integration Complete!"
