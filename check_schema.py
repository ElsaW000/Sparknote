import sqlite3
conn = sqlite3.connect('sparknote.db')
tables = [t[0] for t in conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()]
print("Tables:", tables)
for t in tables:
    schema = conn.execute(f"SELECT sql FROM sqlite_master WHERE name='{t}'").fetchone()
    if schema:
        print(f"\n--- {t} ---")
        print(schema[0])
