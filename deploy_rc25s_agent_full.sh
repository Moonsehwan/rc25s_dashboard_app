#!/bin/bash
echo "🚀 [RC25S] Deploying AGI Agent Studio (Full Interactive Version)..."

FRONTEND_DIR="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend"

# --- React 프론트엔드 강화 ---
cd $FRONTEND_DIR
cat > src/App.tsx <<'REACT'
import React, { useState, useEffect } from "react";

interface SystemStatus {
  cpu: string;
  memory: string;
  uptime: string;
}

export default function App() {
  const [log, setLog] = useState<string[]>([]);
  const [msg, setMsg] = useState("");
  const [status, setStatus] = useState<SystemStatus>({ cpu: "-", memory: "-", uptime: "-" });
  const [ws, setWs] = useState<WebSocket | null>(null);

  useEffect(() => {
    const socket = new WebSocket("wss://" + window.location.host + "/ws");
    socket.onopen = () => setLog(prev => [...prev, "🧠 연결됨: AGI 실시간 스트림 활성화"]);
    socket.onmessage = (e) => setLog(prev => [...prev, e.data]);
    socket.onclose = () => setLog(prev => [...prev, "⚠️ 연결 종료됨"]);
    setWs(socket);

    const fetchStatus = async () => {
      const res = await fetch("/health");
      const data = await res.json();
      setStatus({
        cpu: (data.cpu ?? "N/A") + "%",
        memory: (data.memory ?? "N/A") + "%",
        uptime: data.time ?? "N/A",
      });
    };
    fetchStatus();
    const interval = setInterval(fetchStatus, 5000);
    return () => clearInterval(interval);
  }, []);

  const send = () => {
    if (ws && msg.trim()) {
      ws.send(msg);
      setLog(prev => [...prev, "👤 " + msg]);
      setMsg("");
    }
  };

  return (
    <div className="bg-zinc-950 text-zinc-100 h-screen flex flex-col">
      <header className="p-4 text-cyan-400 text-2xl font-bold border-b border-zinc-800">
        🧠 RC25S AGI Agent Studio
      </header>
      <div className="grid grid-cols-4 flex-grow overflow-hidden">
        <div className="col-span-3 flex flex-col p-4">
          <div className="bg-zinc-900 rounded-2xl p-4 flex-grow overflow-y-auto border border-zinc-700 shadow-inner">
            {log.map((l, i) => (
              <div key={i} className="mb-1 whitespace-pre-wrap">{l}</div>
            ))}
          </div>
          <div className="flex mt-3">
            <input
              value={msg}
              onChange={(e) => setMsg(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && send()}
              placeholder="명령을 입력하세요..."
              className="flex-grow rounded-l-lg bg-zinc-800 p-3 text-sm outline-none"
            />
            <button
              onClick={send}
              className="bg-cyan-500 hover:bg-cyan-600 text-black font-bold px-4 rounded-r-lg"
            >
              전송
            </button>
          </div>
        </div>
        <aside className="bg-zinc-900 border-l border-zinc-800 p-4 flex flex-col">
          <h2 className="text-cyan-400 font-semibold mb-2">📊 시스템 상태</h2>
          <p>🧩 CPU 사용률: <span className="text-cyan-300">{status.cpu}</span></p>
          <p>💾 메모리: <span className="text-cyan-300">{status.memory}</span></p>
          <p>⏱ Uptime: <span className="text-cyan-300">{status.uptime}</span></p>
        </aside>
      </div>
    </div>
  );
}
REACT

# --- 빌드 ---
npm run build

# --- 서비스 재시작 ---
sudo systemctl restart rc25s-dashboard.service
sudo systemctl reload nginx

echo "✅ RC25S Agent Studio (Full) 배포 완료!"
echo "🌐 접속: https://api.mcpvibe.org/agi/"
