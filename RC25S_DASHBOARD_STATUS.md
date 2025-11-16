## 🧠 RC25S Dashboard 현재 상태 요약 (2025-11 기준)

- **프로젝트 이름**: RC25S Dashboard  
- **루트 경로**: `/srv/repo/vibecoding`  
- **관련 상위 컨텍스트**: `RC25S_DEV_CONTEXT.md` (전체 시스템 개요는 거기에 정리되어 있음)

이 문서는 **“Dashboard / 자율 모니터링 UI”에 한정된 실제 구현 상태**를 요약합니다.  
Cursor / Apidog / RC25S 에이전트가 **프론트엔드·백엔드·Self-Check·Auto-Heal 연결 상태를 빠르게 파악**하는 용도입니다.

---

## 📁 Dashboard 관련 실제 디렉터리 구조 (요약)

```text
/srv/repo/vibecoding
├── rc25s_dashboard_app/
│   ├── backend/
│   │   ├── cursor_client.py      # Cursor Composer API 클라이언트 (단일 스크립트 형태)
│   │   └── utils/
│   │       └── apidog_sync.py    # Apidog API 문서 동기화 유틸
│   │
│   ├── rc25s_frontend/           # Vite 기반 React 대시보드
│   │   ├── src/
│   │   │   ├── App.jsx           # 메인 React 컴포넌트 (WebSocket 로그 뷰어)
│   │   │   ├── wsClient.js      # WebSocket 클라이언트 (wss://api.mcpvibe.org/ws/agi)
│   │   │   ├── components/
│   │   │   │   ├── AGIConsole.jsx
│   │   │   │   └── SystemMonitor.jsx
│   │   │   └── main.jsx          # React 엔트리 포인트
│   │   ├── dist/                 # 최신 Vite 빌드 결과
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   └── vite.config.js
│   │
│   ├── ui.html                   # 단일 HTML AGI Dashboard (직접 WebSocket 연결)
│   └── (기타) 재빌드/수정용 셸 스크립트들
│
├── rc25s_dashboard/
│   └── agi_status_dashboard.py   # 별도 Dashboard 관련 Python 모듈 (추가 분석 필요)
│
├── rc25s_agent_backend.py        # FastAPI 기반 AGI WebSocket/헬스체크 서버
└── logs/
    └── (여러 로그 파일, Dashboard/AGI 상태 추적용)
```

---

## 🌐 프론트엔드 (Vite + React) 실제 상태

### 1) 메인 앱 (`rc25s_dashboard_app/rc25s_frontend/src/App.jsx`)

- **역할**
  - `connectWS`(wsClient)를 통해 WebSocket 서버에 연결
  - 수신한 메시지를 `logs` 상태에 누적해 **단순 로그 타임라인 UI**로 렌더링
  - 스타일은 인라인 CSS로 적용된 **풀스크린 다크 테마 대시보드**
- **핵심 구현**
  - WebSocket 콜백에서 전달된 메시지 객체/문자열을 그대로 `JSON.stringify` 후 `<code>`로 출력
  - 아직 **CPU/RAM/LLM 상태를 별도 카드/위젯으로 나누는 구조까지는 안 가고**, “스트림 로그 뷰어” 형태에 가까운 상태

```4:36:rc25s_dashboard_app/rc25s_frontend/src/App.jsx
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
```

> **요약**: 프론트엔드는 “실시간 로그 뷰”로 동작 가능한 상태이며, CPU/RAM/LLM/빌드 상태 등은 아직 개별 위젯으로 분리되기 전 단계입니다.

### 2) WebSocket 클라이언트 (`rc25s_dashboard_app/rc25s_frontend/src/wsClient.js`)

- **엔드포인트**
  - 현재는 **고정 값**으로 `wss://api.mcpvibe.org/ws/agi`에 연결하도록 구현됨.
  - 재연결 로직 포함 (`onerror`, `onclose` 시 5초 후 재시도).
- **특징**
  - 메시지를 JSON으로 파싱 후 콜백에 그대로 전달.
  - 내부에서 직접 상태를 관리하지 않고, 상위 `App.jsx`에서 상태를 관리.

```1:24:rc25s_dashboard_app/rc25s_frontend/src/wsClient.js
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
```

> **주의할 점**: 서버 내부 FastAPI WebSocket 엔드포인트(`/agi/ws`)와는 달리, 이 클라이언트는 **퍼블릭 호스트 `api.mcpvibe.org` 기준 엔드포인트**에 고정되어 있어, 로컬 테스트/다른 호스트에서 실행 시에는 별도 수정이 필요합니다.

