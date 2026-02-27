import os
import tempfile

from fastapi.testclient import TestClient

# ensure tests use a file-based sqlite database so tables persist across connections
os.environ.setdefault("DATABASE_URL", "sqlite:///./test.db")

from backend import main

# ensure tables exist before launching the test client
main.init_db()

client = TestClient(main.app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json().get("status") == "ok"


def test_notes_and_conversation_flow():
    # create note
    r = client.post("/notes", json={"title": "Hello", "content": "first note"})
    assert r.status_code == 200
    note = r.json()
    assert note["title"] == "Hello"

    # create conversation
    r = client.post("/conversations", json={"title": "chat1"})
    assert r.status_code == 200
    conv = r.json()
    cid = conv["id"]

    # add user message -> expect ai reply
    r = client.post(
        f"/conversations/{cid}/message",
        json={"sender": "user", "text": "This is an idea"},
    )
    assert r.status_code == 200
    j = r.json()
    assert "user_message" in j
    # AI reply is processed asynchronously by worker; wait and then fetch messages
    import time

    time.sleep(1.0)
    r = client.get(f"/conversations/{cid}/messages")
    assert r.status_code == 200
    msgs = r.json()
    # should include at least 2 messages (user + ai)
    assert any(m["sender"] == "ai" for m in msgs)

    # close conversation -> creates a note
    r = client.post(f"/conversations/{cid}/close")
    assert r.status_code == 200
    j = r.json()
    assert "note_id" in j and "summary" in j


def test_debug_ai():
    # debug endpoint should return some text even without keys (mock reply)
    r = client.get("/debug/ai", params={"prompt": "test"})
    assert r.status_code == 200
    d = r.json()
    assert "reply" in d
    assert isinstance(d["reply"], str)
    assert d["reply"] != ""  # mock or real reply
