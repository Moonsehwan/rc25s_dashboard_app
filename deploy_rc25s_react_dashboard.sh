#!/bin/bash
echo "🚀 [RC25S] Deploying React Realtime Dashboard + Live Chat Interface..."

# 1. React 앱 디렉토리 생성
mkdir -p /srv/repo/vibecoding/rc25s_dashboard_app

# 2. React 기본 구조 다운로드 및 설치 (자동)
cd /srv/repo/vibecoding/rc25s_dashboard_app
npx create-react-app rc25s_frontend --template typescript --use-npm

# 3. 백엔드와 WebSocket 브릿지 연결 추가 예정
echo "✅ React base created at rc25s_dashboard_app/rc25s_frontend"
echo "⚙️ Next step: integrate WebSocket + Korean LLM chat endpoints."
