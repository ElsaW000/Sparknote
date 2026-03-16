# Sparknote Development Log

## 2026-02-28

### Summary
- Completed backend test stabilization and API flow validation.
- Current backend test suite passes: `3 passed`.
- Project is now ready for end-to-end local testing (backend + Flutter prototype).

### Work Done
- Updated backend API tests to follow authenticated flow:
  - Register/login user and attach Bearer token for protected endpoints.
- Isolated test database per run:
  - Switched tests to use a temporary SQLite DB file to avoid stale schema conflicts.
- Fixed AI worker message persistence:
  - Added `user_id` propagation into async worker jobs.
  - Ensured AI and AI-error messages persist with `user_id`.
- Improved local auth hashing compatibility:
  - Switched password hashing scheme to `pbkdf2_sha256` for stable local/dev behavior.

### Verification
- Ran: `pytest backend/tests -q`
- Result: `3 passed in 2.42s`

### Known Gaps
- Mobile app currently has login, notes list, and chat prototype flow.
- Registration UI and fuller product features (voice/image upload, richer note lifecycle) are still pending.

## 2026-03-11

### Summary
- Restored reliable local login against the real project database at `d:\02-Projects\01-Sparknote\sparknote.db`.
- Confirmed backend regression signal is available again when running pytest with plugin autoload disabled.
- Verified the backend happy path for `register -> login -> notes CRUD -> conversation message -> close conversation`.
- Confirmed `mobile/lib/pages/ai_workspace.dart` is still a frontend-only prototype and is not wired to backend conversation endpoints yet.

### Verification
- Ran: `PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 .\.venv\Scripts\python.exe -m pytest backend\tests\test_api.py -q`
- Result: `14 passed`
- Manual backend flow check via `fastapi.testclient`:
  - `GET /auth/captcha` -> OK
  - `POST /auth/register` with captcha + identity -> `201`
  - `POST /auth/login` -> `200`
  - `POST /notes` -> `200`
  - `PATCH /notes/{id}` -> `200`
  - `GET /notes` -> `200`
  - `POST /conversations` -> `200`
  - `POST /conversations/{id}/message` -> `200`
  - `GET /conversations/{id}/messages` -> `200`
  - `POST /conversations/{id}/close` -> `200`
  - `DELETE /notes/{id}` -> `200`

### Findings
- Root cause of the login blocker was not the login page itself. The real blocker was the local root database using an old schema, plus several debug scripts editing the wrong database file under `backend/sparknote.db`.
- `tester@example.com / pass1234` is currently a working local login for the real root database.
- `test@example.com / test123` also works as a fallback local account.
- Real external AI calls are still blocked in the current environment. Backend conversation close still returns `200`, but the generated content is based on provider failure/fallback behavior rather than a successful remote model response.
- `mobile/lib/pages/ai_workspace.dart` currently simulates AI chat locally and does not prove the real backend AI flow from the UI.

### Debug Scripts
- Keep for short-term debugging:
  - `check_user.py`: inspect users in the real root database
  - `fix_user.py`: reset/create a known local user in the real root database
  - `reset_user.py`: recreate `test@example.com` in the real root database
  - `test_login.py`: quick HTTP smoke test for `/health` and `/auth/login`
- Archive or delete after this iteration:
  - `debug_login.py`
  - `debug_login2.py`
  - `check_db.py`

### Remaining Blockers
- There is still no recorded UI-level end-to-end proof for `LoginPage -> NotesPage -> AIWorkspacePage`.
- `AIWorkspacePage` remains a prototype UI and should not be treated as evidence that the real AI product flow is complete.
- The notes UI is still functional but visually prototype-level, not presentation-ready.

## 2026-03-15

### Summary
- Rebuilt the core product UI around the new “灵感流 + 灵感工作台” model and aligned product copy from the old “AI续写” wording.
- Wired the workspace to real backend conversation flow instead of a frontend-only prototype.
- Added MVP attachments, audio transcription, and Notion integration entry points.
- Improved homepage interactivity and quick capture ergonomics, including title parsing, heatmap filtering, and workspace launch from the dashboard.

### Work Done
- Product/UI alignment
  - Rewrote `mobile/lib/pages/notes.dart` into the PRD desktop three-column layout plus mobile “灵感流 + 快速输入” structure.
  - Unified entry naming to “灵感工作台”.
  - Updated PRD wording and removed duplicated/obsolete “AI续写” design copy.
- Auth and onboarding
  - Refined login/register palette to the agreed green system:
    - `#1A3C34`
    - `#2D6A4F`
    - `#D8E2DC`
    - `#FFFFFF`
  - Kept the login page as the baseline layout and made register follow the same visual skeleton.
  - Added persona-card immersion scene navigation from the login page.
  - Removed identity selection from registration flow.
  - Fixed captcha question mojibake in backend responses.
