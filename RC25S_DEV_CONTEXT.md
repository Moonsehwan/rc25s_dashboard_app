# 🧠 RC25S 전체 개발 상태 요약 (실제 서버 기준 / Cursor용 컨텍스트)

## 🏗️ 프로젝트 개요

- **프로젝트 이름**: RC25S Dashboard / AGI Core
- **루트 경로**: `/srv/repo/vibecoding`
- **주요 구성 요소**:
  - LLM 기반 AGI 코어 (`agi_core/engine.py`)
  - RC25S Dashboard 웹 앱 (`rc25s_dashboard_app/` + `dashboard/`)
  - Nginx + Auto-Heal + Self-Check systemd 서비스들 (`rc25s-*.service`, `rc25s-*.timer`)

Cursor는 이 파일을 읽고 나서 **코드 리팩터링, 서비스 관리, React 대시보드 수정, Auto-Heal 로직 개선**까지 이어서 작업한다고 가정하면 됨.

---

## 📁 실제 디렉토리 구조 (요약)

```text
/srv/repo/vibecoding
├── agi_core/                  # AGI 코어 엔진
│   └── engine.py              # LLM/에이전트 메인 엔진 모듈
│
├── rc25s_dashboard_app/       # RC25S Dashboard 앱(백엔드 + 프론트엔드 래퍼)
│   ├── backend/
│   │   ├── cursor_client.py   # Cursor Composer ↔ 서버 LLM/도구 브리지
│   │   └── utils/
│   │       └── apidog_sync.py # Apidog 연동 유틸리티 (API 문서/테스트)
│   │
│   ├── rc25s_frontend/        # RC25S React/Vite 프론트엔드 소스
│   │   ├── src/
│   │   ├── public/
│   │   ├── dist/              # 빌드 결과 (Nginx/서비스에서 사용)
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   └── ui.html                # 간단한 UI/임시 엔트리 포인트
│
├── dashboard/                 # 별도 Vite/React 기반 대시보드 앱
│   ├── src/
│   ├── public/
│   ├── dist/
│   ├── node_modules/
│   ├── package.json
│   └── tsconfig.json
│
├── config/                    # Nginx/서비스/앱 관련 설정 스크립트/파일들
│   (...세부 내용은 개별 파일을 열어서 확인 필요...)
│
├── agi_generated/             # AGI 자동 생성 결과(코드/설정/메모리 등)
├── agentkit/                  # 에이전트 툴킷/유틸
│
├── 스크립트들 (일부만 기재)
│   ├── agi_autofix_loop.py
│   ├── agi_autofix_setup.sh
│   ├── agi_loop.py
│   ├── agi_loop_autosetup.sh
│   ├── agi_status_dashboard.py
│   ├── agi_system_manager.py
│   ├── ai_react_autobuilder.py
│   ├── ai_react_autoloop.py
│   ├── ai_react_builder.py
│   ├── deploy_rc25s_full_dashboard.sh
│   ├── deploy_rc25s_agent_dashboard.sh
│   ├── deploy_rc25s_agent_full.sh
│   ├── deploy_rc25s_agent_studio.sh
│   ├── deploy_rc25s_full_agi_interface.sh
│   ├── deploy_rc25s_react_dashboard.sh
│   ├── fix_dashboard_app_fullpatch.sh
│   ├── fix_dashboard_build_v3.sh
│   ├── fix_nginx_rc25s_clean_rebuild.sh
│   ├── fix_nginx_rc25s_dashboard.sh
│   ├── fix_mcp_port_conflict.sh
│   ├── clean_nginx_conf_all.sh
│   ├── create_backup_vibe_agi.sh
│   ├── install_rc25s_agi_full.sh
│   ├── patch_fix_free_llm_server.sh
│   ├── setup_cursor_mobile_bridge.sh
│   ├── setup_rc25s_knowledge_fusion.sh
│   ├── upgrade_rc25s_dashboard_realtime.sh
│   ├── upgrade_rc25s_autoheal_full.sh
│   └── fix_rc25s_nginx.sh
│
└── (기타) RC25H_*.py, 자동수정 메모리 등
```

