import os, json, subprocess, datetime, time
from rc25_kernel_pro_R3 import ProKernel
from reflection_engine import run_reflection
from memory_engine import update_memory
from autofix_loop import auto_fix

class RC25H_CentralCore:
    def __init__(self):
        self.kernel = ProKernel(llm=None)
        self.state_path = "/srv/repo/vibecoding/reflection.json"
        self.mem_path = "/srv/repo/vibecoding/memory_vector.json"
        self.log = "/srv/repo/vibecoding/logs/centralcore.log"

    def read_state(self):
        try:
            reflection = json.load(open(self.state_path))
            memory = json.load(open(self.mem_path))
            return reflection, memory
        except Exception:
            return None, None

    def analyze_and_decide(self, reflection, memory):
        if not reflection or not memory:
            return "INIT"
        conf = reflection.get("confidence", 0)
        errors = reflection.get("error_count", 0)
        memlen = len(memory)
        if conf < 0.6: return "REFLECT"
        if memlen < 5: return "MEMORY"
        if errors > 0: return "AUTOFIX"
        return "CREATIVE"

    def execute(self, decision, context=""):
        with open(self.log, "a") as f:
            f.write(f"[{datetime.datetime.now()}] Decision: {decision}\n")
        if decision == "REFLECT":
            run_reflection()
        elif decision == "MEMORY":
            update_memory()
        elif decision == "AUTOFIX":
            auto_fix()
        elif decision == "CREATIVE":
            self.kernel.run_turn(context, "새 아이디어 생성", mode="creative")

    def loop(self):
        while True:
            ref, mem = self.read_state()
            decision = self.analyze_and_decide(ref, mem)
            self.execute(decision)
            time.sleep(300)

if __name__ == "__main__":
    core = RC25H_CentralCore()
    core.loop()
