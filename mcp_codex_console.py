#!/usr/bin/env python3
# =======================================================
# RC25H Codex Web Console (Full Edition)
# Server-side Codex IDE | RC v25H Hybrid Kernel
# =======================================================
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import subprocess, os, datetime, json

BASE_DIR = "/srv/repo/vibecoding"
LOG_DIR = f"{BASE_DIR}/logs"
LOG_PATH = f"{LOG_DIR}/codex_console.log"
os.makedirs(LOG_DIR, exist_ok=True)

app = FastAPI(title="RC25H Codex Console", version="2.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

def log(msg: str):
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    with open(LOG_PATH, "a", encoding="utf-8") as f: f.write(line + "\n")
    print(line, flush=True)

@app.get("/chat", response_class=HTMLResponse)
async def chat_ui():
    html = """
    <html>
    <head><title>RC25H Codex Console</title></head>
    <body style='background:#0e0e0e;color:#ccc;font-family:monospace'>
      <h2>💻 RC25H Codex Live Console</h2>
      <div id='out' style='white-space:pre;height:70vh;overflow:auto;background:#111;padding:10px;'></div>
      <input id='cmd' style='width:80%;background:#222;color:#0f0;border:none;padding:8px;' placeholder='명령 입력...'>
      <button onclick='send()' style='background:#333;color:#fff;border:none;padding:8px;'>Run</button>
      <script>
        async function send(){
          let c=document.getElementById('cmd').value;
          document.getElementById('out').innerText += "\\n> "+c+"\\n";
          let r=await fetch('/exec',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({cmd:c})});
          let t=await r.text();
          document.getElementById('out').innerText += t + "\\n";
          document.getElementById('cmd').value='';
        }
      </script>
    </body>
    </html>
    """
    return HTMLResponse(content=html)

@app.post("/exec")
async def exec_cmd(req: Request):
    data = await req.json()
    cmd = data.get("cmd","").strip()
    if not cmd: return JSONResponse({"error":"empty command"})
    log(f"EXEC: {cmd}")
    try:
        result = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT, text=True)
        log(f"OUT: {result[:300]}")
        return result
    except subprocess.CalledProcessError as e:
        log(f"ERR: {e.output[:300]}")
        return e.output

@app.get("/logs/view")
async def view_logs():
    try:
        files = [f for f in os.listdir(LOG_DIR) if f.endswith(".log")]
        data = {f: open(os.path.join(LOG_DIR,f)).read()[-1000:] for f in files}
        return JSONResponse(data)
    except Exception as e:
        return JSONResponse({"error": str(e)})

@app.post("/files/edit")
async def edit_file(req: Request):
    data = await req.json()
    path = data.get("path")
    content = data.get("content","")
    if not path or not path.startswith(BASE_DIR):
        return JSONResponse({"error":"invalid path"})
    with open(path,"w",encoding="utf-8") as f: f.write(content)
    log(f"EDITED: {path}")
    return {"status":"ok","file":path}

if __name__ == "__main__":
    import uvicorn
    ssl_key = "/etc/letsencrypt/live/api.mcpvibe.org/privkey.pem"
    ssl_cert = "/etc/letsencrypt/live/api.mcpvibe.org/fullchain.pem"
    uvicorn.run(app, host="0.0.0.0", port=444, ssl_keyfile=ssl_key, ssl_certfile=ssl_cert)
