import os
import tempfile

from fastapi.testclient import TestClient

# Ensure tests use an isolated file-based sqlite database so tables persist
# across connections and are not polluted by stale local test.db schemas.
_tmp_db_fd, _tmp_db_path = tempfile.mkstemp(prefix="sparknote_test_", suffix=".db")
os.close(_tmp_db_fd)
os.environ["DATABASE_URL"] = f"sqlite:///{_tmp_db_path}"

from backend import main

# ensure tables exist before launching the test client
main.init_db()

client = TestClient(main.app)


def _auth_headers(email: str = "tester@example.com", password: str = "pass1234") -> dict:
    # Keep tests idempotent: user may already exist in local db.
    client.post("/auth/register", json={"email": email, "password": password})
    r = client.post("/auth/login", json={"email": email, "password": password})
    assert r.status_code == 200
    token = r.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json().get("status") == "ok"


def test_notes_and_conversation_flow():
    headers = _auth_headers()

    # create note
    r = client.post("/notes", json={"title": "Hello", "content": "first note"}, headers=headers)
    assert r.status_code == 200
    note = r.json()
    assert note["title"] == "Hello"

    # create conversation
    r = client.post("/conversations", json={"title": "chat1"}, headers=headers)
    assert r.status_code == 200
    conv = r.json()
    cid = conv["id"]

    # add user message -> expect ai reply
    r = client.post(
        f"/conversations/{cid}/message",
        json={"sender": "user", "text": "This is an idea"},
        headers=headers,
    )
    assert r.status_code == 200
    j = r.json()
    assert "user_message" in j
    # AI reply is processed asynchronously by worker; wait and then fetch messages
    import time

    time.sleep(1.0)
    r = client.get(f"/conversations/{cid}/messages", headers=headers)
    assert r.status_code == 200
    msgs = r.json()
    # should include at least 2 messages (user + ai)
    assert any(m["sender"] == "ai" for m in msgs)

    # close conversation -> creates a note
    r = client.post(f"/conversations/{cid}/close", headers=headers)
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


def test_note_auto_extract_hashtags():
    headers = _auth_headers("tagger@example.com", "pass1234")

    r = client.post(
        "/notes",
        json={
            "title": "Tag Test",
            "content": "capture #idea and #工作 and keep #work-log",
            "tags": ["manual", "#idea"],
        },
        headers=headers,
    )
    assert r.status_code == 200
    note = r.json()
    assert set(note["tags"]) == {"manual", "idea", "工作", "work-log"}

    note_id = note["id"]
    r = client.patch(
        f"/notes/{note_id}",
        json={"content": "updated content with #newtag and #工作"},
        headers=headers,
    )
    assert r.status_code == 200
    updated = r.json()
    assert "newtag" in updated["tags"]
    assert "工作" in updated["tags"]
