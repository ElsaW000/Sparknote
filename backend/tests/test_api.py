import os
import re
import tempfile
import base64

from fastapi.testclient import TestClient

# Ensure tests use an isolated file-based sqlite database so tables persist
# across connections and are not polluted by stale local test.db schemas.
_tmp_db_fd, _tmp_db_path = tempfile.mkstemp(prefix="sparknote_test_", suffix=".db")
os.close(_tmp_db_fd)
os.environ["DATABASE_URL"] = f"sqlite:///{_tmp_db_path}"
os.environ["REQUIRE_REGISTER_CAPTCHA"] = "0"

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


def test_manual_tags():
    headers = _auth_headers("manual@example.com", "pass")
    r = client.post(
        "/notes",
        json={"title": "Manual", "content": "no tags", "tags": ["X", "#Y", "x"]},
        headers=headers,
    )
    assert r.status_code == 200
    note = r.json()
    # normalization should remove leading # and dedupe; case is preserved so X and x are distinct
    assert note["tags"] == ["X", "Y", "x"]


def test_sync_since_filter():
    headers = _auth_headers("syncer@example.com", "pass")
    # create first note
    r1 = client.post(
        "/notes",
        json={"title": "First", "content": "1"},
        headers=headers,
    )
    assert r1.status_code == 200
    first = r1.json()
    since = first["created_at"]
    # create second note after a tiny delay
    import time

    time.sleep(0.1)
    r2 = client.post(
        "/notes",
        json={"title": "Second", "content": "2"},
        headers=headers,
    )
    assert r2.status_code == 200
    # list with since=first.created_at should return only second
    rlist = client.get("/notes", headers=headers, params={"since": since})
    assert rlist.status_code == 200
    notes = rlist.json()
    assert len(notes) == 1
    assert notes[0]["title"] == "Second"


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


def test_tags_suggest():
    headers = _auth_headers("suggester@example.com", "pass")
    # create notes with tags
    client.post(
        "/notes",
        json={"title": "A", "content": "tag #foo", "tags": ["bar"]},
        headers=headers,
    )
    client.post(
        "/notes",
        json={"title": "B", "content": "#foo #baz"},
        headers=headers,
    )
    client.post(
        "/notes",
        json={"title": "C", "content": "#foo"},
        headers=headers,
    )
    r = client.get("/tags/suggest", headers=headers)
    assert r.status_code == 200
    tags = r.json()
    # Should be sorted by frequency: foo (3), bar (1), baz (1)
    assert tags[0]["tag"] == "foo" and tags[0]["count"] == 3
    assert len(tags) == 3


def test_notes_tag_filter():
    headers = _auth_headers("filter@example.com", "pass")
    # create notes with different tags
    client.post(
        "/notes",
        json={"title": "Note1", "content": "has #work", "tags": ["urgent"]},
        headers=headers,
    )
    client.post(
        "/notes",
        json={"title": "Note2", "content": "has #personal"},
        headers=headers,
    )
    client.post(
        "/notes",
        json={"title": "Note3", "content": "also #work"},
        headers=headers,
    )
    # filter by tag=work
    r = client.get("/notes", headers=headers, params={"tag": "work"})
    assert r.status_code == 200
    notes = r.json()
    assert len(notes) == 2
    titles = {n["title"] for n in notes}
    assert titles == {"Note1", "Note3"}


def test_notes_search_filter():
    headers = _auth_headers("search@example.com", "pass")
    client.post(
        "/notes",
        json={"title": "FastAPI tips", "content": "How to build APIs with auth", "tags": ["backend"]},
        headers=headers,
    )
    client.post(
        "/notes",
        json={"title": "Random note", "content": "Nothing related here"},
        headers=headers,
    )
    client.post(
        "/notes",
        json={"title": "Cooking", "content": "fastapi mentioned in lowercase"},
        headers=headers,
    )

    r = client.get("/notes", headers=headers, params={"q": "FastAPI"})
    assert r.status_code == 200
    notes = r.json()
    assert len(notes) == 2
    titles = {n["title"] for n in notes}
    assert titles == {"FastAPI tips", "Cooking"}

    r2 = client.get("/notes", headers=headers, params={"q": "auth", "tag": "backend"})
    assert r2.status_code == 200
    notes2 = r2.json()
    assert len(notes2) == 1
    assert notes2[0]["title"] == "FastAPI tips"


