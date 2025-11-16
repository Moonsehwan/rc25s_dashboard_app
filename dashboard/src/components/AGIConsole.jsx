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
