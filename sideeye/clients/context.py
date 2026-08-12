"""Optional context clients: SonarQube, Jira, Octopus Deploy."""

from __future__ import annotations

import logging
import os
from typing import Any, Optional

import requests

logger = logging.getLogger(__name__)


class SonarClient:
    def __init__(self, base_url: str, token: str, timeout: int = 30) -> None:
        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()
        self.session.auth = (token, "")
        self.timeout = timeout

    def project_summary(self, project_key: str) -> str:
        if not project_key:
            return ""
        try:
            url = f"{self.base_url}/api/measures/component"
            resp = self.session.get(
                url,
                params={
                    "component": project_key,
                    "metricKeys": "bugs,vulnerabilities,code_smells,coverage,security_hotspots",
                },
                timeout=self.timeout,
            )
            resp.raise_for_status()
            measures = ((resp.json().get("component") or {}).get("measures")) or []
            parts = [f"{m.get('metric')}={m.get('value')}" for m in measures]
            return f"SonarQube {project_key}: " + ", ".join(parts)
        except Exception as exc:  # noqa: BLE001 — context is best-effort
            logger.warning("SonarQube lookup failed for %s: %s", project_key, exc)
            return f"SonarQube {project_key}: unavailable ({exc})"


class JiraClient:
    def __init__(
        self,
        base_url: str,
        email: str,
        token: str,
        timeout: int = 30,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()
        self.session.auth = (email, token)
        self.session.headers.update({"Accept": "application/json"})
        self.timeout = timeout

    def issues_for_keys(self, project_keys: list[str], limit: int = 5) -> str:
        if not project_keys:
            return ""
        jql = " OR ".join(f'project = "{k}"' for k in project_keys)
        jql = f"({jql}) AND updated >= -14d ORDER BY updated DESC"
        try:
            url = f"{self.base_url}/rest/api/3/search"
            resp = self.session.get(
                url,
                params={"jql": jql, "maxResults": limit, "fields": "summary,status,key"},
                timeout=self.timeout,
            )
            resp.raise_for_status()
            issues = resp.json().get("issues") or []
            lines = []
            for issue in issues:
                fields = issue.get("fields") or {}
                status = ((fields.get("status") or {}).get("name")) or "?"
                lines.append(
                    f"- {issue.get('key')}: {fields.get('summary')} [{status}]"
                )
            return "Recent Jira issues:\n" + ("\n".join(lines) if lines else "(none)")
        except Exception as exc:  # noqa: BLE001
            logger.warning("Jira lookup failed: %s", exc)
            return f"Jira: unavailable ({exc})"


class OctopusClient:
    def __init__(self, base_url: str, api_key: str, timeout: int = 30) -> None:
        self.base_url = base_url.rstrip("/")
        self.session = requests.Session()
        self.session.headers.update({"X-Octopus-ApiKey": api_key, "Accept": "application/json"})
        self.timeout = timeout

    def project_status(self, project_slug: str) -> str:
        if not project_slug:
            return ""
        try:
            # Resolve project then latest dashboard item (best-effort summary).
            url = f"{self.base_url}/api/projects/all"
            resp = self.session.get(url, timeout=self.timeout)
            resp.raise_for_status()
            projects = resp.json() or []
            match: Optional[dict[str, Any]] = None
            for p in projects:
                if p.get("Slug") == project_slug or p.get("Name") == project_slug:
                    match = p
                    break
            if not match:
                return f"Octopus {project_slug}: not found"
            return f"Octopus project {match.get('Name')} (id={match.get('Id')}) present"
        except Exception as exc:  # noqa: BLE001
            logger.warning("Octopus lookup failed for %s: %s", project_slug, exc)
            return f"Octopus {project_slug}: unavailable ({exc})"


def gather_context(
    *,
    sonar_keys: list[str],
    jira_keys: list[str],
    octopus_slugs: list[str],
    tokens: dict[str, str],
) -> str:
    chunks: list[str] = []
    sonar_url = os.environ.get("SONAR_URL", "")
    if sonar_url and tokens.get("sonar_token") and sonar_keys:
        client = SonarClient(sonar_url, tokens["sonar_token"])
        for key in sonar_keys:
            chunks.append(client.project_summary(key))

    jira_url = os.environ.get("JIRA_URL", "")
    if jira_url and tokens.get("jira_token") and jira_keys:
        client = JiraClient(
            jira_url,
            email=tokens.get("jira_email") or "sideeye@example.com",
            token=tokens["jira_token"],
        )
        chunks.append(client.issues_for_keys(jira_keys))

    octopus_url = os.environ.get("OCTOPUS_URL", "")
    if octopus_url and tokens.get("octopus_api_key") and octopus_slugs:
        client = OctopusClient(octopus_url, tokens["octopus_api_key"])
        for slug in octopus_slugs:
            chunks.append(client.project_status(slug))

    return "\n".join(c for c in chunks if c)
