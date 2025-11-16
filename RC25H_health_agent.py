from fastapi import FastAPI
import datetime, os, psutil, platform

app = FastAPI(title="RC25H Health Agent")

@app.get("/health")
async def health():
    uptime = os.popen("uptime -p").read().strip()
    mem = psutil.virtual_memory()
    cpu = psutil.cpu_percent(interval=0.5)
    return {
        "status": "ok",
        "message": "RC25H Health Agent active",
        "system": platform.node(),
        "uptime": uptime,
        "cpu": f"{cpu}%",
        "memory": f"{mem.percent}%",
        "timestamp": str(datetime.datetime.now())
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
