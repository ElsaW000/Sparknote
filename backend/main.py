from fastapi import FastAPI, HTTPException, Depends, status, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import OAuth2PasswordBearer
from sqlmodel import SQLModel, Field, create_engine, Session, select
from typing import Optional, List, Generator
from datetime import datetime, timedelta, date
from sqlalchemy import func, or_
import json
import os
import re
import random
import threading
import uuid
import requests
import logging
import base64
from jose import JWTError, jwt
from passlib.context import CryptContext
from dotenv import load_dotenv

# åŠ è½½çŽ¯å¢ƒå˜é‡
load_dotenv()

# é…ç½®æ—¥å¿—
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ---------- database setup ----------
_DEFAULT_DB_PATH = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "sparknote.db",
)
DATABASE_URL = os.getenv("DATABASE_URL", f"sqlite:///{_DEFAULT_DB_PATH}")
engine = create_engine(
    DATABASE_URL,
    echo=True,
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {},
)


def get_session() -> Generator[Session, None, None]:
    with Session(engine) as session:
        yield session


def init_db() -> None:
    """Create all database tables. Can be called manually by tests or startup."""
    SQLModel.metadata.create_all(engine)
    _ensure_legacy_schema()


def _ensure_legacy_schema() -> None:
    # Keep local legacy sqlite DB compatible after adding new columns.
    if not DATABASE_URL.startswith("sqlite"):
        return
    try:
        with engine.begin() as conn:
            def _table_columns(table_name: str) -> set[str]:
                rows = conn.exec_driver_sql(f"PRAGMA table_info({table_name})").fetchall()
                return {str(r[1]) for r in rows}

            note_cols = _table_columns("note")
            if "user_id" not in note_cols:
                conn.exec_driver_sql("ALTER TABLE note ADD COLUMN user_id INTEGER")
            if "created_at" not in note_cols:
                conn.exec_driver_sql("ALTER TABLE note ADD COLUMN created_at TEXT")
                conn.exec_driver_sql(
                    "UPDATE note SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL"
                )

            user_cols = _table_columns("user")
            if "identity" not in user_cols:
                conn.exec_driver_sql("ALTER TABLE user ADD COLUMN identity TEXT")
            if "notion_api_token" not in user_cols:
                conn.exec_driver_sql("ALTER TABLE user ADD COLUMN notion_api_token TEXT")
            if "notion_database_id" not in user_cols:
                conn.exec_driver_sql("ALTER TABLE user ADD COLUMN notion_database_id TEXT")

            conversation_cols = _table_columns("conversation")
            if "user_id" not in conversation_cols:
                conn.exec_driver_sql("ALTER TABLE conversation ADD COLUMN user_id INTEGER")

            message_cols = _table_columns("message")
            if "user_id" not in message_cols:
                conn.exec_driver_sql("ALTER TABLE message ADD COLUMN user_id INTEGER")
    except Exception:
        # Schema compatibility patch should not block app startup.
        pass


# ---------- models ----------
class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(index=True)
    password_hash: str
    identity: Optional[str] = Field(default=None)  # å°è¯´ä½œè€…/äº§å“ç»ç†/å†…å®¹åˆ›ä½œè€…/å…¨éƒ¨
    is_active: bool = True
    notion_api_token: Optional[str] = Field(default=None)
    notion_database_id: Optional[str] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)


