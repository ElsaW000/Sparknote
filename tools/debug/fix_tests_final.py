# Simple approach: truncate to remove bad tests, then re-add correctly
content = open(r'D:\02-Projects\01-Sparknote\backend\tests\test_api.py', 'r', encoding='utf-8-sig').read()
# Find where bad content starts (after "assert id3 in ids_pinned")
marker = 'assert id3 in ids_pinned\n'
idx = content.find(marker)
if idx == -1:
    print('Marker not found')
else:
    end_idx = idx + len(marker)
    clean_content = content[:end_idx]
    new_tests = '''

def test_templates_list():
    """NOTE-10: list available templates."""
    headers = _auth_headers("template_user@example.com", "pass1234")
    r = client.get("/templates", headers=headers)
    assert r.status_code == 200
    templates = r.json()
    assert isinstance(templates, list)
    assert len(templates) >= 3
    names = {t["name"] for t in templates}
    assert "会议纪要" in names
    assert "灵感卡片" in names
    assert "复盘" in names
    for t in templates:
        assert "id" in t
        assert "name" in t
        assert "content_template" in t
        assert "default_tags" in t


def test_templates_preview():
    """NOTE-10: preview a template with variables."""
    headers = _auth_headers("preview_user@example.com", "pass1234")
    r = client.get("/templates", headers=headers)
    meeting = next(t for t in r.json() if t["name"] == "会议纪要")
    r = client.post("/templates/preview", json={
        "template_id": meeting["id"],
        "variables": {"date": "2026-04-30", "topic": "Q2规划"}
    }, headers=headers)
    assert r.status_code == 200
    resp = r.json()
    assert "【会议】2026-04-30 Q2规划" in resp["title"]
    assert "## 会议目标" in resp["content"]


def test_create_note_from_template():
    """NOTE-10: create a note using a template."""
    headers = _auth_headers("note_from_template@example.com", "pass1234")
    r = client.get("/templates", headers=headers)
    meeting = next(t for t in r.json() if t["name"] == "会议纪要")
    r = client.post("/notes", json={
        "template_id": meeting["id"],
        "template_variables": {"date": "2026-04-30", "topic": "产品评审"},
        "content": "本次评审重点讨论 MVP 上线计划"
    }, headers=headers)
    assert r.status_code == 200
    note = r.json()
    assert "产品评审" in note["title"]
    assert "会议" in note["tags"]
    assert "本次评审重点讨论 MVP 上线计划" in note["content"]


def test_create_note_template_not_found():
    """NOTE-10: creating from non-existent template falls back to plain note."""
    headers = _auth_headers("fallback_user@example.com", "pass1234")
    r = client.post("/notes", json={
        "template_id": 9999,
        "title": "Fallback Note",
        "content": "This should still work"
    }, headers=headers)
    assert r.status_code == 200
    note = r.json()
    assert note["title"] == "Fallback Note"
    assert note["content"] == "This should still work"
'''
    final_content = clean_content + new_tests
    open(r'D:\02-Projects\01-Sparknote\backend\tests\test_api.py', 'w', encoding='utf-8-sig').write(final_content)
    print('Done. File length:', len(final_content))