---

## 🧠 AGI 코어 (`agi_core/engine.py` 기준)

- **파일**: `agi_core/engine.py`
- **역할**:
  - LLM/에이전트 호출의 중심 모듈
  - RC25S 대시보드, Cursor 클라이언트, Self-* 서비스들이 공통으로 사용하는 **코어 AGI 엔진**
- **Cursor에서 할 일 예시**:
  - `engine.py`의 클래스/함수 구조를 읽고 **모듈화/리팩터링**
  - 로깅, 예외 처리, 타임아웃, 재시도 로직 강화
  - OpenAI/로컬 LLM 하이브리드 전략 추가

> 세부 구조를 이해하려면 Cursor에서 `agi_core/engine.py` 파일을 열고 코드 레벨 컨텍스트를 추가로 읽게 하면 됨.

---

## 🧩 RC25S Dashboard 앱 구조

### 1) `rc25s_dashboard_app/backend/`

- **디렉토리**: `/srv/repo/vibecoding/rc25s_dashboard_app/backend`
- **핵심 파일**:
  - `cursor_client.py`
    - Cursor Composer / LLM / 서버 사이의 브리지
    - Cursor에서 생성된 코드/명령을 서버 측으로 전달하고, 결과를 다시 IDE/대시보드로 돌려주는 역할
  - `utils/apidog_sync.py`
    - Apidog와 FastAPI/백엔드 엔드포인트를 동기화하는 유틸
    - API 문서/테스트 자동화 기반

- **Cursor에서 할 일 예시**:
  - `cursor_client.py` 내 요청/응답 포맷을 정리해서 **타입 안정성** 강화
  - 에러 케이스(타임아웃, 연결 실패, DNS 문제) 처리 코드 보강
  - `apidog_sync.py`와 FastAPI 라우터를 연결해 **자동 문서화 파이프라인** 완성

### 2) `rc25s_dashboard_app/rc25s_frontend/` (React/Vite 기반 대시보드)

- **디렉토리**: `/srv/repo/vibecoding/rc25s_dashboard_app/rc25s_frontend`
- **구성**:
  - `src/` : React 컴포넌트/페이지 (LLM 상태, CPU/RAM, 로그, 대화 UI 등)
  - `public/` : 정적 리소스
  - `dist/` : 빌드 결과 (Nginx 또는 백엔드에서 서빙)
  - `package.json`, `tsconfig.json` : 빌드/타입 설정
- **역할**:
  - RC25S 전용 Dashboard UI
  - WebSocket/HTTP를 통해 AGI 상태, 로그, LLM 응답 등을 실시간 표시

- **Cursor에서 할 일 예시**:
  - `src/` 구조를 읽어 **상태관리/컴포넌트 구조 리팩터링**
  - 빌드 에러(Unicode/Emoji 문제 등) 자동 수정 루틴과 맞물리게 코드 수정
  - Nginx 라우팅 구조와 맞춰서 `base`/`publicPath` 등을 정리

### 3) `dashboard/` (별도 Vite/React 앱)

- **디렉토리**: `/srv/repo/vibecoding/dashboard`
- **구성(실제 확인됨)**:
  - `src/`, `public/`, `dist/`, `node_modules/`
  - `package.json`, `tsconfig.json`
- **역할(추정)**:
  - RC25S Agent Dashboard / Studio용 별도 프론트엔드
  - `deploy_rc25s_agent_dashboard.sh`, `deploy_rc25s_agent_studio.sh` 와 연동

---

## ⚙️ Auto-Heal / Self-* 시스템 (systemd 기준 실제 상태)

### 1) 타이머 (실제 활성화 확인됨)

다음 타이머들은 `systemctl list-timers --all | grep rc25s`로 확인됨:

| 타이머 유닛 | 역할(요약) |
|------------|-----------|
| `rc25s-nginx-autoheal.timer` | Nginx 설정/상태 주기 점검 → 이상 시 Auto-Heal 스크립트 실행 |
| `rc25s-selfcheck.timer` | RC25S 전체 셀프체크(서비스/포트/상태) 주기 실행 |