### 3) 빌드/배포 상태 (Vite)

- `rebuild_dashboard.sh` + `rebuild_dashboard.log` 기준:
  - 2025-11-14 시점에 **Vite 빌드가 성공**했고,  
    `dist/assets/index-*.js` 빌드 산출물이 Nginx와 연결되도록 설정된 상태입니다.
  - 로그에 `https://api.mcpvibe.org/dashboard` 경로로 접근하라고 안내되어 있음.

```1:6:rc25s_dashboard_app/rc25s_frontend/rebuild_dashboard.log
[2025-11-14 21:56:04] 🚀 Rebuilding AGI Dashboard from scratch...
[2025-11-14 21:56:04] ✅ vite.config.js rewritten.
[2025-11-14 21:56:04] ⚙️ Running Vite build...
[2025-11-14 21:56:04] ✅ Build JS reference detected: /dashboard/assets/index-RQjVk0yp.js
[2025-11-14 21:56:04] ✅ Nginx restarted successfully.
[2025-11-14 21:56:04] 🎯 Dashboard rebuild complete. Visit: https://api.mcpvibe.org/dashboard
```

> **이전 설명과의 차이점**: 기존 CRA 기반 `/agi/static/js/main.*.js` 경로 대신,  
> 현재는 **Vite 빌드 결과 `/dashboard/assets/index-*.js`**를 사용하는 구조로 이미 업데이트된 상태입니다.

---

## ⚙️ 백엔드 / Self-Check / Auto-Heal 연동 실제 상태

### 1) AGI Dashboard FastAPI 서버 (`rc25s_agent_backend.py`)

- **역할**
  - `/health` 엔드포인트 제공 (상태 `"ok"` 응답)
  - `/` 에서 `rc25s_dashboard_app/ui.html`을 서빙 (단일 HTML 대시보드)
  - `/agi/ws` WebSocket 엔드포인트 제공
- **WebSocket 동작**
  - 접속 시 “🤖 RC25S Agent Dashboard 연결됨” 메시지 전송
  - 클라이언트로부터 텍스트 명령을 받아 **에코 + 로그 일부 조회** 기능 제공
  - `"로그"`, `"상태"` 키워드 포함 시 `logs/agi_reflection.log` 마지막 15줄 전송

```5:34:rc25s_agent_backend.py
app = FastAPI()

@app.get("/health")
async def health():
    return {"status":"ok","model":"RC25S-Agent","time":datetime.datetime.now().isoformat()}

@app.get("/")
async def root():
    html = open("/srv/repo/vibecoding/rc25s_dashboard_app/ui.html","r",encoding="utf-8").read()
    return HTMLResponse(html)

@app.websocket("/agi/ws")
async def ws(websocket: WebSocket):
    await websocket.accept()
    clients.append(websocket)
    await websocket.send_text("🤖 RC25S Agent Dashboard 연결됨")
    ...
```

> **상태 요약**: FastAPI 기반의 **기본 AGI Dashboard 백엔드(헬스체크 + 간단 WebSocket 콘솔)**는 동작 가능한 수준까지 구현되어 있습니다.  
> LLM 연동(`/llm`)이나 하이브리드 LLM 로직은 **이 파일에는 아직 포함되어 있지 않으며**, 다른 AGI 코어와 결합이 필요한 상태입니다.

### 2) Self-Check 스크립트 (`rc25s-selfcheck.sh`)

- **역할**
  - `systemd` 타이머에서 주기적으로 호출되어 RC25S 상태를 점검하고, 필요 시 Auto-Heal 동작 수행.
- **체크 항목**
  - `http://127.0.0.1:4545/health` → FastAPI 백엔드 상태 확인
    - 실패 시 `systemctl restart rc25s-dashboard.service`
  - `http://127.0.0.1:4545/llm` → LLM 통합 체크 (현재 구현 여부는 별도 확인 필요)
  - `https://api.mcpvibe.org/agi/static/js/main.ffd914ce.js` → 프론트엔드 정적 JS 접근 가능 여부
  - `https://api.mcpvibe.org/agi/manifest.json` → PWA Manifest 확인

