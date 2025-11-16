#!/bin/bash
set -e
echo "🧠 [RC25S] Project Orchestrator 설치 중..."

cat > /srv/repo/vibecoding/rc25s_project_orchestrator.py <<'PYCODE'
import os, json, time, datetime, subprocess, traceback, requests

LOG_PATH = "/srv/repo/vibecoding/logs/project_orchestrator.log"
PROJECTS_PATH = "/srv/repo/projects"

os.makedirs(PROJECTS_PATH, exist_ok=True)

def log(msg):
    t = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[🧠Orchestrator {t}] {msg}")
    with open(LOG_PATH, "a") as f:
        f.write(f"[{t}] {msg}\n")

def call_llm(prompt, model="qwen2.5"):
    try:
        r = requests.post("http://127.0.0.1:4545/llm", json={"prompt": prompt}, timeout=180)
        out = r.json().get("output", "")
        return out or "❌ LLM 응답 없음"
    except Exception as e:
        return f"❌ LLM 호출 실패: {e}"

def create_project_structure(name):
    path = os.path.join(PROJECTS_PATH, name)
    os.makedirs(path, exist_ok=True)
    os.makedirs(os.path.join(path, "backend"), exist_ok=True)
    os.makedirs(os.path.join(path, "frontend"), exist_ok=True)
    os.makedirs(os.path.join(path, "docs"), exist_ok=True)
    return path

def generate_spec(requirement):
    prompt = f"""
당신은 AGI 프로젝트 설계자입니다.
다음 목표를 분석해 백엔드/프론트엔드/DB/배포 구성으로 나누어 JSON으로 정의하세요.

목표: {requirement}

JSON 형식:
{{
  "backend": "...FastAPI 또는 Flask 등 설계...",
  "frontend": "...React 또는 Next.js 설계...",
  "database": "...SQLite, Postgres 등...",
  "deployment": "...Nginx, Docker 설정 요약..."
}}
"""
    return call_llm(prompt)

def generate_code(spec, section):
    prompt = f"""
아래 프로젝트 스펙의 '{section}' 부분을 기반으로 실제 코드를 작성하세요.
전체 Python/React 코드로 출력해주세요.

스펙:
{spec}
"""
    return call_llm(prompt)

def main_loop():
    log("🚀 RC25S Project Orchestrator 시작.")
    while True:
        try:
            if not os.path.exists("/srv/repo/vibecoding/memory_store/reflection.json"):
                time.sleep(60)
                continue

            with open("/srv/repo/vibecoding/memory_store/reflection.json") as f:
                reflection = json.load(f)
            reflection_text = reflection.get("reflection", "").strip()

            # “앱 만들자” 등의 트리거 감지
            if "앱" in reflection_text or "프로젝트" in reflection_text:
                proj_name = "project_" + datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
                log(f"🧩 새 프로젝트 감지 → {proj_name}")
                path = create_project_structure(proj_name)

                spec = generate_spec(reflection_text)
                log(f"📐 설계 생성 완료 → {path}/docs/spec.json")
                with open(os.path.join(path, "docs", "spec.json"), "w") as f:
                    f.write(spec)

                for section in ["backend", "frontend"]:
                    code = generate_code(spec, section)
                    file_path = os.path.join(path, section, f"{section}_main.txt")
                    with open(file_path, "w") as f:
                        f.write(code)
                    log(f"✅ {section} 코드 생성 완료 → {file_path}")

                log("⚙️ 자동 빌드/테스트 준비 완료.")
                reflection["reflection"] = f"✅ {proj_name} 생성 완료"
                with open("/srv/repo/vibecoding/memory_store/reflection.json", "w") as f:
                    json.dump(reflection, f, indent=2)
            else:
                log("💤 대기 중 — 새로운 프로젝트 지시 없음.")
            time.sleep(300)
        except Exception:
            log(traceback.format_exc())
            time.sleep(60)

if __name__ == "__main__":
    main_loop()
PYCODE

chmod +x /srv/repo/vibecoding/rc25s_project_orchestrator.py

cat > /etc/systemd/system/rc25s-project-orchestrator.service <<'UNIT'
[Unit]
Description=RC25S Project Orchestrator (자율 앱 설계 루프)
After=rc25s-knowledge-fusion.service

[Service]
ExecStart=/srv/repo/vibecoding/rc25h_env/bin/python /srv/repo/vibecoding/rc25s_project_orchestrator.py
Restart=always
RestartSec=20

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable rc25s-project-orchestrator.service
systemctl restart rc25s-project-orchestrator.service

echo "✅ Project Orchestrator 설치 및 실행 완료."
