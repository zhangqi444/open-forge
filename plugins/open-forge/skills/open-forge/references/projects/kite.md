---
name: Kite
description: "Modern Kubernetes dashboard. Go 1.25+ + React 19 + TypeScript. Multi-cluster management, enterprise RBAC + OAuth + audit logs, AI agents. kite-org. Apache. Bilingual (English/Chinese)."
---

# Kite

Kite is **"Lens / Headlamp / K9s — but modern web-UI + multi-cluster + AI-agents + enterprise-governance"** — a lightweight, modern Kubernetes dashboard. **Unified workspace** for real-time observability, multi-cluster management, resource management, enterprise user-governance (OAuth + RBAC + audit logs), and **AI agents**. Go 1.25+ backend + React 19 + TypeScript. Switch between multiple K8s clusters; independent Prometheus config per cluster; auto-discovery from kubeconfig. i18n: English + Chinese.

Built + maintained by **kite-org**. License: **Apache**. Active; Slack; live demo at kite-demo.zzde.me; docs at kite.zzde.me; Trendshift badge.

Use cases: (a) **multi-cluster Kubernetes ops** — dev+staging+prod+multi-region (b) **replace Lens (commercial) or self-host Headlamp alternative** (c) **RBAC-controlled team-access to K8s** (d) **AI-assisted troubleshooting** — ask questions about cluster state (e) **compliance audit-logs** — who did what on cluster (f) **Prometheus-backed observability** — integrated per-cluster (g) **bilingual ops team** — English/Chinese support (h) **modern UX for Kubernetes** — better-than-vanilla-Dashboard.

Features (per README):

- **Multi-cluster management** (kubeconfig auto-discovery)
- **Per-cluster Prometheus config**
- **Real-time observability**
- **Resource management**
- **OAuth + RBAC + audit logs**
- **AI agents** (built-in)
- **Dark/light/color themes** + system-preference detection
- **Global search** across resources
- **Responsive design** (desktop/tablet/mobile)
- **i18n** (English + Chinese)

- Upstream repo: <https://github.com/kite-org/kite>
- Website: <https://kite.zzde.me>
- Live demo: <https://kite-demo.zzde.me>
- Slack: <https://join.slack.com/t/kite-dashboard/>

## Architecture in one minute

- **Go 1.25+** backend
- **React 19 + TypeScript** frontend
- **Connects to**: Kubernetes API server(s) + Prometheus endpoints
- **Resource**: low-moderate — 100-300MB RAM
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream image**                                              | **Primary**                                                                        |
| **Kubernetes**     | **Deployed AS a pod in cluster**                                | Cloud-native                                                                                   |
| Source             | Go + React                                                                            | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `kite.example.com`                                          | URL          | TLS MANDATORY                                                                                    |
| kubeconfig / SA token | K8s API access                                             | **CRITICAL** | **Compromise = cluster-admin**                                                                                    |
| Prometheus endpoint  | Per-cluster                                                 | Observability |                                                                                    |
| OAuth provider       | Google / GitHub / OIDC                                      | Auth         |                                                                                    |
| RBAC mapping         | Which users get which cluster / resource access             | Authorization |                                                                                    |
| AI provider          | OpenAI / self-hosted LLM for AI agents                                                                                 | AI           |                                                                                    |

## Install via Docker

```yaml
services:
  kite:
    image: ghcr.io/kite-org/kite:latest        # **pin version**
    volumes:
      - ~/.kube/config:/root/.kube/config:ro        # or ServiceAccount in-cluster
    ports: ["8080:8080"]
    environment:
      OAUTH_CLIENT_ID: ...
      OAUTH_CLIENT_SECRET: ...
```

Or deploy AS Pod in cluster with ServiceAccount.

## First boot

1. Start → browse web UI
2. Configure OAuth
3. Add clusters (from kubeconfig OR ServiceAccount in-cluster)
4. Configure per-cluster Prometheus
5. Set up RBAC mappings
6. Test audit-log generation
7. Configure AI-agent provider (if desired)
8. Put behind TLS reverse proxy + strong auth

## Data & config layout

- Configuration (OAuth + clusters + RBAC) — stored per upstream
- No cluster-data stored locally (queries K8s API directly)

## Backup

Config is the valuable part; K8s itself has its own state.

## Upgrade

1. Releases: <https://github.com/kite-org/kite/releases>. Active.
2. Docker pull + restart

## Gotchas

