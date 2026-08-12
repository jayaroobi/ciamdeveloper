"""Profile and runtime configuration for Sideeye."""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Any


DEFAULT_MODEL_ID = "anthropic.claude-opus-4-20250514-v1:0"
DEFAULT_SECRET_ID = "sideeye/tokens"
DEFAULT_STATE_DIR = "/mnt/sideeye-state"


def _split_csv(raw: str) -> list[str]:
    return [p.strip() for p in raw.split(",") if p.strip()]


@dataclass
class ProfileConfig:
    """Per-tenant/profile settings (matches CronJob --profile NAME)."""

    name: str
    bitbucket_workspace: str
    bitbucket_repos: list[str] = field(default_factory=list)
    poll_open_prs: bool = True
    max_prs_per_run: int = 10
    sonar_project_keys: list[str] = field(default_factory=list)
    jira_project_keys: list[str] = field(default_factory=list)
    octopus_project_slugs: list[str] = field(default_factory=list)
    review_prompt_extra: str = ""


def _build_profiles() -> dict[str, ProfileConfig]:
    return {
        "chip": ProfileConfig(
            name="chip",
            bitbucket_workspace=os.environ.get("SIDEYE_CHIP_WORKSPACE", "chip"),
            bitbucket_repos=_split_csv(os.environ.get("SIDEYE_CHIP_REPOS", "")),
            sonar_project_keys=_split_csv(os.environ.get("SIDEYE_CHIP_SONAR", "")),
            jira_project_keys=_split_csv(os.environ.get("SIDEYE_CHIP_JIRA", "")),
            octopus_project_slugs=_split_csv(os.environ.get("SIDEYE_CHIP_OCTOPUS", "")),
            review_prompt_extra=(
                "Focus on CHIP platform services, API contracts, and security."
            ),
        ),
        "ciam": ProfileConfig(
            name="ciam",
            bitbucket_workspace=os.environ.get("SIDEYE_CIAM_WORKSPACE", "ciam"),
            bitbucket_repos=_split_csv(os.environ.get("SIDEYE_CIAM_REPOS", "")),
            sonar_project_keys=_split_csv(os.environ.get("SIDEYE_CIAM_SONAR", "")),
            jira_project_keys=_split_csv(os.environ.get("SIDEYE_CIAM_JIRA", "")),
            octopus_project_slugs=_split_csv(os.environ.get("SIDEYE_CIAM_OCTOPUS", "")),
            review_prompt_extra=(
                "Focus on CIAM/identity concerns: authn/authz, token handling, "
                "SAML/OIDC, secrets, PII, and least privilege."
            ),
        ),
    }


PROFILES = _build_profiles()


@dataclass
class RuntimeConfig:
    profile: ProfileConfig
    aws_region: str = field(
        default_factory=lambda: os.environ.get("AWS_REGION", "us-east-1")
    )
    bedrock_model_id: str = field(
        default_factory=lambda: os.environ.get("BEDROCK_MODEL_ID", DEFAULT_MODEL_ID)
    )
    secret_id: str = field(
        default_factory=lambda: os.environ.get("SIDEYE_SECRET_ID", DEFAULT_SECRET_ID)
    )
    state_dir: str = field(
        default_factory=lambda: os.environ.get("SIDEYE_STATE_DIR", DEFAULT_STATE_DIR)
    )
    dry_run: bool = False
    log_level: str = field(
        default_factory=lambda: os.environ.get("SIDEYE_LOG_LEVEL", "INFO")
    )

    @property
    def state_db_path(self) -> str:
        return os.path.join(self.state_dir, "state.db")

    @property
    def log_dir(self) -> str:
        return os.path.join(self.state_dir, "logs")


def load_runtime(profile_name: str, dry_run: bool = False) -> RuntimeConfig:
    key = profile_name.strip().lower()
    profiles = _build_profiles()
    if key not in profiles:
        known = ", ".join(sorted(profiles))
        raise SystemExit(f"Unknown profile '{profile_name}'. Known: {known}")
    return RuntimeConfig(profile=profiles[key], dry_run=dry_run)


def tokens_from_secret_payload(payload: dict[str, Any]) -> dict[str, str]:
    """Normalize Secrets Manager JSON into integration tokens."""
    return {
        "bitbucket_token": str(
            payload.get("bitbucket_token") or payload.get("BITBUCKET_TOKEN") or ""
        ),
        "sonar_token": str(payload.get("sonar_token") or payload.get("SONAR_TOKEN") or ""),
        "jira_token": str(payload.get("jira_token") or payload.get("JIRA_TOKEN") or ""),
        "jira_email": str(payload.get("jira_email") or payload.get("JIRA_EMAIL") or ""),
        "octopus_api_key": str(
            payload.get("octopus_api_key") or payload.get("OCTOPUS_API_KEY") or ""
        ),
    }
