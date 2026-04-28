---
name: langfuse
description: Langfuse — open-source LLM engineering platform for observability, evals, prompt management, metrics, and dataset tooling. Self-hosted via Docker Compose, Kubernetes Helm chart, or vendor-published Terraform modules for AWS / GCP / Azure plus a Railway one-click. v3 architecture is six services (web, worker, Postgres, ClickHouse, Redis, MinIO/S3); v2 was a simpler single-Postgres stack and is documented separately upstream for legacy installs only.
---

# Langfuse — software-layer recipe

Upstream repo: https://github.com/langfuse/langfuse — Apache-2.0 core, with the `ee/` directory under a separate Langfuse EE license (free for self-hosters, requires a paid license key only for clearly-flagged commercial features).

Upstream self-hosting docs index: https://langfuse.com/self-hosting — verified against `langfuse/langfuse-docs` repo at `content/self-hosting/deployment/` per *strict-doc policy*.

## What Langfuse is

LLM observability + evaluation platform. Captures traces, tokens, latency, and cost across SDK / OTel / OpenAI-proxy / LiteLLM / LangChain integrations; layers prompt management, datasets, scoring, and dashboards on top. Common pairings in the open-forge stack:

- **vLLM / Ollama** as the inference backend → trace via OTel or Langfuse SDK.
- **LibreChat / Open WebUI / Dify** as the chat / app front — all ship Langfuse integration in their own configs.
- **Aider** logs via OTel.
- **AnythingLLM** has built-in Langfuse tracing.

Langfuse is a *cross-cutting* layer — recipe assumes most users add it alongside an existing inference + UI deployment rather than as the primary workload.

## Architecture (v3)

Verified from `docker-compose.yml` at the repo root:

| Service | Port | Role |
|---|---|---|
| `langfuse-web` | 3000 | Main UI + ingestion API + tRPC |
| `langfuse-worker` | 3030 | Async ingestion / eval jobs |
| `postgres` | 5432 | Relational store (users, projects, prompts, datasets) |
| `clickhouse` | 8123 / 9000 | Analytics store (traces, observations, scores) |
| `redis` | 6379 | Queue + cache |
| `minio` | 9000 / 9090 | S3-compatible blob storage (event uploads, media, batch exports) |

ClickHouse, Redis, and the S3 store are non-optional — v3 ingestion writes traces to S3 first, queues a job in Redis, and the worker drains into ClickHouse. Don't try to "simplify" the architecture; if you don't want six containers, run v2 instead (legacy, no new features) or use Langfuse Cloud.

## Compatible runtimes (combo table)

Every row below is documented under `langfuse.com/self-hosting/deployment/*`. Cited URLs are verbatim from the upstream docs index.

| # | Method | Path | Source | Use when |
|---|---|---|---|---|
| 1 | Docker Compose (local quick-start) | `compose` | `self-hosting/deployment/docker-compose` | Laptop demo, internal sandbox; not HA |
| 2 | Docker Compose on a single VM | `compose-vm` | same page, "VM Setup" subsection | Single-tenant prod, small team |
| 3 | Kubernetes + Helm (`langfuse/langfuse-k8s`) | `k8s` | `self-hosting/deployment/kubernetes-helm` | Recommended production path |
| 4 | Terraform on AWS (`langfuse/langfuse-terraform-aws`) | `tf-aws` | `self-hosting/deployment/aws` | Net-new AWS account, want EKS+Aurora+Redis+S3+ALB done in one apply |
| 5 | Terraform on GCP (`langfuse/langfuse-terraform-gcp`) | `tf-gcp` | `self-hosting/deployment/gcp` | Net-new GCP project, want GKE+Cloud SQL+Memorystore+GCS+LB |
| 6 | Terraform on Azure (`langfuse/langfuse-terraform-azure`) | `tf-azure` | `self-hosting/deployment/azure` | Net-new Azure sub, want AKS+PG-Flex+Redis+Storage+App Gateway |
| 7 | Railway template | `railway` | `self-hosting/deployment/railway` | Don't want to manage infra; happy on Railway |

Default recommended: **#3 Helm** for production, **#1 Compose** for evaluation. The Terraform modules call the Helm chart internally — they are *bootstrappers* that provision cloud infra and then `helm install` Langfuse into it.

## Inputs to collect

