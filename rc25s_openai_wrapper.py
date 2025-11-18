import os, time, json
from openai import OpenAI
from rc25_kernel_RC25S import RC25SKernel

kernel = RC25SKernel()


def _get_openai_client() -> OpenAI:
    """
    항상 최신 OPENAI_API_KEY를 사용하도록 클라이언트를 생성한다.
    - 우선 순위:
      1) 환경변수 OPENAI_API_KEY
      2) /etc/openai_api_key.txt 파일 (존재 시)
    """
    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key or "$(" in str(api_key):
        key_path = "/etc/openai_api_key.txt"
        if os.path.exists(key_path):
            api_key = open(key_path).read().strip()
            os.environ["OPENAI_API_KEY"] = api_key
        else:
            raise RuntimeError("No valid OPENAI_API_KEY or /etc/openai_api_key.txt found")
    return OpenAI(api_key=api_key)


def rc25s_chat(prompt, history=None, model="gpt-4o-mini"):
    """
    Wrapper that runs prompt through RC25S meta control before OpenAI call.
    """
    start = time.time()
    mode = kernel.detect_mode(prompt)
    reflection = kernel.self_reflect(prompt)
    meta_prompt = f"[MODE:{mode}] [REFLECT:{reflection}]\\n{prompt}"

    client = _get_openai_client()
    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "RC25S Meta-Control Active"},
            {"role": "user", "content": meta_prompt},
        ],
    )

    text = response.choices[0].message.content
    elapsed = round(time.time() - start, 3)
    metrics = kernel.report_kpi()
    metrics["response_time"] = elapsed
    return {"response": text, "metrics": metrics}