### 2) 서비스 유닛 (실제 등록된 목록)

`systemctl list-unit-files | grep rc25s` 결과 기준:

| 서비스 유닛 | enabled | 설명(역할, 추정 포함) |
|------------|---------|------------------------|
| `rc25s-agent-dashboard.service` | enabled | Agent Dashboard 백엔드/프론트 구동 서비스 |
| `rc25s-dashboard.service` | enabled | 메인 RC25S Dashboard 서비스 (프론트/백엔드 엔트리) |
| `rc25s-knowledge-fusion.service` | enabled | Knowledge Fusion 파이프라인 (LLM + 메모리/지식 통합) |
| `rc25s-project-orchestrator.service` | enabled | RC25S 전체 작업/서비스 오케스트레이션 |
| `rc25s-selfevo.service` | enabled | Self-Evolution(자가 진화) 루프, 코드/설정 개선 시도 |
| `rc25s-selfupdate.service` | enabled | 자동 업데이트/패치 수행 |
| `rc25s-websearch.service` | enabled | 웹 검색/외부 정보 연동 에이전트 |
| `rc25s-nginx-autoheal.service` | disabled (timer가 트리거) | Nginx Auto-Heal 실제 실행 파이프라인 |
| `rc25s-selfcheck.service` | disabled (timer가 트리거) | Self-Check 실제 실행 파이프라인 |

> **중요**: Auto-Heal과 Self-Check는 보통 `*.timer`가 주기적으로 `*.service`를 트리거하는 구조.
> Cursor에서 유닛 파일(`/etc/systemd/system/rc25s-*.service`, `rc25s-*.timer`)을 열고, 실제 실행 스크립트(예: `fix_rc25s_nginx.sh`, `upgrade_rc25s_autoheal_full.sh`)와 연결 관계를 분석하면 전체 복구 플로우를 이해 가능.

---

## 🔄 현재 동작 기능 (실제 서버 기준)

- **Nginx**: 활성화 상태 (포트 80/443 리슨 확인됨)
- **Auto-Heal**:
  - `rc25s-nginx-autoheal.timer` → `rc25s-nginx-autoheal.service` → `fix_rc25s_nginx.sh`/`clean_nginx_conf_all.sh` 등과 연동
- **Self-Check**:
  - `rc25s-selfcheck.timer` → `rc25s-selfcheck.service` → RC25S 관련 서비스/포트/상태 점검 및 로그 기록
- **Dashboard/에이전트**:
  - `rc25s-agent-dashboard.service`, `rc25s-dashboard.service` 등 활성화 상태 (자세한 포트/엔드포인트는 유닛/스크립트에서 확인 필요)
- **AGI/콘솔**:
  - `/srv/repo/vibecoding/rc25h_env/bin/python -m uvicorn mcp_codex_console:app --host 0.0.0.0 --port 444` 프로세스가 백그라운드에서 실행 중인 상태 확인됨

---

## 🧪 향후 A → B → C 개선 플랜 (이 문서 이후 Cursor 작업 로드맵)

> 사용자가 요청한 순서: **A → B → C 순으로 실제 코드/서비스를 점검·수정·배포**

### A. 문서/구조 동기화 (지금 이 단계)

- 이 `RC25S_DEV_CONTEXT.md`는 **실제 서버 상태** 기준으로 재작성됨.
- 과거 GPT 세션에서 가상으로 만들었던 `agi_core/main.py`, `llm_engine.py`, `agi_status_web.py` 등은 **현재 존재하지 않으므로 제거/보정**.
- 이후 변경 사항이 생기면, Cursor는 이 문서를 항상 최신 상태로 유지하는 역할을 맡음.

### B. Dashboard / Backend / Nginx 전체 플로우 정리 및 안정화

Cursor가 이어서 할 작업 예시:

1. `rc25s_dashboard_app/backend/`의 FastAPI/백엔드 코드 구조 파악
2. `rc25s_dashboard_app/rc25s_frontend/`와 `dashboard/`의 Vite/React 구조 분석, 빌드 스크립트/환경변수 정리
3. Nginx 설정 파일(예: `/etc/nginx/sites-available/*` 혹은 `config/` 아래 템플릿)을 열어 **대시보드/백엔드/AGI 엔드포인트 라우팅**을 명확히 정리
4. 빌드 및 배포 플로우 정리:
   - `npm install && npm run build` (또는 `pnpm`/`yarn`) → `dist/` → Nginx/서비스 연계
   - `deploy_rc25s_*` 스크립트들이 어떤 순서로 호출되는지 플로우 차트로 정리

### C. Auto-Heal / Self-* / AGI 오케스트레이션 고도화

1. `rc25s-nginx-autoheal.service` / `rc25s-selfcheck.service` 의 **ExecStart 스크립트**를 열어 로직 분석
2. `fix_rc25s_nginx.sh`, `upgrade_rc25s_autoheal_full.sh`, `clean_nginx_conf_all.sh` 등을 리팩터링
3. 실패 시 알림/로그 강화 (예: 특정 로그 파일이나 대시보드에서 바로 확인 가능하게)
4. `rc25s-selfevo.service`, `rc25s-selfupdate.service`, `rc25s-knowledge-fusion.service`가 AGI 코어와 어떻게 상호작용하는지 코드 레벨에서 정리

---

## ✅ Cursor에서 이 컨텍스트 사용하는 방법

1. **이 파일 열기**
   - Cursor에서: `Ctrl + P` → `RC25S_DEV_CONTEXT.md` 또는 전체 경로 `/srv/repo/vibecoding/RC25S_DEV_CONTEXT.md` 검색 후 열기

2. **프로젝트 컨텍스트 읽기**
   - 상단 메뉴 또는 사이드바에서 **AI → Read Project Context** 실행
   - 이 문서를 기반으로, Cursor는:
     - 프로젝트 구조
     - AGI 코어 / Dashboard / Auto-Heal / Self-* 역할 관계
     - systemd 서비스/타이머 구조
     를 기억하고, 이후 코드 수정/배포/리팩터링에 반영

3. **이후 작업 시 가이드**
   - 특정 서비스/스크립트를 수정하고 싶을 때, 이 문서의 해당 섹션을 먼저 읽고 나서
   - 실제 코드 파일(예: `agi_core/engine.py`, `rc25s_dashboard_app/backend/cursor_client.py`, `fix_rc25s_nginx.sh`)을 열어 상세 구조를 이해한 뒤 수정

---

**생성 시점 기준 실제 서버 상태**: 이 문서는 `/srv/repo/vibecoding` 및 `systemctl` 정보를 기반으로 자동 요약되었습니다.  
추후 디렉토리/파일/서비스 구조가 바뀌면, Cursor를 통해 이 문서를 다시 업데이트해야 최신 상태를 반영할 수 있습니다.

---

## 🧠 (업데이트) RC25S AGI 코어 루프 + Planner/Executor/World State 구조

> ✅ 이 섹션은 2025-11-16 이후에 추가된 **AGI 코어/플래너/태스크 실행기/월드 상태** 관련 구현을 요약합니다.  
> Cursor 세션이 끊겨도, 이 섹션만 보면 **지금 AGI가 어떻게 스스로 판단·계획·실행하는지**를 복구할 수 있습니다.

### 1) 중앙 AGI 코어 루프 (systemd 서비스)

- **파일**: `RC25H_CentralCore.py`
- **역할**:
  - `reflection_engine.run_reflection()` / `memory_engine.update_memory()` / `autofix_loop.auto_fix()` 등을 호출해  
    **REFLECT / MEMORY / AUTOFIX / CREATIVE** 모드를 순환하는 중앙 루프.
  - 최근 결정은 `world_state.update_core_decision(decision)` 으로 `world_state.json`에 기록됨.
- **실행 방식**:
  - systemd 유닛: `_systemd/rc25s-agi-core.service`
  - 배포/등록 스크립트: `setup_rc25s_agi_core.sh`
  - 실제 ExecStart:
    - `/srv/repo/vibecoding/rc25h_env/bin/python /srv/repo/vibecoding/RC25H_CentralCore.py`
  - 로그:
    - `/srv/repo/vibecoding/logs/centralcore.log`

