---
name: Cerbos
description: "Open-source policy-decision-point (PDP) for application authorization — YAML policies, gRPC+REST APIs, RBAC+ABAC, GitOps-friendly. Self-hosted PDP is Apache-2.0; optional Cerbos Hub SaaS for policy distribution. Go."
---

# Cerbos

Cerbos is **"a stateless authorization microservice you call from your app"** — it answers two questions:

1. **CheckResources**: "Can principal P perform action A on resource R?"
2. **PlanResources**: "Which resources of kind K can principal P access?"

Policies are **YAML files** (stored on disk, Git, cloud object stores, or SQL) describing RBAC roles + derived roles + ABAC conditions (Google CEL expressions). The PDP loads them at startup, hot-reloads on change, exposes **gRPC + REST APIs**. Your app calls it per-request.

Built + maintained by **Cerbos** (UK startup) — commercial entity; open-core model: **PDP is Apache-2.0 and fully-featured for authorization decisions**; **Cerbos Hub** is the paid SaaS control plane for **policy distribution, collaborative playgrounds, embedded PDPs** for browser/serverless/edge. You can self-host the PDP forever for free without Hub; Hub is a productivity / fleet-management layer, not a gating layer.

Cerbos exists because: (a) every app reimplements auth badly (b) mixing auth logic into app code = hard to audit (c) policy changes require code deploys (d) no single source of truth across microservices. Cerbos externalizes + centralizes + versions authorization.

Features:

- **Policy-as-code**: YAML files in Git
- **RBAC + ABAC** — resource policies, principal policies, derived roles
- **Conditions** via Google CEL (cel-go) — evaluated at runtime against request context
- **Storage backends**: disk, git, blob (S3/GCS/Azure), SQL (sqlite3, MySQL, Postgres)
- **APIs**: gRPC + REST + HTTP; SDKs for Go/JS/Python/Java/.NET/Ruby/PHP
- **Query plan adapters** — convert PlanResources to SQL WHERE clauses for your ORM
- **Kubernetes** — service or sidecar
- **Helm chart** official
- **Systemd service** — bare metal
- **AWS Lambda** — serverless deployment
- **Audit logs** — every decision logged
- **Testing** — cerbos ctl verify runs tests against policies (`CI/CD-friendly`)
- **Playground** — local + cloud for iterating

- Upstream repo: <https://github.com/cerbos/cerbos>
- Homepage: <https://cerbos.dev>
- Docs: <https://docs.cerbos.dev>
- Quickstart: <https://docs.cerbos.dev/cerbos/latest/quickstart.html>
- Playground: <https://play.cerbos.dev>
- Cerbos Hub (managed): <https://cerbos.dev/product-cerbos-hub>
- Helm chart: <https://docs.cerbos.dev/cerbos/latest/installation/helm.html>
- Docker image: <https://ghcr.io/cerbos/cerbos>

## Architecture in one minute

- **Go** PDP binary (single static binary)
- **Stateless** — loads policies at startup; no DB required for decisions (DB-backed storage is optional alternative to disk/git)
- **Hot reload** — policies can be updated live
- **APIs**: :3592 HTTP, :3593 gRPC (defaults)
- **Resource**: tiny — 50-200 MB RAM; hot path sub-millisecond decisions

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Kubernetes         | **Official Helm chart** — service OR sidecar patterns                         | **Upstream-primary**                                                                |
| Docker             | `ghcr.io/cerbos/cerbos` container                                          | Container install                                                                          |
| Bare-metal         | Single binary + systemd unit                                                       | Supported + documented                                                                     |
| Serverless         | AWS Lambda deployment                                                                   | Edge / pay-per-use                                                                          |
| Storage: Git       | Point PDP at a Git repo with policies                                                            | **GitOps-recommended**                                                                                              |
| Storage: Blob      | S3 / GCS / Azure Blob                                                                                 | Works for large-fleet deployments                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Policy repo          | Git repo with `policies/*.yaml`                                 | Storage      | GitOps pattern = single source of truth                                          |
| Sidecar vs service   | Sidecar per-pod (K8s) OR central service                                | Deployment   | Sidecar = lower latency + no network hop; central = fewer resources                                                    |
| mTLS                 | Certs for app-to-PDP                                                      | Transport    | Same-pod sidecar can use Unix socket                                                                          |
| Audit log sink       | file / stdout / OTel                                                            | Observability | Required-for-compliance in regulated environments                                                                                |
| Storage backend      | disk / git / blob / sql                                                             | Storage      | Choose per deployment                                                                                                 |
| Dev vs prod          | `--set admin.enabled=true` is DEV-only                                                        | Security     | Admin API exposes policy-management endpoints                                                                                                 |

