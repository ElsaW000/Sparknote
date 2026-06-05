"""
Spark Vault Agent — mentor agents with tool-calling skills.

Architecture (inspired by stepanogil/autonomous-hr-chatbot v2):
  - Each mentor is an Agent that receives the same Skills (Tools)
  - The LLM decides WHEN to call which skill, not the frontend
  - Skills: search_memory (embedding-based retrieval from user fragments)
  - No LangChain — pure DashScope compatible-mode API

Tools / Skills:
  search_memory(query) — semantic search in user's personal fragments
"""

from __future__ import annotations

import json
import math
import os
from typing import Any

import requests

DASHSCOPE_BASE = os.getenv(
    "DASHSCOPE_URL",
    "https://dashscope.aliyuncs.com/compatible-mode/v1",
).rstrip("/")

# In-memory embedding cache: {fragment_id: list[float]}
# Avoids re-embedding the same fragment on every turn
_embed_cache: dict[str, list[float]] = {}

# ── Tool / Skill schema ────────────────────────────────────────────────────────

SKILLS = [
    {
        "type": "function",
        "function": {
            "name": "search_memory",
            "description": (
                "在用户的个人记录里搜索与当前问题相关的片段。"
                "当需要了解用户的背景、历史想法或相关记录时调用。"
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "用于搜索的关键词或问题，中文即可",
                    }
                },
                "required": ["query"],
            },
        },
    }
]


# ── Embedding ──────────────────────────────────────────────────────────────────


def _embed(text: str, api_key: str) -> list[float]:
    """Call DashScope compatible-mode embeddings endpoint."""
    resp = requests.post(
        f"{DASHSCOPE_BASE}/embeddings",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json={"model": "text-embedding-v1", "input": text[:512]},
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()["data"][0]["embedding"]


def _cosine(a: list[float], b: list[float]) -> float:
    dot = sum(x * y for x, y in zip(a, b))
    norm_a = math.sqrt(sum(x * x for x in a))
    norm_b = math.sqrt(sum(x * x for x in b))
    return dot / (norm_a * norm_b + 1e-9)


# ── Skill implementation ───────────────────────────────────────────────────────


def search_memory(query: str, fragments: list[dict[str, Any]], api_key: str) -> str:
    """
    Semantic search over user fragments using DashScope embeddings.
    Returns top-5 relevant fragments as a formatted string.
    """
    if not fragments:
        return "用户暂无个人记录。"

    try:
        q_emb = _embed(query, api_key)
    except Exception as e:
        return f"搜索失败：{e}"

    scores: list[tuple[float, str]] = []
    for f in fragments:
        fid = f.get("id", "")
        text = (f.get("content") or f.get("originalText") or "").strip()
        if not text:
            continue

        # Use cache to avoid re-embedding same fragment
        if fid and fid in _embed_cache:
            f_emb = _embed_cache[fid]
        else:
            try:
                f_emb = _embed(text, api_key)
            except Exception:
                continue
            if fid:
                _embed_cache[fid] = f_emb

        sim = _cosine(q_emb, f_emb)
        scores.append((sim, text))

    scores.sort(reverse=True)
    top = [(s, t) for s, t in scores[:5] if s > 0.1]

    if not top:
        return "未找到相关记录。"

    return "\n---\n".join(
        f"[{i + 1}] (相关度 {s:.2f}) {t[:350]}"
        for i, (s, t) in enumerate(top)
    )


SKILL_DISPATCH = {
    "search_memory": search_memory,
}


# ── Agent loop ─────────────────────────────────────────────────────────────────


def run_agent(
    messages: list[dict],
    mentor_prompt: str,
    fragments: list[dict],
    api_key: str,
    max_iterations: int = 5,
) -> str:
    """
    Run one conversation turn through the agent loop.

    Flow (same pattern as autonomous-hr-chatbot v2):
      1. Send messages + tools to qwen-plus
      2. If model calls a skill → execute → feed result back → repeat
      3. When model returns final text → done

    Args:
        messages:      Conversation history WITHOUT system message.
        mentor_prompt: The perspective/viewpoint to analyze from (task-focused).
        fragments:     All user personal fragments to search over.
        api_key:       DashScope API key.
        max_iterations: Guard against infinite tool-call loops.

    Returns:
        Final assistant response text.
    """
    full_messages = [{"role": "system", "content": mentor_prompt}] + messages

    for _ in range(max_iterations):
        resp = requests.post(
            f"{DASHSCOPE_BASE}/chat/completions",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": "qwen-plus",
                "messages": full_messages,
                "tools": SKILLS,
                "tool_choice": "auto",
                "temperature": 0.7,
                "max_tokens": 1000,
            },
            timeout=60,
        )
        resp.raise_for_status()
        data = resp.json()
        choice = data["choices"][0]
        finish_reason = choice.get("finish_reason")

        if finish_reason == "tool_calls":
            assistant_msg = choice["message"]
            full_messages.append(assistant_msg)

            for tool_call in assistant_msg.get("tool_calls", []):
                fn_name = tool_call["function"]["name"]
                fn_args_raw = tool_call["function"]["arguments"]
                try:
                    fn_args = json.loads(fn_args_raw)
                except json.JSONDecodeError:
                    fn_args = {}

                skill = SKILL_DISPATCH.get(fn_name)
                if skill is None:
                    result = json.dumps({"error": f"Unknown skill: {fn_name}"})
                elif fn_name == "search_memory":
                    result = skill(
                        query=fn_args.get("query", ""),
                        fragments=fragments,
                        api_key=api_key,
                    )
                else:
                    result = json.dumps({"error": "Unhandled skill"})

                full_messages.append(
                    {
                        "role": "tool",
                        "tool_call_id": tool_call["id"],
                        "content": result,
                    }
                )
        else:
            # Final answer — stop the loop
            return choice["message"]["content"]

    return "无法完成响应，请重试。"
