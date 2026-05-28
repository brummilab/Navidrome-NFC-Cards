import sqlite3
from pathlib import Path
from typing import Optional


class MappingDB:
    def __init__(self, db_path: str):
        Path(db_path).parent.mkdir(parents=True, exist_ok=True)
        self.db_path = db_path
        self._init_db()

    def _init_db(self):
        with self._conn() as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS mappings (
                    uid         TEXT PRIMARY KEY,
                    item_type   TEXT NOT NULL,
                    item_id     TEXT NOT NULL,
                    name        TEXT NOT NULL,
                    artist      TEXT,
                    cover_url   TEXT,
                    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)

    def _conn(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def add_mapping(self, uid: str, item_type: str, item_id: str, name: str,
                    artist: str = None, cover_url: str = None) -> None:
        with self._conn() as conn:
            conn.execute(
                """INSERT OR REPLACE INTO mappings
                   (uid, item_type, item_id, name, artist, cover_url)
                   VALUES (?, ?, ?, ?, ?, ?)""",
                (uid, item_type, item_id, name, artist, cover_url),
            )

    def get_mapping(self, uid: str) -> Optional[dict]:
        with self._conn() as conn:
            row = conn.execute("SELECT * FROM mappings WHERE uid = ?", (uid,)).fetchone()
        return dict(row) if row else None

    def list_mappings(self) -> list:
        with self._conn() as conn:
            rows = conn.execute("SELECT * FROM mappings ORDER BY name").fetchall()
        return [dict(r) for r in rows]

    def delete_mapping(self, uid: str) -> bool:
        with self._conn() as conn:
            result = conn.execute("DELETE FROM mappings WHERE uid = ?", (uid,))
        return result.rowcount > 0
