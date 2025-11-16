import os, subprocess, textwrap, json, datetime

ROOT = "/srv/repo/vibecoding/static/preview"
os.makedirs(ROOT, exist_ok=True)

# React 소스 코드 자동 생성
react_code = textwrap.dedent(f"""
import React from 'react'
import ReactDOM from 'react-dom/client'

function App() {{
  const [count, setCount] = React.useState(0)
  return (
    <div style={{textAlign:'center', marginTop:'100px'}}>
      <h1>🤖 AI React Builder</h1>
      <p>Generated at {datetime.datetime.now().strftime('%H:%M:%S')}</p>
      <button onClick={{() => setCount(count + 1)}}>Click me: {{count}}</button>
    </div>
  )
}}

ReactDOM.createRoot(document.getElementById('root')).render(<App />)
""")

html_code = """
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>AI React Preview</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="main.jsx"></script>
  </body>
</html>
"""

with open(f"{ROOT}/main.jsx", "w") as f:
    f.write(react_code)

with open(f"{ROOT}/index.html", "w") as f:
    f.write(html_code)

# Vite 설정 파일 자동 생성
vite_config = """
import {{ defineConfig }} from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({{
  plugins: [react()],
  build: {{
    outDir: './dist',
  }},
}})
"""
with open(f"{ROOT}/vite.config.js", "w") as f:
    f.write(vite_config)

# package.json
pkg = {
    "name": "ai-react-preview",
    "private": True,
    "version": "0.0.1",
    "scripts": {"dev": "vite", "build": "vite build"},
    "dependencies": {"react": "^18.3.1", "react-dom": "^18.3.1"},
    "devDependencies": {"vite": "^5.1.0", "@vitejs/plugin-react": "^4.0.0"},
}
with open(f"{ROOT}/package.json", "w") as f:
    json.dump(pkg, f, indent=2)

print("✅ React preview project generated at", ROOT)
