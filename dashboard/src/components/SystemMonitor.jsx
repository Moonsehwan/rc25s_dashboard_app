import React, { useEffect, useState } from "react";

export default function SystemMonitor() {
  const [stats, setStats] = useState({ cpu: 0, mem: 0, disk: 0 });

  useEffect(() => {
    const proto = window.location.protocol === "https:" ? "wss://" : "ws://";
    const ws = new WebSocket(`${proto}${window.location.host}/ws/system2`);
    ws.onmessage = (event) => setStats(JSON.parse(event.data));
    return () => ws.close();
  }, []);

  return (
    <div className="p-6 bg-white rounded-2xl shadow-md">
      <h2 className="text-2xl font-semibold mb-4">🖥️ Server Status</h2>
      <p>CPU Usage: {stats.cpu}%</p>
      <p>Memory Usage: {stats.mem}%</p>
      <p>Disk Usage: {stats.disk}%</p>
    </div>
  );
}