| Phase | Question | Type | Notes |
|---|---|---|---|
| 0 — choose method | Which deployment method? | choice (table above) | Drives everything below |
| 1 — domain | Public domain (or `localhost` for compose dev)? | string | Required for `NEXTAUTH_URL` and TLS |
| 1 — version | Pin `langfuse-web` / `langfuse-worker` image tag? | string | Default `langfuse/langfuse:3` (latest v3); pin to a specific tag for prod |
| 2 — secrets | `NEXTAUTH_SECRET` (256-bit), `SALT` (256-bit), `ENCRYPTION_KEY` (64 hex chars) | auto | Generate via `openssl rand -hex 32` and `openssl rand -base64 32` — never reuse |
| 2 — admin | Initial admin email + password — or SSO? | choice | First user to sign up becomes org owner unless `LANGFUSE_INIT_*` vars set |
| 3 — datastores | In-stack Postgres / ClickHouse / Redis / S3, or external? | choice | Helm chart and TF modules support both; compose ships in-stack only |
| 4 — sign-ups | Open sign-ups, or `AUTH_DISABLE_SIGNUP=true`? | choice | Default open. Lock down for public-internet deploys. |
| 4 — telemetry | `TELEMETRY_ENABLED` (default `true`)? | choice | Anonymized usage stats to Langfuse — opt-out is `false` |
| 5 — license key | Have a paid Langfuse EE license? | string (optional) | Only needed if you intend to use EE-flagged features |

## Phase applicability

| Phase | Applies | Notes |
|---|---|---|
| Preflight | ✅ | Per chosen method (docker / kubectl+helm / terraform). See `references/runtimes/*` and `references/infra/*`. |
| Provision | ✅ | Compose: skip. Helm: existing cluster required. TF modules: provisions cluster + datastores. |
| DNS | ✅ for any non-localhost deploy | Required because `NEXTAUTH_URL` must match the public URL |
| TLS | ✅ for any non-localhost deploy | Compose has none; put it behind a reverse proxy. Helm: cert-manager. TF: ACM / GCP-managed / Key Vault. |
| SMTP | ⚠️ optional | Only for transactional emails (invites, password reset) — see `configuration/transactional-emails.mdx` |
| Inbound forwarder | n/a | Single ingress service `langfuse-web` |
| Backups | ✅ critical | Postgres + ClickHouse + S3. See `configuration/backups.mdx`. |
| Monitoring | ⚠️ recommended | Health endpoints `/api/public/health` (web) and `/api/health` (worker) — see `configuration/health-readiness-endpoints.mdx` |
| Hardening | ✅ | Disable signups; rotate secrets; firewall ClickHouse and Postgres; encrypt at rest |

---

## Method 1 + 2 — Docker Compose (local, and on a VM)

Source: https://langfuse.com/self-hosting/deployment/docker-compose (`langfuse-docs/content/self-hosting/deployment/docker-compose.mdx`).

Single canonical `docker-compose.yml` lives at the root of `langfuse/langfuse`. Same file works for laptop dev and a single Ubuntu VM; only difference is the host you point DNS at and whether you front it with a reverse proxy.

### Prerequisites

- Local: Git + Docker Desktop (or Docker Engine + Compose plugin).
- VM: Ubuntu, SSH, **min 4 cores / 16 GiB RAM / 100 GiB disk** (per upstream — `t3.xlarge` is the cited reference size). Smaller VMs OOM-kill ClickHouse.

### Bring it up

```bash
git clone https://github.com/langfuse/langfuse.git
cd langfuse
docker compose up -d
```

After ~2–3 minutes `docker compose logs langfuse-web` should print `Ready`. Then open http://localhost:3000.

### Before exposing to the internet

The shipped `docker-compose.yml` has placeholder secrets — every line tagged `# CHANGEME` MUST be replaced. Use:

```bash
openssl rand -hex 32       # for SALT and ENCRYPTION_KEY (64 hex chars)
openssl rand -base64 32    # for NEXTAUTH_SECRET, Postgres / ClickHouse / Redis / MinIO passwords
```

Set `NEXTAUTH_URL` to the public URL you'll serve from. The compose file does not terminate TLS; put Caddy / nginx / Traefik in front (see `references/modules/tls.md`) and reverse-proxy `:3000` only — never expose Postgres (5432), ClickHouse (8123/9000), Redis (6379), or MinIO (9000/9090) publicly.

### Lifecycle

```bash
docker compose up --pull always -d   # upgrade
docker compose down                  # stop
docker compose down -v               # destroy data — DANGER
```

