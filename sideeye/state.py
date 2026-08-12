"""SQLite state store (persisted on EFS at sideeye-state/state.db)."""

from __future__ import annotations

import sqlite3
import time
from contextlib import contextmanager
from pathlib import Path
from typing import Iterator


SCHEMA = """
CREATE TABLE IF NOT EXISTS reviewed_prs (
    profile TEXT NOT NULL,
    workspace TEXT NOT NULL,
    repo_slug TEXT NOT NULL,
    pr_id INTEGER NOT NULL,
    commit_hash TEXT NOT NULL,
    reviewed_at REAL NOT NULL,
    comment_posted INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (profile, workspace, repo_slug, pr_id, commit_hash)
);

CREATE TABLE IF NOT EXISTS run_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile TEXT NOT NULL,
    started_at REAL NOT NULL,
    finished_at REAL,
    prs_seen INTEGER DEFAULT 0,
    prs_reviewed INTEGER DEFAULT 0,
    status TEXT NOT NULL,
    detail TEXT
);
"""


class StateStore:
    def __init__(self, db_path: str) -> None:
        self.db_path = db_path
        Path(db_path).parent.mkdir(parents=True, exist_ok=True)
        with self._conn() as conn:
            conn.executescript(SCHEMA)

    @contextmanager
    def _conn(self) -> Iterator[sqlite3.Connection]:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
            conn.commit()
        finally:
            conn.close()

    def already_reviewed(
        self,
        profile: str,
        workspace: str,
        repo_slug: str,
        pr_id: int,
        commit_hash: str,
    ) -> bool:
        with self._conn() as conn:
            row = conn.execute(
                """
                SELECT 1 FROM reviewed_prs
                WHERE profile=? AND workspace=? AND repo_slug=?
                  AND pr_id=? AND commit_hash=?
                """,
                (profile, workspace, repo_slug, pr_id, commit_hash),
            ).fetchone()
            return row is not None

    def mark_reviewed(
        self,
        profile: str,
        workspace: str,
        repo_slug: str,
        pr_id: int,
        commit_hash: str,
        comment_posted: bool,
    ) -> None:
        with self._conn() as conn:
            conn.execute(
                """
                INSERT OR REPLACE INTO reviewed_prs
                (profile, workspace, repo_slug, pr_id, commit_hash, reviewed_at, comment_posted)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    profile,
                    workspace,
                    repo_slug,
                    pr_id,
                    commit_hash,
                    time.time(),
                    1 if comment_posted else 0,
                ),
            )

    def start_run(self, profile: str) -> int:
        with self._conn() as conn:
            cur = conn.execute(
                """
                INSERT INTO run_log (profile, started_at, status)
                VALUES (?, ?, 'running')
                """,
                (profile, time.time()),
            )
            return int(cur.lastrowid)

    def finish_run(
        self,
        run_id: int,
        *,
        prs_seen: int,
        prs_reviewed: int,
        status: str,
        detail: str = "",
    ) -> None:
        with self._conn() as conn:
            conn.execute(
                """
                UPDATE run_log
                SET finished_at=?, prs_seen=?, prs_reviewed=?, status=?, detail=?
                WHERE id=?
                """,
                (time.time(), prs_seen, prs_reviewed, status, detail, run_id),
            )