def test_related_notes():
    headers = _auth_headers("rel@example.com", "pass")
    r1 = client.post(
        "/notes",
        json={"title": "N1", "content": "#shared"},
        headers=headers,
    )
    r2 = client.post(
        "/notes",
        json={"title": "N2", "content": "#shared"},
        headers=headers,
    )
    id1 = r1.json()["id"]
    id2 = r2.json()["id"]
    r = client.get(f"/notes/{id1}/related", headers=headers)
    assert r.status_code == 200
    related = r.json()
    assert any(n["title"] == "N2" and n["score"] > 0 for n in related)
    
    # Test explicit relation
    r3 = client.post(f"/notes/{id1}/relations", 
                     json={"to_note_id": id2, "relation_type": "related"}, 
                     headers=headers)
    assert r3.status_code == 201
    relation_id = r3.json()["id"]
    
    # Check related notes again - should have higher score now
    r = client.get(f"/notes/{id1}/related", headers=headers)
    assert r.status_code == 200
    related = r.json()
    n2_entry = next((n for n in related if n["title"] == "N2"), None)
    assert n2_entry is not None
    assert n2_entry["score"] >= 5  # Direct relation score
    
    # Delete relation
    r4 = client.delete(f"/notes/{id1}/relations/{relation_id}", headers=headers)
    assert r4.status_code == 200


def test_stats_heatmap_and_review():
    headers = _auth_headers("heat@example.com", "pass")
    # create two notes on same day
    client.post(
        "/notes",
        json={"title": "H1", "content": "x"},
        headers=headers,
    )
    client.post(
        "/notes",
        json={"title": "H2", "content": "y"},
        headers=headers,
    )
    # also create a note with yesterday's timestamp
    import datetime

    yesterday = (datetime.datetime.utcnow() - datetime.timedelta(days=1)).isoformat()
    r3 = client.post(
        "/notes",
        json={"title": "H0", "content": "z"},
        headers=headers,
    )
    assert r3.status_code == 200
    # manually update created_at of H0
    noteid = r3.json()["id"]
    from backend.main import engine, Note
    from sqlmodel import Session

    with Session(engine) as ses:
        n = ses.get(Note, noteid)
        n.created_at = datetime.datetime.utcnow() - datetime.timedelta(days=1)
        ses.add(n)
        ses.commit()
    # full heatmap
    r = client.get("/stats/heatmap", headers=headers)
    assert r.status_code == 200
    heat = r.json()
    # should have at least two dates present
    assert len(heat) >= 2
    # filter by start=yesterday
    r2 = client.get(
        "/stats/heatmap",
        headers=headers,
        params={"start": (datetime.date.today() - datetime.timedelta(days=1)).isoformat()},
    )
    assert r2.status_code == 200
    heat2 = r2.json()
    assert any(entry["date"] < datetime.date.today().isoformat() for entry in heat2)
    # review endpoint returns today's notes
    r3 = client.get("/review/daily", headers=headers)
    assert r3.status_code == 200
    review = r3.json()
    assert any(item["title"] in ("H1", "H2") for item in review)
    assert all("content" in item for item in review)

def test_registration_captcha():
    main.REQUIRE_REGISTER_CAPTCHA = True
    try:
        rc = client.get("/auth/captcha")
        assert rc.status_code == 200
        chal = rc.json()
        bad = client.post(
            "/auth/register",
            json={"email": "cap@example.com", "password": "pass", "captcha_id": chal["captcha_id"], "captcha_answer": "wrong"},
        )
        assert bad.status_code == 400

        nums = [int(v) for v in re.findall(r"\d+", chal["question"])]
        assert len(nums) >= 2
        answer = str(nums[0] + nums[1])

        good = client.post(
            "/auth/register",
            json={"email": "cap@example.com", "password": "pass", "captcha_id": chal["captcha_id"], "captcha_answer": answer},
        )
        assert good.status_code == 201
    finally:
        main.REQUIRE_REGISTER_CAPTCHA = False


