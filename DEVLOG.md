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
