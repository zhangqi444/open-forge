---
name: nirvati
description: Nirvati recipe for open-forge. Self-hosted app management platform (also known as n5i) for 1-click deploying popular self-hosted apps via a web UI on Kubernetes. Rust backend, Nuxt frontend. AGPL-3.0. Based on upstream at https://gitlab.com/nirvati-ug/nirvati/backend.
---

# Nirvati

Self-hosted application management platform (also known internally as n5i) that lets you 1-click deploy and manage popular self-hosted apps from a web UI. Kubernetes-native; the Rust backend exposes a GraphQL API consumed by a Nuxt frontend dashboard. Supports plugin system for Bitcoin/LND, Tor, Stalwart mail, and Tipi app compatibility. AGPL-3.0. Upstream: https://gitlab.com/nirvati-ug/nirvati/backend. Website: https://nirvati.org.

## Compatible install methods

| Method | When to use |
|---|---|
| Kubernetes (official) | Required; Nirvati runs on top of k8s |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Kubernetes cluster available?" | Yes/No | Nirvati requires an existing k8s cluster |
| preflight | "kubectl configured and connected?" | Yes/No | |
| config | "Domain for Nirvati dashboard?" | FQDN | For ingress routing |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Rust (backend), Nuxt/Vue (frontend) |
| Infra requirement | Kubernetes cluster (local or cloud) |
| API | GraphQL |
| Services | Agent (app install/domain mgmt), GraphQL API, Background Updater, Node Agent |
| App store | Fetches and installs apps from compatible stores (Tipi-compatible) |
| Plugins | Bitcoin/LND, Tor, Stalwart mail integration (some WIP) |
| Status | Active development; some modules marked WIP |

## Install

Official install documentation is at https://nirvati.org. The backend source is at https://gitlab.com/nirvati-ug/nirvati/backend and the frontend dashboard at https://gitlab.com/n5i/dashboard.

**General approach:**

1. Provision a Kubernetes cluster (k3s on a single VPS is a common lightweight option)
2. Deploy the Nirvati stack via Helm chart or manifests from the upstream repo
3. Access the dashboard at your configured domain to complete setup

Check https://nirvati.org for current installation guides — the project is under active development and install procedures may change between releases.

## Upgrade procedure

Follow upstream release notes at https://gitlab.com/nirvati-ug/nirvati/backend/-/releases.

## Gotchas

- Kubernetes is required: Unlike most self-hosted app managers (Cosmos, Portainer, Dockge), Nirvati is Kubernetes-native and cannot run on bare Docker. A single-node k3s cluster is the minimum viable setup.
- Active development: Several modules (Mail plugin, SaaS module, Audit logs) are marked WIP in the source. Expect API changes between versions.
- Multi-repository architecture: Backend, frontend (dashboard), and plugins live in separate repositories under the gitlab.com/nirvati-ug and gitlab.com/n5i namespaces.
- Tipi plugin: Adds compatibility with Tipi app definitions, expanding the app catalog that Nirvati can install.
- Resource requirements: Running a k8s control plane adds overhead versus Docker-only solutions. Not ideal for very low-resource hardware.

## Links

- Website: https://nirvati.org
- Backend source: https://gitlab.com/nirvati-ug/nirvati/backend
- Frontend (dashboard): https://gitlab.com/n5i/dashboard
- Releases: https://gitlab.com/nirvati-ug/nirvati/backend/-/releases
