#!/usr/bin/env bash
set -e
BASE=/srv/repo/vibecoding
UI_DIR=$BASE/dashboard
LOG=$BASE/logs/dashboard_setup.log
mkdir -p $UI_DIR/src/components
echo "🚀 Setting up AGI Dashboard..." | tee -a $LOG

# 1️⃣ FastAPI endpoint 추가 (mcp_server.py 확장)
cat << 'PY' > $BASE/mcp_server.py
from fastapi import FastAPI, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
import os, json, glob

app = FastAPI(title="RC25H AGI MCP Server")

BASE = "/srv/repo/vibecoding"
LOG_DIR = f"{BASE}/logs"
MEM_PATH = f"{BASE}/memory_store"
APP_DIR = f"{BASE}/generated_apps"
DASHBOARD_PATH = f"{BASE}/dashboard/dist"

app.mount("/static", StaticFiles(directory=DASHBOARD_PATH), name="static")

@app.get("/health")
async def health():
    return {"ok": True, "engine": "RC25H Hybrid Kernel", "status": "running"}

@app.get("/reflect/view")
async def reflect_view():
    path = os.path.join(MEM_PATH, "reflection.json")
    if os.path.exists(path):
        return json.load(open(path))
    return {"error": "no reflection"}

@app.get("/memory/view")
async def memory_view():
    path = os.path.join(MEM_PATH, "memory_vector.json")
    if os.path.exists(path):
        return json.load(open(path))
    return {"error": "no memory"}

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

@app.get("/")
async def index():
    return FileResponse(os.path.join(DASHBOARD_PATH, "index.html"))
PY

# 2️⃣ React Frontend 구성
cat << 'JSX' > $UI_DIR/src/App.jsx
import React, { useEffect, useState } from "react";

export default function App() {
  const [logs, setLogs] = useState({});
  const [reflection, setReflection] = useState({});
  const [apps, setApps] = useState([]);

  async function load() {
    const r1 = await fetch("/logs/live").then(r=>r.json());
    const r2 = await fetch("/reflect/view").then(r=>r.json());
    const r3 = await fetch("/apps/list").then(r=>r.json());
    setLogs(r1); setReflection(r2); setApps(r3.apps);
  }
  useEffect(()=>{ load(); const i=setInterval(load,5000); return ()=>clearInterval(i);},[]);

  return (
    <div className="p-6 font-sans text-gray-200 bg-slate-900 min-h-screen">
      <h1 className="text-2xl font-bold text-green-400">RC25H AGI Dashboard</h1>
      <div className="mt-4 grid grid-cols-2 gap-6">
        <div className="bg-slate-800 p-4 rounded-xl">
          <h2 className="text-lg font-semibold text-blue-300 mb-2">🪞 Reflection</h2>
          <pre className="text-sm">{JSON.stringify(reflection, null, 2)}</pre>
        </div>
        <div className="bg-slate-800 p-4 rounded-xl">
          <h2 className="text-lg font-semibold text-amber-300 mb-2">📜 Recent Logs</h2>
          {Object.keys(logs).map(f=>(
            <details key={f} className="mb-2">
              <summary className="text-green-400">{f}</summary>
              <pre className="text-xs">{logs[f].join("")}</pre>
            </details>
          ))}
        </div>
        <div className="bg-slate-800 p-4 rounded-xl col-span-2">
          <h2 className="text-lg font-semibold text-pink-300 mb-2">🧩 Generated Apps</h2>
          <ul className="text-sm">
            {apps.map(a=>(
              <li key={a} className="text-slate-200">• {a}</li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}
JSX

# 3️⃣ 기본 React 환경
cat << 'JSON' > $UI_DIR/package.json
{
  "name": "agi-dashboard",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "build": "npx vite build"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "vite": "^5.2.0",
    "@vitejs/plugin-react": "^4.3.1"
  }
}
JSON

# 4️⃣ React 빌드 (Vite 사용)
cd $UI_DIR
npm install --silent
npx vite build
echo "✅ Dashboard built successfully."