```8:36:rc25s-selfcheck.sh
# ✅ 1. FastAPI /health check
if curl -s http://127.0.0.1:4545/health | grep -q "ok"; then
  log "✅ FastAPI backend responding correctly."
else
  log "❌ FastAPI backend not responding. Restarting..."
  systemctl restart rc25s-dashboard.service
fi
...
# ✅ 3. Frontend JS & Manifest
if curl -sI https://api.mcpvibe.org/agi/static/js/main.ffd914ce.js | grep -q "200"; then
  log "✅ Frontend static JS accessible."
else
  log "❌ Frontend static files missing. Reloading Nginx..."
  systemctl reload nginx
fi

if curl -sI https://api.mcpvibe.org/agi/manifest.json | grep -q "200"; then
  log "✅ Manifest OK."
else
  log "⚠️ Manifest not reachable."
fi
```

> **중요한 불일치 포인트**  
> - Self-Check는 여전히 **옛 CRA 경로(`/agi/static/js/main.*.js`)와 manifest.json**을 기준으로 검사하고 있습니다.  
> - 반면, 실제 대시보드는 **Vite 빌드(/dashboard/assets/index-*.js)**로 이미 전환되어 있어,  
>   - JS 체크 → 실패로 인식하고 Nginx reload를 반복할 가능성  
>   - Manifest 체크 → “⚠️ Manifest not reachable.” 로그가 계속 찍힐 가능성이 큽니다.  
> - 추후에는 **Self-Check 스크립트를 Vite 빌드 아티팩트와 Nginx 라우팅에 맞게 업데이트**해야 합니다.

### 3) Auto-Heal / 로그

- Auto-Heal 마스터 스크립트와 타이머/서비스 유닛은 `RC25S_DEV_CONTEXT.md`에 정리된 구조대로 존재하며,  
  Dashboard 관련 문제(정적 파일 404, Nginx 설정 오류 등) 발생 시 **Nginx reload 및 설정 복구 스크립트**를 호출하는 구조입니다.
- `/srv/repo/vibecoding/logs/` 및 `/var/log/rc25s-autoheal.log` 계열 로그에  
  Self-Check와 Auto-Heal의 실제 동작 기록이 남도록 설계되어 있습니다.

---

## 🤝 Cursor / Apidog 연동 실제 상태

### 1) Cursor Composer 클라이언트 (`backend/cursor_client.py`)

- **구현 상태**
  - 환경 변수 `CURSOR_API` (기본값 `https://api.cursor.sh/composer`)와 `CURSOR_API_KEY`를 사용.
  - CLI 형태로 실행되며, 인자로 받은 프롬프트(또는 기본 프롬프트)를 Cursor Composer API로 전송.
  - 응답을 JSON 형태로 출력만 하고, 아직 Dashboard/백엔드 로직과 **직접 연결되지는 않음**.

```4:24:rc25s_dashboard_app/backend/cursor_client.py
CURSOR_API = os.getenv("CURSOR_API", "https://api.cursor.sh/composer")
API_KEY = os.getenv("CURSOR_API_KEY")
...
def run_cursor(prompt: str):
    try:
        res = requests.post(
            CURSOR_API,
            headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
            json={"prompt": prompt}
        )
        ...
    except Exception as e:
        print("⚠️ Cursor call failed:", e)
        return None
```

> **상태 요약**: Cursor 연동은 **단일 유틸리티 스크립트 수준까지 구현**되어 있으며,  
> 아직 FastAPI 엔드포인트나 Dashboard UI와 직접 연계된 자동 리팩토링/코드 수정 파이프라인은 구축되지 않은 상태입니다.

### 2) Apidog 연동 (`backend/utils/apidog_sync.py`)

- **구현 상태**
  - 환경 변수 `APIDOG_API_KEY`를 사용하여 `https://api.apidog.com/v1/api-docs/sync`로 POST.
  - `project: "RC25S"` / `description: "Cursor-Generated API sync"` 형태의 페이로드 전송.
  - 실행 시 상태 코드와 응답 바디를 그대로 출력.

```4:21:rc25s_dashboard_app/backend/utils/apidog_sync.py
APIDOG_KEY = os.getenv("APIDOG_API_KEY")
APIDOG_URL = "https://api.apidog.com/v1/api-docs/sync"

def sync_apidog():
    if not APIDOG_KEY:
        print("⚠️ Missing Apidog API key.")
        return
    payload = {"project": "RC25S", "description": "Cursor-Generated API sync"}
    ...
```

