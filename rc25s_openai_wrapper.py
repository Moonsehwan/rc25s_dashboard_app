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
