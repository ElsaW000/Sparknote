import logging
import os
import queue
import threading

from sqlmodel import Session, create_engine

from backend.ai_provider import get_provider

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

_JOB_QUEUE: "queue.Queue[dict]" = queue.Queue()
_WORKER_THREAD: threading.Thread | None = None
_RUNNING = False


def _get_engine():
    default_db_path = os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        "sparknote.db",
    )
    database_url = os.getenv("DATABASE_URL", f"sqlite:///{default_db_path}")
    return create_engine(
        database_url,
        echo=False,
        connect_args={"check_same_thread": False} if database_url.startswith("sqlite") else {},
    )


def enqueue_job(
    conversation_id: int,
    user_text: str,
    user_id: int,
    note_title: str | None = None,
    note_content: str | None = None,
    attachment_labels: list[str] | None = None,
) -> None:
    try:
        _JOB_QUEUE.put(
            {
                "conversation_id": conversation_id,
                "text": user_text,
                "user_id": user_id,
                "note_title": note_title,
                "note_content": note_content,
                "attachment_labels": attachment_labels or [],
            }
        )
        logger.info("Enqueued job for conversation %s", conversation_id)
    except Exception as e:
        logger.error("Failed to enqueue job: %s", e)


def _worker_loop():
    global _RUNNING
    engine = None
    provider = None

    try:
        engine = _get_engine()
        provider = get_provider()
        logger.info("AI worker started")
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
                logger.info("Processing job for conversation %s", cid)

                from backend.main import Message, _build_workspace_prompt

                full_prompt = _build_workspace_prompt(
                    prompt,
                    note_title=job.get("note_title"),
                    note_content=job.get("note_content"),
                    attachment_labels=job.get("attachment_labels"),
                )
                reply = provider.get_reply(full_prompt)

                with Session(engine) as session:
                    ai_msg = Message(conversation_id=cid, sender="ai", text=reply, user_id=uid)
                    session.add(ai_msg)
                    session.commit()

                logger.info("Completed job for conversation %s", cid)
            except Exception as e:
                import traceback

                tb = traceback.format_exc()
                logger.error("Error processing job: %s\n%s", e, tb)
                try:
                    from backend.main import Message

                    with Session(engine) as session:
                        err_msg = Message(
                            conversation_id=job.get("conversation_id"),
                            sender="ai",
                            text=f"[AI worker error] {str(e)}",
                            user_id=job.get("user_id"),
                        )
                        session.add(err_msg)
                        session.commit()
                except Exception as save_err:
                    logger.error("Failed to save error message: %s", save_err)
                    traceback.print_exc()
            finally:
                _JOB_QUEUE.task_done()
    except Exception as e:
        logger.error("Worker loop failed: %s", e)
    finally:
        _RUNNING = False
        logger.info("AI worker stopped")


def start_worker():
    global _WORKER_THREAD
    if _WORKER_THREAD and _WORKER_THREAD.is_alive():
        logger.info("AI worker is already running")
        return

    try:
        _WORKER_THREAD = threading.Thread(target=_worker_loop, daemon=True)
        _WORKER_THREAD.start()
        logger.info("AI worker started successfully")
    except Exception as e:
        logger.error("Failed to start AI worker: %s", e)


def stop_worker():
    global _RUNNING
    _RUNNING = False
    logger.info("AI worker stopping...")

    if _WORKER_THREAD and _WORKER_THREAD.is_alive():
        _WORKER_THREAD.join(timeout=5.0)
        if _WORKER_THREAD.is_alive():
            logger.warning("AI worker thread did not terminate gracefully")
        else:
            logger.info("AI worker stopped successfully")
