import React, { useCallback, useEffect, useMemo, useState } from "react";
import { connectWS, sendWS } from "./wsClient";

const makeId = () =>
  (globalThis.crypto?.randomUUID?.() ??
    `${Date.now()}-${Math.random().toString(16).slice(2)}`);

const baseCard = {
  background: "#0f0f15",
  borderRadius: "18px",
  padding: "18px 22px",
  border: "1px solid rgba(255,255,255,0.08)",
  boxShadow: "0 18px 40px rgba(2,6,23,0.55)",
  backdropFilter: "blur(6px)",
};

const quickCommands = [
  { label: "월드 상태 동기화", command: "request_world_state" },
  { label: "Planner 실행", command: "command_planner" },
  { label: "Executor 1회 실행", command: "command_executor" },
  { label: "Self-Check", command: "command_selfcheck" },
];

const connectionBadge = {
  connecting: { text: "⏳ 연결 중", color: "#ffd166" },
  connected: { text: "🟢 연결됨", color: "#70ffbe" },
  closed: { text: "🟡 재시도", color: "#f6bd60" },
  error: { text: "🔴 오류", color: "#ff6b6b" },
};

const nowLabel = () => new Date().toISOString();

export default function App() {
  const [logs, setLogs] = useState([]);
  const [worldState, setWorldState] = useState(null);
  const [systemStats, setSystemStats] = useState(null);
  const [status, setStatus] = useState("connecting");
  const [input, setInput] = useState("");
  const [chatHistory, setChatHistory] = useState([]);
  const [jobs, setJobs] = useState([]);

  const appendLog = useCallback((entry) => {
    setLogs((prev) => [
      ...prev.slice(-199),
      {
        _id: makeId(),
        timestamp: entry.timestamp || nowLabel(),
        ...entry,
      },
    ]);
  }, []);

  useEffect(() => {
    connectWS({
      onMessage: (msg) => {
        if (msg?.type === "llm_response") {
          setChatHistory((prev) => [
            ...prev.slice(-49),
            {
              role: "assistant",
              text: msg.message,
              timestamp: msg.timestamp || nowLabel(),
            },
          ]);
          appendLog({
            type: "llm_response",
            message: msg.message,
            timestamp: msg.timestamp,
          });
          return;
        }
        if (msg?.type === "job_preview") {
          setJobs(msg.jobs || []);
          return;
        }
        appendLog({
          type: msg?.type || "event",
          message: msg?.message || JSON.stringify(msg),
        });
      },
      onWorldState: (snapshot) => {
        const payload =
          snapshot?.world_state || snapshot?.payload || snapshot || null;
        if (payload) {
          setWorldState(payload);
        }
        appendLog({
          type: "world_state",
          message: "월드 상태 업데이트",
          timestamp: payload?.timestamp || snapshot?.timestamp,
        });
      },
      onStatus: (state) => setStatus(state),
    });

    let sysWS;
    try {
      const proto = window.location.protocol === "https:" ? "wss://" : "ws://";
      // 새로운 시스템 모니터링 채널 (/ws/system2)
      sysWS = new WebSocket(`${proto}${window.location.host}/ws/system2`);
      sysWS.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          if (data?.type === "system_stats") {
            setSystemStats(data);
          }
        } catch (err) {
          console.warn("system WS parse 실패", err);
        }
      };
    } catch (err) {
      console.warn("system WS 미구현 또는 연결 불가", err);
    }
    return () => sysWS && sysWS.close();
  }, [appendLog]);

  const goals = useMemo(
    () => worldState?.planner?.goals ?? [],
    [worldState?.planner?.goals]
  );
  const tasks = useMemo(
    () => worldState?.planner?.tasks ?? [],
    [worldState?.planner?.tasks]
  );
  const actions = useMemo(
    () => (worldState?.actions_log ?? worldState?.last_actions ?? []).slice(),
    [worldState]
  );
  const suggestions = useMemo(
    () => worldState?.reflection?.kernel_suggestions ?? [],
    [worldState?.reflection?.kernel_suggestions]
  );
  const videoInsights = useMemo(
    () => (worldState?.reflection?.videos ?? []).slice().reverse(),
    [worldState?.reflection?.videos]
  );
  const webInsights = useMemo(
    () => (worldState?.reflection?.web_links ?? []).slice().reverse(),
    [worldState?.reflection?.web_links]
  );

  const sendCommand = useCallback(
    (command, payload = {}, successMsg) => {
      const ok = sendWS({ type: "command", command, payload });
      appendLog({
        type: ok ? "command" : "error",
        message: ok
          ? successMsg || `${command} 전송`
          : `${command} 전송 실패 (WS 미연결)`,
      });
      return ok;
    },
    [appendLog]
  );

  const handleFreeText = () => {
    if (!input.trim()) return;
    const msg = input.trim();
    setChatHistory((prev) => [
      ...prev.slice(-49),
      { role: "user", text: msg, timestamp: nowLabel() },
    ]);
    if (
      sendCommand(
        "free_text",
        { message: msg },
        `프리텍스트 전송: ${msg.slice(0, 42)}`
      )
    ) {
      setInput("");
    }
  };

  const handleApproveGoal = (goal) => {
    sendCommand("approve_goal", { goal_id: goal?.id }, `${goal?.title} 승인`);
  };

  const handleTriggerTask = (task) => {
    sendCommand("trigger_task", { task_id: task?.id }, `${task?.title} 실행 요청`);
  };

  const handleApproveSuggestion = (suggestion) => {
    sendCommand(
      "approve_kernel_tuning",
      { suggestion },
      `커널 튜닝 승인: ${suggestion?.param || "제안"}`
    );
  };

  const badge = connectionBadge[status] || connectionBadge.connecting;

  return (
    <div
      style={{
      minHeight: "100vh",
        background: "radial-gradient(circle at top,#0b0b16,#010103 70%)",
        color: "#f7f7ff",
        fontFamily: "Inter, Pretendard, sans-serif",
        padding: "32px 14px 60px",
      }}
    >
      <div style={{ maxWidth: "1280px", margin: "0 auto" }}>
        <header style={{ textAlign: "center", marginBottom: "26px" }}>
          <h1
            style={{
              fontSize: "44px",
              marginBottom: "4px",
              letterSpacing: "-0.02em",
            }}
          >
            RC25S Self-Improvement Console
          </h1>
          <p style={{ opacity: 0.76 }}>Reflection ↔ Planner ↔ Executor Loop</p>
          <span
            style={{
              display: "inline-flex",
              marginTop: "10px",
              padding: "6px 12px",
              borderRadius: "999px",
              border: `1px solid ${badge.color}`,
              color: badge.color,
              fontSize: "14px",
            }}
          >
            {badge.text}
          </span>
        </header>

        <main
          style={{
            display: "grid",
            gap: "18px",
            gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))",
          }}
        >
          <section style={baseCard}>
            <h2 style={{ color: "#ff86d3", fontSize: "18px", marginBottom: 8 }}>
              🧠 리플렉션 & 메모
            </h2>
            {worldState ? (
              <>
                <p>
                  <strong>인사이트:</strong>{" "}
                  {worldState.reflection?.insight || "정보 없음"}
                </p>
                <p>
                  <strong>개선 목표:</strong>{" "}
                  {worldState.reflection?.improvement_goal || "정보 없음"}
                </p>
                <p>
                  <strong>메모리 요약:</strong>{" "}
                  {worldState.memory_summary || "요약 없음"}
                </p>
                <small style={{ opacity: 0.6 }}>
                  업데이트: {worldState.timestamp || "—"}
                </small>
              </>
            ) : (
              <p>⏳ 월드 상태 수신 대기</p>
            )}
          </section>

          <section style={baseCard}>
            <h2 style={{ color: "#ffa5a5", fontSize: "18px", marginBottom: 8 }}>
              🎞️ 최근 YouTube 학습
            </h2>
            {videoInsights.length === 0 ? (
              <p>아직 영상 인사이트가 없습니다.</p>
            ) : (
              <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
                {videoInsights.slice(0, 3).map((item, idx) => (
                  <li
                    key={`${item.url}-${idx}`}
                    style={{
                      marginBottom: "12px",
                      paddingBottom: "10px",
                      borderBottom: "1px solid rgba(255,255,255,0.08)",
                    }}
                  >
                    <div style={{ fontWeight: 600 }}>{item.title || "제목 없음"}</div>
                    <small style={{ opacity: 0.7 }}>{item.timestamp}</small>
                    <p style={{ marginTop: "6px", opacity: 0.8 }}>
                      {item.summary || "요약 대기"}
                    </p>
                    <a
                      href={item.url}
                      target="_blank"
                      rel="noreferrer"
                      style={{ color: "#ffa5a5", fontSize: "13px" }}
                    >
                      영상 열기 ↗
                    </a>
                  </li>
                ))}
              </ul>
            )}
          </section>

          <section style={baseCard}>
            <h2 style={{ color: "#a5c7ff", fontSize: "18px", marginBottom: 8 }}>
              🌐 웹 링크 인사이트
            </h2>
            {webInsights.length === 0 ? (
              <p>아직 웹 링크 분석 기록이 없습니다.</p>
            ) : (
              <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
                {webInsights.slice(0, 3).map((item, idx) => (
                  <li
                    key={`${item.url}-${idx}`}
                    style={{
                      marginBottom: "12px",
                      paddingBottom: "10px",
                      borderBottom: "1px solid rgba(255,255,255,0.08)",
                    }}
                  >
                    <div style={{ fontWeight: 600 }}>{item.title || "제목 없음"}</div>
                    <small style={{ opacity: 0.7 }}>{item.timestamp}</small>
                    <p style={{ marginTop: "6px", opacity: 0.8 }}>
                      {item.summary || "요약 대기"}
                    </p>
                    <a
                      href={item.url}
                      target="_blank"
                      rel="noreferrer"
                      style={{ color: "#a5c7ff", fontSize: "13px" }}
                    >
                      링크 열기 ↗
                    </a>
                  </li>
                ))}
              </ul>
            )}
          </section>

          <section style={baseCard}>
            <h2 style={{ color: "#8ed4ff", fontSize: "18px", marginBottom: 8 }}>
              🎯 목표 (Goals)
            </h2>
            {goals.length === 0 ? (
              <p>등록된 목표가 없습니다.</p>
            ) : (
              <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
                {goals.map((goal) => (
                  <li
                    key={goal.id}
                    style={{
                      marginBottom: "12px",
                      paddingBottom: "10px",
                      borderBottom: "1px solid rgba(255,255,255,0.08)",
                    }}
                  >
                    <div style={{ fontWeight: 600 }}>
                      [{goal.status}] {goal.title}
                    </div>
                    <small style={{ opacity: 0.7 }}>
                      우선순위 {goal.priority} · 분류 {goal.category || "-"}
                    </small>
                    <div style={{ marginTop: "8px" }}>
                      <button
                        onClick={() => handleApproveGoal(goal)}
                        style={{
                          border: "none",
                          background: "#70ffbe",
                          color: "#071612",
                          padding: "6px 10px",
                          borderRadius: "8px",
                          cursor: "pointer",
                          fontWeight: 600,
                        }}
                      >
                        승인
                      </button>
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </section>

          <section style={baseCard}>
            <h2 style={{ color: "#ffd26f", fontSize: "18px", marginBottom: 8 }}>
              🧩 작업 (Tasks)
            </h2>
            {tasks.length === 0 ? (
              <p>실행 대기 작업이 없습니다.</p>
            ) : (
              <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
                {tasks.map((task) => (
                  <li
                    key={task.id}
                    style={{
                      marginBottom: "12px",
                      paddingBottom: "10px",
                      borderBottom: "1px solid rgba(255,255,255,0.08)",
                    }}
                  >
                    <div style={{ fontWeight: 600 }}>
                      [{task.status}] {task.title}
                    </div>
                    <small style={{ opacity: 0.7 }}>
                      goal: {task.goal_id} · priority {task.priority}
                    </small>
                    <div style={{ marginTop: "8px" }}>
                      <button
                        onClick={() => handleTriggerTask(task)}
                        style={{
                          border: "none",
                          background: "#ffd26f",
                          color: "#2a1800",
                          padding: "6px 10px",
                          borderRadius: "8px",
                          cursor: "pointer",
                          fontWeight: 600,
                        }}
                      >
                        실행
                      </button>
                    </div>
                  </li>
                ))}
              </ul>
            )}
          </section>

          <section style={baseCard}>
            <h2 style={{ color: "#9ff7ff", fontSize: "18px", marginBottom: 8 }}>
              ⚙️ 시스템 상태
            </h2>
            {systemStats ? (
              <>
                <p>CPU: {systemStats.cpu ?? "?"}%</p>
                <p>Memory: {systemStats.memory ?? "?"}%</p>
                <p>Disk: {systemStats.disk ?? "?"}%</p>
                <small style={{ opacity: 0.6 }}>{systemStats.time}</small>
              </>
            ) : (
              <p>모니터링 채널 연결 대기</p>
            )}
          </section>

          <section style={baseCard}>
            <h2 style={{ color: "#d4a9ff", fontSize: "18px", marginBottom: 8 }}>
              🛰️ 커널 튜닝 제안
            </h2>
            {suggestions.length === 0 ? (
              <p>새 제안이 없습니다.</p>
            ) : (
              <ul style={{ listStyle: "none", margin: 0, padding: 0 }}>
                {suggestions.map((sug, idx) => (
                  <li
                    key={`${sug.param || "sugg"}-${idx}`}
                    style={{
                      marginBottom: "12px",
                      paddingBottom: "10px",
                      borderBottom: "1px solid rgba(255,255,255,0.08)",
                    }}
                  >
                    <div style={{ fontWeight: 600 }}>
                      {sug.param || "제안"} → {sug.proposed || "-"}
                    </div>
                    <p style={{ opacity: 0.8, margin: "6px 0" }}>
                      {sug.rationale || "설명 없음"}
                    </p>
                    <button
                      onClick={() => handleApproveSuggestion(sug)}
                      style={{
                        border: "1px solid rgba(255,255,255,0.18)",
                        background: "transparent",
                        color: "#d4a9ff",
                        padding: "6px 10px",
                        borderRadius: "8px",
                        cursor: "pointer",
                        fontWeight: 600,
                      }}
                    >
                      승인/반영
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </section>

          <section style={baseCard}>
            <h2 style={{ color: "#7fe8c9", fontSize: "18px", marginBottom: 8 }}>
              ⚡ Quick Commands
            </h2>
            <div style={{ display: "flex", flexWrap: "wrap", gap: "10px" }}>
              {quickCommands.map((cmd) => (
                <button
                  key={cmd.command}
                  onClick={() => sendCommand(cmd.command, {}, cmd.label)}
                  style={{
                    border: "1px solid rgba(255,255,255,0.2)",
                    background: "transparent",
                    color: "#f7f7ff",
                    padding: "8px 12px",
                    borderRadius: "10px",
                    cursor: "pointer",
                    flex: "1 1 140px",
                  }}
                >
                  {cmd.label}
                </button>
              ))}
            </div>
          </section>

          <section style={baseCard}>
            <h2 style={{ color: "#ffd3a0", fontSize: "18px", marginBottom: 8 }}>
              💬 LLM 대화
            </h2>
            {chatHistory.length === 0 ? (
              <p>아직 대화 기록이 없습니다.</p>
            ) : (
              <div style={{ maxHeight: "240px", overflowY: "auto" }}>
                {chatHistory
                  .slice()
                  .reverse()
                  .map((entry, idx) => (
                    <div key={`${entry.timestamp}-${idx}`} style={{ marginBottom: "10px" }}>
                      <div style={{ fontSize: "12px", opacity: 0.7 }}>
                        {entry.role === "user" ? "👤 사용자" : "🤖 RC25S"} ·{" "}
                        {entry.timestamp}
                      </div>
                      <div style={{ whiteSpace: "pre-wrap", marginTop: "4px" }}>
                        {entry.text}
                      </div>
                    </div>
                  ))}
              </div>
            )}
          </section>

          <section style={baseCard}>
            <h2 style={{ color: "#f6f38d", fontSize: "18px", marginBottom: 8 }}>
              🛰️ 실행 프리뷰
            </h2>
            {jobs.length === 0 ? (
              <p>현재 실행 중인 작업이 없습니다.</p>
            ) : (
              <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
                {jobs.map((job) => (
                  <li
                    key={job.id}
                    style={{
                      marginBottom: "12px",
                      paddingBottom: "10px",
                      borderBottom: "1px solid rgba(255,255,255,0.08)",
                    }}
                  >
                    <div style={{ fontWeight: 600 }}>{job.label}</div>
                    <small style={{ opacity: 0.7 }}>
                      상태: {job.status} · 시작: {job.started_at}
                    </small>
                    {job.url && (
                      <div style={{ fontSize: "12px", marginTop: "4px" }}>{job.url}</div>
                    )}
                    {job.error && (
                      <div style={{ color: "#ff7b7b", fontSize: "13px" }}>{job.error}</div>
                    )}
                  </li>
                ))}
              </ul>
            )}
          </section>

          <section
            style={{
              ...baseCard,
              gridColumn: "1 / -1",
            }}
          >
            <h2 style={{ color: "#ffb3c1", fontSize: "18px", marginBottom: 8 }}>
              💬 프리 텍스트 명령 / 채팅
            </h2>
            <div
              style={{
                display: "flex",
                gap: "10px",
                flexWrap: "wrap",
              }}
            >
              <input
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="LLM에게 보낼 메시지 또는 링크를 입력"
                style={{
                  flex: "1 1 260px",
                  padding: "10px 12px",
                  borderRadius: "10px",
                  border: "1px solid rgba(255,255,255,0.12)",
                  background: "#050509",
                  color: "#f7f7ff",
                }}
              />
              <button
                onClick={handleFreeText}
                style={{
                  border: "none",
                  borderRadius: "10px",
                  background:
                    "linear-gradient(135deg, #ff86d3 0%, #ffb677 100%)",
                  padding: "10px 18px",
                  color: "#0c030d",
                  fontWeight: 700,
                  cursor: "pointer",
                }}
              >
                전송
              </button>
            </div>
          </section>

          <section
            style={{
              ...baseCard,
              gridColumn: "1 / -1",
            }}
          >
            <h2 style={{ color: "#9ad7ff", fontSize: "18px", marginBottom: 8 }}>
              📜 최근 명령 / 로그
            </h2>
            <div
              style={{
                maxHeight: "240px",
                overflowY: "auto",
                borderRadius: "12px",
                background: "#05050a",
                padding: "12px",
              }}
            >
              {logs.length === 0 && <p>아직 로그가 없습니다.</p>}
              {logs
                .slice()
                .reverse()
                .map((log) => (
                  <div
                    key={log._id}
                    style={{
                      borderBottom: "1px solid rgba(255,255,255,0.08)",
                      padding: "8px 0",
                    }}
                  >
                    <div style={{ fontSize: "12px", opacity: 0.6 }}>
                      {log.timestamp}
                    </div>
                    <div style={{ fontWeight: 600 }}>
                      [{log.type}] {log.message}
                    </div>
                    {log.payload && (
                      <code
                        style={{
                          fontSize: "12px",
                          opacity: 0.7,
                          display: "block",
                          marginTop: "4px",
                          wordBreak: "break-all",
                        }}
                      >
                        {JSON.stringify(log.payload)}
                      </code>
                    )}
          </div>
        ))}
            </div>
          </section>

          <section
            style={{
              ...baseCard,
              gridColumn: "1 / -1",
            }}
          >
            <h2 style={{ color: "#f7e480", fontSize: "18px", marginBottom: 8 }}>
              ✅ 승인/명령 실행 로그
            </h2>
            {actions.length === 0 ? (
              <p>최근 실행 기록이 없습니다.</p>
            ) : (
              <ul style={{ listStyle: "none", margin: 0, padding: 0 }}>
                {actions
                  .slice()
                  .reverse()
                  .map((action, idx) => (
                    <li
                      key={`${action.command}-${idx}`}
                      style={{
                        marginBottom: "10px",
                        paddingBottom: "10px",
                        borderBottom: "1px solid rgba(255,255,255,0.08)",
                      }}
                    >
                      <div style={{ fontWeight: 600 }}>
                        {action.command} —{" "}
                        {typeof action.payload === "object"
                          ? JSON.stringify(action.payload)
                          : action.payload}
                      </div>
                      <small style={{ opacity: 0.6 }}>
                        {action.time || action.timestamp || "시간 정보 없음"}
                      </small>
                    </li>
                  ))}
              </ul>
            )}
          </section>
        </main>
      </div>
    </div>
  );
}