## Install via Kubernetes (sidecar pattern)

Add the Cerbos container to your app's pod spec, sharing a volume with policy files OR pulling from Git:

```yaml
containers:
- name: my-app
  image: my-app:1.0
  env:
    - name: CERBOS_URL
      value: "http://localhost:3592"
- name: cerbos
  image: ghcr.io/cerbos/cerbos:0.40.0                # pin version
  args: ["server"]
  ports:
    - containerPort: 3592
      name: http
  volumeMounts:
    - name: cerbos-policies
      mountPath: /policies
```

For Helm-managed service deployment:
```sh
helm install cerbos oci://ghcr.io/cerbos/helm-charts/cerbos \
  --version 0.40.0 \
  --set cerbos.config.storage.driver=git \
  --set cerbos.config.storage.git.url=https://github.com/org/policies
```

## First boot

1. Write initial policies in `policies/` (see quickstart)
2. `cerbos ctl verify` locally to validate
3. Deploy PDP with chosen storage backend
4. Health-check: `GET /_cerbos/health`
5. Call from app using SDK: `cerbos.checkResource({principal, resource, actions})`
6. Enable audit logging to file/OTel
7. Integrate policy testing into CI
8. (optional) Sign up for Cerbos Hub for policy distribution across fleet

## Data & config layout

- **Policies**: `resource_*.yaml`, `principal_*.yaml`, `derived_roles_*.yaml`, `export_*.yaml`
- **Config**: `.cerbos.yaml` — server + storage + audit config
- **No persistent state** in disk/git mode — fully reproducible from source
- **Audit logs** per config destination

## Backup

Policies live in Git → backup = Git remote. That's the GitOps win.

Server config: `.cerbos.yaml` — back up with your infra config.

## Upgrade

1. Releases: <https://github.com/cerbos/cerbos/releases>. Active cadence.
2. **Policy syntax is versioned** (`apiVersion: api.cerbos.dev/v1`). Backward-compatible.
3. Upgrade path: bump image tag → redeploy → verify health. Stateless = low-risk.
4. Read release notes for deprecated fields; upstream is careful about policy compat.

## Gotchas

- **Cerbos ≠ identity provider (IdP).** Cerbos is the **Policy Decision Point**; you still need an IdP (Keycloak/Authentik/Kanidm/Okta) to AUTHENTICATE users and produce a token containing the principal's roles + attributes. Cerbos consumes that info for AUTHORIZATION. Don't expect Cerbos to handle login.
- **Stateless requires you pass context on every call.** The app sends `{principal, resource, actions}` per check. Means: your app must already have the identity + resource data. Cerbos doesn't fetch from your DB.
- **PlanResources generates conditions — your app applies them.** PlanResources returns a CEL expression / parsed AST; you use a query-plan adapter to convert to SQL WHERE. **Without the adapter, this is just a bag of JSON.** Check <https://docs.cerbos.dev> for adapter availability for your ORM (SQLAlchemy, Prisma, etc.).
- **Sidecar vs service tradeoff**: sidecar = sub-ms latency + no network hop + per-pod policy version drift possible during rollouts; service = fewer resources + centralized + network hop (1-3ms). For high-RPS apps the sidecar is usually correct.
- **GitOps storage = EVENTUAL consistency.** A policy commit takes N seconds to propagate to PDP instances (poll interval). If you need instant distribution, use Cerbos Hub OR in-memory reload via API.
- **Admin API is DEV-only.** `admin.enabled: true` exposes endpoints for policy mutation. DO NOT enable in production — policies should come from Git/blob/disk, not REST pokes.
- **Audit log sensitivity**: decision audit logs include principal attributes + resource attributes. That can include PII. Review + redact before shipping to centralized logging.
- **Policy test coverage**: Cerbos has `cerbos ctl verify` for unit-testing policies. **Use it.** Unreviewed policy changes = production incidents. Require tests in PR.
- **CEL conditions are Turing-incomplete** (by design — no loops, bounded eval). Good: predictable perf. Caveat: complex business rules may need to be pre-computed in principal/resource attributes.
- **Storage driver choice carries operational weight**:
  - Git: best GitOps; requires PDP can pull from Git endpoint
  - Disk: simple; ConfigMap in K8s; requires pod restart or mount trick for updates
  - Blob: good for large-fleet; S3/GCS permissions
  - SQL: dynamic policy changes via API; required for Cerbos Hub sync
