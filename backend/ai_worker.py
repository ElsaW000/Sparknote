import os
import threading
import queue
import time
import logging
from typing import Any

from sqlmodel import SQLModel, Field, create_engine, Session, select

from backend.ai_provider import get_provider

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


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
    """将AI任务加入队列"""
    try:
        _JOB_QUEUE.put({"conversation_id": conversation_id, "text": user_text, "user_id": user_id})
        logger.info(f"Enqueued job for conversation {conversation_id}")
    except Exception as e:
        logger.error(f"Failed to enqueue job: {e}")


def _worker_loop():
    """AI工作器主循环"""
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
                logger.info(f"Processing job for conversation {cid}")
                
                # 调用AI提供商
                reply = provider.get_reply(prompt)
                
                # 保存回复为Message
                from backend.main import Message  # 本地导入避免循环依赖

                with Session(engine) as session:
                    ai_msg = Message(conversation_id=cid, sender="ai", text=reply, user_id=uid)
                    session.add(ai_msg)
                    session.commit()
                
                logger.info(f"Completed job for conversation {cid}")
            except Exception as e:
                # 出错时，保存错误消息
                import traceback
                tb = traceback.format_exc()
                logger.error(f"Error processing job: {e}\n{tb}")
                
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
                    logger.error(f"Failed to save error message: {save_err}")
                    traceback.print_exc()
            finally:
                _JOB_QUEUE.task_done()
    except Exception as e:
        logger.error(f"Worker loop failed: {e}")
    finally:
        _RUNNING = False
        logger.info("AI worker stopped")


def start_worker():
    """启动AI工作器"""
    global _WORKER_THREAD
    if _WORKER_THREAD and _WORKER_THREAD.is_alive():
        logger.info("AI worker is already running")
        return
    
    try:
        _WORKER_THREAD = threading.Thread(target=_worker_loop, daemon=True)
        _WORKER_THREAD.start()
        logger.info("AI worker started successfully")
    except Exception as e:
        logger.error(f"Failed to start AI worker: {e}")


def stop_worker():
    """停止AI工作器"""
    global _RUNNING
    _RUNNING = False
    logger.info("AI worker stopping...")
    
    # 等待线程结束
    if _WORKER_THREAD and _WORKER_THREAD.is_alive():
        _WORKER_THREAD.join(timeout=5.0)
        if _WORKER_THREAD.is_alive():
            logger.warning("AI worker thread did not terminate gracefully")
        else:
            logger.info("AI worker stopped successfully")
