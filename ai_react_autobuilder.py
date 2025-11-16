import os, sys, datetime, textwrap, json

ROOT = "/srv/repo/vibecoding/static/preview"
os.makedirs(ROOT, exist_ok=True)

phase = None
if "--phase" in sys.argv:
    phase = sys.argv[sys.argv.index("--phase") + 1]

def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(content)

def phase_init():
    html = """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <title>AI React Builder</title>
      </head>
      <body>
        <div id="root"></div>
        <script type="module" src="main.jsx"></script>
      </body>
    </html>
    """
    main = """
    import React from 'react'
    import ReactDOM from 'react-dom/client'
    import App from './App.jsx'

    ReactDOM.createRoot(document.getElementById('root')).render(<App />)
    """
    app = f"""
    import React from 'react'

    export default function App() {{
      return (
        <div style={{textAlign:'center', marginTop:'100px'}}>
          <h1>🤖 Initializing AI Builder...</h1>
          <p>Started at {datetime.datetime.now().strftime('%H:%M:%S')}</p>
        </div>
      )
    }}
    """
    write(f"{ROOT}/index.html", html)
    write(f"{ROOT}/main.jsx", main)
    write(f"{ROOT}/App.jsx", app)

def phase_expand():
    app = """
    import React from 'react'
    import Header from './components/Header.jsx'
    import Footer from './components/Footer.jsx'
    import Counter from './components/Counter.jsx'

    export default function App() {
      return (
        <div>
          <Header />
          <main style={{textAlign:'center', marginTop:'80px'}}>
            <Counter />
          </main>
          <Footer />
        </div>
      )
    }
    """
    write(f"{ROOT}/App.jsx", app)
    write(f"{ROOT}/components/Header.jsx", """
    import React from 'react'
    export default function Header() {
      return (
        <header style={{background:'#0077ff', color:'#fff', padding:'20px'}}>
          <h1>AI React App Builder</h1>
        </header>
      )
    }
    """)
    write(f"{ROOT}/components/Footer.jsx", """
    import React from 'react'
    export default function Footer() {
      return (
        <footer style={{marginTop:'100px', padding:'20px', color:'#888'}}>
          <p>© AI Builder {datetime.datetime.now().year}</p>
        </footer>
      )
    }
    """)
    write(f"{ROOT}/components/Counter.jsx", """
    import React, { useState } from 'react'
    export default function Counter() {
      const [count, setCount] = useState(0)
      return (
        <div>
          <h2>Click Count: {count}</h2>
          <button onClick={() => setCount(count + 1)}>Increase</button>
        </div>
      )
    }
    """)

def phase_style():
    app = """
    import React from 'react'
    import Header from './components/Header.jsx'
    import Footer from './components/Footer.jsx'
    import Counter from './components/Counter.jsx'
    import './style.css'

    export default function App() {
      return (
        <div className="container">
          <Header />
          <Counter />
          <Footer />
        </div>
      )
    }
    """
    css = """
    body { background:#f5f8ff; margin:0; font-family:Arial, sans-serif; }
    .container { text-align:center; padding-top:80px; }
    button { padding:10px 20px; background:#0077ff; color:white; border:none; border-radius:8px; cursor:pointer; }
    button:hover { background:#005bd1; }
    """
    write(f"{ROOT}/App.jsx", app)
    write(f"{ROOT}/style.css", css)

def phase_final():
    app = """
    import React from 'react'
    import Header from './components/Header.jsx'
    import Footer from './components/Footer.jsx'
    import Counter from './components/Counter.jsx'
    import './style.css'

    export default function App() {
      return (
        <div className="container">
          <Header />
          <h1>🎉 Your AI App is Complete!</h1>
          <Counter />
          <Footer />
        </div>
      )
    }
    """
    write(f"{ROOT}/App.jsx", app)

if phase == "init": phase_init()
elif phase == "expand": phase_expand()
elif phase == "style": phase_style()
elif phase == "final": phase_final()