- Workspace and AI flow
  - Connected `AIWorkspacePage` to real backend conversations.
  - Sent current note title/content and attachment context together with user prompts so AI can answer based on the note instead of saying it received no content.
  - Added workspace return navigation, resizable assistant panel, optional `编辑居中 / 对话居中` layout switch, and less intrusive auto-scroll behavior.
  - Added an AI “thinking” placeholder to reduce the blank wait before a full response arrives.
- Attachments and audio
  - Added backend note attachment support:
    - `GET /notes/{note_id}/attachments`
    - `POST /notes/{note_id}/attachments`
    - static file serving for `/uploads/...`
  - Added backend audio transcription endpoint:
    - `POST /audio/transcribe`
  - Added frontend local file picker utilities for Flutter web.
  - Added image/file upload and audio transcription entry points in the workspace.
  - Added image/file selection and audio transcription entry points to the homepage quick composer.
- Homepage and note capture
  - Added inline quick title parsing using `#标题` on the first line.
  - Changed note-card fallback title behavior to prefer the first content line instead of always showing “未命名灵感”.
  - Added selected attachment feedback above the quick composer with filename chips and remove actions.
  - Made the heatmap clickable to filter notes by date.
  - Added a summary block to “今日回顾” and made review cards clickable.
  - Made the right-side “灵感工作台” card clickable to open a note search/selection dialog before entering the workspace.
  - Replaced note-card database id badges with human-facing order labels such as “第 1 条”.
- Integrations and tooling
  - Added Notion integration settings MVP:
    - `GET /integrations/notion`
    - `PUT /integrations/notion`
  - Added an `API连接` entry in the left rail.
  - Cleaned up root-level debug scripts and consolidated them into `tools/debug/`.
  - Added `docs/testing/mvp_checklist.md` with split columns for `AI测试` and `人工测试`.

### Verification
- Backend tests
  - `pytest backend/tests -q` -> passed during this cycle after test/environment fixes.
  - `pytest backend/tests/test_api.py -q -k "audio_transcription or attachment or conversation or notion_integration"` -> `4 passed`
- Frontend
  - `flutter build web --dart-define=BACKEND_URL=http://127.0.0.1:8000` -> passed multiple times during this cycle.
  - Latest `flutter analyze` result shows only non-blocking warnings/info and no new functional errors.
- Functional checks completed in this cycle
  - `register -> login -> notes CRUD -> conversation message -> close conversation`
  - workspace reads current note content
  - homepage quick composer can send note content and attach selected files

### Known Gaps
- AI replies are still polled and rendered as whole-message responses; true token-level streaming is not implemented yet.
- Audio input is currently “import audio file and transcribe”, not live browser recording or realtime voice agent.
- Quick composer currently supports explicit image/file selection, but direct clipboard paste for images/files is still pending.
- Some legacy analyzer warnings remain in unrelated files and utility wrappers.

## 2026-03-16

### Summary
- Audited the current codebase against existing docs and synchronized the main functional documentation with the real implementation state.
- Confirmed that login, registration, notes CRUD, search/filtering, workspace conversation flow, attachments, audio transcription, related notes, and Notion configuration are already implemented in code.
- Fixed the Chinese hashtag auto-extraction regression found during automated verification.
- Continued manual UI verification and closed several frontend/backend consistency issues found during attachment and dashboard testing.

### Work Done
- Documentation sync
  - Rewrote root `README.md` to reflect the actual MVP feature set instead of the old scaffold description.
  - Updated `mobile/README.md` to describe the current Flutter product flow and limitations.
  - Updated `backend/README.md` to document the implemented API surface and current verification status.
  - Updated `NEXT_STEP.md` to replace outdated “AIWorkspace is still prototype-only” guidance.
  - Updated `docs/testing/mvp_checklist.md` with a fresh automated-check snapshot and a clearer split between verified and still-manual items.
- Status clarification
  - Recorded that `AIWorkspacePage` is now wired to real backend conversations.
  - Recorded that logout, search, tag filtering, attachments, audio file transcription, and Notion config are available.
  - Marked streaming AI, realtime recording, clipboard paste, and real Notion sync as remaining enhancement items.
- Bug fix
  - Replaced the old `\w`-based hashtag extraction rule with a delimiter-based matcher so Chinese tags such as `#工作` are preserved correctly.
- Deployment prep
  - Added `Dockerfile` for shipping backend plus built Flutter web assets together.
  - Added `render.yaml` for Render Blueprint deployment with persistent disk.
  - Added `DEPLOY_RENDER.md` with step-by-step deployment instructions.
  - Added `UPLOADS_DIR` support so uploads can persist outside the app container.