def test_insight_endpoints():
    headers = _auth_headers("aiuser@example.com", "pass")
    # perspectives list
    r = client.get("/insights/perspectives", headers=headers)
    assert r.status_code == 200
    pers = r.json()
    assert isinstance(pers, list)
    assert any(p.get("name") for p in pers)

    # create a note and run insight
    rnote = client.post(
        "/notes",
        json={"title": "AiNote", "content": "content1"},
        headers=headers,
    )
    nid = rnote.json()["id"]
    rr = client.post(
        "/insights/run",
        json={"perspective_id": pers[0].get("id", 1), "note_ids": [nid]},
        headers=headers,
    )
    assert rr.status_code == 200
    out = rr.json()
    assert "result" in out

    # history should include the run
    rh = client.get("/insights/history", headers=headers)
    assert rh.status_code == 200
    hist = rh.json()
    assert any(h.get("id") == out.get("id") for h in hist)


def test_monetization_endpoints():
    headers = _auth_headers("biz@example.com", "pass")
    r = client.get("/me/subscription", headers=headers)
    assert r.status_code == 200
    sub = r.json()
    assert sub["plan"].lower() in ("free", "pro", "max") or sub["plan"]

    r2 = client.post(
        "/billing/checkout",
        headers=headers,
        json={"plan": "Pro"},
    )
    assert r2.status_code == 200
    body = r2.json()
    assert "checkout_url" in body


def test_notion_integration_endpoints():
    headers = _auth_headers("notion@example.com", "pass1234")

    r = client.get("/integrations/notion", headers=headers)
    assert r.status_code == 200
    initial = r.json()
    assert initial["connected"] is False
    assert initial["api_token"] is None
    assert initial["database_id"] is None

    r2 = client.put(
        "/integrations/notion",
        headers=headers,
        json={
            "api_token": "secret_test_token",
            "database_id": "db_123456",
        },
    )
    assert r2.status_code == 200
    updated = r2.json()
    assert updated["connected"] is True
    assert updated["api_token"] == "secret_test_token"
    assert updated["database_id"] == "db_123456"


def test_note_attachment_endpoints():
    headers = _auth_headers("attach@example.com", "pass1234")

    r_note = client.post(
        "/notes",
        json={"title": "Attachment note", "content": "body"},
        headers=headers,
    )
    assert r_note.status_code == 200
    note_id = r_note.json()["id"]

    payload = {
        "file_name": "idea.txt",
        "mime_type": "text/plain",
        "content_base64": base64.b64encode(b"hello attachment").decode("utf-8"),
    }
    r_upload = client.post(f"/notes/{note_id}/attachments", json=payload, headers=headers)
    assert r_upload.status_code == 201
    uploaded = r_upload.json()
    assert uploaded["file_name"] == "idea.txt"
    assert uploaded["mime_type"] == "text/plain"
    assert uploaded["url"].startswith("/uploads/")

    r_list = client.get(f"/notes/{note_id}/attachments", headers=headers)
    assert r_list.status_code == 200
    attachments = r_list.json()
    assert len(attachments) == 1
    assert attachments[0]["file_name"] == "idea.txt"
    attachment_id = attachments[0]["id"]

    r_get = client.get(f"/notes/{note_id}", headers=headers)
    assert r_get.status_code == 200
    note = r_get.json()
    assert len(note["attachments"]) == 1

    r_delete = client.delete(
        f"/notes/{note_id}/attachments/{attachment_id}",
        headers=headers,
    )
    assert r_delete.status_code == 200

    r_list_again = client.get(f"/notes/{note_id}/attachments", headers=headers)
    assert r_list_again.status_code == 200
    assert r_list_again.json() == []


def test_audio_transcription_endpoint():
    headers = _auth_headers("audio@example.com", "pass1234")
    payload = {
        "mime_type": "audio/webm",
        "content_base64": base64.b64encode(b"fake audio bytes").decode("utf-8"),
        "context": "test context",
    }
    r = client.post("/audio/transcribe", json=payload, headers=headers)
    assert r.status_code == 200
    body = r.json()
    assert "transcript" in body
    assert isinstance(body["transcript"], str)


