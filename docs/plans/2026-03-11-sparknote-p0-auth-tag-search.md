# Sparknote P0 Auth + Tag Colors + Search Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement P0 features for identity selection on registration, tag-color mapping for notes/calendar, and note search by title/content in the Sparknote app.

**Architecture:** Backend in FastAPI (backend/main.py + tests), frontend currently assumed as mobile Flutter app. For this plan we will first wire the backend API (auth identity field, tag color mapping support, search endpoint), plus minimal DB changes. Frontend/mobile integration can be added in a follow-up plan if needed.

**Tech Stack:** FastAPI, Python, SQLite (dev), pytest.

---

### Task 1: Review current backend structure and PRD for these features

**Files:**
- Read: `backend/main.py`
- Read: `PRD/04-epics-and-stories.md`

**Step 1:** Open `backend/main.py` and skim for existing auth, notes, and tags endpoints.

**Step 2:** Confirm whether user model already has an `identity` or similar field, and whether notes have tag information stored.

**Step 3:** Cross-check with `PRD/04-epics-and-stories.md` for AUTH-01, CAL-01, TAG-01, NOTE-06 to ensure acceptance criteria are fully captured.

**Step 4:** Update this plan (if needed) to align with the actual code structure (e.g., path operations, models, DB helpers).

---

### Task 2: Design/extend database schema for user identity and note tags + search support

**Files:**
- Modify (if exists): `db/schema.sql` or equivalent migration/init script
- Read/modify: any ORM/datastore layer in `backend/main.py`

**Step 1:** Locate where database schema is defined (direct SQL, ORM models, or `sparknote.db` initialization code).

**Step 2:** Ensure the `users` table has an `identity` column (e.g., TEXT, values like `novel`, `product`, `content`, `all`). If missing, plan a migration/init change.

**Step 3:** Ensure the `notes` table has a way to store tags (e.g., `tags` TEXT as comma-separated or JSON) and that title/content columns exist for search.

**Step 4:** If full-text search (FTS) isnt used yet, decide to implement simple `LIKE`-based search first for P0.

**Step 5:** Document expected allowed `identity` values and tag format in code comments.

---

### Task 3: Add/extend backend models/schemas for identity and tags

**Files:**
- Modify: `backend/main.py` (Pydantic models for UserCreate/User, NoteCreate/Note if they exist)
- Tests: `backend/tests/` (auth + notes tests)

**Step 1:** Locate Pydantic request/response models for registration and users.

**Step 2:** Add an `identity: Literal["novel", "product", "content", "all"]` (or `str` with validation) field to the registration request model and user model.

**Step 3:** Locate note models and ensure they have a `tags: List[str]` (or `str`) field that matches storage.

**Step 4:** Add docstrings/comments describing identity choices and tag format for future frontend integration.

---

### Task 4: Implement registration endpoint support for identity selection

**Files:**
- Modify: `backend/main.py` (registration route/function)
- Test: `backend/tests/test_auth.py` (create if not existing)

**Step 1: Write the failing test**

Create or extend `backend/tests/test_auth.py` with a test like:

```python
from fastapi.testclient import TestClient
from backend.main import app

client = TestClient(app)


def test_register_with_identity_success():
    payload = {
        "email": "user@example.com",
        "password": "test1234",
        "identity": "novel",
    }
    response = client.post("/auth/register", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == payload["email"]
    assert data["identity"] == payload["identity"]
```

**Step 2:** Run this test and confirm it fails due to missing identity handling.

**Step 3: Implement minimal code**

In `backend/main.py`, update the registration endpoint to:
- Accept `identity` in the request model
- Validate it against allowed values
- Store it in the users table
- Return it in the response

**Step 4:** Re-run the test to verify it now passes.

---

### Task 5: Enforce identity selection requirement and default behavior

**Files:**
- Modify: `backend/main.py`
- Test: `backend/tests/test_auth.py`

**Step 1: Add tests**

In `backend/tests/test_auth.py`, add tests for:
- Missing identity (should return 422 or 400 depending on design)
- Invalid identity (e.g., `"other"`) returns error

**Step 2:** Implement validation logic (either via Pydantic `Literal` or manual check) so these tests fail initially.

**Step 3:** Implement the validation to make tests pass.

**Step 4:** Ensure error messages are clear for frontend use.

---

### Task 6: Implement backend support for tag color mapping (data side)

**Files:**
- Modify: `backend/main.py` (note creation/updating + note retrieval endpoints)
- Tests: `backend/tests/test_notes.py`

**Step 1:** Decide on a deterministic color mapping strategy based on tag name (e.g., hash tag to a fixed palette of colors) or a fixed mapping for common tags.

