#!/usr/bin/env python3
"""
Bedrock NHI assistant — demonstrates least-privilege AWS identity calling Bedrock.

Use case: a workload (non-human identity) asks Bedrock to help debug SAML/CIAM concepts.
Requires: AWS credentials with bedrock:InvokeModel on the chosen model.
"""
from __future__ import annotations

import argparse
import json
import os
import sys

from dotenv import load_dotenv

load_dotenv()


def invoke_bedrock(prompt: str) -> str:
    import boto3

    region = os.environ.get("AWS_REGION", "us-east-1")
    model_id = os.environ.get(
        "BEDROCK_MODEL_ID", "anthropic.claude-3-haiku-20240307-v1:0"
    )

    client = boto3.client("bedrock-runtime", region_name=region)

    body = json.dumps(
        {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1024,
            "messages": [{"role": "user", "content": prompt}],
        }
    )

    response = client.invoke_model(
        modelId=model_id,
        body=body,
        contentType="application/json",
        accept="application/json",
    )
    payload = json.loads(response["body"].read())
    return payload["content"][0]["text"]


def main() -> int:
    parser = argparse.ArgumentParser(description="CIAM lab Bedrock NHI assistant")
    parser.add_argument(
        "--prompt",
        default="List 5 common SAML ACS validation failures and how to fix them.",
        help="Question for the model",
    )
    args = parser.parse_args()

    try:
        text = invoke_bedrock(args.prompt)
        print(text)
        return 0
    except Exception as exc:
        print(f"Error: {exc}", file=sys.stderr)
        print(
            "\nEnsure AWS credentials are configured and the model is enabled in Bedrock.",
            file=sys.stderr,
        )
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
