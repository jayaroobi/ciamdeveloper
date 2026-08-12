"""Bitbucket Cloud REST client — list PRs, fetch diffs, post review comments."""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Any, Optional
from urllib.parse import quote

import requests

logger = logging.getLogger(__name__)

API_BASE = "https://api.bitbucket.org/2.0"


@dataclass
class PullRequest:
    id: int
    title: str
    repo_slug: str
    workspace: str
    source_commit: str
    destination_branch: str
    author: str
    link: str
    description: str


class BitbucketClient:
    def __init__(self, token: str, timeout: int = 60) -> None:
        self.session = requests.Session()
        self.session.headers.update(
            {
                "Authorization": f"Bearer {token}",
                "Accept": "application/json",
                "Content-Type": "application/json",
            }
        )
        self.timeout = timeout

    def _get(self, path: str, params: Optional[dict[str, Any]] = None) -> dict[str, Any]:
        url = f"{API_BASE}{path}"
        resp = self.session.get(url, params=params, timeout=self.timeout)
        resp.raise_for_status()
        return resp.json()

    def _post(self, path: str, payload: dict[str, Any]) -> dict[str, Any]:
        url = f"{API_BASE}{path}"
        resp = self.session.post(url, json=payload, timeout=self.timeout)
        resp.raise_for_status()
        return resp.json()

    def list_open_prs(
        self,
        workspace: str,
        repo_slug: str,
        *,
        page_len: int = 50,
    ) -> list[PullRequest]:
        path = f"/repositories/{quote(workspace)}/{quote(repo_slug)}/pullrequests"
        data = self._get(
            path,
            params={"state": "OPEN", "pagelen": page_len, "sort": "-updated_on"},
        )
        results: list[PullRequest] = []
        for item in data.get("values") or []:
            source = item.get("source") or {}
            dest = item.get("destination") or {}
            commit = ((source.get("commit") or {}).get("hash")) or ""
            author = ((item.get("author") or {}).get("display_name")) or ""
            link = ((item.get("links") or {}).get("html") or {}).get("href") or ""
            results.append(
                PullRequest(
                    id=int(item["id"]),
                    title=item.get("title") or "",
                    repo_slug=repo_slug,
                    workspace=workspace,
                    source_commit=commit,
                    destination_branch=((dest.get("branch") or {}).get("name")) or "",
                    author=author,
                    link=link,
                    description=item.get("description") or "",
                )
            )
        return results

    def get_pr_diff(self, workspace: str, repo_slug: str, pr_id: int) -> str:
        path = (
            f"/repositories/{quote(workspace)}/{quote(repo_slug)}"
            f"/pullrequests/{pr_id}/diff"
        )
        url = f"{API_BASE}{path}"
        resp = self.session.get(
            url,
            timeout=self.timeout,
            headers={**self.session.headers, "Accept": "text/plain"},
        )
        resp.raise_for_status()
        text = resp.text
        # Cap extremely large diffs to keep Bedrock prompts bounded.
        max_chars = int(__import__("os").environ.get("SIDEYE_MAX_DIFF_CHARS", "120000"))
        if len(text) > max_chars:
            logger.warning(
                "Diff for %s/%s#%s truncated from %s to %s chars",
                workspace,
                repo_slug,
                pr_id,
                len(text),
                max_chars,
            )
            text = text[:max_chars] + "\n\n… [diff truncated by Sideeye] …\n"
        return text

    def post_pr_comment(
        self,
        workspace: str,
        repo_slug: str,
        pr_id: int,
        markdown: str,
    ) -> dict[str, Any]:
        path = (
            f"/repositories/{quote(workspace)}/{quote(repo_slug)}"
            f"/pullrequests/{pr_id}/comments"
        )
        return self._post(path, {"content": {"raw": markdown}})

    def list_workspace_repos(self, workspace: str) -> list[str]:
        """Fallback when profile has no explicit repo list."""
        path = f"/repositories/{quote(workspace)}"
        data = self._get(path, params={"pagelen": 100, "role": "member"})
        return [item.get("slug") for item in (data.get("values") or []) if item.get("slug")]