- **105th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — Kubernetes-control-plane-UI sub-category**:
  - Kite holds: kubeconfigs (cluster-admin-equivalent) + OAuth creds + Prometheus creds + AI-agent API keys
  - Compromise of Kite = **CLUSTER-ADMIN ON EVERY CLUSTER** → full-infrastructure compromise
  - **105th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "Kubernetes-multi-cluster-control-plane-UI"** (1st — Kite)
  - Distinct from Canine (104) "infra-control-plane" because Kite is pure-K8s-dashboard (not deploy-orchestrator)
  - **CROWN-JEWEL Tier 1: 27 tools / 24 sub-categories**
- **MULTI-CLUSTER = MULTIPLE-CREDENTIAL-CONCENTRATION**:
  - Each cluster adds to Kite's credential-store
  - One tool compromise → ALL clusters compromised
  - **Recipe convention: "multi-cluster-credential-concentration risk"** — stronger form of concentrated-risk
  - **NEW recipe convention** (Kite 1st formally)
- **AI-AGENTS ON K8S**:
  - Built-in AI agents can query cluster state
  - If AI uses cloud-LLM → cluster state → OpenAI/etc.
  - **LLM-feature-sends-data-externally extended**: now 3 tools (EventCatalog+Spliit+Kite) 🎯 **3-TOOL MILESTONE**
  - **Mitigation**: self-hosted LLM (Ollama) for AI-agent
  - **Recipe convention: "AI-agent-on-privileged-cluster-tool" callout**
  - **NEW recipe convention** (Kite 1st formally — especially concerning for cluster-state)
- **AI-AGENT-EXECUTING-COMMANDS RISK**:
  - If AI-agent can execute kubectl commands based on LLM-output → prompt-injection → cluster-destruction
  - **Recipe convention: "AI-agent-execution-on-cluster danger"** — careful-scoping needed
  - **NEW recipe convention** (Kite 1st formally) — VERY important for AI-agents on K8s
- **RBAC-MAPPING DISCIPLINE**:
  - Mapping OAuth-users → K8s RBAC roles
  - Errors = escalation or access-denial
  - **Recipe convention: "OAuth-to-RBAC-mapping-discipline"** — standard
- **AUDIT LOG INTEGRITY**:
  - Kite audit-logs are ADDITIONAL to K8s API-server audit-logs
  - Both should be retained; neither is the other
  - **Recipe convention: "dual-audit-log-integrity" callout**
- **BILINGUAL i18n (English + Chinese)**:
  - Suggests Chinese-maintainer-base (zzde.me domain)
  - **Recipe convention: "bilingual-support positive-signal"** — inclusive + broader-community
- **K8S-DASHBOARD-CATEGORY (crowded):**
  - **Kite** — modern + multi-cluster + AI
  - **Kubernetes Dashboard** — official; minimal
  - **Lens** (commercial; IDE-style)
  - **Headlamp** — OSS Lens-alternative
  - **K9s** — TUI; keyboard-driven
  - **Rancher** — multi-cluster + full-stack
  - **Octant** — legacy Lens-alt
  - **Kubewise / Kubernator** — niche alts
- **ALTERNATIVES WORTH KNOWING:**
  - **Headlamp** — if you want OSS + CNCF + single-cluster
  - **K9s** — if you want TUI + keyboard-first
  - **Rancher** — if you want multi-cluster + ecosystem + SUSE-backed
  - **Kubernetes Dashboard** — if you want minimal official
  - **Choose Kite if:** you want multi-cluster + AI-agents + bilingual + modern UX.
- **INSTITUTIONAL-STEWARDSHIP**: kite-org + Slack + community + AI-features. **91st tool — modern-K8s-tool-org sub-tier.**
- **TRANSPARENT-MAINTENANCE**: active + Go 1.25+ + React 19 + Apache + Slack + demo + docs + i18n + Trendshift-trend. **99th tool in transparent-maintenance family — approaching 100.**
- **PROJECT HEALTH**: active + modern-stack + AI + multi-cluster + Slack. Strong but young.

## Links

- Repo: <https://github.com/kite-org/kite>
- Website: <https://kite.zzde.me>
- Demo: <https://kite-demo.zzde.me>
- Headlamp (alt): <https://headlamp.dev>
- K9s (alt): <https://k9scli.io>
- Rancher (alt): <https://www.rancher.com>
- Kubernetes Dashboard: <https://github.com/kubernetes/dashboard>