**Step 2:** Implement a pure function in `backend/main.py`, e.g.:

```python
TAG_COLORS = ["#FF6B6B", "#4ECDC4", "#FFD93D", "#1A535C", "#FF9F1C"]


def get_tag_color(tag: str) -> str:
    if not tag:
        return "#CCCCCC"
    idx = abs(hash(tag)) % len(TAG_COLORS)
    return TAG_COLORS[idx]
```

**Step 3:** Make sure note retrieval endpoints include tag color info, for example by returning a list of `{ "name": tag, "color": "#RRGGBB" }` objects, or by adding a derived `tag_colors` field.

**Step 4: Write tests in `backend/tests/test_notes.py`** to verify that:
- Notes with tags return colors consistently for the same tag name.
- Multiple tags on a note each get a color.

---

### Task 7: Expose tag color information for calendar heatmap

**Files:**
- Modify: `backend/main.py` (calendar/summary endpoint if exists, or create one)
- Tests: `backend/tests/test_calendar.py`

**Step 1:** Check if there is already an endpoint that aggregates notes per day; if not, design one such as `GET /calendar/heatmap` that returns, per date:

```json
{
  "date": "2026-03-11",
  "total_notes": 5,
  "tag_counts": {"novel": 3, "product": 2},
  "tags": [
    {"name": "novel", "color": "#FF6B6B"},
    {"name": "product", "color": "#4ECDC4"}
  ]
}
```

**Step 2:** Implement this endpoint using existing note/tag data and `get_tag_color`.

**Step 3:** Write tests that:
- Seed some notes with tags on specific dates
- Assert the endpoint returns aggregated counts and matching colors.

---

### Task 8: Implement search endpoint by title/content (NOTE-06)

**Files:**
- Modify: `backend/main.py` (add `/notes/search` endpoint or query param to `/notes`)
- Tests: `backend/tests/test_search.py`

**Step 1: Write failing tests** in `backend/tests/test_search.py`:

```python
from fastapi.testclient import TestClient
from backend.main import app

client = TestClient(app)


def test_search_notes_by_keyword_in_title_and_content():
    # Seed: create a few notes via the API or setup helper
    client.post("/notes", json={"title": "FastAPI tips", "content": "How to build APIs"})
    client.post("/notes", json={"title": "Random", "content": "Nothing related"})

    resp = client.get("/notes/search", params={"q": "FastAPI"})
    assert resp.status_code == 200
    results = resp.json()
    assert any("FastAPI" in note["title"] for note in results)
    assert all("FastAPI" in (note["title"] + note["content"]) for note in results)
```

**Step 2:** Run the tests and confirm failure due to missing search endpoint.

**Step 3: Implement minimal search**

- Add a new route in `backend/main.py`, e.g. `GET /notes/search?q=...`.
- Use SQL `LIKE` queries (or ORM equivalent) on title and content columns.
- Return matching notes sorted by recency.

**Step 4:** Re-run tests to confirm they pass.

---

### Task 9: Handle edge cases for search

**Files:**
- Modify: `backend/main.py`
- Tests: `backend/tests/test_search.py`

**Step 1:** Add tests for:
- Empty `q` (should return 400 or empty list)
- Query with no matches (returns empty list)
- Case-insensitive search.

**Step 2:** Implement behavior that makes these tests pass (e.g. normalize case, trim whitespace, enforce min length).

**Step 3:** Ensure search endpoint is documented in code comments for frontend.

---

### Task 10: Wire identity, tag colors, and search into existing API documentation / README

**Files:**
- Modify: `backend/README.md`
- Possibly modify: `PRD/04-epics-and-stories.md` or `PRD/todo_plan.md` to check off items.

**Step 1:** Update `backend/README.md` with:
- Registration payload including `identity` and allowed values.
- Note/tag representation and tag color behavior.
- Search endpoint path, query parameters, and example responses.

**Step 2:** Optionally update PRD todo plan to mark these P0 backend tasks as implemented or in-progress.

**Step 3:** Run the full test suite (e.g. `pytest`) to ensure all tests pass.

---

### Task 11: Manual sanity checks via FastAPI TestClient or HTTP client

**Files:**
- Use: `backend/main.py`

**Step 1:** Start the FastAPI app locally (e.g. `uvicorn backend.main:app --reload`).

**Step 2:** Manually exercise endpoints using a REST client (or `TestClient` scripts):
- Register a user with each identity type.
- Create notes with `#标签` or tag payload.
- Call the calendar/heatmap endpoint and inspect colors.
- Use the search endpoint with several keywords.

**Step 3:** Note any UX or API inconsistencies to feed back into PRD or follow-up tasks.