> **상태 요약**: Apidog 연동 유틸은 준비되어 있으며,  
> 실제 FastAPI 라우터 메타데이터와 연결해 **자동 API 문서화/테스트 시나리오 생성**으로 확장할 수 있는 여지가 있습니다.

---

## 🔍 “설명 vs 실제 코드” 정합성 체크

- **프론트엔드**
  - 설명: CRA + TypeScript 기반 `App.tsx` / WebSocket(`ws://localhost:4545/ws`) 구조  
  - 실제: **Vite + React (JSX)** 기반 `App.jsx` / WebSocket(`wss://api.mcpvibe.org/ws/agi`) 구조  
  - 결론: **컨셉은 동일(실시간 상태/LLM 메시지 대시보드)**이나, 구현 스택과 엔드포인트는 변경된 최신 버전이 존재.

- **백엔드**
  - 설명: `rc25s_dashboard_app/backend/main.py` 또는 `server.py` 형태의 FastAPI 서버  
  - 실제: `rc25s_agent_backend.py`에 FastAPI 서버가 구현되어 있고,  
    `rc25s_dashboard_app/backend/`에는 Cursor / Apidog 유틸만 존재.  
  - 결론: **파일 위치와 모듈 구조가 설명과 다소 다르며**, Dashboard 백엔드 역할은 `rc25s_agent_backend.py`가 실제로 담당.

- **Self-Check / 프론트 정적 파일**
  - 설명: `manifest.json` “not reachable” 상태  
  - 실제: Self-Check 스크립트는 여전히 옛 CRA 경로(`/agi/static/js/main.*.js`, `/agi/manifest.json`)를 검사.  
  - 대시보드는 Vite `/dashboard/assets/index-*.js` 구조로 빌드/배포.  
  - 결론: **Self-Check 기준 경로와 실제 배포 경로가 어긋난 상태**이며, 이로 인해 경고 로그가 계속 발생할 수 있음.

---

## ✅ 현재까지 구현된 Dashboard 관련 기능 요약

- **동작하는 부분**
  - Vite 기반 React 대시보드(`rc25s_frontend`) 빌드 및 Nginx 연동
  - AGI Dashboard FastAPI 백엔드 (`rc25s_agent_backend.py`)의 `/health`, `/`, `/agi/ws` 기본 기능
  - Self-Check 스크립트에 의한 Backend/LLM/Frontend 경로 점검 및 Auto-Heal 트리거 로직 뼈대
  - Cursor / Apidog 연동 유틸 스크립트 (환경변수 세팅 시 수동 실행 가능)

- **부분 구현 / 향후 개선 필요**
  - WebSocket 경로를 **환경에 따라 선택 가능하게**(로컬 vs 퍼블릭 호스트) 구성
  - Self-Check 스크립트의 정적 파일/manifest 경로를 **Vite 빌드 산출물 기준으로 업데이트**
  - LLM 하이브리드 엔진과 Dashboard 간의 데이터 플로우(LLM 응답 → WebSocket → React 위젯) 구체화
  - Cursor/Apidog 유틸을 FastAPI 라우터/대시보드 UI와 연결해 **“AI 주도 리팩토링/문서화 파이프라인”** 완성

---

## 🧭 이 문서를 Cursor / 에이전트가 활용하는 방법

1. **Dashboard 관련 작업 전**  
   - 이 파일(`RC25S_DASHBOARD_STATUS.md`)과 상위 컨텍스트(`RC25S_DEV_CONTEXT.md`)를 먼저 읽고,  
     실제 디렉터리·엔드포인트·빌드 경로를 파악합니다.
2. **프론트엔드/백엔드/셀프체크 수정 시**  
   - 여기서 정리한 **“불일치 포인트(Self-Check 경로 vs Vite 경로 등)”**를 우선적으로 해결합니다.
3. **Self-Healing / Self-Improvement 고도화 단계로 갈 때**  
   - 이 문서를 기준으로, “어디까지 구현되어 있는지”를 체크포인트로 삼고  
   - 새로운 기능(Unicode Auto-Rebuild, Intelligent Testing, AGI Self-Upgrade 등)을 단계적으로 추가하면 됩니다.

> 이 파일은 2025-11 시점 실제 코드 기준으로 작성되었습니다.  
> 향후 디렉터리 구조, 빌드 경로, 엔드포인트가 변경될 경우 **반드시 이 문서를 함께 업데이트**해야  
> RC25S가 스스로 자신의 상태를 정확히 이해하고 관리할 수 있습니다.