- **Cerbos Hub is OPTIONAL** — self-host PDP stays fully functional without Hub. Hub is a productivity layer for multi-team + multi-environment policy distribution, collaborative playgrounds, embedded PDPs (browser/edge). Small teams: skip Hub; large fleets: evaluate it.
- **Embedded PDP (browser/edge)** is a Cerbos Hub feature — policies compiled to WASM for client-side evaluation. Important caveat: client-side policy check = **defense-in-depth, NOT security boundary**. Server-side revalidate. This is the universal axiom (same as SurveyJS batch 78).
- **API versioning**: `apiVersion: api.cerbos.dev/v1` is stable. v2 may come but upstream is cautious about breaking.
- **Kubernetes-admission-controller pattern**: Cerbos can be used as a Kubernetes admission webhook for admission policies. Niche but powerful.
- **OPA comparison**: Open Policy Agent is the incumbent "policy engine". OPA uses Rego DSL; Cerbos uses YAML + CEL. Rego is more powerful + more intimidating; Cerbos YAML is more approachable + purpose-built for app authz. Both excellent. Cerbos is an opinionated app-authz tool; OPA is a general-purpose policy engine.
- **Performance**: sub-millisecond per decision on commodity hardware. Published benchmarks.
- **License**: **Apache-2.0** for PDP. Cerbos Hub is proprietary commercial SaaS.
- **Project health**: Cerbos (UK company) venture-backed; active development; strong docs + SDKs + community. Commercial-tier-funds-upstream pattern (consistent with other tools — Hub sales fund PDP development).
- **Alternatives worth knowing:**
  - **Open Policy Agent (OPA)** — general-purpose; Rego DSL; CNCF-graduated; widely used
  - **Casbin** — library embedded into apps (not a service); multiple DSLs (ACL/RBAC/ABAC); multi-language
  - **Oso** — authz library + cloud product; polar DSL; commercial
  - **Keto / Ory** — authz service; inspired by Google Zanzibar (ReBAC)
  - **SpiceDB** (AuthZed) — Zanzibar-inspired ReBAC at scale
  - **Permify** — Zanzibar-inspired ReBAC; OSS
  - **Topaz** — OSS PDP combining OPA policies + local data; open-source
  - **Choose Cerbos if:** you want a dedicated authz service with YAML policies, great ergonomics, GitOps-first.
  - **Choose OPA if:** you want a general-purpose policy engine (K8s admission, app authz, infra policy all in one).
  - **Choose SpiceDB / Permify if:** you have complex relationship-based authz (sharing, groups, hierarchies).
  - **Choose Casbin if:** embedded library within a single language stack is fine.

## Links

- Repo: <https://github.com/cerbos/cerbos>
- Homepage: <https://cerbos.dev>
- Docs: <https://docs.cerbos.dev>
- Quickstart: <https://docs.cerbos.dev/cerbos/latest/quickstart.html>
- Policy language: <https://docs.cerbos.dev/cerbos/latest/policies/>
- Storage drivers: <https://docs.cerbos.dev/cerbos/latest/configuration/storage.html>
- SDK list: <https://docs.cerbos.dev/cerbos/latest/sdks.html>
- Query plan adapters: <https://docs.cerbos.dev/cerbos/latest/api/index.html>
- Playground: <https://play.cerbos.dev>
- Cerbos Hub: <https://cerbos.dev/product-cerbos-hub>
- Helm: <https://docs.cerbos.dev/cerbos/latest/installation/helm.html>
- Releases: <https://github.com/cerbos/cerbos/releases>
- OPA (alt): <https://www.openpolicyagent.org>
- SpiceDB (alt): <https://authzed.com/spicedb>
- Casbin (alt): <https://casbin.org>
- Permify (alt): <https://permify.co>
