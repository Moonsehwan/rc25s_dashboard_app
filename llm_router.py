import os, json, requests

# --- Dynamic LLM Port Config ---
FREE_LLM_PORT = 8001
try:
    cfg_path = "/srv/repo/vibecoding/free_llm_port.json"
    if os.path.exists(cfg_path):
        with open(cfg_path) as f:
            port_cfg = json.load(f)
            FREE_LLM_PORT = port_cfg.get("port", 8001)
except Exception as e:
    print(f"[LLM Router] Warning: failed to load port config: {e}")

FREE_LLM_URL = f"http://localhost:{FREE_LLM_PORT}/generate"

def call_free_llm(prompt):
    """로컬 LLM 호출"""
    try:
        response = requests.post(FREE_LLM_URL, json={"prompt": prompt}, timeout=30)
    elapsed = time.time() - start_time
    if elapsed > 15:
        print("⚠️ Qwen2.5 응답 지연 — phi로 자동 전환");
        response = requests.post("http://127.0.0.1:11434/api/generate", json={"model": "phi", "prompt": prompt}, timeout=60)
        if response.status_code == 200:
            return response.json().get("output", "")
        else:
            return f"⚠️ LLM error: {response.status_code} {response.text}"
    except Exception as e:
        return f"❌ LLM connection failed: {e}"
