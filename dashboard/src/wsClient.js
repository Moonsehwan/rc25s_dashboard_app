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
