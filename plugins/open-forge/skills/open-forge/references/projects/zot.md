---
name: Zot
description: "Production-ready vendor-neutral OCI-native image registry. OCI image-format + distribution-spec on-the-wire. CII Best Practices + OpenSSF Scorecard + FOSSA + CodeQL + codecov + OCI conformance. Project Zot org. Apache-2."
---

# Zot

Zot is **"Harbor — but smaller, stricter-OCI-compliant, single-binary, Linux Foundation-adjacent"** — a **production-ready vendor-neutral OCI image registry**. Images stored in OCI image format; distribution spec on-the-wire; **that's it**. No proprietary formats, no vendor lock-in. Documented at <https://zotregistry.dev>.

Built + maintained by **Project Zot** (community org). License: **Apache-2.0** (FOSSA-verified). **Excellent security/quality signaling**: CII Best Practices badge + OpenSSF Scorecard + FOSSA + CodeQL + codecov + OCI conformance + nightly CI.

Use cases: (a) **self-hosted container registry** — alternative to Docker Hub (b) **airgapped registry** — strict OCI isolation (c) **multi-tenant registry with OCI artifacts** — Helm, models, etc. (d) **Harbor-light** for small clusters (e) **Kubernetes-native-registry** for in-cluster (f) **edge/IoT-registry** — small binary footprint (g) **private-mirror of Docker Hub** (h) **OCI-conformance-test target** — reference-level OCI.

Features (per README + docs):

- **Pure OCI** — image spec + distribution spec
- **Single Go binary**
- **Vendor-neutral**
- **Conformance-tested** (badge)
- **Apache-2.0 + FOSSA-cleared**
- **Security-signaled**: CII + OpenSSF Scorecard + CodeQL

- Upstream repo: <https://github.com/project-zot/zot>
- Docs: <https://zotregistry.dev>

## Architecture in one minute

- **Go** single binary
- **Storage backend**: local FS or S3-compatible
- **Auth**: htpasswd, LDAP, OIDC
- **Extensions**: signature verification, scanning
- **Resource**: low-to-medium — scales with images stored
- **Port**: 5000 (Docker-registry convention) or custom

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`ghcr.io/project-zot/zot`**                                   | **Primary**                                                                        |
| **Binary**         | Single Go binary                                                                                                       | Alt                                                                                   |
| **Kubernetes**     | Helm chart                                                                                                             | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `registry.example.com`                                      | URL          | **TLS MANDATORY** (registry clients require)                                                                                    |
| Auth method          | htpasswd / LDAP / OIDC                                      | Auth         |                                                                                    |
| Storage backend      | Local FS or S3                                              | Storage      | **Grows large**                                                                                    |
| Upstream mirrors     | If federated                                                | Config       |                                                                                    |

## Install via Docker

Follow: <https://zotregistry.dev/v2.1.4/install-guides/install-guide-docker/>

```yaml
services:
  zot:
    image: ghcr.io/project-zot/zot-linux-amd64:latest        # **pin version**
    ports: ["5000:5000"]
    volumes:
      - ./zot-data:/var/lib/registry
      - ./config.json:/etc/zot/config.json:ro
    restart: unless-stopped
```

`config.json` per <https://zotregistry.dev/v2.1.4/admin-guide/admin-configuration/>.

## First boot

1. Write config.json (storage + auth)
2. Start
3. Put behind TLS (MUST — Docker/Podman clients refuse plain HTTP for most ops)
4. Test: `docker login registry.example.com`
5. Push test image: `docker push registry.example.com/myimage:1`
6. Pull: `docker pull registry.example.com/myimage:1`
7. Back up data dir

## Data & config layout

- `/var/lib/registry/` — image blobs + manifests (grows LARGE)
- `/etc/zot/config.json` — config

## Backup

```sh
sudo tar czf zot-config-$(date +%F).tgz config.json
# Data directory = large — use image mirroring / object-storage-backend with snapshot, or rsync
# Each image in registry is individually re-pullable from source — back up based on criticality
```

## Upgrade

1. Releases: <https://github.com/project-zot/zot/releases>. Active; nightly CI.
2. Docker pull + restart
3. Storage format is OCI — stable

## Gotchas

