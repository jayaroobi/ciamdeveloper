"""Unit tests for Sideeye (no live AWS/Bitbucket required)."""

from __future__ import annotations

import json
import os
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from sideeye.config import load_runtime, tokens_from_secret_payload
from sideeye.reviewer import Reviewer, _format_comment
from sideeye.state import StateStore


def test_tokens_from_secret_payload_aliases() -> None:
    tokens = tokens_from_secret_payload(
        {
            "BITBUCKET_TOKEN": "bb",
            "sonar_token": "sq",
            "JIRA_EMAIL": "a@b.c",
            "jira_token": "jt",
        }
    )
    assert tokens["bitbucket_token"] == "bb"
    assert tokens["sonar_token"] == "sq"
    assert tokens["jira_email"] == "a@b.c"
    assert tokens["jira_token"] == "jt"


def test_load_runtime_unknown_profile() -> None:
    with pytest.raises(SystemExit):
        load_runtime("nope")


def test_state_dedupes_reviews(tmp_path: Path) -> None:
    db = tmp_path / "state.db"
    store = StateStore(str(db))
    assert not store.already_reviewed("ciam", "ws", "repo", 1, "abc")
    store.mark_reviewed("ciam", "ws", "repo", 1, "abc", True)
    assert store.already_reviewed("ciam", "ws", "repo", 1, "abc")
    assert not store.already_reviewed("ciam", "ws", "repo", 1, "def")


def test_format_comment_footer() -> None:
    body = _format_comment("## Summary\nok", "ciam", "abcdef1234567890")
    assert "Sideeye" in body
    assert "ciam" in body
    assert "abcdef123456" in body


def test_dry_run_empty_repos(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("SIDEYE_STATE_DIR", str(tmp_path))
    monkeypatch.setenv("SIDEYE_CIAM_REPOS", "")
    runtime = load_runtime("ciam", dry_run=True)
    assert Reviewer(runtime).run() == 0
    assert (tmp_path / "state.db").exists()


def test_review_posts_comment(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("SIDEYE_STATE_DIR", str(tmp_path))
    monkeypatch.setenv("SIDEYE_CIAM_WORKSPACE", "ciam")
    monkeypatch.setenv("SIDEYE_CIAM_REPOS", "identity-api")
    monkeypatch.setenv(
        "SIDEYE_TOKENS_JSON",
        json.dumps({"bitbucket_token": "t"}),
    )
    runtime = load_runtime("ciam", dry_run=False)

    fake_pr = MagicMock()
    fake_pr.id = 42
    fake_pr.title = "Add OIDC"
    fake_pr.repo_slug = "identity-api"
    fake_pr.workspace = "ciam"
    fake_pr.source_commit = "deadbeef" * 5
    fake_pr.destination_branch = "main"
    fake_pr.author = "dev"
    fake_pr.link = "https://bitbucket.example/pr/42"
    fake_pr.description = "desc"

    with (
        patch("sideeye.reviewer.load_tokens", return_value={"bitbucket_token": "t"}),
        patch("sideeye.reviewer.BitbucketClient") as BB,
        patch("sideeye.reviewer.invoke_bedrock", return_value="## Summary\nLooks good\n\n## Verdict\nApprove"),
        patch("sideeye.reviewer.gather_context", return_value=""),
    ):
        bb = BB.return_value
        bb.list_open_prs.return_value = [fake_pr]
        bb.get_pr_diff.return_value = "diff --git a/x b/x\n+hello"
        code = Reviewer(runtime).run()

    assert code == 0
    bb.post_pr_comment.assert_called_once()
    args = bb.post_pr_comment.call_args[0]
    assert args[0] == "ciam"
    assert args[1] == "identity-api"
    assert args[2] == 42
    assert "Sideeye" in args[3]
