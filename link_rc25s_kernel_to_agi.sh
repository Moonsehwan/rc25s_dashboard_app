#!/bin/bash
set -e
echo "🧠 [RC25S-AGI] Integrating Sentient Kernel with all AGI Loops and OpenAI API..."

KERNEL_PATH="/srv/repo/vibecoding/rc25_kernel_RC25S.py"
AGI_PATH="/srv/repo/vibecoding"
ENV_FILE="/etc/vibecoding/env"

if [ ! -f "$KERNEL_PATH" ]; then
  echo "❌ Kernel file missing: $KERNEL_PATH"
  exit 1
fi

# 1️⃣ Patch all core AGI loops to import RC25S kernel
for f in agi_autofix_loop.py ai_react_autoloop.py reflection_engine.py memory_engine.py agi_system_manager.py; do
  if [ -f "$AGI_PATH/$f" ]; then
    sudo sed -i '1i\from rc25_kernel_RC25S import RC25SKernel\nkernel = RC25SKernel()\n' "$AGI_PATH/$f"
    echo "✅ Patched $f"
  fi
done

# 2️⃣ Add OpenAI RC25S Wrapper
WRAP_FILE="$AGI_PATH/rc25s_openai_wrapper.py"
cat <<'PYEOF' | sudo tee "$WRAP_FILE" > /dev/null
import os, time, json
from openai import OpenAI
from rc25_kernel_RC25S import RC25SKernel

kernel = RC25SKernel()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def rc25s_chat(prompt, history=None, model="gpt-4o-mini"):
    """
    Wrapper that runs prompt through RC25S meta control before OpenAI call.
    """
    start = time.time()
    mode = kernel.detect_mode(prompt)
    reflection = kernel.self_reflect(prompt)
    meta_prompt = f"[MODE:{mode}] [REFLECT:{reflection}]\\n{prompt}"

    response = client.chat.completions.create(
        model=model,
        messages=[{"role":"system","content":"RC25S Meta-Control Active"},{"role":"user","content":meta_prompt}]
    )

    text = response.choices[0].message.content
    elapsed = round(time.time()-start,3)
    metrics = kernel.report_kpi()
    metrics["response_time"] = elapsed
    return {"response": text, "metrics": metrics}
PYEOF
echo "✅ Created RC25S OpenAI Wrapper: $WRAP_FILE"

# 3️⃣ Integrate into reflection & autofix
for f in reflection_engine.py agi_autofix_loop.py memory_engine.py; do
  sudo sed -i '/OpenAI(/s/^/#/' "$AGI_PATH/$f" 2>/dev/null || true
  sudo sed -i '1i\from rc25s_openai_wrapper import rc25s_chat' "$AGI_PATH/$f"
done
echo "✅ Linked RC25S wrapper into AGI reflection/memory/autofix"

# 4️⃣ Restart all AGI services
for s in free-llm.service agi-memory.service agi-reflection.service agi-autofix.service ai-react-loop.service agi-selfevo.service; do
  sudo systemctl restart $s 2>/dev/null || true
done
sleep 5

# 5️⃣ Health checks
echo "🩺 Checking RC25S kernel endpoint..."
curl -s http://127.0.0.1:8011/health
echo
echo "🧠 Testing OpenAI wrapper (RC25S Meta-Control)..."
sudo /srv/repo/vibecoding/rc25h_env/bin/python -c "from rc25s_openai_wrapper import rc25s_chat; print(rc25s_chat('현재 시스템의 인지상태를 설명해줘.'))"
echo
echo "✅ [RC25S] Kernel successfully integrated with AGI loops + OpenAI layer."
