from rc25_kernel_RC25S import RC25SKernel
kernel = RC25SKernel()

import os
import json
from openai import OpenAI

# Load API key from environment variable
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY').strip()
if not OPENAI_API_KEY:
    raise ValueError("API key is missing or empty.")

# Initialize OpenAI client
openai_client = OpenAI(api_key=OPENAI_API_KEY)

def run_reflection_engine():
    try:
        # Your reflection engine logic here
        pass
    except Exception as e:
        print(f"Reflection Engine failed: {e}")

def main():
    run_reflection_engine()

if __name__ == "__main__":
    main()