class Note(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: Optional[str] = None
    content: str
    user_id: int = Field(foreign_key="user.id")
    created_at: datetime = Field(default_factory=datetime.utcnow)


class NoteTag(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    note_id: int = Field(foreign_key="note.id", index=True)
    user_id: int = Field(foreign_key="user.id", index=True)
    tag: str = Field(index=True)


class NoteAttachment(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    note_id: int = Field(foreign_key="note.id", index=True)
    user_id: int = Field(foreign_key="user.id", index=True)
    file_name: str
    stored_name: str
    mime_type: Optional[str] = None
    size_bytes: int = 0
    created_at: datetime = Field(default_factory=datetime.utcnow)


class Conversation(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: Optional[str] = None
    status: str = "open"
    user_id: int = Field(foreign_key="user.id")


class ConversationCreate(SQLModel):
    title: Optional[str] = None
    status: Optional[str] = None


class Message(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    conversation_id: int = Field(foreign_key="conversation.id")
    sender: str
    text: str
    user_id: int = Field(foreign_key="user.id")


class MessageCreate(SQLModel):
    sender: str
    text: str
    note_title: Optional[str] = None
    note_content: Optional[str] = None
    attachment_labels: List[str] = Field(default_factory=list)


class NoteCreate(SQLModel):
    title: Optional[str] = None
    content: str
    tags: Optional[List[str]] = None


class NoteUpdate(SQLModel):
    title: Optional[str] = None
    content: Optional[str] = None
    tags: Optional[List[str]] = None


class NoteRead(SQLModel):
    id: int
    title: Optional[str] = None
    content: str
    user_id: int
    created_at: datetime
    tags: List[str] = Field(default_factory=list)
    attachments: List["NoteAttachmentRead"] = Field(default_factory=list)


class NoteAttachmentRead(SQLModel):
    id: int
    note_id: int
    file_name: str
    mime_type: Optional[str] = None
    size_bytes: int
    created_at: datetime
    url: str


class NoteAttachmentCreate(SQLModel):
    file_name: str
    mime_type: Optional[str] = None
    content_base64: str


NoteRead.update_forward_refs(NoteAttachmentRead=NoteAttachmentRead)


class AudioTranscriptionRequest(SQLModel):
    mime_type: Optional[str] = None
    content_base64: str
    context: Optional[str] = None


class AudioTranscriptionResponse(SQLModel):
    transcript: str


class NoteRelationCreate(SQLModel):
    to_note_id: int
    relation_type: str  # "related", "parent", "child", "reference"


class NoteRelationRead(SQLModel):
    id: int
    from_note_id: int
    to_note_id: int
    relation_type: str
    created_at: datetime


class UserCreate(SQLModel):
    email: str
    password: str


class UserRegister(SQLModel):
    email: str
    password: str
    identity: Optional[str] = None  # å°è¯´ä½œè€…/äº§å“ç»ç†/å†…å®¹åˆ›ä½œè€…/å…¨éƒ¨
    captcha_id: Optional[str] = None
    captcha_answer: Optional[str] = None


class UserRead(SQLModel):
    id: int
    email: str
    identity: Optional[str] = None
    is_active: bool
    created_at: datetime


class NotionIntegrationRead(SQLModel):
    connected: bool
    api_token: Optional[str] = None
    database_id: Optional[str] = None


class NotionIntegrationUpdate(SQLModel):
    api_token: Optional[str] = None
    database_id: Optional[str] = None


class Token(SQLModel):
    access_token: str
    token_type: str = "bearer"


class CaptchaChallenge(SQLModel):
    captcha_id: str
    question: str
    expires_in: int


# --- AI insight models ---
class InsightPerspective(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    category: Optional[str] = None
    prompt_template: str
    is_default: bool = False


class InsightRun(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    perspective_id: int = Field(foreign_key="insightperspective.id")
    # stored as comma-separated list of IDs
    note_ids: str
    result: Optional[str] = None
    status: str = "pending"
    created_at: datetime = Field(default_factory=datetime.utcnow)


# --- Knowledge linking models ---
class NoteRelation(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    from_note_id: int = Field(foreign_key="note.id")
    to_note_id: int = Field(foreign_key="note.id")
    relation_type: str  # e.g., "related", "parent", "child", "reference"
    user_id: int = Field(foreign_key="user.id")
    created_at: datetime = Field(default_factory=datetime.utcnow)


# ---------- security & auth helpers ----------
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "dev-secret-change-me")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))
REQUIRE_REGISTER_CAPTCHA = os.getenv("REQUIRE_REGISTER_CAPTCHA", "1").lower() in (
    "1",
    "true",
    "yes",
)
REGISTER_CAPTCHA_TTL_SECONDS = int(os.getenv("REGISTER_CAPTCHA_TTL_SECONDS", "300"))

# Prefer pbkdf2_sha256 for broad compatibility in local/dev environments.
# Some passlib+bcrypt version combos can fail during backend self-check.
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

_CAPTCHA_STORE_LOCK = threading.Lock()
_CAPTCHA_STORE = {}


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def get_user_by_id(session: Session, user_id: int) -> Optional[User]:
    return session.get(User, user_id)


def get_user_by_email(session: Session, email: str) -> Optional[User]:
    return session.exec(select(User).where(User.email == email)).first()


def get_current_user(
    token: str = Depends(oauth2_scheme), session: Session = Depends(get_session)
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        sub = payload.get("sub")
        if sub is None:
            raise credentials_exception
        user_id = int(sub)
    except (JWTError, ValueError):
        raise credentials_exception

    user = get_user_by_id(session, user_id)
    if not user or not user.is_active:
        raise credentials_exception
    return user


# ---------- application & startup ----------
class ChineseJSONResponse(JSONResponse):
    def render(self, content) -> bytes:
        return json.dumps(
            content,
            ensure_ascii=False,
            allow_nan=False,
            indent=None,
            separators=(",", ":"),
        ).encode("utf-8")

app = FastAPI(title="Sparknote Backend", default_response_class=ChineseJSONResponse)
# during local development we allow all origins to avoid CORS issues
# (in production this should be locked down to the real frontend URL)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """å…¨å±€å¼‚å¸¸å¤„ç†ä¸­é—´ä»¶"""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error", "error": str(exc)}
    )


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """HTTPå¼‚å¸¸å¤„ç†ä¸­é—´ä»¶"""
    logger.info(f"HTTP exception: {exc.detail}")
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail}
    )


@app.on_event("startup")
def on_startup():
    """Create database tables if they don't exist."""
    SQLModel.metadata.create_all(engine)
    _ensure_legacy_schema()
    # start background AI worker
    try:
        from backend.ai_worker import start_worker

        start_worker()
    except Exception:
        pass

# ---------- helpers ----------
from backend.ai_provider import get_provider

# Initialize provider at module load
_AI_PROVIDER = get_provider()


def _ai_reply(prompt: str) -> str:
    try:
        return _AI_PROVIDER.get_reply(prompt)
    except Exception as e:
        return f"[AI provider error: {e}]"


def _build_workspace_prompt(
    user_text: str,
    note_title: Optional[str] = None,
    note_content: Optional[str] = None,
    attachment_labels: Optional[List[str]] = None,
) -> str:
    title = (note_title or "").strip()
    content = (note_content or "").strip()
    user_request = user_text.strip()
    if not title and not content:
        return user_request
    sections = [
        "\u4f60\u662f Sparknote \u7684\u7075\u611f\u5de5\u4f5c\u53f0 AI \u52a9\u624b\u3002",
        "\u4f60\u9700\u8981\u57fa\u4e8e\u5f53\u524d\u7b14\u8bb0\u5185\u5bb9\u56de\u7b54\u7528\u6237\u95ee\u9898\uff0c\u4e0d\u8981\u8bf4\u201c\u672a\u6536\u5230\u5177\u4f53\u5185\u5bb9\u201d\uff0c\u9664\u975e\u4e0b\u9762\u7684\u7b14\u8bb0\u771f\u7684\u4e3a\u7a7a\u3002",
    ]
    if title:
        sections.append(f"\u5f53\u524d\u7b14\u8bb0\u6807\u9898\uff1a{title}")
    if content:
        sections.append("\u5f53\u524d\u7b14\u8bb0\u6b63\u6587\uff1a\n" + content)
    labels = [label.strip() for label in (attachment_labels or []) if label and label.strip()]
    if labels:
        sections.append("\u5f53\u524d\u9644\u4ef6\uff1a\n- " + "\n- ".join(labels))
    sections.append("\u7528\u6237\u95ee\u9898\uff1a\n" + user_request)
    sections.append(
        "\u8bf7\u7ed3\u5408\u8fd9\u6761\u7b14\u8bb0\u7ed9\u51fa\u5177\u4f53\u3001\u53ef\u6267\u884c\u7684\u5efa\u8bae\uff0c\u5fc5\u8981\u65f6\u5f15\u7528\u7b14\u8bb0\u4e2d\u7684\u5173\u952e\u70b9\u3002"
    )
    return "\n\n".join(sections)


def _transcribe_audio(
    content_base64: str,
    mime_type: Optional[str] = None,
    context: Optional[str] = None,
) -> str:
    dash_key = os.getenv("DASHSCOPE_API_KEY") or os.getenv("DASHSCOPE")
    if not dash_key:
        return "[mock transcript] 当前环境未配置语音识别服务，请配置 DASHSCOPE_API_KEY。"

    audio_mime = (mime_type or "audio/webm").strip() or "audio/webm"
    prompt = (
        (context or "").strip()
        or "请将这段中文语音准确转写成简体中文文本，保留原意，去掉无意义语气词。"
    )
    base = os.getenv("DASHSCOPE_URL", "https://dashscope.aliyuncs.com/compatible-mode/v1").rstrip("/")
    model = os.getenv("DASHSCOPE_ASR_MODEL", "qwen3-asr-flash")
    payload = {
        "model": model,
        "messages": [
            {
                "role": "system",
                "content": [{"type": "text", "text": prompt}],
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "input_audio",
                        "input_audio": {
                            "data": f"data:{audio_mime};base64,{content_base64}",
                            "format": audio_mime.split("/")[-1],
                        },
                    }
                ],
            },
        ],
    }
    try:
        r = requests.post(
            f"{base}/chat/completions",
            headers={
                "Authorization": f"Bearer {dash_key}",
                "Content-Type": "application/json",
            },
            json=payload,
            timeout=90,
        )
        r.raise_for_status()
        body = r.json()
        content = body["choices"][0]["message"]["content"]
        if isinstance(content, str):
            return content.strip()
        if isinstance(content, list):
            texts = []
            for item in content:
                if isinstance(item, dict):
                    text = item.get("text") or item.get("transcript")
                    if text:
                        texts.append(str(text))
            return "\n".join(texts).strip()
        return str(content).strip()
    except Exception as e:
        return f"[ASR failed] {e}"


def _normalize_tags(tags: Optional[List[str]]) -> List[str]:
    if not tags:
        return []
    seen = set()
    normalized: List[str] = []
    for t in tags:
        if not t:
            continue
        tag = t.strip()
        if tag.startswith("#"):
            tag = tag[1:].strip()
        if not tag or tag in seen:
            continue
        seen.add(tag)
        normalized.append(tag)
    return normalized


def _extract_tags_from_content(content: Optional[str]) -> List[str]:
    if not content:
        return []
    # Capture tags until whitespace or obvious punctuation so CJK tags like
    # #工作 are preserved instead of being truncated by \w-only matching.
    found = re.findall(
        r"(?<!\S)#([^\s#.,!?;:，。！？；：、/\\|()\[\]{}<>\"'“”‘’]+)",
        content,
        flags=re.UNICODE,
    )
    return _normalize_tags(found)


def _merge_tags(manual_tags: Optional[List[str]], content: Optional[str]) -> List[str]:
    return _normalize_tags((manual_tags or []) + _extract_tags_from_content(content))


def _get_note_tags(session: Session, note_id: int, user_id: int) -> List[str]:
    rows = session.exec(
        select(NoteTag).where((NoteTag.note_id == note_id) & (NoteTag.user_id == user_id))
    ).all()
    return [r.tag for r in rows]


def _set_note_tags(session: Session, note_id: int, user_id: int, tags: Optional[List[str]]) -> None:
    existing = session.exec(
        select(NoteTag).where((NoteTag.note_id == note_id) & (NoteTag.user_id == user_id))
    ).all()
    for row in existing:
        session.delete(row)
    for tag in _normalize_tags(tags):
        session.add(NoteTag(note_id=note_id, user_id=user_id, tag=tag))


def _uploads_dir() -> str:
    path = os.getenv("UPLOADS_DIR") or os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        "uploads",
    )
    os.makedirs(path, exist_ok=True)
    return path