### Production caveats from upstream

- No HA, no horizontal scaling, no built-in backups.
- Single MinIO replica → not durable. Either swap to external S3 (env vars under `LANGFUSE_S3_*`) or back the MinIO volume up.
- Upstream explicitly recommends Helm for production.

---

## Method 3 — Kubernetes via Helm

Source: https://langfuse.com/self-hosting/deployment/kubernetes-helm. Chart repo: https://github.com/langfuse/langfuse-k8s. Chart index: `https://langfuse.github.io/langfuse-k8s`.

This is the upstream-recommended production path. The chart bundles Bitnami sub-charts for Postgres, ClickHouse, Redis, and S3-compatible storage so a fresh install runs end-to-end; each can be swapped to an external-managed service via `values.yaml`.

### Prerequisites

- A Kubernetes cluster (1.28+). Cluster provisioning is **out of scope** for open-forge — bring your own EKS / GKE / AKS / DOKS / k3s. See `references/runtimes/kubernetes.md` for the cluster-side preflight.
- `kubectl` configured, `helm` v3 installed.
- An ingress controller (nginx-ingress, AWS LBC, GCE, etc.) and `cert-manager` if you want automatic TLS.

### Install

```bash
helm repo add langfuse https://langfuse.github.io/langfuse-k8s
helm repo update
kubectl create namespace langfuse
helm install langfuse langfuse/langfuse -n langfuse
```

Upstream specifically warns: *"Our chart assumes that it's installed as `langfuse`. If you want to install it with a different name, you will have to adjust the Redis hostname in the `values.yaml` accordingly."* — leave the release name as `langfuse` unless you know why you're changing it.

Allow up to 5 minutes for first boot — `langfuse-web` and `langfuse-worker` will restart a few times while Postgres / ClickHouse provision.

### Verify

```bash
kubectl get pods -n langfuse
kubectl get svc -n langfuse
kubectl logs -n langfuse deploy/langfuse-web -f       # watch for "Ready"
kubectl port-forward -n langfuse svc/langfuse-web 3000:3000   # then open http://localhost:3000
```

### Customize via values.yaml

The full schema is in `langfuse-k8s/charts/langfuse/values.yaml`. The high-leverage knobs:

```yaml
langfuse:
  nextauth:
    url: https://langfuse.example.com
    secret: "<openssl rand -base64 32>"
  salt: "<openssl rand -base64 32>"
  encryptionKey: "<openssl rand -hex 32>"   # 64 hex chars
  additionalEnv:
    - name: TELEMETRY_ENABLED
      value: "false"
    - name: AUTH_DISABLE_SIGNUP
      value: "true"

# In-chart datastores (default: enabled). Set enabled=false and point at external services.
postgresql:
  enabled: true                     # set false → use postgresql.deploy.host etc.
clickhouse:
  enabled: true
  shards: 1
  replicaCount: 3
redis:
  enabled: true
s3:
  deploy: true                      # set false → langfuse.s3 with external bucket creds

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: langfuse.example.com
      paths: [{ path: /, pathType: Prefix }]
  tls:
    - secretName: langfuse-tls
      hosts: [langfuse.example.com]

langfuse:
  web:
    replicas: 2
  worker:
    replicas: 2
```

`helm upgrade langfuse langfuse/langfuse -n langfuse -f values.yaml` applies changes.

### Uninstall

```bash
helm uninstall langfuse -n langfuse
kubectl delete namespace langfuse        # also nukes PVCs — back up first
```

### Companion tooling

- `references/runtimes/kubernetes.md` — generic cluster preflight (`kubectl auth can-i …`, ingress, cert-manager).
- `references/modules/dns.md` + `references/modules/tls.md` — DNS / TLS playbooks.
- `references/modules/backups.md` — Postgres + ClickHouse + S3 backup approach.

---

## Method 4 — Terraform on AWS

Source: https://langfuse.com/self-hosting/deployment/aws. Module repo: https://github.com/langfuse/langfuse-terraform-aws (current pinned ref `0.6.2`).

The AWS module provisions a full production stack and `helm install`s the Langfuse chart on top of it. End-state architecture:

| AWS service | Role |
|---|---|
| EKS with Fargate | Kubernetes control + serverless data-plane |
| Aurora PostgreSQL Serverless v2 | Relational DB |
| ElastiCache Redis cluster | Queue + cache |
| S3 bucket | Event uploads, media, batch exports |
| Application Load Balancer | Public ingress |
| Route 53 hosted zone | DNS |
| ACM | TLS certificates |
| EFS + CSI driver | PVC backing for ClickHouse |
| VPC, IAM, Security Groups | Network + auth wiring |

