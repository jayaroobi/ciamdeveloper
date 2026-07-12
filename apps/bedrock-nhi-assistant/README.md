# Bedrock NHI Assistant

Small Python utility showing how a **non-human identity** (IAM role) can call Amazon Bedrock for CIAM learning — not for production identity decisions.

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Configure AWS credentials via:

- IAM role (preferred for workloads)
- AWS SSO profile
- Short-lived session tokens

**Do not** store long-lived access keys in this repo.

## IAM policy example (attach to workload role)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["bedrock:InvokeModel"],
      "Resource": "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-haiku-*"
    }
  ]
}
```

## Run

```bash
python main.py --prompt "Explain Circle of Trust in SAML federation"
```

## NHI tie-in

| Human SSO | This lab |
|-----------|----------|
| User logs into AM via browser | IAM role assumes identity for API call |
| Session cookie | AWS credential chain |
| SAML assertion | SigV4 signed request |

Discuss this contrast in interviews when asked about NHI vs human identities.
