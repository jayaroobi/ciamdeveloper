# Sideeye architecture

Private/confidential design notes for the Sideeye automated PR review tool (CIAM Sandbox).

## Runtime environment

| Item | Value |
|------|--------|
| Cluster | EKS `ciam-eks-sandbox` |
| Namespace | `sideeye` |
| Workload | Job pods from CronJobs |
| Entry | `ciam-reviewer --profile NAME` |
| Identity | IRSA `sideeye-NAME` |
| State volume | EFS PVC `sideeye-state` → `state.db` + logs |
| Secrets | AWS Secrets Manager `sideeye/tokens` (`GetSecretValue`) |
| Model | AWS Bedrock `InvokeModel` (Claude Opus) |
| Egress | Transit Gateway → Bitbucket, SonarQube, Jira, Octopus |

## Control plane

Two CronJobs drive profile-specific runs:

- **`sideeye-chip`** — schedule `*/5 * * * *` → `--profile chip`
- **`sideeye-ciam`** — schedule `* * * * *` → `--profile ciam`

`concurrencyPolicy: Forbid` prevents overlapping runs for the same profile while a previous Job is still reviewing.

## Data flow (one run)

1. CronJob creates a Job/Pod with ServiceAccount `sideeye-{profile}`.
2. Pod mounts EFS at `/mnt/sideeye-state`.
3. Reviewer calls `GetSecretValue` for `sideeye/tokens` (Bitbucket + optional tool tokens).
4. Lists open PRs for configured Bitbucket workspace/repos.
5. Skips PRs already recorded in `state.db` for the same source commit.
6. Optionally gathers Sonar / Jira / Octopus context.
7. Sends diff + context to Bedrock Claude; receives Markdown review.
8. **POSTs review comments** to Bitbucket.
9. Persists review row + run metrics in SQLite; appends logs under `logs/`.

## IAM (IRSA)

Minimum permissions per `sideeye-NAME` role:

- `secretsmanager:GetSecretValue` on `arn:...:secret:sideeye/tokens*`
- `bedrock:InvokeModel` (and `InvokeModelWithResponseStream` if enabled) on the Claude model ARN
- EKS pod identity trust for `system:serviceaccount:sideeye:sideeye-NAME`

## Secret payload shape

```json
{
  "bitbucket_token": "…",
  "sonar_token": "…",
  "jira_email": "sideeye@example.com",
  "jira_token": "…",
  "octopus_api_key": "…"
}
```

## Security notes

- No long-lived AWS keys in the pod; IRSA only.
- Tokens never written to `state.db`; only PR/commit metadata and run status.
- Diff size is capped (`SIDEYE_MAX_DIFF_CHARS`) before model invoke.
- Egress should stay on private paths (Transit Gateway) to internal DevOps tools.