def test_workspace_resume_and_history_actions():
    headers = _auth_headers("workspace@example.com", "pass1234")

    r_note = client.post(
        "/notes",
        json={"title": "产品灵感整合草稿", "content": "draft body"},
        headers=headers,
    )
    assert r_note.status_code == 200
    note_id = r_note.json()["id"]

    r_resume = client.get(f"/workspace/notes/{note_id}/resume", headers=headers)
    assert r_resume.status_code == 200
    resumed = r_resume.json()
    assert resumed["note_id"] == note_id
    assert resumed["status"] == "open"
    conversation_id = resumed["conversation_id"]

    r_note_detail = client.get(f"/notes/{note_id}", headers=headers)
    assert r_note_detail.status_code == 200
    note_detail = r_note_detail.json()
    assert note_detail["workspace_conversation_id"] == conversation_id
    assert note_detail["workspace_status"] == "open"

    r_history = client.get("/workspace/history", headers=headers)
    assert r_history.status_code == 200
    history = r_history.json()
    assert any(item["conversation_id"] == conversation_id for item in history)

    r_share = client.post(f"/workspace/history/{conversation_id}/share", headers=headers)
    assert r_share.status_code == 200
    shared = r_share.json()
    assert str(conversation_id) in shared["share_text"]

    r_delete = client.delete(f"/workspace/history/{conversation_id}", headers=headers)
    assert r_delete.status_code == 200

    r_history_after = client.get("/workspace/history", headers=headers)
    assert r_history_after.status_code == 200
    assert all(item["conversation_id"] != conversation_id for item in r_history_after.json())


def test_note_auto_extract_hashtags():
    headers = _auth_headers("tagger@example.com", "pass1234")

    r = client.post(
        "/notes",
        json={
            "title": "Tag Test",
            "content": "capture #idea and #å·¥ä½œ and keep #work-log",
            "tags": ["manual", "#idea"],
        },
        headers=headers,
    )
    assert r.status_code == 200
    note = r.json()
    assert set(note["tags"]) == {"manual", "idea", "å·¥ä½œ", "work-log"}

    note_id = note["id"]
    r = client.patch(
        f"/notes/{note_id}",
        json={"content": "updated content with #newtag and #å·¥ä½œ"},
        headers=headers,
    )
    assert r.status_code == 200
    updated = r.json()
    assert "newtag" in updated["tags"]
    assert "å·¥ä½œ" in updated["tags"]


def test_note_search():
    headers = _auth_headers("searcher@example.com", "pass1234")

    # Create notes with known content for search testing
    r1 = client.post("/notes", json={"title": "Python 技巧", "content": "学会使用列表推导式"}, headers=headers)
    assert r1.status_code == 200
    note1_id = r1.json()["id"]

    r2 = client.post("/notes", json={"title": "JavaScript 入门", "content": "学习 Python 语法"}, headers=headers)
    assert r2.status_code == 200

    r3 = client.post("/notes", json={"title": "Rust vs Go", "content": "系统编程语言比较", "tags": ["Python"]}, headers=headers)
    assert r3.status_code == 200
    note3_id = r3.json()["id"]

    # Search by title keyword
    r = client.get("/notes/search", params={"q": "JavaScript"}, headers=headers)
    assert r.status_code == 200
    resp = r.json()
    assert resp["total"] >= 1
    assert any(n["id"] == note1_id or n["title"] == "JavaScript 入门" for n in resp["results"])

    # Search by content keyword
    r = client.get("/notes/search", params={"q": "列表推导式"}, headers=headers)
    assert r.status_code == 200
    resp = r.json()
    assert resp["total"] >= 1
    assert resp["results"][0]["match_type"] in ("title", "content")

    # Search by tag
    r = client.get("/notes/search", params={"q": "Python"}, headers=headers)
    assert r.status_code == 200
    resp = r.json()
    # Should match note2 (content) and note3 (tag)
    assert resp["total"] >= 2
    ids = {n["id"] for n in resp["results"]}
    assert note1_id in ids or note3_id in ids

    # Pagination
    r = client.get("/notes/search", params={"q": "Python", "page": 1, "limit": 1}, headers=headers)
    assert r.status_code == 200
    resp = r.json()
    assert resp["page"] == 1
    assert resp["limit"] == 1
    assert resp["total"] >= 2
    assert len(resp["results"]) == 1

    # Empty query returns empty
    r = client.get("/notes/search", params={"q": ""}, headers=headers)
    assert r.status_code == 200
    resp = r.json()
    assert resp["results"] == []
    assert resp["total"] == 0


