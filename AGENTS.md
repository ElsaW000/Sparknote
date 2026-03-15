# Repository Instructions

## Git Workflow
- Default remote is `origin = https://github.com/ElsaW000/Sparknote.git`.
- Unless the user explicitly says `只提交本地` or `不要推远端`, finish code/document updates by:
  1. updating relevant docs/logs,
  2. creating a git commit,
  3. pushing the current branch to `origin`.
- Before pushing, summarize what changed in the final response and include the commit hash when available.

## Update Log
- When a development cycle finishes, update `DEVLOG.md` with the new capabilities, validations, and known gaps since the previous log entry.

## Temporary Files
- Do not commit local runtime output or scratch artifacts such as:
  - `uploads/`
  - `.tmp_*`
  - ad-hoc cache files