- **134th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — SUPPLY-CHAIN-ARTIFACT-HOST**:
  - Hosts ALL container images for your infra — compromise = supply-chain poisoning
  - Auth creds (htpasswd/LDAP/OIDC) for pulls + pushes
  - Potential target for malicious-image-injection
  - **134th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "container-registry + supply-chain-artifact-host"** (1st — Zot; distinct as infra-tier)
  - **CROWN-JEWEL Tier 1: 39 tools / 36 sub-categories**
- **SUPPLY-CHAIN-POISONING-RISK**:
  - Compromised registry = everyone pulls poisoned images
  - **Recipe convention: "supply-chain-poisoning-via-registry callout"**
  - **NEW recipe convention** (Zot 1st formally)
- **SIGNATURE-VERIFICATION ENCOURAGED**:
  - Cosign integration
  - **Recipe convention: "image-signature-verification-discipline callout"**
  - **NEW recipe convention** (Zot 1st formally)
- **STORAGE GROWS UNBOUNDED**:
  - Images accumulate; GC/retention important
  - **Recipe convention: "registry-GC-retention-policy callout"**
  - **NEW recipe convention** (Zot 1st formally)
- **OCI-CONFORMANCE-TESTED**:
  - CI runs OCI conformance tests
  - Reference-implementation quality
  - **Recipe convention: "OCI-conformance-tested positive-signal"**
  - **NEW positive-signal convention** (Zot 1st formally)
- **STRONG SECURITY-HYGIENE SIGNALING**:
  - CII Best Practices badge
  - OpenSSF Scorecard
  - FOSSA license-cleared
  - CodeQL static analysis
  - codecov coverage
  - **Recipe convention: "security-hygiene-badge-constellation positive-signal"**
  - **NEW positive-signal convention** (Zot 1st formally) — the most comprehensive security-signaling we've seen
  - **Security-hygiene-badge-constellation: 1 tool** 🎯 **NEW MILESTONE**
- **VENDOR-NEUTRAL-POSITIONING**:
  - Explicit positioning
  - **Recipe convention: "vendor-neutral-positioning positive-signal"**
  - **NEW positive-signal convention** (Zot 1st formally)
- **NIGHTLY-CI-BUILDS**:
  - Nightly workflow
  - **Recipe convention: "nightly-CI-quality-ops positive-signal"**
  - **NEW positive-signal convention** (Zot 1st formally)
- **APACHE-2 LICENSE**:
  - Standard permissive
  - **Apache-2-permissive-license: 2 tools** (VersityGW+Zot) 🎯 **2-TOOL MILESTONE**
- **PRODUCTION-READY DECLARATION**:
  - Upstream self-describes as "production-ready"
  - Contrast Stump/Reiverr honest-WIP
  - **Recipe convention: "declared-production-ready positive-signal"**
  - **NEW positive-signal convention** (Zot 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: Project Zot community org + CII + OpenSSF + FOSSA + CodeQL + codecov + OCI-conformance + nightly + website + Apache-2. **120th tool 🎯 120-TOOL MILESTONE — highest-security-signaling sub-tier** (NEW — reference-grade OSS-infra stewardship).
- **TRANSPARENT-MAINTENANCE**: active + 7+ security/quality badges + nightly + website + docs + OCI-conformance. **126th tool in transparent-maintenance family.**
- **CONTAINER-REGISTRY-CATEGORY:**
  - **Zot** — pure-OCI; single-binary; strong-security-signals
  - **Harbor** — CNCF; larger; policy + scan built-in
  - **Distribution (Docker Registry)** — reference; minimal
  - **Quay** — Red Hat; enterprise
  - **Forgejo/Gitea** — Git+Registry combined
- **ALTERNATIVES WORTH KNOWING:**
  - **Harbor** — if you want CNCF + policy-engine + scanning + enterprise
  - **Distribution** — if you want reference minimal
  - **Gitea/Forgejo Package Registry** — if you also want Git + packages + registry in one
  - **Choose Zot if:** you want OCI-purity + single-binary + strong-security-signaling.
- **PROJECT HEALTH**: excellent — 7 quality/security badges, conformance-tested, nightly-CI, Apache-2. **Reference-grade**.

## Links

- Repo: <https://github.com/project-zot/zot>
- Docs: <https://zotregistry.dev>
- Harbor (alt): <https://github.com/goharbor/harbor>
- Distribution (alt): <https://github.com/distribution/distribution>
