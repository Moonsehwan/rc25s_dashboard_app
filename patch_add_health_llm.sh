#!/bin/bash
set -e
TARGET="/srv/repo/vibecoding/free_llm_server.py"

echo "🧠 [RC25H] Adding /health endpoint to free_llm_server.py..."

# 이미 있으면 패치하지 않음
if ! grep -q "@app.get(\"/health\")" "$TARGET"; then
sudo sed -i '/app = FastAPI.*/a \
\
@app.get("/health")\n\
def health():\n\
    return {"status": "ok", "model": "local-llm", "port": 8011}' "$TARGET"
fi

sudo systemctl restart free-llm.service
sleep 3
curl -s http://127.0.0.1:8011/health
