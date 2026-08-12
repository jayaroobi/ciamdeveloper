#!/usr/bin/env python3
"""
Sideeye entrypoint — matches architecture:

  Pod: ciam-reviewer --profile NAME
  IRSA: sideeye-NAME
  Secrets: sideeye/tokens (GetSecretValue)
  Bedrock: InvokeModel (Claude)
  State: EFS sideeye-state/state.db + logs
"""

from __future__ import annotations

import argparse
import logging
import sys
from logging.handlers import RotatingFileHandler
from pathlib import Path

from sideeye.config import load_runtime
from sideeye.reviewer import Reviewer


def _setup_logging(log_dir: str, level: str) -> None:
    Path(log_dir).mkdir(parents=True, exist_ok=True)
    root = logging.getLogger()
    root.setLevel(getattr(logging, level.upper(), logging.INFO))
    fmt = logging.Formatter(
        "%(asctime)s %(levelname)s [%(name)s] %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%SZ",
    )
    sh = logging.StreamHandler(sys.stdout)
    sh.setFormatter(fmt)
    root.addHandler(sh)
    fh = RotatingFileHandler(
        Path(log_dir) / "sideeye.log",
        maxBytes=5_000_000,
        backupCount=5,
    )
    fh.setFormatter(fmt)
    root.addHandler(fh)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="ciam-reviewer",
        description="Sideeye automated PR reviewer (Bedrock + Bitbucket)",
    )
    parser.add_argument(
        "--profile",
        required=True,
        help="Profile name (chip | ciam) — maps to CronJob / IRSA sideeye-NAME",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Do not call Secrets/Bedrock/Bitbucket write APIs unless tokens provided",
    )
    args = parser.parse_args(argv)

    runtime = load_runtime(args.profile, dry_run=args.dry_run)
    _setup_logging(runtime.log_dir, runtime.log_level)
    logging.getLogger(__name__).info(
        "Starting Sideeye profile=%s dry_run=%s state=%s model=%s",
        runtime.profile.name,
        runtime.dry_run,
        runtime.state_db_path,
        runtime.bedrock_model_id,
    )
    return Reviewer(runtime).run()


if __name__ == "__main__":
    raise SystemExit(main())