> Cursor에서 AGI 코어를 수정할 때는, 이 유닛/스크립트와 함께 보고 설계해야 합니다.  
> `centralcore.log`를 tail 해서 실제 의사결정 흐름을 확인하는 것이 좋습니다.

### 2) World State (`world_state.py` / `world_state.json`)

- **파일**:
  - 코드: `world_state.py`
  - 데이터: `world_state.json`
- **역할**:
  - RC25S 전체의 **단일 월드 상태(Single Source of Truth)** 역할.
  - 주요 섹션:
    - `core`: 마지막 AGI 의사결정 (`last_decision`, `last_decision_time`)
    - `reflection`: 최신 리플렉션 JSON
    - `memory`: 메모리 스냅샷
    - `planner`: `rc25s_planner`가 생성한 `signals`, `goals`, `tasks`
    - `last_actions`: 최근 태스크 실행 로그 (최대 50개)
    - `metrics`: 헬스 점수, 프론트엔드 이슈 카운트 등 정량 지표
    - `task_stats`: 태스크별 `success`/`fail` 카운트
- **주요 함수**:
  - `load_world_state()`, `save_world_state()`
  - `update_reflection_memory(reflection, memory)`
  - `update_core_decision(decision)`
  - `update_planner(planner_state)`
  - `append_action_log(action)`
  - `update_task_stats(task_id, success)`
  - `update_metrics_from_signals(signals)`

### 3) Planner (`rc25s_planner.py`)

- **파일**: `rc25s_planner.py`
- **입력**:
  - `/var/log/rc25s-autoheal-ai.log`, `/var/log/rc25s-autoheal.log` 의 tail 을 분석해 `signals` 생성.
- **출력**:
  - `memory_store/rc25s_planner_state.json`
  - `world_state.planner`, `world_state.metrics`
- **기능**:
  - `signals`에서 `autoheal_frontend_issues`, `selfcheck_frontend_issues` 등을 계산.
  - `Goal` 목록 생성:
    - `goal_stability`, `goal_frontend_reliability`, `goal_self_improvement` 등.
  - `Task` 목록 생성:
    - `goal_stability_check_health_endpoints`
    - `goal_frontend_reliability_review_nginx`
    - `goal_frontend_reliability_align_selfcheck_autoheal`
    - `goal_self_improvement_expose_logs_in_dashboard`
    - `goal_self_improvement_plan_llm_integration`
  - **의존성/멀티스텝**:
    - `Task.depends_on` 필드로 선행 태스크를 지정.
    - 예시:
      - `goal_frontend_reliability_align_selfcheck_autoheal`  
        → `["goal_frontend_reliability_review_nginx"]` 완료 후에만 실행.
      - `goal_self_improvement_plan_llm_integration`  
        → `["goal_self_improvement_expose_logs_in_dashboard"]` 완료 후 실행.
  - **학습 기반 우선순위 조정**:
    - `world_state.task_stats[task_id]`를 읽어 성공/실패 횟수에 따라 priority 수정:
      - 실패 3회 이상 & 성공 0 → priority −15
      - 성공 3회 이상 & 실패 0 → priority +10
    - 이렇게 해서 **시간이 지날수록 “잘 되는 루틴”에 더 가중치를 주고, 계속 실패하는 작업은 다소 후순위로 미룸.**

### 4) Task Executor (`rc25s_task_executor.py`) + Action Metadata (`rc25s_actions.py`)

- **파일**:
  - 실행기: `rc25s_task_executor.py`
  - 액션 메타데이터: `rc25s_actions.py`
- **입력**:
  - `memory_store/rc25s_planner_state.json` (Planner가 생성한 상태)
