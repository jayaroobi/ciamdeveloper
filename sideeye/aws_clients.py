"""AWS helpers: Secrets Manager (tokens) and Bedrock InvokeModel via IRSA."""

from __future__ import annotations

import json
import logging
import os
from typing import Any

from sideeye.config import tokens_from_secret_payload

logger = logging.getLogger(__name__)


def get_secret_payload(secret_id: str, region: str) -> dict[str, Any]:
    """Call secretsmanager:GetSecretValue (IRSA in cluster)."""
    # Allow local/dev override without AWS.
    inline = os.environ.get("SIDEYE_TOKENS_JSON")
    if inline:
        return json.loads(inline)

    import boto3

    client = boto3.client("secretsmanager", region_name=region)
    resp = client.get_secret_value(SecretId=secret_id)
    raw = resp.get("SecretString") or ""
    return json.loads(raw)


def load_tokens(secret_id: str, region: str) -> dict[str, str]:
    payload = get_secret_payload(secret_id, region)
    return tokens_from_secret_payload(payload)


def invoke_bedrock(
    *,
    region: str,
    model_id: str,
    system: str,
    user_prompt: str,
    max_tokens: int = 4096,
) -> str:
    """Invoke Bedrock Claude Messages API via IRSA."""
    import boto3

    client = boto3.client("bedrock-runtime", region_name=region)
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": max_tokens,
        "system": system,
        "messages": [{"role": "user", "content": user_prompt}],
    }
    logger.info("Invoking Bedrock model %s", model_id)
    response = client.invoke_model(
        modelId=model_id,
        body=json.dumps(body),
        contentType="application/json",
        accept="application/json",
    )
    payload = json.loads(response["body"].read())
    parts = payload.get("content") or []
    texts = [p.get("text", "") for p in parts if p.get("type") == "text"]
    return "\n".join(texts).strip()