ClickHouse runs *inside* the EKS cluster (3 replicas by default) — there's no managed AWS equivalent.

### Prerequisites

- AWS account with admin (or roughly equivalent) credentials.
- `aws` CLI configured (`aws sts get-caller-identity` returns).
- `terraform` >= 1.0, `kubectl`, `helm` v3.
- A domain whose nameservers you can delegate to Route 53.

### Apply (two-stage because of DNS delegation)

Create `main.tf`:

```hcl
terraform {
  required_version = ">= 1.0"
}

provider "aws" { region = "us-east-1" }

module "langfuse" {
  source = "github.com/langfuse/langfuse-terraform-aws?ref=0.6.2"

  domain                       = "langfuse.example.com"
  name                         = "langfuse"
  vpc_cidr                     = "10.0.0.0/16"
  kubernetes_version           = "1.32"
  postgres_instance_count      = 2
  postgres_min_capacity        = 0.5
  postgres_max_capacity        = 2.0
  cache_node_type              = "cache.t4g.small"
  cache_instance_count         = 2
  langfuse_helm_chart_version  = "1.5.14"
}

output "route53_nameservers" { value = module.langfuse.route53_nameservers }
```

```bash
terraform init
# Stage 1 — create the Route 53 zone, pull the NS records
terraform apply -target=module.langfuse.aws_route53_zone.zone
# Take the four NS values from `terraform output route53_nameservers`
# and configure them at your domain registrar BEFORE the next step,
# otherwise ACM cert validation hangs.
terraform apply
```

### Useful variables

| Variable | Default | When you'd change it |
|---|---|---|
| `vpc_id`, `private_subnet_ids`, `public_subnet_ids` | null | Reuse an existing VPC instead of creating a new one |
| `use_single_nat_gateway` | `true` | Set `false` for multi-AZ HA NAT (more expensive) |
| `alb_scheme` | `internet-facing` | Set `internal` for VPN-only access |
| `ingress_inbound_cidrs` | `["0.0.0.0/0"]` | Lock down to office / VPN CIDRs |
| `redis_at_rest_encryption` | `false` | Enable for compliance |
| `redis_multi_az` | `false` | Enable for prod HA |
| `clickhouse_replicas` | `3` | Drop to `1` for non-prod |
| `langfuse_web_replicas` / `langfuse_worker_replicas` | `1` | Scale horizontally |
| `enable_clickhouse_log_tables` | `false` | Enable for ClickHouse server-side logging |

### Connecting kubectl post-apply

```bash
aws eks update-kubeconfig --name langfuse --region us-east-1
kubectl get pods -n langfuse
```

### Tear down

```bash
terraform destroy
```

Note: S3 bucket and Aurora cluster have deletion protection / data; remove blocks via the console or vars before destroy if you intend to wipe.

---

## Method 5 — Terraform on GCP

Source: https://langfuse.com/self-hosting/deployment/gcp. Module repo: https://github.com/langfuse/langfuse-terraform-gcp (current pinned ref `0.3.3`).

End-state architecture:

| GCP service | Role |
|---|---|
| GKE | Kubernetes cluster |
| Cloud SQL for PostgreSQL | Relational DB |
| Cloud Memorystore for Redis | Queue + cache |
| Cloud Storage bucket | Event uploads, media, batch exports |
| Compute Engine HTTPS Load Balancer + Managed SSL | Public ingress |
| Cloud DNS managed zone | DNS |
| Cloud KMS | Encryption keys |
| Filestore + CSI driver | PVC backing for ClickHouse |

ClickHouse again runs in-cluster.

### Prerequisites

