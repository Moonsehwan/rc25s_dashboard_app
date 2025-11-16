#!/bin/bash
echo "🚀 [RC25S] Deploying Full AGI Realtime Dashboard (React + WS + Korean Interface)..."

FRONT_DIR="/srv/repo/vibecoding/rc25s_dashboard_app"
BACK_PORT=4545
NGINX_CONF="/etc/nginx/sites-enabled/codex_console.conf"

# 1️⃣ React 앱 생성 (존재하지 않으면)
if [ ! -d "$FRONT_DIR/rc25s_frontend" ]; then
  mkdir -p $FRONT_DIR
  cd $FRONT_DIR
  npx create-react-app rc25s_frontend --template typescript --use-npm
fi

# 2️⃣ React UI 교체 (AGI 전용)
cat <<'REACT' > $FRONT_DIR/rc25s_frontend/src/App.tsx
import React, { useState, useEffect } from "react";

function App() {
  const [log, setLog] = useState<string[]>([]);
  const [msg, setMsg] = useState("");
  const ws = React.useRef<WebSocket | null>(null);

  useEffect(() => {
    ws.current = new WebSocket("wss://" + window.location.host + "/ws");
    ws.current.onmessage = (e) => {
      setLog((prev) => [...prev, "🧠 " + e.data]);
    };
    ws.current.onopen = () => setLog((prev) => [...prev, "✅ 실시간 연결 성공"]);
    ws.current.onclose = () => setLog((prev) => [...prev, "⚠️ 연결 종료됨"]);
    return () => ws.current?.close();
  }, []);

  const sendMsg = () => {
    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(msg);
      setMsg("");
    }
  };

  return (
    <div style={{ background: "#0e0e0e", color: "#f2f2f2", height: "100vh", padding: "2rem", fontFamily: "Pretendard, sans-serif" }}>
      <h1 style={{ color: "#7df9ff" }}>🧠 RC25S AGI 실시간 대시보드</h1>
      <div style={{ background: "#111", borderRadius: "10px", padding: "1rem", margin: "1rem auto", maxWidth: "800px", height: "60vh", overflowY: "auto" }}>
        {log.map((line, i) => (<div key={i}>{line}</div>))}
      </div>
      <div>
        <input
          value={msg}
          onChange={(e) => setMsg(e.target.value)}
          placeholder="명령 입력..."
          style={{ width: "70%", padding: "0.6rem", fontSize: "1rem", borderRadius: "8px", border: "none" }}
        />
        <button
          onClick={sendMsg}
          style={{ padding: "0.6rem 1rem", marginLeft: "10px", background: "#7df9ff", color: "#000", border: "none", borderRadius: "8px", fontWeight: "bold" }}
        >
          전송
        </button>
      </div>
    </div>
  );
}

export default App;
REACT

# 3️⃣ React 빌드
cd $FRONT_DIR/rc25s_frontend
npm install > /dev/null 2>&1
npm run build

# 4️⃣ Nginx 정적 파일 연결
sed -i '/location \/agi\//,/}/d' $NGINX_CONF
cat <<NGX >> $NGINX_CONF

### RC25S AGI DASHBOARD ###
location /agi/ {
    root $FRONT_DIR/rc25s_frontend/build/;
    try_files \$uri /index.html;
}
location /ws {
    proxy_pass http://127.0.0.1:$BACK_PORT/ws;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "Upgrade";
}
NGX

nginx -t && systemctl reload nginx
echo "✅ React AGI Dashboard deployed! Visit https://api.mcpvibe.org/agi/"