def _get_note_attachments(session: Session, note_id: int, user_id: int) -> List["NoteAttachmentRead"]:
    rows = session.exec(
        select(NoteAttachment).where(
            (NoteAttachment.note_id == note_id) & (NoteAttachment.user_id == user_id)
        )
    ).all()
    return [
        NoteAttachmentRead(
            id=row.id,
            note_id=row.note_id,
            file_name=row.file_name,
            mime_type=row.mime_type,
            size_bytes=row.size_bytes,
            created_at=row.created_at,
            url=f"/uploads/{row.stored_name}",
        )
        for row in rows
    ]


def _to_note_read(session: Session, note: Note) -> NoteRead:
    return NoteRead(
        id=note.id,
        title=note.title,
        content=note.content,
        user_id=note.user_id,
        created_at=note.created_at,
        tags=_get_note_tags(session, note.id, note.user_id),
        attachments=_get_note_attachments(session, note.id, note.user_id),
    )


def _prune_expired_captcha() -> None:
    now = datetime.utcnow()
    expired = [k for k, v in _CAPTCHA_STORE.items() if v["expires_at"] <= now]
    for key in expired:
        _CAPTCHA_STORE.pop(key, None)


def _create_captcha() -> CaptchaChallenge:
    left = random.randint(1, 9)
    right = random.randint(1, 9)
    captcha_id = str(uuid.uuid4())
    answer = str(left + right)
    expires_at = datetime.utcnow() + timedelta(seconds=REGISTER_CAPTCHA_TTL_SECONDS)
    with _CAPTCHA_STORE_LOCK:
        _prune_expired_captcha()
        _CAPTCHA_STORE[captcha_id] = {"answer": answer, "expires_at": expires_at}
    return CaptchaChallenge(
        captcha_id=captcha_id,
        question=f"\u8bf7\u8ba1\u7b97\uff1a{left} + {right} = ?",
        expires_in=REGISTER_CAPTCHA_TTL_SECONDS,
    )


