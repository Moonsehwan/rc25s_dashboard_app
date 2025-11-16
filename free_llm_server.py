from fastapi import FastAPI, Request
from pydantic import BaseModel
from rc25_kernel_RC25S import RC25SKernel as ProKernel
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
