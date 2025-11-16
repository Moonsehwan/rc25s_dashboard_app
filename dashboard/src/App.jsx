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