def _verify_and_consume_captcha(captcha_id: Optional[str], captcha_answer: Optional[str]) -> bool:
    if not captcha_id or not captcha_answer:
        return False
    with _CAPTCHA_STORE_LOCK:
        _prune_expired_captcha()
        row = _CAPTCHA_STORE.get(captcha_id)
        if not row:
            return False
        expected = str(row["answer"]).strip()
        provided = str(captcha_answer).strip()
        if expected != provided:
            return False
        _CAPTCHA_STORE.pop(captcha_id, None)
        return True


# Ensure background worker starts when module imported (helps tests and dev)
try:
    from backend.ai_worker import start_worker

    start_worker()
except Exception as e:
    # print error so startup logs show issue rather than silently passing
    print(f"ai_worker.start failed: {e}")


# ---------- routes ----------
@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/debug/ai")
def debug_ai(prompt: str):
    """Simple endpoint to test AI reply logic.

    Usage: /debug/ai?prompt=hello
    Returns JSON `{reply: <text>}` using configured DASHSCOPE or OPENAI key.
    """
    return {"reply": _ai_reply(prompt)}


@app.get("/auth/captcha", response_model=CaptchaChallenge)
def get_register_captcha():
    return _create_captcha()


@app.post("/auth/register", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def register_user(payload: UserRegister, session: Session = Depends(get_session)):
    if REQUIRE_REGISTER_CAPTCHA:
        ok = _verify_and_consume_captcha(payload.captcha_id, payload.captcha_answer)
        if not ok:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired captcha",
            )
    existing = get_user_by_email(session, payload.email)
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")
    user = User(email=payload.email, password_hash=hash_password(payload.password), identity=payload.identity)
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


