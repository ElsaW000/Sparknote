import os
from typing import Optional

import requests


class AIProvider:
    def get_reply(self, prompt: str) -> str:
        raise NotImplementedError()


class DashscopeProvider(AIProvider):
    def __init__(self, api_key: str, model: str = "qwen-plus"):
        self.api_key = api_key
        self.model = model

    def get_reply(self, prompt: str) -> str:
        try:
            # Prefer official SDK if available
            # Try OpenAI-compatible SDK (recommended by docs) with base_url
            try:
                from openai import OpenAI

                client = OpenAI(api_key=self.api_key, base_url=os.getenv("DASHSCOPE_URL", "https://dashscope.aliyuncs.com/compatible-mode/v1"))
                messages = [
                    {"role": "system", "content": "You are a helpful assistant."},
                    {"role": "user", "content": prompt},
                ]
                resp = client.chat.completions.create(model=self.model, messages=messages, max_tokens=512)
                return resp.choices[0].message.content
            except Exception:
                # Try dashscope SDK if installed
                try:
                    from dashscope import Generation

                    messages = [
                        {"role": "system", "content": "You are a helpful assistant."},
                        {"role": "user", "content": prompt},
                    ]
                    resp = Generation.call(api_key=self.api_key, model=self.model, messages=messages, result_format="message")
                    if getattr(resp, "status_code", None) == 200:
                        return resp.output.choices[0].message.content
                    return f"[DASHSCOPE SDK error: status={getattr(resp,'status_code',None)}]"
                except Exception:
                    # Fallback to HTTP OpenAI-compatible endpoint
                    base = os.getenv("DASHSCOPE_URL", "https://dashscope.aliyuncs.com/compatible-mode/v1")
                    # ensure no trailing slash
                    base = base.rstrip('/')
                    url = f"{base}/chat/completions"
                    headers = {"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"}
                    data = {"model": self.model, "messages": [{"role": "user", "content": prompt}], "max_tokens": 512}
                    r = requests.post(url, json=data, headers=headers, timeout=15)
                    r.raise_for_status()
                    j = r.json()
                    # OpenAI-compatible response
                    try:
                        return j["choices"][0]["message"]["content"].strip()
                    except Exception:
                        # older/other formats
                        return j.get("text", "").strip()
        except Exception as e:
            return f"[DASHSCOPE call failed: {e}]"


class OpenAIProvider(AIProvider):
    def __init__(self, api_key: str, model: str = "gpt-3.5-turbo"):
        self.api_key = api_key
        self.model = model

    def get_reply(self, prompt: str) -> str:
        try:
            url = "https://api.openai.com/v1/chat/completions"
            headers = {"Authorization": f"Bearer {self.api_key}", "Content-Type": "application/json"}
            data = {"model": self.model, "messages": [{"role": "user", "content": prompt}], "max_tokens": 512}
            r = requests.post(url, json=data, headers=headers, timeout=15)
            r.raise_for_status()
            j = r.json()
            return j["choices"][0]["message"]["content"].strip()
        except Exception as e:
            return f"[OpenAI call failed: {e}]"


class MockProvider(AIProvider):
    def get_reply(self, prompt: str) -> str:
        return f"AI (mock) reply to: {prompt[:200]}"


def get_provider() -> AIProvider:
    # Priority: DASHSCOPE (SDK/API) -> OPENAI -> Mock
    # During pytest runs prefer the MockProvider to avoid external network calls
    import sys

    if os.getenv("PYTEST_CURRENT_TEST") or os.getenv("PYTEST_ADDOPTS") or "pytest" in sys.modules:
        return MockProvider()
    dash_key = os.getenv("DASHSCOPE_API_KEY") or os.getenv("DASHSCOPE")
    if dash_key:
        model = os.getenv("DASHSCOPE_MODEL", "qwen-plus")
        return DashscopeProvider(api_key=dash_key, model=model)

    openai_key = os.getenv("OPENAI_API_KEY")
    if openai_key:
        model = os.getenv("OPENAI_MODEL", "gpt-3.5-turbo")
        return OpenAIProvider(api_key=openai_key, model=model)

    return MockProvider()
