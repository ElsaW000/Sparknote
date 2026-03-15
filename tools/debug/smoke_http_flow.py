import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import requests


ROOT = Path(__file__).resolve().parents[2]
HOST = "127.0.0.1"
PORT = 8011
BASE_URL = f"http://{HOST}:{PORT}"


def wait_for_server(timeout_seconds: float = 20.0) -> None:
    deadline = time.time() + timeout_seconds
    last_error = None
    while time.time() < deadline:
        try:
            response = requests.get(f"{BASE_URL}/health", timeout=1.5)
            response.raise_for_status()
            return
        except Exception as exc:  # pragma: no cover - debug script
            last_error = exc
            time.sleep(0.5)
    raise RuntimeError(f"backend did not become healthy in time: {last_error}")


def run_flow() -> None:
    fd, db_path = tempfile.mkstemp(prefix="sparknote_smoke_", suffix=".db")
    os.close(fd)

    env = os.environ.copy()
    env["DATABASE_URL"] = f"sqlite:///{db_path}"
    env["REQUIRE_REGISTER_CAPTCHA"] = "0"

    process = subprocess.Popen(
        [
            sys.executable,
            "-m",
            "uvicorn",
            "backend.main:app",
            "--host",
            HOST,
            "--port",
            str(PORT),
        ],
        cwd=ROOT,
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    try:
        wait_for_server()

        email = f"smoke_{int(time.time())}@example.com"
        password = "pass1234"

        register = requests.post(
            f"{BASE_URL}/auth/register",
            json={"email": email, "password": password, "identity": "全部"},
            timeout=10,
        )
        register.raise_for_status()

        login = requests.post(
            f"{BASE_URL}/auth/login",
            json={"email": email, "password": password},
            timeout=10,
        )
        login.raise_for_status()
        token = login.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        note = requests.post(
            f"{BASE_URL}/notes",
            headers=headers,
            json={
                "title": "Smoke note",
                "content": "A first idea about plot twists and product hooks.",
                "tags": ["小说", "产品"],
            },
            timeout=10,
        )
        note.raise_for_status()
        note_data = note.json()

        notes = requests.get(f"{BASE_URL}/notes", headers=headers, timeout=10)
        notes.raise_for_status()
        assert any(item["id"] == note_data["id"] for item in notes.json())

        conversation = requests.post(
            f"{BASE_URL}/conversations",
            headers=headers,
            json={"title": "Smoke workspace"},
            timeout=10,
        )
        conversation.raise_for_status()
        conversation_id = conversation.json()["id"]

        message = requests.post(
            f"{BASE_URL}/conversations/{conversation_id}/message",
            headers=headers,
            json={"sender": "user", "text": "请给我 3 个灵感延展方向"},
            timeout=10,
        )
        message.raise_for_status()

        ai_seen = False
        for _ in range(12):
            messages = requests.get(
                f"{BASE_URL}/conversations/{conversation_id}/messages",
                headers=headers,
                timeout=10,
            )
            messages.raise_for_status()
            payload = messages.json()
            if any(item.get("sender") == "ai" for item in payload):
                ai_seen = True
                break
            time.sleep(1)
        if not ai_seen:
            raise RuntimeError("AI reply was not observed in conversation messages")

        summary = requests.post(
            f"{BASE_URL}/conversations/{conversation_id}/close",
            headers=headers,
            timeout=10,
        )
        summary.raise_for_status()
        summary_data = summary.json()

        print(
            json.dumps(
                {
                    "registered_email": email,
                    "note_id": note_data["id"],
                    "conversation_id": conversation_id,
                    "close_result": summary_data,
                },
                ensure_ascii=True,
                indent=2,
            )
        )
    finally:
        process.terminate()
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
        try:
            os.remove(db_path)
        except OSError:
            pass


if __name__ == "__main__":
    run_flow()
