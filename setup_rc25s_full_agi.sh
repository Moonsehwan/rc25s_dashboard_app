#!/bin/bash
echo "🧠 [RC25S AGI] 완전 자동 GPT형 대화 환경 구성 시작..."

# ✅ FastAPI 백엔드 LLM API 추가
BACKEND="/srv/repo/vibecoding/rc25s_dashboard/agi_status_dashboard.py"

if ! grep -q "@app.post(\"/llm" "$BACKEND"; then
cat <<'PY' >> "$BACKEND"

from fastapi import Request
import subprocess, os, json

@app.post("/llm")
async def llm(req: Request):
    data = await req.json()
    prompt = data.get("prompt", "")
    provider = data.get("provider", "local")

    if provider == "local":
        cmd = ["ollama", "run", "qwen2.5:7b-instruct-q4_0", prompt]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        return {"provider": "qwen2.5", "output": result.stdout.strip()}
    else:
        import openai
        openai.api_key = os.getenv("OPENAI_API_KEY")
        completion = openai.ChatCompletion.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}]
        )
        return {"provider": "openai", "output": completion.choices[0].message.content}
PY
fi

# ✅ React GPT형 UI 생성
FRONT="/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/src/App.tsx"
cat <<'TSX' > "$FRONT"
import React, { useState } from "react";
import "./App.css";

function App() {
  const [messages, setMessages] = useState([{ role: "system", content: "🧠 RC25S AGI Assistant Online" }]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [provider, setProvider] = useState("local");

  const sendMessage = async () => {
    if (!input.trim()) return;
    setLoading(true);
    setMessages([...messages, { role: "user", content: input }]);
    const res = await fetch("/llm", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt: input, provider }),
    });
    const data = await res.json();
    setMessages((msgs) => [
      ...msgs,
      { role: "assistant", content: data.output || data.error },
    ]);
    setInput("");
    setLoading(false);
  };

  return (
    <div className="chat-ui">
      <header>🤖 RC25S AGI Assistant ({provider})</header>
      <div className="messages">
        {messages.map((m, i) => (
          <div key={i} className={m.role}>
            {m.content}
          </div>
        ))}
        {loading && <div className="assistant">⏳ Thinking...</div>}
      </div>
      <footer>
        <select value={provider} onChange={(e) => setProvider(e.target.value)}>
          <option value="local">🧩 Local (Qwen2.5)</option>
          <option value="openai">🌐 OpenAI GPT-4o</option>
        </select>
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="메시지를 입력하세요..."
          onKeyDown={(e) => e.key === "Enter" && sendMessage()}
        />
        <button onClick={sendMessage}>Send</button>
      </footer>
    </div>
  );
}

export default App;
TSX

# ✅ 스타일 (ChatGPT 테마)
cat <<'CSS' > /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend/src/App.css
.chat-ui {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background: #111;
  color: #eee;
  font-family: "Inter", sans-serif;
}
header {
  padding: 12px;
  background: #1e1e1e;
  text-align: center;
  font-weight: bold;
  font-size: 18px;
  border-bottom: 1px solid #333;
}
.messages {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
}
.user {
  background: #0066ff33;
  margin: 6px 0;
  padding: 10px;
  border-radius: 12px;
  align-self: flex-end;
}
.assistant {
  background: #222;
  margin: 6px 0;
  padding: 10px;
  border-radius: 12px;
  align-self: flex-start;
}
footer {
  display: flex;
  padding: 10px;
  background: #1e1e1e;
  border-top: 1px solid #333;
}
input {
  flex: 1;
  background: #222;
  border: none;
  color: white;
  padding: 10px;
  border-radius: 8px;
}
button {
  margin-left: 10px;
  background: #0066ff;
  border: none;
  color: white;
  padding: 10px 16px;
  border-radius: 8px;
}
select {
  background: #222;
  color: white;
  border: none;
  margin-right: 10px;
  padding: 10px;
  border-radius: 8px;
}
CSS

# ✅ React 빌드 & FastAPI 재시작
cd /srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend
npm run build

sudo systemctl restart rc25s-dashboard.service

echo "✅ RC25S AGI UI 완성! 접속 주소 → https://api.mcpvibe.org/agi/"
