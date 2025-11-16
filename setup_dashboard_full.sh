#!/usr/bin/env bash
set -e
BASE=/srv/repo/vibecoding
UI_DIR=$BASE/dashboard
mkdir -p $UI_DIR/src/components
echo "🚀 Installing Full AGI Dashboard (A+B+C)..."

# 1️⃣ FastAPI 확장: 명령 엔드포인트 추가
cat << 'PY' > $BASE/mcp_server.py
from fastapi import FastAPI, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
import os, json, glob, subprocess, datetime

app = FastAPI(title="RC25H AGI Control Server")

BASE = "/srv/repo/vibecoding"
LOG_DIR = f"{BASE}/logs"
MEM_PATH = f"{BASE}/memory_store"
APP_DIR = f"{BASE}/generated_apps"
DASHBOARD_PATH = f"{BASE}/dashboard/dist"
VENV_PYTHON = "/srv/repo/venv/bin/python3"

app.mount("/static", StaticFiles(directory=DASHBOARD_PATH), name="static")

def run_cmd(cmd):
    try:
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except Exception as e:
        return False

@app.get("/health")
async def health():
    return {"ok": True, "engine": "RC25H Hybrid Kernel", "status": "running"}

@app.get("/reflect/view")
async def reflect_view():
    p = os.path.join(MEM_PATH, "reflection.json")
    return json.load(open(p)) if os.path.exists(p) else {"error": "no reflection"}

@app.get("/memory/view")
async def memory_view():
    p = os.path.join(MEM_PATH, "memory_vector.json")
    return json.load(open(p)) if os.path.exists(p) else {"error": "no memory"}

@app.get("/apps/list")
async def apps_list():
    apps = [os.path.basename(p) for p in glob.glob(f"{APP_DIR}/*/")]
    return {"apps": apps}

@app.get("/logs/live")
async def logs_live():
    files = sorted(glob.glob(f"{LOG_DIR}/agi_*.log"), reverse=True)
    data = {}
    for f in files[:3]:
        name = os.path.basename(f)
        with open(f, encoding="utf-8") as fp:
            data[name] = fp.readlines()[-15:]
    return JSONResponse(data)

# 🔘 Control Endpoints
@app.post("/run/{module}")
async def run_module(module: str):
    script_map = {
        "reflection": "reflection_engine.py",
        "autofix": "agi_autofix_loop.py",
        "selfbuild": "agi_selfbuild_loop.py"
    }
    if module not in script_map:
        return {"error": "invalid module"}
    path = os.path.join(BASE, script_map[module])
    ok = run_cmd([VENV_PYTHON, path])
    return {"ok": ok, "started": module}

# 💬 Chat Endpoint
@app.post("/chat")
async def chat(req: Request):
    data = await req.json()
    user = data.get("message", "")
    if not user.strip():
        return {"error": "empty message"}
    from openai import OpenAI
    api_key = os.getenv("OPENAI_API_KEY") or ""
    if not api_key and os.path.exists("/etc/openai_api_key.txt"):
        api_key = open("/etc/openai_api_key.txt").read().strip()
    client = OpenAI(api_key=api_key)
    res = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role":"system","content":"You are RC25H AGI assistant connected to a live AGI kernel."},
                  {"role":"user","content":user}]
    )
    text = res.choices[0].message.content.strip()
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return {"response": text, "time": ts}

@app.get("/")
async def index():
    return FileResponse(os.path.join(DASHBOARD_PATH, "index.html"))
PY

# 2️⃣ React 프론트엔드 확장
cat << 'JSX' > $UI_DIR/src/App.jsx
import React, { useEffect, useState } from "react";

