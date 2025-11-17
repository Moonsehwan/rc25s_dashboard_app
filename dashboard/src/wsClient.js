let ws;
let reconnectTimer = null;

const WS_URL =
  (window.location.protocol === "https:" ? "wss://" : "ws://") +
  window.location.host +
  "/ws/agi";

export function connectWS({ onMessage, onWorldState, onStatus } = {}) {
  if (ws && ws.readyState === WebSocket.OPEN) {
    return;
  }

  onStatus && onStatus("connecting");
  ws = new WebSocket(WS_URL);

  ws.onopen = () => {
    onStatus && onStatus("connected");
    try {
      ws.send(
        JSON.stringify({
          type: "handshake",
          message: "대시보드 클라이언트 연결",
          language: "ko",
        })
      );
    } catch (err) {
      console.error("WS send error:", err);
    }
  };

  ws.onmessage = (event) => {
    let data;
    try {
      data = JSON.parse(event.data);
    } catch {
      data = { type: "text", message: event.data };
    }
    if (data?.type === "world_state") {
      onWorldState && onWorldState(data);
    } else {
      onMessage && onMessage(data);
    }
  };

  ws.onerror = (err) => {
    console.error("❌ WS Error:", err);
    onStatus && onStatus("error");
  };

  ws.onclose = () => {
    console.warn("⚠️ WS Closed, retrying...");
    onStatus && onStatus("closed");
    if (!reconnectTimer) {
      reconnectTimer = setTimeout(() => {
        reconnectTimer = null;
        connectWS({ onMessage, onWorldState, onStatus });
      }, 4000);
    }
  };
}

export function sendWS(payload) {
  if (!ws || ws.readyState !== WebSocket.OPEN) return false;
  try {
    const message =
      typeof payload === "string" ? payload : JSON.stringify(payload);
    ws.send(message);
    return true;
  } catch (err) {
    console.error("WS send failed:", err);
    return false;
  }
}
