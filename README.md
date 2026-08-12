# Sideeye — Automated PR Review

Sideeye is the CIAM sandbox automated pull-request reviewer. CronJobs in EKS start a `ciam-reviewer` pod per profile; the pod loads tokens from AWS Secrets Manager, analyzes open Bitbucket PRs with Bedrock (Claude), and posts review comments. Optional context comes from SonarQube, Jira, and Octopus Deploy over Transit Gateway egress.

```text
CIAM Sandbox — EKS ciam-eks-sandbox — ns sideeye
┌─────────────────────────────────────────────────────────────┐
│  CronJob sideeye-chip (*/5)   CronJob sideeye-ciam (* * *)  │
│              └──────────┬──────────┘                        │
│                         ▼                                   │
│         Pod: ciam-reviewer --profile NAME                   │
│         IRSA: sideeye-NAME                                  │
│              │         │         │                          │
│              ▼         ▼         ▼                          │
│         EFS sideeye-state    Secrets Manager                │
│         state.db + logs      GetSecretValue sideeye/tokens  │
│              │                                              │
│              ▼                                              │
│         Bedrock InvokeModel (Claude Opus)                   │
└────────────────────────────┬────────────────────────────────┘
                             │ egress via Transit Gateway
                             ▼
              Bitbucket (POST review comments)
              SonarQube · Jira · Octopus Deploy
```

## Layout

| Path | Purpose |
|------|---------|
| `sideeye/` | Python reviewer (`python -m sideeye --profile NAME`) |
| `deploy/sideeye/` | Namespace, IRSA SAs, EFS PVC, CronJobs, Dockerfile |
| `docs/sideeye-architecture.md` | Architecture notes matching the internal diagram |

## Local dry-run

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r sideeye/requirements.txt -r sideeye/tests/requirements-dev.txt
export SIDEYE_STATE_DIR=./.sideeye-state
python -m sideeye --profile ciam --dry-run
pytest -q sideeye/tests
```

With real tokens (local JSON instead of Secrets Manager):

```bash
export SIDEYE_TOKENS_JSON='{"bitbucket_token":"..."}'
export SIDEYE_CIAM_WORKSPACE=your-workspace
export SIDEYE_CIAM_REPOS=repo-a,repo-b
# Needs AWS creds with bedrock:InvokeModel
python -m sideeye --profile ciam
```

## Cluster deploy (sandbox)

1. Replace `ACCOUNT_ID` / `REGION` in `deploy/sideeye/*.yaml` and the Dockerfile image.
2. Ensure IAM roles `sideeye-chip` / `sideeye-ciam` trust the SAs and allow `secretsmanager:GetSecretValue` on `sideeye/tokens` plus `bedrock:InvokeModel`.
3. Create secret `sideeye/tokens` JSON with `bitbucket_token` (and optional Sonar/Jira/Octopus keys).
4. Apply manifests:

```bash
kubectl apply -f deploy/sideeye/namespace.yaml
kubectl apply -f deploy/sideeye/serviceaccounts.yaml
kubectl apply -f deploy/sideeye/configmap.yaml
kubectl apply -f deploy/sideeye/pvc-efs.yaml
kubectl apply -f deploy/sideeye/cronjob-chip.yaml
kubectl apply -f deploy/sideeye/cronjob-ciam.yaml
```

## Profiles

| Profile | CronJob | Schedule | IRSA SA |
|---------|---------|----------|---------|
| `chip` | `sideeye-chip` | every 5 min | `sideeye-chip` |
| `ciam` | `sideeye-ciam` | every 1 min | `sideeye-ciam` |

State is shared on EFS (`/mnt/sideeye-state/state.db`) so the same PR commit is not reviewed twice.