export default function App() {
  const [logs, setLogs] = useState({});
  const [reflection, setReflection] = useState({});
  const [apps, setApps] = useState([]);
  const [chat, setChat] = useState([]);
  const [input, setInput] = useState("");

  async function load() {
    const r1 = await fetch("/logs/live").then(r=>r.json());
    const r2 = await fetch("/reflect/view").then(r=>r.json());
    const r3 = await fetch("/apps/list").then(r=>r.json());
    setLogs(r1); setReflection(r2); setApps(r3.apps);
  }

  async function sendChat() {
    const msg = input.trim(); if(!msg) return;
    setChat(c=>[...c, {from:"user", text:msg}]);
    setInput("");
    const res = await fetch("/chat",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({message:msg})});
    const data = await res.json();
    setChat(c=>[...c, {from:"agi", text:data.response}]);
  }

  async function runModule(m){
    await fetch("/run/"+m,{method:"POST"});
    alert(m+" started!");
  }

  useEffect(()=>{load(); const i=setInterval(load,4000); return ()=>clearInterval(i)},[]);

  return (
    <div className="min-h-screen bg-slate-900 text-gray-200 font-sans p-6">
      <h1 className="text-3xl font-bold text-green-400 mb-4">RC25H AGI Control Dashboard</h1>

      <div className="grid grid-cols-2 gap-6">
        {/* Reflection */}
        <div className="bg-slate-800 p-4 rounded-xl">
          <h2 className="text-lg text-blue-300 mb-2">🪞 Reflection</h2>
          <pre className="text-sm">{JSON.stringify(reflection,null,2)}</pre>
        </div>

        {/* Logs */}
        <div className="bg-slate-800 p-4 rounded-xl">
          <h2 className="text-lg text-amber-300 mb-2">📜 Logs</h2>
          {Object.keys(logs).map(f=>(
            <details key={f}><summary className="text-green-400">{f}</summary>
            <pre className="text-xs">{logs[f].join("")}</pre></details>
          ))}
        </div>

        {/* Apps */}
        <div className="col-span-2 bg-slate-800 p-4 rounded-xl">
          <h2 className="text-lg text-pink-300 mb-2">🧩 Generated Apps</h2>
          <ul>{apps.map(a=><li key={a}>• {a}</li>)}</ul>
        </div>

        {/* Controls */}
        <div className="col-span-2 bg-slate-800 p-4 rounded-xl">
          <h2 className="text-lg text-yellow-300 mb-2">⚙️ Controls</h2>
          <div className="flex gap-3">
            <button onClick={()=>runModule("reflection")} className="bg-blue-600 hover:bg-blue-700 px-3 py-1 rounded-lg">Run Reflection</button>
            <button onClick={()=>runModule("autofix")} className="bg-green-600 hover:bg-green-700 px-3 py-1 rounded-lg">Run AutoFix</button>
            <button onClick={()=>runModule("selfbuild")} className="bg-purple-600 hover:bg-purple-700 px-3 py-1 rounded-lg">Run SelfBuild</button>
          </div>
        </div>

        {/* Chat Console */}
        <div className="col-span-2 bg-slate-800 p-4 rounded-xl">
          <h2 className="text-lg text-cyan-300 mb-2">💬 AGI Chat Console</h2>
          <div className="h-64 overflow-y-auto bg-slate-900 rounded-lg p-2 mb-2">
            {chat.map((c,i)=>(
              <div key={i} className={c.from==="user"?"text-right":"text-left"}>
                <span className={c.from==="user"?"text-green-300":"text-amber-300"}>{c.from==="user"?"You":"AGI"}:</span>
                <span className="ml-2">{c.text}</span>
              </div>
            ))}
          </div>
          <div className="flex gap-2">
            <input className="flex-1 p-2 rounded-lg bg-slate-700 text-white"
              value={input} onChange={e=>setInput(e.target.value)} placeholder="Type a message..." />
            <button onClick={sendChat} className="bg-cyan-600 px-4 rounded-lg">Send</button>
          </div>
        </div>

        {/* Visualization */}
        <div className="col-span-2 bg-slate-800 p-4 rounded-xl">
          <h2 className="text-lg text-red-300 mb-2">🧠 System Status Map</h2>
          <div className="text-sm">
            Reflection → Memory → AutoFix → SelfBuild → Dashboard<br/>
            ↳ Each loop updates logs, memory_store, and generated_apps
          </div>
        </div>
      </div>
    </div>
  );
}
JSX

# 3️⃣ index.html & vite 설정
cat << 'EOF2' > $UI_DIR/index.html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>RC25H AGI Dashboard</title>
  </head>
  <body class="bg-slate-900 text-gray-100">
    <div id="root"></div>
    <script type="module" src="/src/App.jsx"></script>
  </body>
</html>
EOF2

cat << 'EOF3' > $UI_DIR/vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
export default defineConfig({
  plugins: [react()],
  root: '.',
  build: { outDir: 'dist', emptyOutDir: true },
})
EOF3

# 4️⃣ Build
cd $UI_DIR
npm install --silent
npx vite build
echo "✅ Full AGI Dashboard built successfully."
