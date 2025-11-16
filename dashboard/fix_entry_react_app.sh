#!/bin/bash
set -e
LOG="/var/log/mcp_dashboard_fix.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')
cd /srv/repo/vibecoding/dashboard

echo "[$TS] ⚙️ Fixing React entry point..." | tee -a $LOG

# ✅ 1️⃣ src 디렉토리 생성
mkdir -p src

# ✅ 2️⃣ App.jsx 생성
cat << 'JS' > src/App.jsx
import React from 'react'

export default function App() {
  return (
    <div style={{
      padding: "40px",
      textAlign: "center",
      fontFamily: "Arial, sans-serif",
      color: "#333"
    }}>
      <h1>🚀 AGI Dashboard Online</h1>
      <p>Deployment successful at https://api.mcpvibe.org/dashboard</p>
    </div>
  )
}
JS

# ✅ 3️⃣ main.jsx 생성
cat << 'JS' > src/main.jsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
JS

# ✅ 4️⃣ vite.config.js 보장
cat << 'JS' > vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  root: './',
  base: '/dashboard/',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
})
JS

# ✅ 5️⃣ index.html 재생성 (base 포함)
cat << 'HTML' > index.html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <base href="/dashboard/">
    <title>AGI Dashboard</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
HTML

# ✅ 6️⃣ 빌드
npm run build --silent

sudo nginx -t && sudo systemctl restart nginx
echo "[$TS] ✅ React entry rebuild complete. Visit https://api.mcpvibe.org/dashboard" | tee -a $LOG
