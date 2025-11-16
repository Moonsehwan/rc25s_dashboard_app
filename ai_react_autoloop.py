from rc25_kernel_RC25S import RC25SKernel
kernel = RC25SKernel()

import os, time, json, datetime
from openai import OpenAI

ROOT="/srv/repo/vibecoding/static/preview"
LOG_PATH="/srv/repo/vibecoding/logs/ai_react_autoloop.log"
os.makedirs(ROOT, exist_ok=True)

client=OpenAI(api_key=os.getenv("OPENAI_API_KEY","").strip())

def log(msg):
    print(msg)
    with open(LOG_PATH,"a") as f: f.write(f"[{datetime.datetime.now()}] {msg}\n")

def read_file(path):
    return open(path).read() if os.path.exists(path) else ""

def write_file(path,content):
    os.makedirs(os.path.dirname(path),exist_ok=True)
    with open(path,"w") as f: f.write(content)

def loop():
    log("🚀 RC25H Kernel Auto-Build Started.")
    app_path=f"{ROOT}/App.jsx"
    base_code=read_file(app_path) or "<h1>Hello AI World</h1>"
    while True:
        try:
            prompt=f"Refine and expand this React component for visual simulation:\n{base_code}"
            log("🧠 Calling GPT-5-search-api...")
            resp=client.chat.completions.create(
                model="gpt-5-search-api",
                messages=[{"role":"user","content":prompt}],
                temperature=0.7
            )
            new_code=resp.choices[0].message.content
            if new_code and "import" in new_code:
                write_file(app_path,new_code)
                log("✅ Preview updated.")
            else:
                log("⚠️ No valid JSX output.")
        except Exception as e:
            log(f"❌ Error: {e}")
        time.sleep(60)
if __name__=="__main__": loop()
