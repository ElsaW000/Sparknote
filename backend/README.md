# Sparknote Backend Prototype

This backend is a minimal FastAPI prototype used for early iteration and integration testing.

Quickstart (recommended to use a virtualenv):

1. Install dependencies:

```bash
python -m pip install -r backend/requirements.txt
```

2. Run development server:

```bash
uvicorn backend.main:app --reload --port 8000
```

3. Endpoints:
- `GET /health` — health check
- `POST /notes` — create note
- `GET /notes` — list notes
- `POST /conversations` — create conversation
- `POST /conversations/{id}/message` — add message (user messages trigger AI reply)
- `POST /conversations/{id}/close` — summarize conversation and create a note

The AI integration first checks for a `DASHSCOPE` environment variable (通义千问 API key). If present it will call the DASHSCOPE endpoint. Otherwise it falls back to using `OPENAI_API_KEY` (OpenAI). If neither is set, the prototype returns mocked AI responses.
