from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
import subprocess, json
from RC25H_CentralCore import RC25H_CentralCore

app = FastAPI(title="RC25H Unified Kernel Server")
core = RC25H_CentralCore()

@app.get("/health")
async def health():
    return {"status":"ok","message":"RC25H Unified Kernel active"}

@app.get("/chat", response_class=HTMLResponse)
async def chat_ui():
    html = """
    <html><body style='background:#0e0e0e;color:#ccc;font-family:monospace'>
    <h2>🧠 RC25H Unified Console</h2>
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
    </script></body></html>"""
    return HTMLResponse(html)

@app.post("/exec")
async def exec_command(request: Request):
    data = await request.json()
    cmd = data.get("cmd","")
    # 간단한 한글→명령 매핑
    mapping = {"리플렉션":"python3 reflection_engine.py","메모리":"python3 memory_engine.py","자동수정":"python3 autofix_loop.py"}
    for k,v in mapping.items():
        if k in cmd:
            cmd = v
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=120)
        return JSONResponse({"cmd":cmd,"output":result.stdout + result.stderr})
    except Exception as e:
        return JSONResponse({"error":str(e)})

@app.post("/reflect/run")
async def reflect_run():
    core.execute("REFLECT")
    return {"status":"ok","action":"reflection"}

@app.post("/memory/update")
async def mem_update():
    core.execute("MEMORY")
    return {"status":"ok","action":"memory update"}
