import time, requests, subprocess, datetime, os, psutil, json

LOG = "/srv/repo/vibecoding/logs/rc25h_centralcore.log"
MCP_HEALTH = "http://127.0.0.1:8000/health"
RC25H_HEALTH = "http://127.0.0.1:8001/health"

def log(msg):
    t = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG, "a") as f:
        f.write(f"[{t}] {msg}\n")

def check_service(url):
    try:
        r = requests.get(url, timeout=2)
        if r.status_code == 200:
            return True
    except Exception:
        return False
    return False

def restart_mcp():
    log("⚠️ MCP Server unresponsive — attempting restart")
    subprocess.run(["systemctl", "restart", "mcp.service"], stdout=subprocess.DEVNULL)
    time.sleep(5)
    ok = check_service(MCP_HEALTH)
    log(f"✅ MCP Restart Result: {'OK' if ok else 'FAILED'}")

def main_loop():
    log("🧠 RC25H CentralCore Loop initialized")
    while True:
        mcp_ok = check_service(MCP_HEALTH)
        rc_ok = check_service(RC25H_HEALTH)
        cpu = psutil.cpu_percent(interval=1)
        mem = psutil.virtual_memory().percent

        status = {
            "time": datetime.datetime.now().isoformat(),
            "MCP": "OK" if mcp_ok else "DOWN",
            "RC25H": "OK" if rc_ok else "DOWN",
            "CPU": f"{cpu}%",
            "MEM": f"{mem}%"
        }

        log(json.dumps(status, ensure_ascii=False))
        if not mcp_ok:
            restart_mcp()

        time.sleep(30)

if __name__ == "__main__":
    main_loop()
