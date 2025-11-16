#!/bin/bash
set -e
TS=$(date +"%Y-%m-%d %H:%M:%S")
LOG=/srv/repo/vibecoding/setup_agi_realtime.log

echo "[$TS] 🚀 Starting AGI Realtime Environment Setup..." | tee -a $LOG

# 1️⃣ Install dependencies
echo "[$TS] 📦 Installing WebSocket dependencies..." | tee -a $LOG
source /srv/repo/venv/bin/activate
pip install -q "uvicorn[standard]" websockets fastapi

# 2️⃣ Configure Nginx WebSocket proxy
echo "[$TS] ⚙️ Updating Nginx WebSocket configuration..." | tee -a $LOG
sudo tee /etc/nginx/sites-available/mcpvibe.conf > /dev/null <<'NGINXCONF'
server {
    listen 443 ssl;
    server_name api.mcpvibe.org;

    ssl_certificate     /etc/ssl/cloudflare/api_mcpvibe_org.crt;
    ssl_certificate_key /etc/ssl/cloudflare/api_mcpvibe_org.key;
    ssl_protocols TLSv1.2 TLSv1.3;

    location /dashboard/ {
        alias /srv/repo/vibecoding/dashboard/dist/;
        index index.html;
        try_files \$uri \$uri/ /dashboard/index.html;
    }

    # ✅ WebSocket Proxy (AGI)
    location /ws/agi {
        proxy_pass http://127.0.0.1:8000/ws/agi;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host \$host;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }

    # ✅ API proxy (FastAPI)
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINXCONF

sudo nginx -t && sudo systemctl restart nginx
echo "[$TS] ✅ Nginx updated and restarted." | tee -a $LOG

# 3️⃣ Create WS Client for React Dashboard
echo "[$TS] 🧠 Creating React WS client..." | tee -a $LOG
cat << 'JS' > /srv/repo/vibecoding/dashboard/src/wsClient.js
let ws;
export function connectWS(onMessage) {
  ws = new WebSocket("wss://api.mcpvibe.org/ws/agi");

  ws.onopen = () => {
    console.log("✅ Connected to AGI Server");
    ws.send(JSON.stringify({ message: "ping" }));
  };

  ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    onMessage && onMessage(data);
  };

  ws.onerror = (err) => {
    console.error("❌ WS Error:", err);
    setTimeout(() => connectWS(onMessage), 5000);
  };

  ws.onclose = () => {
    console.warn("⚠️ WS Closed, retrying...");
    setTimeout(() => connectWS(onMessage), 5000);
  };
}
JS

# 4️⃣ Create modern React dashboard
echo "[$TS] 🎨 Creating beautiful dashboard UI..." | tee -a $LOG
cat << 'JS' > /srv/repo/vibecoding/dashboard/src/App.jsx
import React, { useEffect, useState } from "react";
import { connectWS } from "./wsClient";

export default function App() {
  const [logs, setLogs] = useState([]);
  useEffect(() => connectWS((msg) => setLogs((p) => [...p, msg])), []);

  return (
    <div style={{
      minHeight: "100vh",
      background: "linear-gradient(135deg, #0a0a0a, #1a1a1a)",
      color: "#eaeaea",
      fontFamily: "Inter, sans-serif",
      textAlign: "center",
      padding: "40px"
    }}>
      <h1 style={{ fontSize: "42px", marginBottom: "20px" }}>🚀 AGI Dashboard</h1>
      <p style={{ fontSize: "18px", opacity: 0.8 }}>Realtime AI System Link Established</p>
      <div style={{
        background: "#00000066",
        borderRadius: "20px",
        margin: "40px auto",
        maxWidth: "700px",
        textAlign: "left",
        padding: "20px"
      }}>
        {logs.length === 0 && <p>⏳ Waiting for server response...</p>}
        {logs.map((msg, i) => (
          <div key={i} style={{ borderBottom: "1px solid #333", padding: "8px 0" }}>
            <code>{JSON.stringify(msg)}</code>
          </div>
        ))}
      </div>
    </div>
  );
}
JS

# 5️⃣ Build dashboard
echo "[$TS] 🧱 Building React dashboard..." | tee -a $LOG
cd /srv/repo/vibecoding/dashboard
npm run build

# 6️⃣ Restart server
echo "[$TS] 🔁 Restarting MCP server..." | tee -a $LOG
sudo systemctl restart mcp-server.service

echo "[$TS] ✅ Setup complete! Visit: https://api.mcpvibe.org/dashboard" | tee -a $LOG
