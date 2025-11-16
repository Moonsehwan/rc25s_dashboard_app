#!/bin/bash
set -e
TS=$(date +"[%Y-%m-%d %H:%M:%S]")
LOG="/var/log/fix_realtime_dashboard.log"

echo "$TS 🚀 Starting Realtime Dashboard Integration..." | tee -a $LOG

# 1️⃣ FastAPI WebSocket 추가
cat << 'PY' > /srv/repo/vibecoding/mcp_server_realtime.py
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
import psutil, asyncio, json

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.websocket("/ws/system")
async def ws_system(ws: WebSocket):
    await ws.accept()
    while True:
        cpu = psutil.cpu_percent()
        mem = psutil.virtual_memory().percent
        disk = psutil.disk_usage('/').percent
        data = {"cpu": cpu, "mem": mem, "disk": disk}
        await ws.send_json(data)
        await asyncio.sleep(1)

@app.websocket("/ws/agi")
async def ws_agi(ws: WebSocket):
    await ws.accept()
    await ws.send_json({"system": "AGI Console connected."})
    try:
        while True:
            msg = await ws.receive_text()
            if msg == "status":
                await ws.send_json({"status": "AGI Core running"})
            elif msg.startswith("exec:"):
                cmd = msg.split("exec:", 1)[1].strip()
                await ws.send_json({"result": f"Executed: {cmd}"})
            else:
                await ws.send_json({"error": "Unknown command"})
    except:
        await ws.close()
PY

sudo systemctl stop mcp-server.service || true
sudo sed -i 's/vibecoding.mcp_server/vibecoding.mcp_server_realtime/' /etc/systemd/system/mcp-server.service
sudo systemctl daemon-reload
sudo systemctl restart mcp-server.service
echo "$TS ✅ WebSocket backend integrated." | tee -a $LOG

# 2️⃣ React Components 생성
mkdir -p /srv/repo/vibecoding/dashboard/src/components

cat << 'JS' > /srv/repo/vibecoding/dashboard/src/components/SystemMonitor.jsx
import React, { useEffect, useState } from "react";

export default function SystemMonitor() {
  const [stats, setStats] = useState({ cpu: 0, mem: 0, disk: 0 });

  useEffect(() => {
    const ws = new WebSocket("wss://api.mcpvibe.org/ws/system");
    ws.onmessage = (event) => setStats(JSON.parse(event.data));
    return () => ws.close();
  }, []);

  return (
    <div className="p-6 bg-white rounded-2xl shadow-md">
      <h2 className="text-2xl font-semibold mb-4">🖥️ Server Status</h2>
      <p>CPU Usage: {stats.cpu}%</p>
      <p>Memory Usage: {stats.mem}%</p>
      <p>Disk Usage: {stats.disk}%</p>
    </div>
  );
}
JS

cat << 'JS' > /srv/repo/vibecoding/dashboard/src/components/AGIConsole.jsx
import React, { useEffect, useState } from "react";

export default function AGIConsole() {
  const [logs, setLogs] = useState([]);
  const [input, setInput] = useState("");
  const [socket, setSocket] = useState(null);

  useEffect(() => {
    const ws = new WebSocket("wss://api.mcpvibe.org/ws/agi");
    ws.onmessage = (event) =>
      setLogs((prev) => [...prev, JSON.parse(event.data)]);
    setSocket(ws);
    return () => ws.close();
  }, []);

  const sendCommand = () => {
    if (socket && input.trim()) {
      socket.send(input);
      setInput("");
    }
  };

  return (
    <div className="p-6 bg-gray-50 rounded-2xl shadow-md">
      <h2 className="text-2xl font-semibold mb-4">🧠 AGI Command Console</h2>
      <div className="h-48 overflow-y-auto bg-black text-green-400 p-2 rounded mb-2">
        {logs.map((log, i) => (
          <div key={i}>{JSON.stringify(log)}</div>
        ))}
      </div>
      <input
        value={input}
        onChange={(e) => setInput(e.target.value)}
        onKeyDown={(e) => e.key === "Enter" && sendCommand()}
        placeholder="Enter command (e.g. status or exec: task)"
        className="w-full p-2 border rounded"
      />
    </div>
  );
}
JS

# 3️⃣ App.jsx 통합
cat << 'JS' > /srv/repo/vibecoding/dashboard/src/App.jsx
import React from "react";
import SystemMonitor from "./components/SystemMonitor";
import AGIConsole from "./components/AGIConsole";

export default function App() {
  return (
    <div className="p-10 bg-gray-100 min-h-screen space-y-6">
      <h1 className="text-4xl font-bold text-center">🚀 AGI Dashboard</h1>
      <SystemMonitor />
      <AGIConsole />
    </div>
  );
}
JS

# 4️⃣ Rebuild React
cd /srv/repo/vibecoding/dashboard
npm run build --silent
sudo nginx -t && sudo systemctl reload nginx

echo "$TS ✅ Realtime Dashboard deployed at https://api.mcpvibe.org/dashboard" | tee -a $LOG
