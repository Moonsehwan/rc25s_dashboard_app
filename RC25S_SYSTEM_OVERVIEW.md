## 🧠 RC25S: Autonomous Realtime Coding & Self‑Healing System

**RC25S는 “AI가 스스로 코드를 수정·배포·복구·개발”하는 자율형 개발 시스템(AGI Assistant Developer)** 입니다.  
인간이 매번 세부 명령을 내리지 않아도, 시스템이 스스로 상태를 인지하고 고치며, 개발 환경을 유지·업그레이드하는 것이 목표입니다.

---

## 🎯 최종 목표 (Final Objective)

RC25S의 성숙 단계는 다음 4단계로 정의됩니다.

- **🧩 1단계 – Self‑Healing (자율 복구)**  
  - 서비스 다운/에러/빌드 실패 발생 시, **AI가 스스로 원인을 분석 → 수정 → 재시작**까지 처리  
  - 예: Nginx 설정 오류, FastAPI 다운, React 빌드 실패 등을 자동 감지 후 복원

- **⚙️ 2단계 – Self‑Improvement (자동 리팩토링)**  
  - 코드 구조, API 스펙, UI를 **Cursor / Apidog / LLM**을 활용해 지속적으로 개선  
  - 코드 스멜 제거, API 일관성 향상, UI/UX 다듬기 등을 자동으로 수행

- **🧠 3단계 – Self‑Development (자기 개발)**  
  - 인간이 “새 기능 추가해줘”라고 직접 말하지 않아도,  
  - **AI가 스스로 필요한 기능을 제안하고, 설계하고, 구현**하는 단계

- **🌐 4단계 – Self‑Orchestration (지능형 배포)**  
  - Nginx / FastAPI / React / DB / LLM 인프라 전체를  
  - **AI가 자동으로 배포·모니터링·최적화**하는 수준

---

## 🧱 전체 시스템 아키텍처 (개념)

텍스트 기반 개념 구조는 아래와 같습니다.

```text
           ┌───────────────────────────────────────┐
           │          FRONTEND (React)            │
           │ - 실시간 LLM 대시보드 UI             │
           │ - CPU/RAM 모니터링 위젯              │
           │ - AGI 상태/로그 스트림               │
           └───────────────────────────────────────┘
                           │ WebSocket / HTTP
                           ▼
┌────────────────────────────────────────────────────────────┐
│                 BACKEND (FastAPI / Python)                 │
│  - /health : Self-Check API                                │
│  - /llm    : Hybrid LLM 엔드포인트                         │
│  - /agi/ws : 실시간 상태/로그 WebSocket                    │
│  - Auto-Heal, Rebuild, systemd status 조회                 │
│  - Cursor / Apidog 연동 브리지                             │
└────────────────────────────────────────────────────────────┘
                 │                               │
                 ▼                               ▼
      ┌───────────────────────┐        ┌──────────────────────┐
      │  Auto-Heal Watcher    │        │ Cursor + Apidog Hub  │
      │ - nginx/fapi 복구     │        │ - 코드 리팩토링 요청 │
      │ - 메모리/캐시 감시    │        │ - API 문서 동기화    │
      │ - systemd 로그 기록   │        │ - 자동 테스트/배포   │
      └───────────────────────┘        └──────────────────────┘
                 │                               │
                 └──────────────┬────────────────┘
                                ▼
                      ┌───────────────────────┐
                      │  RC25S SELF‑CHECK     │
                      │ - Frontend 정적 파일  │
                      │ - LLM 응답 테스트     │
                      │ - 재빌드/Reload 수행 │
                      └───────────────────────┘
```

이 외에도, RC25H/RC25S 코어 에이전트, Reflection 엔진, Memory 엔진, Auto‑Fix 루프 등은  
`RC25H_CentralCore.py`, `rc25s_autofix_system.py`, `reflection_engine.py` 등에서 동작합니다.

---

## 📂 주요 디렉터리 및 컴포넌트

- **루트 경로**: `/srv/repo/vibecoding`

- **AGI 코어 / 루프**
  - `RC25H_CentralCore.py`  
    - Reflection 결과와 메모리 상태를 읽어 **REFLECT / MEMORY / AUTOFIX / CREATIVE** 모드 중 하나를 선택하고 실행하는 중앙 루프
  - `rc25s_autofix_system.py`, `reflection_engine.py`, `memory_engine.py`  
    - 코드 자동 수정, 자기 반성(reflection), 장기 메모리 업데이트 등의 핵심 로직

- **LLM / 라우터**
  - `llm_router.py`, `free_llm_server.py`, `rc25s_openai_wrapper.py`  
    - 로컬 LLM과 OpenAI API를 **Hybrid**로 사용하는 백엔드 구성

- **Dashboard / UI**
  - `rc25s_dashboard_app/rc25s_frontend/`  
    - Vite + React 기반 **실시간 AGI 대시보드**  
    - WebSocket으로 상태/로그를 받아서 렌더링
  - `rc25s_agent_backend.py`  
    - `/health`, `/`, `/agi/ws` 를 제공하는 FastAPI 서버
  - `rc25s_dashboard/agi_status_dashboard.py`, `rc25s_dashboard/index.html`  
    - 별도의 간단한 FastAPI + HTML 대시보드 구현 (레거시/보조용)