- **기능**:
  - `find_pending_tasks()`:
    - `status == "pending"` 이고,
    - `depends_on` 에 있는 태스크들이 모두 `"done"` 인 작업만 큐에 올림.
  - `execute_task(task)`:
    - `goal_stability_check_health_endpoints`  
      → `http://127.0.0.1:4545/health`, `/llm` 호출로 실제 헬스 체크.
    - `goal_frontend_reliability_review_nginx`  
      → `repair_nginx_rc25s_dashboard.sh` 실행.
    - `goal_frontend_reliability_align_selfcheck_autoheal`  
      → `rc25s-selfcheck.sh`, `RC25S_AI_Autoheal.sh` 연속 실행.
    - `goal_self_improvement_sync_apidog_spec` (플래너에 추가 시)  
      → `rc25s_dashboard_app/backend/utils/apidog_sync.py` 실행.
  - **위험도/롤백/테스트**:
    - `rc25s_actions.ACTIONS[task.id]` 로 `ActionMeta` 참조:
      - `risk`: `"L0" | "L1" | "L2"`
      - `post_tests`: 실행 후 AutoTest 여부
      - `rollback_hint`: 실패 시 권장 롤백 전략 설명
    - `RC25S_MAX_RISK_LEVEL` 환경변수로 **최대 허용 위험도** 설정 (기본 L2).
      - 태스크 위험도가 상한을 넘으면 그 태스크는 **스킵**.
    - 위험도 L2 작업 전:
      - `create_backup_vibe_agi.sh`가 있으면 자동 실행(선행 백업).
    - `post_tests=True` + 태스크 성공 시:
      - `rc25s_autotest_runner.py` 실행 → 실패하면 태스크 결과를 **실패로 다시 표시**.
  - **world_state 연동**:
    - 실행 후:
      - `append_action_log({...})` → `world_state.last_actions`에 기록.
      - `update_task_stats(task.id, success)` → 성공/실패 카운트 업데이트.

### 5) Reflection Engine (`reflection_engine.py`)의 Self-Evaluation 루프

- **파일**: `reflection_engine.py`
- **LLM 호출 경로**:
  - 직접 `openai`를 쓰지 않고, `rc25s_openai_wrapper.rc25s_chat()`을 사용.
- **입력**:
  - `memory_store/memory_vector.json`
  - `world_state.metrics`
  - `world_state.last_actions` (최근 액션들)
  - `world_state.planner` (signals/goals/tasks)
- **프롬프트 역할**:
  - 위 네 가지 정보를 모두 넘겨서,
  - **“현재 시스템 상태에 대한 자기 평가 + 다음에 집중할 목표/태스크 피드백”** 을 요청.
- **출력 JSON 구조**:
  - `insight`: 현재 상태에 대한 요약 인사이트
  - `improvement_goal`: 다음으로 추구해야 할 개선 목표
  - `confidence`: 0.0 ~ 1.0 신뢰도 스코어
  - `planner_feedback`:
    - `focus_goal_ids`: 더 집중해야 할 goal id 리스트
    - `deprioritize_task_ids`: 우선순위를 낮춰도 되는 task id 리스트
    - `notes`: 이유/설명
- **저장/동기화**:
  - 결과는 `memory_store/reflection.json`에 저장.
  - 동시에 `update_reflection_memory(reflection, memory)` 로  
    `world_state["reflection"]`, `world_state["memory"]`에 반영.

---

## 📌 “세션이 끊겨도 어디서 다시 시작하면 되는지” 요약

1. **AGI 코어 상태 확인**
   - `sudo systemctl status rc25s-agi-core.service`
   - `tail -n 50 /srv/repo/vibecoding/logs/centralcore.log`
2. **월드 상태/플랜/액션 로그 확인**
   - `cat /srv/repo/vibecoding/world_state.json`
   - `cat /srv/repo/vibecoding/memory_store/rc25s_planner_state.json`
3. **다음 개발 포인트 찾기**
   - `RC25S_SYSTEM_OVERVIEW.md` → 큰 그림
   - `RC25S_DEV_CONTEXT.md` (이 파일) → 실제 구현/서비스/스크립트 관계
   - `RC25S_DASHBOARD_STATUS.md` → Dashboard/LLM/Self-Check 관련 세부 상태

이 세 가지를 보면, Cursor/AGI는 이전 대화 세션이 없어도 **현재 AGI가 무엇을 하고 있는지, 다음에 무엇을 개선해야 하는지**를 바로 복구할 수 있습니다.

