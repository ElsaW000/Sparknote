import argparse
import sqlite3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def main() -> None:
    parser = argparse.ArgumentParser(description="Inspect Sparknote users in a sqlite db.")
    parser.add_argument(
        "--db",
        default=str(ROOT / "sparknote.db"),
        help="Path to the sqlite database file.",
    )
    args = parser.parse_args()

    db_path = Path(args.db).resolve()
    if not db_path.exists():
        raise SystemExit(f"database not found: {db_path}")

    conn = sqlite3.connect(db_path)
    try:
        rows = conn.execute(
            "SELECT id, email, is_active, created_at FROM user ORDER BY id"
        ).fetchall()
    finally:
        conn.close()

    print(f"database: {db_path}")
    print(f"user_count: {len(rows)}")
    for row in rows:
        print(f"id={row[0]} email={row[1]} active={row[2]} created_at={row[3]}")


if __name__ == "__main__":
    main()
