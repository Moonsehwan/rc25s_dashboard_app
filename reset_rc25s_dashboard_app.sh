#!/usr/bin/env bash
# =========================================================
# RC25S Dashboard App.tsx - Full Clean Rewrite & Build
# =========================================================
set -e
APP_FILE="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/src/App.tsx"
APP_DIR="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend"

echo "🧩 Rewriting App.tsx with stable, clean React code..."

sudo tee "$APP_FILE" > /dev/null <<'EOC'
import React, { useState } from "react";

function App() {
  const [input, setInput] = useState("");
  const [messages, setMessages] = useState<{ sender: string; text: string }[]>([]);
  const [loading, setLoading] = useState(false);
  const [provider, setProvider] = useState("local");

  const sendMessage = async () => {
    if (!input.trim()) return;
    setLoading(true);
    try {
      const res = await fetch("/llm", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ prompt: input, provider }),
      });

      const text = await res.text();
      try {
        const json = JSON.parse(text);
        setMessages((msgs) => [...msgs, { sender: "ai", text: json.output }]);
      } catch {
        setMessages((msgs) => [
          ...msgs,
          { sender: "system", text: "⚠️ 서버 응답 오류 (504 Timeout 또는 HTML 에러)" },
        ]);
      }
    } catch (err) {
      setMessages((msgs) => [
        ...msgs,
        { sender: "system", text: `❌ 네트워크 오류: ${(err as Error).message}` },
      ]);
    } finally {
      setLoading(false);
      setInput("");
    }
  };

  return (
    <div style={{ maxWidth: "800px", margin: "40px auto", fontFamily: "sans-serif" }}>
      <h2>🤖 RC25S AGI Dashboard</h2>
      <div
        style={{
          border: "1px solid #ccc",
          borderRadius: "8px",
          padding: "12px",
          height: "400px",
          overflowY: "auto",
          background: "#fafafa",
        }}
      >
        {messages.map((m, i) => (
          <div key={i} style={{ marginBottom: "8px" }}>
            <b>{m.sender}:</b> {m.text}
          </div>
        ))}
      </div>
      <div style={{ marginTop: "16px" }}>
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && sendMessage()}
          placeholder="명령을 입력하세요..."
          style={{
            width: "80%",
            padding: "10px",
            borderRadius: "8px",
            border: "1px solid #ccc",
            marginRight: "8px",
          }}
        />
        <button
          onClick={sendMessage}
          disabled={loading}
          style={{
            padding: "10px 20px",
            backgroundColor: "#4CAF50",
            color: "white",
            border: "none",
            borderRadius: "8px",
            cursor: "pointer",
          }}
        >
          {loading ? "⏳..." : "Send"}
        </button>
      </div>
    </div>
  );
}

export default App;
EOC

echo "✅ App.tsx rewritten successfully."
cd "$APP_DIR"
npm run build
sudo systemctl restart rc25s-dashboard.service
echo "🚀 Dashboard rebuilt & restarted successfully."