- A GCP project with billing enabled and these APIs enabled (the module won't enable them for you):
  - Certificate Manager, Cloud DNS, Compute Engine, Container File System, Memorystore for Redis, Kubernetes Engine, Network Connectivity, Service Networking.
- `gcloud` configured and `gcloud auth application-default login` run.
- `terraform` >= 1.0, `kubectl`, `helm` v3.
- A domain you can delegate to Cloud DNS.

### Apply

`main.tf`:

```hcl
provider "google" {
  project = "my-langfuse-project"
  region  = "us-central1"
}

module "langfuse" {
  source = "github.com/langfuse/langfuse-terraform-gcp?ref=0.3.3"

  domain                  = "langfuse.example.com"
  name                    = "langfuse"
  subnetwork_cidr         = "10.0.0.0/16"
  langfuse_chart_version  = "1.5.14"
}

provider "kubernetes" {
  host                   = module.langfuse.cluster_host
  cluster_ca_certificate = module.langfuse.cluster_ca_certificate
  token                  = module.langfuse.cluster_token
}

provider "helm" {
  kubernetes {
    host                   = module.langfuse.cluster_host
    cluster_ca_certificate = module.langfuse.cluster_ca_certificate
    token                  = module.langfuse.cluster_token
  }
}
```

```bash
terraform init
# Stage 1 — DNS zone + cluster
terraform apply \
  -target=module.langfuse.google_dns_managed_zone.this \
  -target=module.langfuse.google_container_cluster.this
# Delegate the four NS records at your registrar
terraform apply
```

### Useful variables

| Variable | Default | When to change |
|---|---|---|
| `database_instance_tier` | `db-perf-optimized-N-2` | Smaller for non-prod (e.g. `db-f1-micro` is too small — Langfuse won't fit) |
| `cache_memory_size_gb` | `1` | Bump for high trace volume |
| `kubernetes_namespace` | `langfuse` | Multi-tenant clusters |
| `additional_env` | `[]` | Inject extra env vars (e.g. `TELEMETRY_ENABLED=false`, OAuth provider creds) |
| `create_dns_zone` | `true` | Set `false` if zone already exists |
| `deletion_protection` | `true` | Keep `true` in prod — protects Cloud SQL + GCS |

### Connecting kubectl

```bash
gcloud container clusters get-credentials langfuse --region us-central1
kubectl get pods -n langfuse
```

---

## Method 6 — Terraform on Azure

Source: https://langfuse.com/self-hosting/deployment/azure. Module repo: https://github.com/langfuse/langfuse-terraform-azure (current pinned ref `0.4.5`).

End-state architecture:

| Azure service | Role |
|---|---|
| AKS (system + user node pools) | Kubernetes cluster |
| Azure Database for PostgreSQL — Flexible Server (HA) | Relational DB |
| Azure Cache for Redis (private endpoint) | Queue + cache |
| Azure Storage Account + Blob | Event uploads, media, batch exports |
| Azure Application Gateway + WAF + SSL | Public ingress |
| Azure DNS Zone | DNS |
| Azure Key Vault | TLS cert storage |
| Azure Virtual Network + NSGs | Network |
| (optional) DDoS Protection Plan | Edge protection |

### Prerequisites

- Azure subscription with Owner / Contributor.
- `az login` done; `az account show` returns the right subscription.
- `terraform` >= 1.0, `kubectl`, `helm` v3.
- A domain you can delegate to Azure DNS.

### Apply

`main.tf`:

```hcl
provider "azurerm" {
  features {}
}

module "langfuse" {
  source = "github.com/langfuse/langfuse-terraform-azure?ref=0.4.5"

  domain   = "langfuse.example.com"
  location = "westeurope"
}

provider "kubernetes" {
  host                   = module.langfuse.cluster_host
  client_certificate     = base64decode(module.langfuse.cluster_client_certificate)
  client_key             = base64decode(module.langfuse.cluster_client_key)
  cluster_ca_certificate = base64decode(module.langfuse.cluster_ca_certificate)
}
```

```bash
terraform init
terraform apply -target=module.langfuse.azurerm_dns_zone.this
# Delegate NS records at your registrar
terraform apply
```

### Useful variables

| Variable | Default | When to change |
|---|---|---|
| `location` | `westeurope` | Pick the Azure region nearest your users |
| `kubernetes_version` | `1.32` | Pin to a version you already use |
| `node_pool_vm_size` | `Standard_D2s_v6` | Bigger for high traffic |
| `postgres_sku_name` | `GP_Standard_D2s_v3` | Bump SKU for prod load |
| `use_encryption_key` | `true` | Required for LLM key storage at rest |
| `langfuse_helm_chart_version` | `1.5.14` | Pin to the chart version you tested |

### Connecting kubectl

```bash
az aks get-credentials --resource-group langfuse --name langfuse
kubectl get pods -n langfuse
```

---

## Method 7 — Railway one-click

Source: https://langfuse.com/self-hosting/deployment/railway. Template URL: `https://railway.com/deploy/exma_H?referralCode=513qqz` (link is published in the upstream docs page; the `referralCode` is upstream-owned).

The Railway template provisions all six services as separate Railway services in one project. Easiest way to get a v3 stack online without owning any infra. Tradeoff: cost; you're on Railway's metered pricing for Postgres + ClickHouse + Redis + S3-equivalent + the two app services. For low-volume usage that's fine; for production trace volume it's typically more expensive than EKS / GKE.

### Steps

1. Click the "Deploy on Railway" button on the upstream docs page (using the upstream-published template URL above).
2. Railway prompts for env values — fill in `NEXTAUTH_URL` (your Railway public domain or a custom domain), and let it generate the secrets unless you have policy reasons to bring your own.
3. Wait for all six services to deploy.
4. Open the public URL of the `langfuse-web` service.

### After-deploy

- Switch to a custom domain via Railway's "Settings → Domains" and update `NEXTAUTH_URL` accordingly — the env var must match the URL users hit, or sign-in breaks.
- Set `AUTH_DISABLE_SIGNUP=true` once you've registered the org owner.

---

## Cross-cutting configuration (env vars)

Source: `langfuse-docs/content/self-hosting/configuration/index.mdx`. Names below appear verbatim in upstream docs.

### Required across every method

| Var | Purpose |
|---|---|
| `DATABASE_URL` | Postgres connection string |
| `CLICKHOUSE_URL`, `CLICKHOUSE_MIGRATION_URL`, `CLICKHOUSE_USER`, `CLICKHOUSE_PASSWORD` | ClickHouse connection |
| `REDIS_CONNECTION_STRING` | Redis connection (or `REDIS_CLUSTER_*` / `REDIS_SENTINEL_*` for HA) |
| `NEXTAUTH_URL` | Public URL Langfuse is served from |
| `NEXTAUTH_SECRET` | 256-bit random — `openssl rand -base64 32` |
| `SALT` | 256-bit random — `openssl rand -base64 32` |
| `ENCRYPTION_KEY` | **Exactly 64 hex chars** (256 bits) — `openssl rand -hex 32`. Never rotate after data is written; encrypted columns become unreadable. |
| `LANGFUSE_S3_EVENT_UPLOAD_BUCKET` (+ region / endpoint / creds) | Event-upload bucket — required, even if it's MinIO |
| `LANGFUSE_S3_MEDIA_UPLOAD_BUCKET` (+ region / endpoint / creds) | Media-upload bucket — required for media features |

### Commonly tweaked

| Var | Default | Purpose |
|---|---|---|
| `TELEMETRY_ENABLED` | `true` | Anonymous usage telemetry — set `false` for opt-out |
| `AUTH_DISABLE_SIGNUP` | `false` | Disable open sign-ups after first admin |
| `LANGFUSE_CSP_ENFORCE_HTTPS` | `false` | Set `true` behind TLS |
| `LANGFUSE_LOG_LEVEL` | `info` | `debug` for triage, `warn` for noisy clusters |
| `LANGFUSE_LOG_FORMAT` | `text` | Set `json` if shipping to a log aggregator |
| `LANGFUSE_S3_BATCH_EXPORT_ENABLED` | `false` | Enable to expose dataset / trace exports |
| `LANGFUSE_INIT_*` | unset | Seed an initial org / project / user / API key on first boot — check the docs for the full list, useful for IaC bootstraps |

### When fronting MinIO or non-AWS S3

Set `LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE=true` (and the same for `_MEDIA_UPLOAD_` and `_BATCH_EXPORT_`). MinIO and most S3-compatibles only support path-style URLs.

---

## Verification (post-install, all methods)

1. **Web reachable**: `curl -fsS https://<domain>/api/public/health` returns `{"status":"OK"}` (per `configuration/health-readiness-endpoints.mdx`).
2. **Worker reachable**: same check against the worker — `curl -fsS http://langfuse-worker:3030/api/health` from inside the cluster.
3. **First-user sign-up**: open `https://<domain>` and register; first user becomes the org owner.
4. **Generate a trace**: from a host with python, `pip install langfuse && python -c "from langfuse import Langfuse; l=Langfuse(public_key='pk-...', secret_key='sk-...', host='https://<domain>'); l.trace(name='hello').end(); l.flush()"` — trace should appear within a few seconds in the UI.
5. **Datastore reachability** (Helm / TF):
   ```bash
   kubectl exec -n langfuse deploy/langfuse-web -- nc -zv postgres 5432
   kubectl exec -n langfuse deploy/langfuse-web -- nc -zv clickhouse 8123
   kubectl exec -n langfuse deploy/langfuse-web -- nc -zv redis-master 6379
   ```

## Gotchas (consolidated)

- **`ENCRYPTION_KEY` is one-way.** Once data is written, rotating this key bricks every encrypted column (LLM provider keys, etc.). Store the value in a secret manager from day one and back it up.
- **Compose isn't HA.** No replication, no backups, single MinIO. Fine for dev — for prod use Helm or one of the TF modules.
- **ClickHouse always lives in-cluster.** None of the Terraform modules use a managed ClickHouse — they run it inside EKS / GKE / AKS via the Helm sub-chart. Plan ClickHouse storage capacity (default 3 replicas × PVCs, EFS / Filestore / Azure Files backed).
- **`NEXTAUTH_URL` mismatch breaks login.** It must equal the URL users actually hit, scheme included. Behind a reverse proxy that rewrites the path or scheme? Set `NEXTAUTH_URL` to the *external* URL.
- **Helm release name is load-bearing.** Upstream chart hard-codes `langfuse-redis-master` etc. — installing as a non-`langfuse` release name requires hand-editing the Redis hostname in `values.yaml`.
- **VM sizing.** `t3.medium` / 2-vCPU / 4 GiB RAM machines OOM-kill ClickHouse during ingestion. Upstream's stated minimum is 4 cores / 16 GiB RAM. Don't go below.
- **TF AWS DNS validation.** ACM cert issuance hangs forever if Route 53 NS delegation isn't done before the second `terraform apply`. The two-stage flow exists for this reason.
- **TF GCP API enablement.** The module **doesn't** enable the GCP APIs — enable them by hand or with `google_project_service` resources before running `terraform apply`.
- **Telemetry on by default.** `TELEMETRY_ENABLED=true` is the default — flag if user policy requires opt-out.
- **First-party docker-compose ships placeholders.** Every secret in the file is `# CHANGEME`; the upstream README is unambiguous about replacing them. Don't expose a default-secret instance to the internet.
- **MinIO not exposed externally by default.** Compose configures the MinIO bucket as internal-only. Direct browser uploads (a v3 feature) need `LANGFUSE_S3_*_EXTERNAL_ENDPOINT` set to a publicly reachable MinIO endpoint, or you use external S3 instead.
- **Postgres CREATE DATABASE permission.** If the DB user can't create databases, set `SHADOW_DATABASE_URL` to a separate DB the user *can* read/write — Prisma migrations otherwise fail.
- **EE features need a license key.** The repo is Apache-2.0 except `ee/` which has its own license. EE features (e.g. SSO/SAML, fine-grained RBAC, audit logs) require `LANGFUSE_EE_LICENSE_KEY`. Core observability / evals are not gated.
- **v2 vs v3.** `langfuse:2` is a single-Postgres simpler stack — still on the docs site under `self-hosting/v2`, no longer the recommended path. Don't pin `:2` for new deploys.

## TODO — verify on subsequent deployments

- [ ] Confirm exact `LANGFUSE_INIT_*` variable names that bootstrap an initial org/project/user/API-key — the docs hint at this but the full list wasn't enumerated in the configuration index page during this write-up. Read `configuration/index.mdx` end-to-end on first real deploy.
- [ ] Validate the current upstream-pinned chart version (`1.5.14` at write time) is still latest; bump module refs accordingly.
- [ ] Verify the Railway template's bundled service list matches v3's six-service architecture — upstream docs page references it but doesn't enumerate.
- [ ] First-run check on each TF module: confirm the two-stage `apply` actually completes without manual intervention beyond the NS delegation step (this is the most common place these modules fail in practice).
- [ ] Capture a known-good `values.yaml` that points at *external* Postgres / ClickHouse / Redis / S3 — useful for users who want managed everything, not yet exercised end-to-end.
- [ ] Document the SMTP / `EMAIL_*` envar names from `configuration/transactional-emails.mdx` after a real invite-flow deploy.
- [ ] Check whether `LANGFUSE_S3_EVENT_UPLOAD_PREFIX` collides between dev and prod when reusing a single bucket — both observed and recommended pattern unclear in upstream docs.
- [ ] Add an Open WebUI / LibreChat / Aider integration cookbook section once we've wired one into a real deploy.
