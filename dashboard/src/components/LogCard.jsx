import React, { useEffect, useState, useRef } from "react";
import axios from "axios";

export default function LogCard() {
    const [logs, setLogs] = useState([]);
    const scrollRef = useRef(null);

    useEffect(() => {
        const fetchLogs = async () => {
            try {
                const res = await axios.get("/agi/fs/read?path=/root/agi_events.jsonl");
                if (res.data.content) {
                    const lines = res.data.content.split("\n").filter(line => line.trim());
                    const parsed = lines.map(line => {
                        try { return JSON.parse(line); } catch (e) { return null; }
                    }).filter(Boolean);

                    // Only update if count changed to avoid jitter
                    setLogs(prev => {
                        if (prev.length !== parsed.length) return parsed;
                        return prev;
                    });
                }
            } catch (err) {
                console.error("Failed to fetch logs", err);
            }
        };

        fetchLogs();
        const interval = setInterval(fetchLogs, 2000);
        return () => clearInterval(interval);
    }, []);

    useEffect(() => {
        if (scrollRef.current) {
            scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
        }
    }, [logs]);

    return (
        <div className="bg-gray-800/50 backdrop-blur-md border border-gray-700 rounded-xl p-6 shadow-xl h-full flex flex-col">
            <h2 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
                📜 System Logs
                <span className="flex h-2 w-2 relative">
                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                    <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
                </span>
            </h2>
            <div
                ref={scrollRef}
                className="flex-1 overflow-y-auto bg-black/40 border border-gray-700/50 rounded-lg p-4 font-mono text-xs space-y-2 scrollbar-thin scrollbar-thumb-gray-700 scrollbar-track-transparent"
            >
                {logs.map((log, i) => (
                    <div key={i} className="border-l-2 border-gray-700 pl-2 hover:bg-white/5 transition p-1 rounded">
                        <div className="flex gap-2 text-gray-500 mb-0.5">
                            <span>{log.timestamp.split('T')[1].split('.')[0]}</span>
                            <span className={`font-bold ${log.event_type === 'error' ? 'text-red-400' :
                                    log.event_type === 'memory_saved' ? 'text-purple-400' :
                                        'text-blue-400'
                                }`}>
                                {log.event_type}
                            </span>
                        </div>
                        <div className="text-gray-300 break-all">
                            {JSON.stringify(log.detail, null, 2)}
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}
