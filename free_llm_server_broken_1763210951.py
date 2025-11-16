from rc25_kernel_pro_R3 import ProKernel, DummyLLM
kernel = ProKernel(DummyLLM())
from fastapi import FastAPI, Request
import requests, sys, socket, uvicorn, json, os

app = FastAPI()

@app.get("/health")

def health():

    return {"status": "ok", "model": "local-llm", "port": 8011}

PORT_INFO_FILE = "/srv/repo/vibecoding/logs/free_llm_port.json"

def save_port(port: int):
    os.makedirs(os.path.dirname(PORT_INFO_FILE), exist_ok=True)
    with open(PORT_INFO_FILE, "w") as f:
        json.dump({"port": port}, f)

def find_free_port(start_port=8001, max_port=9000):
    for port in range(start_port, max_port):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(("0.0.0.0", port)) != 0:
                return port
    raise RuntimeError("No free port found in range 8001–9000")

@app.post("/generate")
@app.post("/generate")

async def generate(req: dict):

    user_input = req.get("prompt", "")

    history = req.get("history", [])

    reply, metrics = kernel.run_turn(history, user_input)

    return {"response": reply, "metrics": asdict(metrics)}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    base_port = 8001
    for i, arg in enumerate(sys.argv):
        if arg == "--port" and i + 1 < len(sys.argv):
            base_port = int(sys.argv[i + 1])

    port = find_free_port(base_port)
    save_port(port)
    print(f"🚀 Free LLM Server started on port {port}")
    uvicorn.run(app, host="0.0.0.0", port=port)
