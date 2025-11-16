from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import socket
import os
import psutil
import datetime

app = FastAPI(title="RC25S Dashboard API")

# CORS 허용 (필요 시 제한 가능)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "RC25S Dashboard API active"}

@app.get("/health")
def health():
    return {
        "status": "ok",
        "system": socket.gethostname(),
        "uptime": os.popen("uptime -p").read().strip(),
        "cpu": f"{psutil.cpu_percent()}%",
        "memory": f"{psutil.virtual_memory().percent}%",
        "timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }

# 🚀 대시보드용 헬스체크 엔드포인트
@app.get("/agi/health")
def agi_health():
    return {"status": "ok", "message": "AGI Dashboard backend active"}