- **자동화 / 배포 스크립트**
  - `upgrade_rc25s_autoheal_full.sh`, `setup_rc25s_full_agi.sh`, `setup_dashboard_full.sh`  
    - RC25S 전체 설치/업그레이드/대시보드 배포
  - `fix_nginx_*.sh`, `rebuild_nginx_rc25s_*.sh`  
    - Nginx 설정 복구 및 재빌드
  - `rc25s-selfcheck.sh`, `RC25S_AI_Autoheal.sh` (또는 유사 이름 스크립트들)  
    - Self‑Check + Auto‑Heal 주기 실행용 스크립트

- **외부 연동**
  - `config/codex.json`  
    - MCP Vibe Codex 원격 워크스페이스/명령 실행 설정
  - `rc25s_dashboard_app/backend/cursor_client.py`  
    - Cursor Composer API 연동 유틸
  - `rc25s_dashboard_app/backend/utils/apidog_sync.py`  
    - Apidog API 문서 자동 동기화

보다 상세한 Dashboard 관련 상태는 `RC25S_DASHBOARD_STATUS.md`에 정리되어 있습니다.

---

## ⚙️ 현재 구현 상태 (2025‑11 기준)

아래 표는 RC25S 전체 로드맵 중 구현된 부분과 예정 상태를 요약합니다.

- **✅ Auto‑Heal (Nginx/FastAPI)**  
  - 설정 오류, 백엔드 다운 시 **자동 복구 스크립트 + systemd + Nginx reload**로 복원

- **✅ Hybrid LLM Backend (부분)**  
  - 로컬 LLM + OpenAI Fallback 구조가 일부 구현되어 있으며, 라우터/엔드포인트와 연동 진행 중

- **✅ Dashboard (Frontend + WebSocket)**  
  - React 대시보드 및 WebSocket 로그/상태 뷰어 구현  
  - 시각화 위젯/세분화는 진행 중

- **✅ Self‑Check 루프**  
  - 주기적으로 백엔드/프론트/LLM 상태를 확인하고, 이상 시 Auto‑Heal 트리거

- **✅ Apidog Integration**  
  - FastAPI 기반 API를 Apidog에 동기화하는 유틸 구현

- **⚠️ Cursor Integration (Composer)**  
  - API 연동 유틸은 있으나, DNS/네트워크 제약으로 직접 호출이 불안정  
  - Proxy/Relay 또는 내부 브리지 필요

- **🚧 Unicode Auto‑Rebuild Agent (예정)**  
  - React 빌드 시 emoji/Unicode 오류를 자동 감지하고, 이스케이프 변환 후 재빌드

- **🚧 AI‑Led Code Refactor (예정)**  
  - Cursor ↔ LLM 협력으로, 구조적 리팩토링을 자동 수행하는 파이프라인

- **🚧 Web IDE (예정)**  
  - 브라우저에서 코드 실시간 수정 가능한 Web IDE (code‑server 등)와 RC25S 연동

- **🪄 AGI Autonomous Upgrade (계획)**  
  - RC25S가 자신을 분석·설계·개선까지 수행하는 완전 자율 업데이트 모드

대시보드와 Self‑Check의 구체적인 현재 상태는 `RC25S_DASHBOARD_STATUS.md`를 참고합니다.

---

## 🧩 RC25S가 “스스로 하는 일” 예시 시나리오

1. **문제 감지**  
   - Frontend 빌드 실패, 로그에 `UnicodeDecodeError` 또는 emoji 관련 오류 감지

2. **AI 판단**  
   - LLM 분석: “`App.tsx` 24번째 줄 Unicode 문자열을 `\uXXXX` 이스케이프로 변환 필요”

3. **코드 수정**  
   - AI가 해당 파일을 패치하고, `npm run build` 또는 `vite build` 재실행  
   - 필요 시 Git 커밋/태깅까지 자동 수행

4. **시스템 복구**  
   - 빌드 성공 후 Nginx reload  
   - Auto‑Heal 로그에 성공 내역 기록

5. **결과 보고**  
   - `[AI-REPORT] ✅ Build success after Unicode fix.` 같은 리포트 메시지를  
     Dashboard 또는 로그 파일로 남김

---

## 📘 이 파일과 다른 컨텍스트 파일의 관계

- **`RC25S_SYSTEM_OVERVIEW.md` (이 파일)**  
  - RC25S 전체 목표, 아키텍처, 주요 컴포넌트, 현재 구현 상태를 개략적으로 설명

- **`RC25S_DEV_CONTEXT.md`**  
  - 더 상세한 개발 히스토리, 스크립트 간 관계, systemd 서비스/타이머, Nginx 라우팅 구조 등을 포함

- **`RC25S_DASHBOARD_STATUS.md`**  
  - Dashboard(React/FastAPI/WebSocket)와 Self‑Check/Auto‑Heal 흐름에 초점을 맞춘 **실제 상태 리포트**

Cursor, AGI 에이전트, 또는 다른 자동화 도구는  
1) 이 파일로 RC25S의 큰 그림을 파악하고,  
2) `RC25S_DASHBOARD_STATUS.md`, `RC25S_DEV_CONTEXT.md`로 세부 구현을 추적한 뒤,  
3) 실제 코드/스크립트 수정을 수행하는 흐름을 따르면 됩니다.


