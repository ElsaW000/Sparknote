from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.security import OAuth2PasswordBearer
from sqlmodel import SQLModel, Field, create_engine, Session, select
from typing import Optional, List, Generator
from datetime import datetime, timedelta
import os
import requests
from jose import JWTError, jwt
from passlib.context import CryptContext

# ---------- database setup ----------
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./sparknote.db")
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
            rows = conn.exec_driver_sql("PRAGMA table_info(note)").fetchall()
            cols = {str(r[1]) for r in rows}
            if "created_at" not in cols:
                conn.exec_driver_sql("ALTER TABLE note ADD COLUMN created_at TEXT")
                conn.exec_driver_sql(
                    "UPDATE note SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL"
                )
    except Exception:
        # Schema compatibility patch should not block app startup.
        pass


# ---------- models ----------
class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(index=True)
    password_hash: str
    is_active: bool = True
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


class UserCreate(SQLModel):
    email: str
    password: str


class UserRead(SQLModel):
    id: int
    email: str
    is_active: bool


class Token(SQLModel):
    access_token: str
    token_type: str = "bearer"


# ---------- security & auth helpers ----------
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "dev-secret-change-me")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))

# Prefer pbkdf2_sha256 for broad compatibility in local/dev environments.
# Some passlib+bcrypt version combos can fail during backend self-check.
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


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
app = FastAPI(title="Sparknote Backend")


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


def _normalize_tags(tags: Optional[List[str]]) -> List[str]:
    if not tags:
        return []
    seen = set()
    normalized: List[str] = []
    for t in tags:
        if not t:
            continue
        tag = t.strip()
        if not tag or tag in seen:
            continue
        seen.add(tag)
        normalized.append(tag)
    return normalized


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


def _to_note_read(session: Session, note: Note) -> NoteRead:
    return NoteRead(
        id=note.id,
        title=note.title,
        content=note.content,
        user_id=note.user_id,
        created_at=note.created_at,
        tags=_get_note_tags(session, note.id, note.user_id),
    )


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


@app.post("/auth/register", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def register_user(payload: UserCreate, session: Session = Depends(get_session)):
    existing = get_user_by_email(session, payload.email)
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")
    user = User(email=payload.email, password_hash=hash_password(payload.password))
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


@app.post("/auth/login", response_model=Token)
def login(payload: UserCreate, session: Session = Depends(get_session)):
    user = get_user_by_email(session, payload.email)
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect email or password")
    access_token = create_access_token({"sub": str(user.id)})
    return Token(access_token=access_token, token_type="bearer")


@app.get("/auth/me", response_model=UserRead)
def read_me(current_user: User = Depends(get_current_user)):
    return current_user


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
    _set_note_tags(session, note.id, current_user.id, payload.tags)
    session.commit()
    return _to_note_read(session, note)


@app.get("/notes", response_model=List[NoteRead])
def list_notes(
    session: Session = Depends(get_session), current_user: User = Depends(get_current_user)
):
    notes = session.exec(select(Note).where(Note.user_id == current_user.id)).all()
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
    if payload.tags is not None:
        _set_note_tags(session, note.id, current_user.id, payload.tags)
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
        try:
            from backend.ai_worker import enqueue_job

            enqueue_job(cid, payload.text, current_user.id)
            return {"user_message": msg, "status": "queued"}
        except Exception:
            # fallback to synchronous reply if enqueue fails
            ai_text = _ai_reply(payload.text)
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
    summary = _ai_reply("请总结以下对话并提取灵感要点：\n" + summary_prompt)
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
