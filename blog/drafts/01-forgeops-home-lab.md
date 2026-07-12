# My ForgeOps Home Lab: Running Ping AM, IDM, and DS Locally

*Draft for Dev.to / LinkedIn — edit with your screenshots and timings.*

## Why I built this

I'm a CIAM engineer working with ForgeRock IDM and AM. To sharpen SAML/SSO skills and prepare for remote roles, I needed a **repeatable local lab** — not just theory.

This post documents my setup using the official ForgeOps minikube guide.

## What gets deployed

The `identity-platform` Helm chart installs:

- **PingAM** — SSO, SAML, OAuth2, journeys
- **PingIDM** — provisioning and workflows
- **PingDS (idrepo)** — identity directory (this is the database)
- **PingDS (cts)** — token/session store
- Login, Admin, and End-user UIs

> PingGateway is **optional** and not in the default chart. I added it in a follow-up post.

## Prerequisites

From the [official quick start](https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html):

- Docker, minikube, kubectl, helm, python3
- 3 CPU, 9 GB RAM, 40 GB disk
- Hosts entry: `127.0.0.1 forgeops.example.com`

## Steps (summary)

```bash
git clone https://github.com/ForgeRock/forgeops.git
cd forgeops && git checkout 2026.2.1

minikube start --cpus=3 --memory=9g --disk-size=40g \
  --addons=ingress,volumesnapshots,metrics-server --driver=docker

python3 -m venv .venv && source .venv/bin/activate
./bin/forgeops configure

# Terminal 2: sudo minikube tunnel

kubectl apply -f etc/resources/selfsigned-issuer.yaml
cd bin
./forgeops env --env-name my-env --fqdn forgeops.example.com \
  --cluster-issuer default-issuer --single-instance
kubectl create namespace my-namespace && kubens my-namespace
./forgeops prereqs
helm upgrade --install identity-platform identity-platform \
  --repo https://ForgeRock.github.io/forgeops/ \
  --namespace my-namespace \
  --values ../helm/my-env/values.yaml
```

Get password:

```bash
./forgeops info | grep amadmin
```

Open: https://forgeops.example.com/platform

## Verification

```bash
kubectl get pods -n my-namespace
```

Wait until `am`, `idm`, `ds-idrepo-0`, `ds-cts-0` are Running and jobs `amster`, `ds-set-passwords` are Complete.

## Pitfalls I hit

1. **Forgot minikube tunnel** — ingress won't bind to localhost
2. **Wrong cluster issuer name** — use `default-issuer` from selfsigned-issuer.yaml
3. **First boot is slow** — DS StatefulSets need persistent volumes

## What's next

Week 2: SAML federation with a Node.js service provider — AM as IdP.

Repo with scripts: [your-github]/ciamdeveloper

## References

- [ForgeOps Start here](https://docs.pingidentity.com/forgeops/2025.2/start/start-here.html)
- [Quick deployment on minikube](https://docs.pingidentity.com/forgeops/2025.2/quick/quick-set-mini.html)
- [ForgeOps GitHub](https://github.com/ForgeRock/forgeops)

---

*Tags: #ciam #forgerock #pingidentity #saml #iam #forgeops*
