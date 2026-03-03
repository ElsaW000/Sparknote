import os
import threading
import queue
import time
from typing import Any

from sqlmodel import SQLModel, Field, create_engine, Session, select

from backend.ai_provider import get_provider


_JOB_QUEUE: "queue.Queue[dict]" = queue.Queue()
_WORKER_THREAD: threading.Thread | None = None
_RUNNING = False


def _get_engine():
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./sparknote.db")
    return create_engine(
        DATABASE_URL,
        echo=False,
        connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {},
    )


def enqueue_job(conversation_id: int, user_text: str, user_id: int) -> None:
    _JOB_QUEUE.put({"conversation_id": conversation_id, "text": user_text, "user_id": user_id})


def _worker_loop():
    global _RUNNING
    engine = _get_engine()
    provider = get_provider()
    _RUNNING = True
    while _RUNNING:
        try:
            job = _JOB_QUEUE.get(timeout=0.5)
        except queue.Empty:
            continue
        try:
            cid = job["conversation_id"]
            prompt = job["text"]
            uid = job["user_id"]
            # call provider
            reply = provider.get_reply(prompt)
            # persist reply as Message
            from backend.main import Message  # local import to avoid circular issues

            with Session(engine) as session:
                ai_msg = Message(conversation_id=cid, sender="ai", text=reply, user_id=uid)
                session.add(ai_msg)
                session.commit()
        except Exception:
            # On error, persist an AI error message so callers/tests see a reply
            import traceback

            tb = traceback.format_exc()
            try:
                from backend.main import Message

                with Session(engine) as session:
                    err_msg = Message(
                        conversation_id=job.get("conversation_id"),
                        sender="ai",
                        text=f"[AI worker error] {tb}",
                        user_id=job.get("user_id"),
                    )
                    session.add(err_msg)
                    session.commit()
            except Exception:
                # if persisting also fails, at least print the traceback
                traceback.print_exc()
        finally:
            _JOB_QUEUE.task_done()


def start_worker():
    global _WORKER_THREAD
    if _WORKER_THREAD and _WORKER_THREAD.is_alive():
        return
    _WORKER_THREAD = threading.Thread(target=_worker_loop, daemon=True)
    _WORKER_THREAD.start()


def stop_worker():
    global _RUNNING
    _RUNNING = False
