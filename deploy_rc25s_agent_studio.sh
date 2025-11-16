#!/bin/bash
echo "🚀 [RC25S] Deploying Agent Studio (Interactive AGI Dashboard)..."

# 1️⃣ UI 리빌드
cd /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend
cat > src/App.tsx <<'REACT'
import React, { useState, useEffect } from "react";

export default function App() {
  const [log, setLog] = useState<string[]>([]);
  const [msg, setMsg] = useState("");
  const [ws, setWs] = useState<WebSocket | null>(null);

  useEffect(() => {
    const socket = new WebSocket("wss://" + window.location.host + "/ws");
    socket.onopen = () => setLog(prev => [...prev, "🧠 연결됨: AGI 실시간 스트림 활성화"]);
    socket.onmessage = (e) => setLog(prev => [...prev, "🤖 " + e.data]);
    socket.onclose = () => setLog(prev => [...prev, "⚠️ 연결 종료됨"]);
    setWs(socket);
    return () => socket.close();
  }, []);

  const send = () => {
    if (ws && msg.trim()) {
      ws.send(msg);
      setLog(prev => [...prev, "👤 " + msg]);
      setMsg("");
    }
  };

  return (
    <div className="bg-zinc-950 text-zinc-100 h-screen flex flex-col items-center justify-center">
      <h1 className="text-2xl text-cyan-400 mb-4">🧠 RC25S AGI Agent Studio</h1>
      <div className="bg-zinc-900 w-4/5 h-2/3 overflow-y-auto rounded-xl p-4 mb-3 shadow-inner border border-cyan-700">
        {log.map((l, i) => <div key={i} className="py-1">{l}</div>)}
      </div>
      <div className="flex w-4/5">
        <input
          value={msg}
          onChange={(e) => setMsg(e.target.value)}
          className="flex-grow rounded-l-lg bg-zinc-800 p-2 text-sm outline-none"
          placeholder="명령을 입력하세요..."
        />
        <button
          onClick={send}
          className="bg-cyan-500 hover:bg-cyan-600 text-black font-bold px-4 rounded-r-lg"
        >전송</button>
      </div>
    </div>
  );
}
REACT

npm run build
sudo systemctl restart rc25s-dashboard.service
sudo systemctl reload nginx

echo "✅ RC25S Agent Studio 배포 완료!"
echo "🌐 접속: https://api.mcpvibe.org/agi/"
