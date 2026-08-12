"""Core review orchestration for one Sideeye profile run."""

from __future__ import annotations

import logging
from pathlib import Path

from sideeye.aws_clients import invoke_bedrock, load_tokens
from sideeye.clients.bitbucket import BitbucketClient, PullRequest
from sideeye.clients.context import gather_context
from sideeye.config import RuntimeConfig
from sideeye.state import StateStore

logger = logging.getLogger(__name__)

SYSTEM_PROMPT_PATH = Path(__file__).parent / "prompts" / "system.txt"


def _system_prompt() -> str:
    return SYSTEM_PROMPT_PATH.read_text(encoding="utf-8").strip()


def _build_user_prompt(
    pr: PullRequest,
    diff: str,
    extra_focus: str,
    context_blob: str,
) -> str:
    parts = [
        f"Profile focus: {extra_focus}" if extra_focus else "",
        f"PR: {pr.workspace}/{pr.repo_slug}#{pr.id} — {pr.title}",
        f"Author: {pr.author}",
        f"Destination branch: {pr.destination_branch}",
        f"Source commit: {pr.source_commit}",
        f"Link: {pr.link}",
        "",
        "PR description:",
        pr.description or "(empty)",
        "",
        "External context:",
        context_blob or "(none)",
        "",
        "Unified diff:",
        "```diff",
        diff or "(empty diff)",
        "```",
    ]
    return "\n".join(parts)


def _format_comment(body: str, profile: str, commit: str) -> str:
    footer = (
        f"\n\n---\n_Automated review by **Sideeye** "
        f"(profile `{profile}`, commit `{commit[:12]}`) via AWS Bedrock._"
    )
    return body.strip() + footer


class Reviewer:
    def __init__(self, runtime: RuntimeConfig) -> None:
        self.runtime = runtime
        self.state = StateStore(runtime.state_db_path)
        Path(runtime.log_dir).mkdir(parents=True, exist_ok=True)

    def run(self) -> int:
        profile = self.runtime.profile
        run_id = self.state.start_run(profile.name)
        prs_seen = 0
        prs_reviewed = 0
        try:
            tokens = self._tokens()
            bb_token = tokens.get("bitbucket_token") or ""
            if not bb_token and not self.runtime.dry_run:
                raise RuntimeError(
                    "Missing bitbucket_token in Secrets Manager payload "
                    f"({self.runtime.secret_id})"
                )

            bb = BitbucketClient(bb_token or "dry-run-token")
            repos = list(profile.bitbucket_repos)
            if not repos:
                if self.runtime.dry_run:
                    logger.info("Dry-run with no repos configured; nothing to do")
                    self.state.finish_run(
                        run_id,
                        prs_seen=0,
                        prs_reviewed=0,
                        status="ok",
                        detail="dry-run empty",
                    )
                    return 0
                repos = bb.list_workspace_repos(profile.bitbucket_workspace)
                logger.info(
                    "Discovered %s repos in workspace %s",
                    len(repos),
                    profile.bitbucket_workspace,
                )

            context_blob = gather_context(
                sonar_keys=profile.sonar_project_keys,
                jira_keys=profile.jira_project_keys,
                octopus_slugs=profile.octopus_project_slugs,
                tokens=tokens,
            )

            for repo in repos:
                open_prs = (
                    []
                    if self.runtime.dry_run and not bb_token
                    else bb.list_open_prs(profile.bitbucket_workspace, repo)
                )
                for pr in open_prs[: profile.max_prs_per_run]:
                    prs_seen += 1
                    if self._review_one(bb, pr, context_blob, tokens):
                        prs_reviewed += 1

            self.state.finish_run(
                run_id,
                prs_seen=prs_seen,
                prs_reviewed=prs_reviewed,
                status="ok",
            )
            logger.info(
                "Profile %s finished: seen=%s reviewed=%s",
                profile.name,
                prs_seen,
                prs_reviewed,
            )
            return 0
        except Exception as exc:  # noqa: BLE001 — top-level run guard
            logger.exception("Sideeye run failed: %s", exc)
            self.state.finish_run(
                run_id,
                prs_seen=prs_seen,
                prs_reviewed=prs_reviewed,
                status="error",
                detail=str(exc),
            )
            return 1

    def _tokens(self) -> dict[str, str]:
        if self.runtime.dry_run:
            import json
            import os

            inline = os.environ.get("SIDEYE_TOKENS_JSON")
            if inline:
                from sideeye.config import tokens_from_secret_payload

                return tokens_from_secret_payload(json.loads(inline))
            return {}
        return load_tokens(self.runtime.secret_id, self.runtime.aws_region)

    def _review_one(
        self,
        bb: BitbucketClient,
        pr: PullRequest,
        context_blob: str,
        tokens: dict[str, str],
    ) -> bool:
        profile = self.runtime.profile
        if self.state.already_reviewed(
            profile.name,
            pr.workspace,
            pr.repo_slug,
            pr.id,
            pr.source_commit,
        ):
            logger.info(
                "Skip already-reviewed %s/%s#%s @ %s",
                pr.workspace,
                pr.repo_slug,
                pr.id,
                pr.source_commit[:12],
            )
            return False

        logger.info("Reviewing %s/%s#%s", pr.workspace, pr.repo_slug, pr.id)
        diff = bb.get_pr_diff(pr.workspace, pr.repo_slug, pr.id)
        user_prompt = _build_user_prompt(
            pr, diff, profile.review_prompt_extra, context_blob
        )

        if self.runtime.dry_run and not tokens.get("bitbucket_token"):
            review_body = (
                "## Summary\nDry-run placeholder review — Bedrock not invoked.\n\n"
                "## Verdict\nNeeds discussion"
            )
        else:
            review_body = invoke_bedrock(
                region=self.runtime.aws_region,
                model_id=self.runtime.bedrock_model_id,
                system=_system_prompt(),
                user_prompt=user_prompt,
            )

        comment = _format_comment(review_body, profile.name, pr.source_commit)
        posted = False
        if self.runtime.dry_run:
            logger.info("Dry-run: would POST comment to PR #%s:\n%s", pr.id, comment[:500])
        else:
            bb.post_pr_comment(pr.workspace, pr.repo_slug, pr.id, comment)
            posted = True
            logger.info("Posted review comment on PR #%s", pr.id)

        self.state.mark_reviewed(
            profile.name,
            pr.workspace,
            pr.repo_slug,
            pr.id,
            pr.source_commit,
            comment_posted=posted or self.runtime.dry_run,
        )
        return True
