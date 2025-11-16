#!/bin/bash
echo "🧩 RC25S Environment Auto-Fix Started"

# 1️⃣ PYTHONPATH 주입
export PYTHONPATH=/srv/repo
echo "✅ Exported PYTHONPATH=/srv/repo"

# 2️⃣ systemd 환경에 재주입
sudo -E systemctl import-environment OPENAI_API_KEY PYTHONPATH
echo "✅ Imported both OPENAI_API_KEY + PYTHONPATH into systemd"

# 3️⃣ 영구화 - 각 서비스 override 파일 생성
for svc in agi-memory agi-reflection agi-autofix; do
  sudo mkdir -p /etc/systemd/system/${svc}.service.d
  sudo tee /etc/systemd/system/${svc}.service.d/env.conf > /dev/null <<EOC
[Service]
Environment="PYTHONPATH=/srv/repo"
EOC
  echo "✅ ${svc}.service.d/env.conf applied"
done

# 4️⃣ systemd 갱신 및 서비스 재시작
sudo systemctl daemon-reload
sudo systemctl daemon-reexec
sudo systemctl restart agi-memory.service agi-reflection.service agi-autofix.service
sleep 3
systemctl status agi-memory.service agi-reflection.service agi-autofix.service | grep Active