- Manual QA fixes
  - Fixed Flutter web local file picking so selected images/files reliably enter frontend state on web and show filename chips with remove actions before upload.
  - Added note-attachment deletion support in the backend and covered it with API tests.
  - Updated the note editor to show already-saved attachments and made the dialog body scroll so action buttons stay reachable when attachments are present.
  - Changed `/review/daily` to return full note payloads instead of title-only summaries.
  - Updated the homepage daily-review cards to open the full note content instead of an empty editor.
  - Removed the temporary `UI-ATTACH-20260316-03` debug marker from the UI after verification.
  - Reworked the heatmap rendering to use clearer multi-level color bands and added a small legend for intensity interpretation.
  - Standardized the local test refresh flow around `flutter build web` plus backend health verification so frontend fixes are not tested against stale bundles.
  - Redesigned the Notion/API settings page into a clearer two-column desktop layout with a left navigation area and a right-side setup guide.
  - Restricted the desktop quick composer to the center content region so it no longer covers the right-side “灵感工作台” card.
  - Tightened the desktop homepage layout:
    - compressed the left rail pulse card,
    - moved more utility into the side rail,
    - reduced the height/spacing of the top stat cards,
    - enlarged the right-side panel area for the heatmap,
    - increased note-list bottom padding so the floating composer does not cover trailing content.
  - Added clearer product guidance to distinguish “碎片输入” from “新建长笔记”.
  - Relaxed the left-rail spacing again after manual review so the pulse, tag, and notebook areas no longer feel stacked too tightly.
  - Expanded the API guide with direct Notion official links for integrations, databases, and authorization setup.
  - Split “设置” and “API 文档” into two separate responsibilities:
    - `设置` now acts as the real configuration center for profile, style, API, and AI provider sections.
    - `API 文档` now behaves like an operation manual page that explains prerequisites, steps, and official references instead of mixing documentation with live config fields.
  - Renamed the left-rail entry from `API连接` to `API文档` so users are guided to docs instead of expecting editable configuration there.
  - Rebuilt the settings page into a unified left-navigation + right-detail layout:
    - left rail for section switching,
    - one focused content canvas on the right,
    - animated section transitions,
    - more console-like information architecture instead of flat card stacking.
  - Rebuilt the API docs page into the same split-view pattern:
    - service directory on the left,
    - one active platform document on the right,
    - reusable document center structure for Notion / Obsidian / Logseq,
    - direct shortcut from docs to the settings configuration page.
  - Introduced a clearer typography and scale pass across the homepage, settings page, and API docs center:
    - main page titles reduced,
    - content titles aligned to a 16px heading scale,
    - body and caption text normalized to a 14px reading size,
    - large container radii aligned around 24px for better cross-page consistency.
  - Moved the desktop note search box out of the center content stream and into the top of the right utility rail so search behaves more like an auxiliary tool and less like the primary workspace.
  - Reduced vertical stacking pressure on the homepage content header by moving the workflow hint beside the page title and trimming note-card / utility-card padding further.
  - Changed note numbering display to follow chronological order labels, so the earliest visible note is treated as `第1条` even when the list itself is shown in reverse chronological order.
  - Normalized desktop note cards into a stricter preview format:
    - single-line title truncation,
    - single-line body truncation,
    - tags moved beside the action row,
    - fixed desktop card height for more consistent list rhythm.
  - Refined the `今日回顾` panel into a more AI-like recap:
    - surfaces compact highlight keywords first,
    - prefers titles and tags over long concatenated prose,
    - falls back to a single short summary sentence when needed.
  - Added attachment upload controls to the long-note editor dialog:
    - supports image and document picking before save,
    - shows pending attachments with remove actions,
    - uploads selected files after the note is successfully created or updated.
  - Relaxed the desktop homepage rhythm:
    - increased note-card spacing in the main flow,
    - added a larger bottom spacer so the fixed quick composer no longer crowds the last notes,
    - softened the composer into a lighter glass-like surface with reduced shadow weight.

### Verification
- Ran: `PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 .\.venv\Scripts\python.exe -m pytest backend\tests -q`
- Result: `17 passed`
- Rebuilt frontend: `flutter build web --dart-define=BACKEND_URL=http://127.0.0.1:8000`
- Verified local backend health: `GET /health -> {"status":"ok"}`

### Known Gaps
- Frontend manual acceptance is still not fully recorded for the end-to-end UI flow.
- Settings remain only partially surfaced in the current main navigation flow.
- `backend/tests/test_api.py::test_stats_heatmap_and_review` is currently date-bound and failed on 2026-03-17 local time because `/review/daily` is using today's local date while the test fixtures are still being created on the previous UTC date.
- Remaining feature gaps from prior notes are still:
  - AI token-level streaming
  - realtime recording
  - clipboard paste for images/files
  - real Notion sync/writeback