@app.post("/auth/login", response_model=Token)
def login(payload: UserCreate, session: Session = Depends(get_session)):
    logger.info(f"Login attempt for email: {payload.email}")
    user = get_user_by_email(session, payload.email)
    if not user:
        logger.warning(f"User not found: {payload.email}")
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect email or password")
    
    logger.info(f"User found: {user.email}, checking password...")
    logger.info(f"Stored hash: {user.password_hash[:50]}...")
    
    is_valid = verify_password(payload.password, user.password_hash)
    logger.info(f"Password valid: {is_valid}")
    
    if not is_valid:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect email or password")
    
    access_token = create_access_token({"sub": str(user.id)})
    logger.info(f"Login successful for: {payload.email}")
    return Token(access_token=access_token, token_type="bearer")


@app.get("/auth/me", response_model=UserRead)
def read_me(current_user: User = Depends(get_current_user)):
    return current_user


@app.get("/integrations/notion", response_model=NotionIntegrationRead)
def get_notion_integration(current_user: User = Depends(get_current_user)):
    return NotionIntegrationRead(
        connected=bool(current_user.notion_api_token and current_user.notion_database_id),
        api_token=current_user.notion_api_token,
        database_id=current_user.notion_database_id,
    )


@app.put("/integrations/notion", response_model=NotionIntegrationRead)
def update_notion_integration(
    payload: NotionIntegrationUpdate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    current_user.notion_api_token = payload.api_token.strip() if payload.api_token else None
    current_user.notion_database_id = payload.database_id.strip() if payload.database_id else None
    session.add(current_user)
    session.commit()
    session.refresh(current_user)
    return NotionIntegrationRead(
        connected=bool(current_user.notion_api_token and current_user.notion_database_id),
        api_token=current_user.notion_api_token,
        database_id=current_user.notion_database_id,
    )


@app.post("/audio/transcribe", response_model=AudioTranscriptionResponse)
def transcribe_audio(
    payload: AudioTranscriptionRequest,
    current_user: User = Depends(get_current_user),
):
    try:
        base64.b64decode(payload.content_base64.encode("utf-8"), validate=True)
    except Exception:
        raise HTTPException(status_code=400, detail="invalid base64 content")
    transcript = _transcribe_audio(
        payload.content_base64,
        mime_type=payload.mime_type,
        context=payload.context,
    )
    return AudioTranscriptionResponse(transcript=transcript)


@app.post("/notes", response_model=NoteRead)
def create_note(
    payload: NoteCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    note = Note(title=payload.title, content=payload.content, user_id=current_user.id)
    session.add(note)
    session.commit()
    session.refresh(note)
    merged_tags = _merge_tags(payload.tags, payload.content)
    _set_note_tags(session, note.id, current_user.id, merged_tags)
    session.commit()
    return _to_note_read(session, note)


@app.get("/notes", response_model=List[NoteRead])
def list_notes(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
    since: Optional[datetime] = None,
    tag: Optional[str] = None,
    q: Optional[str] = None,
):
    """List notes for the current user.
    Optional `since` query param (ISO datetime) filters notes created after the given time.
    Optional `tag` query param filters notes containing the exact tag (TAG-04).
    Optional `q` query param searches note title and content case-insensitively.
    """
    query = select(Note).where(Note.user_id == current_user.id)
    if since is not None:
        query = query.where(Note.created_at > since)
    if tag is not None:
        # Join with NoteTag to filter notes that have the tag
        query = query.join(NoteTag, (NoteTag.note_id == Note.id) & (NoteTag.user_id == current_user.id) & (NoteTag.tag == tag))
    if q is not None and q.strip():
        keyword = f"%{q.strip().lower()}%"
        query = query.where(
            or_(
                func.lower(func.coalesce(Note.title, "")).like(keyword),
                func.lower(Note.content).like(keyword),
            )
        )
    query = query.order_by(Note.created_at.desc())
    notes = session.exec(query).all()
    return [_to_note_read(session, n) for n in notes]


@app.get("/notes/{note_id}", response_model=NoteRead)
def get_note(
    note_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    note = session.get(Note, note_id)
    if not note or note.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="note not found")
    return _to_note_read(session, note)


@app.get("/notes/{note_id}/attachments", response_model=List[NoteAttachmentRead])
def list_note_attachments(
    note_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    note = session.get(Note, note_id)
    if not note or note.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="note not found")
    return _get_note_attachments(session, note_id, current_user.id)


@app.post("/notes/{note_id}/attachments", response_model=NoteAttachmentRead, status_code=201)
def upload_note_attachment(
    note_id: int,
    payload: NoteAttachmentCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    note = session.get(Note, note_id)
    if not note or note.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="note not found")
    file_name = payload.file_name.strip()
    if not file_name:
        raise HTTPException(status_code=400, detail="file name required")
    try:
        raw = base64.b64decode(payload.content_base64.encode("utf-8"), validate=True)
    except Exception:
        raise HTTPException(status_code=400, detail="invalid base64 content")
    if not raw:
        raise HTTPException(status_code=400, detail="empty file")
    safe_name = re.sub(r"[^A-Za-z0-9._-]+", "_", file_name)
    stored_name = f"{uuid.uuid4().hex}_{safe_name}"
    file_path = os.path.join(_uploads_dir(), stored_name)
    with open(file_path, "wb") as f:
        f.write(raw)
    row = NoteAttachment(
        note_id=note_id,
        user_id=current_user.id,
        file_name=file_name,
        stored_name=stored_name,
        mime_type=(payload.mime_type or "").strip() or None,
        size_bytes=len(raw),
    )
    session.add(row)
    session.commit()
    session.refresh(row)
    return NoteAttachmentRead(
        id=row.id,
        note_id=row.note_id,
        file_name=row.file_name,
        mime_type=row.mime_type,
        size_bytes=row.size_bytes,
        created_at=row.created_at,
        url=f"/uploads/{row.stored_name}",
    )


@app.delete("/notes/{note_id}/attachments/{attachment_id}")
def delete_note_attachment(
    note_id: int,
    attachment_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    note = session.get(Note, note_id)
    if not note or note.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="note not found")
    attachment = session.get(NoteAttachment, attachment_id)
    if not attachment or attachment.note_id != note_id or attachment.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="attachment not found")

    file_path = os.path.join(_uploads_dir(), attachment.stored_name)
    try:
        if os.path.exists(file_path):
            os.remove(file_path)
    except OSError:
        pass

    session.delete(attachment)
    session.commit()
    return {"ok": True, "deleted_attachment_id": attachment_id}


@app.get("/tags/suggest")
def suggest_tags(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    """Return top-used tags by frequency, limited to 20 (TAG-03)."""
    # Aggregate tag usage count
    rows = session.exec(
        select(NoteTag.tag, func.count().label("cnt"))
        .where(NoteTag.user_id == current_user.id)
        .group_by(NoteTag.tag)
        .order_by(func.count().desc())
        .limit(20)
    ).all()
    return [{"tag": r.tag, "count": r.cnt} for r in rows]


@app.get("/notes/{note_id}/related")
def related_notes(
    note_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    """Return related notes based on explicit relations and tag similarity."""
    note = session.get(Note, note_id)
    if not note or note.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="note not found")
    
    # Get current note's tags
    current_tags = set(_get_note_tags(session, note_id, current_user.id))
    
    # Find directly related notes via NoteRelation
    direct_relations = session.exec(
        select(NoteRelation).where(
            (NoteRelation.user_id == current_user.id) &
            ((NoteRelation.from_note_id == note_id) | (NoteRelation.to_note_id == note_id))
        )
    ).all()
    
    related_scores = {}
    
    # Process direct relations
    for rel in direct_relations:
        other_id = rel.to_note_id if rel.from_note_id == note_id else rel.from_note_id
        # Higher score for direct relations
        score = 10 if rel.relation_type == "parent" or rel.relation_type == "child" else 5
        related_scores[other_id] = score
    
    # Find notes with shared tags
    if current_tags:
        tag_related = session.exec(
            select(NoteTag.note_id, func.count().label("shared_count"))
            .where(
                (NoteTag.user_id == current_user.id) &
                (NoteTag.tag.in_(current_tags)) &
                (NoteTag.note_id != note_id)
            )
            .group_by(NoteTag.note_id)
        ).all()
        
        for row in tag_related:
            score = min(row.shared_count, 5)  # Cap at 5 for tag similarity
            if row.note_id in related_scores:
                related_scores[row.note_id] += score
            else:
                related_scores[row.note_id] = score
    
    if not related_scores:
        return []
    
    # Get the actual notes
    related_ids = list(related_scores.keys())
    notes = session.exec(select(Note).where(Note.id.in_(related_ids))).all()
    
    # Get relation details for direct relations
    direct_relation_map = {}
    for rel in direct_relations:
        other_id = rel.to_note_id if rel.from_note_id == note_id else rel.from_note_id
        direct_relation_map[other_id] = {
            'relation_id': rel.id,
            'relation_type': rel.relation_type
        }
    
    # Build response with scores and relation details
    result = []
    for n in notes:
        item = {
            "id": n.id,
            "title": n.title,
            "score": related_scores[n.id],
            "relation_type": direct_relation_map.get(n.id, {}).get('relation_type'),
            "relation_id": direct_relation_map.get(n.id, {}).get('relation_id')
        }
        result.append(item)
    
    # Sort by score descending
    result.sort(key=lambda x: x["score"], reverse=True)
    return result


@app.post("/notes/{note_id}/relations", status_code=201)
def create_note_relation(
    note_id: int,
    relation: NoteRelationCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    """Create a relation between two notes."""
    # Verify both notes exist and belong to user
    from_note = session.get(Note, note_id)
    to_note = session.get(Note, relation.to_note_id)
    if not from_note or from_note.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="source note not found")
    if not to_note or to_note.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="target note not found")
    if note_id == relation.to_note_id:
        raise HTTPException(status_code=400, detail="cannot relate note to itself")
    
    # Check if relation already exists
    existing = session.exec(
        select(NoteRelation).where(
            (NoteRelation.user_id == current_user.id) &
            (NoteRelation.from_note_id == note_id) &
            (NoteRelation.to_note_id == relation.to_note_id) &
            (NoteRelation.relation_type == relation.relation_type)
        )
    ).first()
    if existing:
        raise HTTPException(status_code=409, detail="relation already exists")
    
    # Create the relation
    new_relation = NoteRelation(
        from_note_id=note_id,
        to_note_id=relation.to_note_id,
        relation_type=relation.relation_type,
        user_id=current_user.id
    )
    session.add(new_relation)
    session.commit()
    session.refresh(new_relation)
    return NoteRelationRead(
        id=new_relation.id,
        from_note_id=new_relation.from_note_id,
        to_note_id=new_relation.to_note_id,
        relation_type=new_relation.relation_type,
        created_at=new_relation.created_at
    )


@app.delete("/notes/{note_id}/relations/{relation_id}")
def delete_note_relation(
    note_id: int,
    relation_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    """Delete a relation between notes."""
    relation = session.get(NoteRelation, relation_id)
    if not relation or relation.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="relation not found")
    if relation.from_note_id != note_id and relation.to_note_id != note_id:
        raise HTTPException(status_code=404, detail="relation not associated with this note")
    
    session.delete(relation)
    session.commit()
    return {"message": "relation deleted"}


@app.get("/stats/heatmap")
def stats_heatmap(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
    start: Optional[date] = None,
    end: Optional[date] = None,
):
    """Aggregate daily note counts for the current user.

    Optional `start`/`end` date parameters narrow the range. Results are sorted by date.
    """
    query = select(func.date(Note.created_at).label("day"), func.count().label("cnt")).where(
        Note.user_id == current_user.id
    )
    if start is not None:
        query = query.where(func.date(Note.created_at) >= start.isoformat())
    if end is not None:
        query = query.where(func.date(Note.created_at) <= end.isoformat())
    query = query.group_by(func.date(Note.created_at)).order_by(func.date(Note.created_at))
    rows = session.exec(query).all()
    return [{"date": r.day, "count": r.cnt} for r in rows]


@app.get("/review/daily")
def review_daily(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    """Return notes created today to support a simple daily review.

    Future versions can randomize or pick same-day last week.
    """
    today = date.today().isoformat()
    notes = session.exec(
        select(Note).where(
            (Note.user_id == current_user.id)
            & (func.date(Note.created_at) == today)
        )
    ).all()
    return [_to_note_read(session, n) for n in notes]


# ---- AI insight endpoints ----
@app.get("/insights/perspectives")
def list_perspectives(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    # For now return hardcoded default views if none exist in DB
    rows = session.exec(select(InsightPerspective).where(InsightPerspective.is_default == True)).all()
    if not rows:
        rows = [
            InsightPerspective(id=1, name="Default Analysis", prompt_template="Analyze: {notes}", is_default=True),
        ]
    return rows


class InsightRunRequest(SQLModel):
    perspective_id: int
    note_ids: List[int]


@app.post("/insights/run")
def run_insight(
    payload: InsightRunRequest,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    # simple synchronous stub: concatenate note contents
    notes = session.exec(select(Note).where((Note.user_id == current_user.id) & (Note.id.in_(payload.note_ids)))).all()
    text = "\n".join(n.content for n in notes)
    result = f"Stub insight for perspective {payload.perspective_id} on \n{text}"
    insight = InsightRun(
        user_id=current_user.id,
        perspective_id=payload.perspective_id,
        note_ids=",".join(str(i) for i in payload.note_ids),
        result=result,
        status="complete",
    )
    session.add(insight)
    session.commit()
    session.refresh(insight)
    return {"id": insight.id, "result": insight.result}


@app.get("/insights/history")
def insight_history(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    rows = session.exec(select(InsightRun).where(InsightRun.user_id == current_user.id)).all()
    return rows


# --- monetization endpoints ---
class SubscriptionInfo(SQLModel):
    plan: str
    status: str
    expire_at: Optional[datetime] = None


@app.get("/me/subscription", response_model=SubscriptionInfo)
def get_subscription(current_user: User = Depends(get_current_user)):
    # stub return free tier
    return SubscriptionInfo(plan="Free", status="active", expire_at=None)


class CheckoutRequest(SQLModel):
    plan: str


class CheckoutResponse(SQLModel):
    checkout_url: str


@app.post("/billing/checkout", response_model=CheckoutResponse)
def billing_checkout(
    payload: CheckoutRequest,
    current_user: User = Depends(get_current_user),
):
    # return fake url
    return CheckoutResponse(checkout_url=f"https://pay.example.com/{payload.plan}")


@app.patch("/notes/{note_id}", response_model=NoteRead)
def update_note(
    note_id: int,
    payload: NoteUpdate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    note = session.get(Note, note_id)
    if not note or note.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="note not found")
    if payload.title is not None:
        note.title = payload.title
    if payload.content is not None:
        note.content = payload.content
    if payload.tags is not None or payload.content is not None:
        current_tags = payload.tags
        if current_tags is None:
            current_tags = _get_note_tags(session, note.id, current_user.id)
        merged_tags = _merge_tags(current_tags, note.content)
        _set_note_tags(session, note.id, current_user.id, merged_tags)
    session.add(note)
    session.commit()
    session.refresh(note)
    return _to_note_read(session, note)


@app.delete("/notes/{note_id}")
def delete_note(
    note_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    note = session.get(Note, note_id)
    if not note or note.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="note not found")
    tags = session.exec(
        select(NoteTag).where((NoteTag.note_id == note_id) & (NoteTag.user_id == current_user.id))
    ).all()
    for row in tags:
        session.delete(row)
    session.delete(note)
    session.commit()
    return {"ok": True, "deleted_note_id": note_id}


@app.post("/conversations", response_model=Conversation)
def create_conversation(
    payload: ConversationCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    conv = Conversation(
        title=payload.title, status=payload.status or "open", user_id=current_user.id
    )
    session.add(conv)
    session.commit()
    session.refresh(conv)
    return conv


@app.post("/conversations/{cid}/message")
def add_message(
    cid: int,
    payload: MessageCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    conv = session.get(Conversation, cid)
    if not conv or conv.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="conversation not found")
    msg = Message(
        conversation_id=cid,
        sender=payload.sender,
        text=payload.text,
        user_id=current_user.id,
    )
    session.add(msg)
    session.commit()
    session.refresh(msg)

    # If user message, enqueue background AI job and return queued status
    if payload.sender == "user":
        prompt = _build_workspace_prompt(
            payload.text,
            note_title=payload.note_title,
            note_content=payload.note_content,
            attachment_labels=payload.attachment_labels,
        )
        try:
            from backend.ai_worker import enqueue_job

            enqueue_job(
                cid,
                payload.text,
                current_user.id,
                note_title=payload.note_title,
                note_content=payload.note_content,
                attachment_labels=payload.attachment_labels,
            )
            return {"user_message": msg, "status": "queued"}
        except Exception:
            # fallback to synchronous reply if enqueue fails
            ai_text = _ai_reply(prompt)
            ai_msg = Message(
                conversation_id=cid,
                sender="ai",
                text=ai_text,
                user_id=current_user.id,
            )
            session.add(ai_msg)
            session.commit()
            session.refresh(ai_msg)
            return {"user_message": msg, "ai_message": ai_msg}

    return {"message": msg}


@app.get("/conversations/{cid}/messages")
def list_messages(
    cid: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    conv = session.get(Conversation, cid)
    if not conv or conv.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="conversation not found")
    msgs = session.exec(
        select(Message).where(
            (Message.conversation_id == cid) & (Message.user_id == current_user.id)
        )
    ).all()
    return msgs


@app.post("/conversations/{cid}/close")
def close_conversation(
    cid: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    conv = session.get(Conversation, cid)
    if not conv or conv.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="conversation not found")
    # gather messages
    msgs = session.exec(
        select(Message).where(
            (Message.conversation_id == cid) & (Message.user_id == current_user.id)
        )
    ).all()
    summary_prompt = "\n".join([f"{m.sender}: {m.text}" for m in msgs])
    summary = _ai_reply("\u8bf7\u603b\u7ed3\u4ee5\u4e0b\u5bf9\u8bdd\u5e76\u63d0\u53d6\u7075\u611f\u8981\u70b9\uff1a\n" + summary_prompt)
    note = Note(
        title=conv.title or f"Summary {cid}",
        content=summary,
        user_id=current_user.id,
    )
    session.add(note)
    conv.status = "summarized"
    session.commit()
    session.refresh(note)
    return {"note_id": note.id, "summary": summary}


# Serve frontend static files - MUST be at the end
from fastapi.staticfiles import StaticFiles
import os

frontend_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "mobile", "build", "web")
uploads_dir = _uploads_dir()
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")
if os.path.exists(frontend_dir):
    app.mount("/", StaticFiles(directory=frontend_dir, html=True), name="frontend")

