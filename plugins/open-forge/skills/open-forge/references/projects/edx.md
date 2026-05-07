---
name: edx
description: edX (Open edX) recipe for open-forge. Open-source online learning platform powering edX.org. Courses, videos, quizzes, certificates, discussion forums, LTI. AGPL-3.0, Python. Deploy via Tutor (official Docker-based distribution). Source: https://github.com/openedx/
---

# edX (Open edX)

The open-source platform that powers edX.org and hundreds of other online learning portals worldwide. Supports full-featured online courses with video, quizzes, assignments, discussion forums, certificates, cohorts, and LTI integration. AGPL-3.0 licensed, Python/Django backend. The official self-hosted deployment method is **Tutor** — a Docker-based distribution. Website: <https://openedx.org/>. Tutor docs: <https://docs.tutor.edly.io/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux VPS / bare metal | Tutor (Docker) | Official and only recommended deployment method |
| Kubernetes | Tutor + Helm | Tutor has native Kubernetes support |
| AWS | Tutor AMI | Zero-click AWS image available |

> The legacy `devstack` deployment is deprecated. Use Tutor for all new installations.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. learn.example.com — also needs preview.learn.example.com and studio.learn.example.com |
| "Email service?" | SMTP credentials | Tutor needs SMTP for enrollment/certificate emails |
| "Expected concurrent users?" | Count | Drives resource sizing — Open edX is resource-intensive |
| "Platform name?" | string | Displayed in UI and emails |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Tutor plugins needed?" | Indigo / MFE / Ecommerce / etc. | Tutor has an official plugin ecosystem |
| "LMS admin email?" | email | First superuser account |

## Software-Layer Concerns

- **Tutor is the official deployer**: Tutor manages Docker Compose or Kubernetes, configuration, upgrades, and plugin orchestration for Open edX.
- **Multiple domains**: Open edX requires at minimum: `LMS_HOST` (main), `CMS_HOST` (Studio authoring), and `preview.` subdomain. Configure DNS and TLS for all three.
- **Resource-intensive**: A minimal production Open edX needs at least 4 CPU cores and 8GB RAM. Small VPS instances will struggle.
- **Tutor plugins**: Additional features (theming, ecommerce, credentials, SCORM) are installed as Tutor plugins via `pip install tutor-*`.
- **Data volumes**: MySQL, MongoDB, Elasticsearch (optional), and MinIO (file storage) all need persistent volumes.
- **Named releases**: Open edX releases are named (Sumac, Teak, etc.) — Tutor versions track Open edX named releases.
- **Studio**: The course authoring interface is a separate `cms` service, accessed at `studio.learn.example.com`.

## Deployment

### Install Tutor

```bash
pip install "tutor[full]"
# or for latest stable:
pip install tutor

tutor --version
```

### Configure and launch

```bash
# Interactive configuration
tutor config save --interactive
# or set key values directly:
tutor config save \
  --set LMS_HOST=learn.example.com \
  --set CMS_HOST=studio.learn.example.com \
  --set PLATFORM_NAME="My Learning Platform" \
  --set CONTACT_EMAIL=admin@example.com

# Initialize databases and static assets (takes 10-20 min first time)
tutor local launch

# Or step by step:
tutor local start -d
tutor local init
```

### Create admin user

```bash
tutor local do createuser --staff --superuser admin admin@example.com
```

### Start / stop

```bash
tutor local start -d    # start all services in background
tutor local stop        # stop all services
tutor local status      # show running containers
tutor local logs -f     # follow logs
```

### HTTPS (automatic via Caddy)

Tutor uses Caddy as reverse proxy with automatic Let's Encrypt — HTTPS is enabled by default when `ENABLE_HTTPS=true`:

```bash
tutor config save --set ENABLE_HTTPS=true
tutor local launch
```

### Install a plugin

```bash
pip install tutor-indigo   # example: Indigo theme plugin
tutor plugins enable indigo
tutor local launch
```

## Upgrade Procedure

1. `pip install --upgrade tutor`
2. Read the Tutor changelog at https://docs.tutor.edly.io/changelog.html for breaking changes.
3. `tutor local launch` — runs database migrations and asset rebuilds automatically.
4. Named release upgrades (e.g., Redwood → Sumac) follow the Tutor upgrade guide: https://docs.tutor.edly.io/tutorials/upgrade.html

## Gotchas

- **Not lightweight**: Open edX is a large platform — do not deploy on a 1GB RAM VPS. Minimum 4GB RAM, 8GB recommended for production.
- **Three domains minimum**: LMS, Studio, and preview all need DNS + TLS. Missing subdomains cause course preview and authoring failures.
- **Tutor init takes a long time**: First `tutor local launch` may take 20-30 minutes to build assets, run migrations, and pull images.
- **devstack is deprecated**: The old `openedx/devstack` repo is deprecated — do not use it for new deployments.
- **Plugin ecosystem**: Many standard features (ecommerce, credentials, SCORM XBlocks) require Tutor plugins — plan your plugin stack before go-live.
- **Email is critical**: Open edX sends enrollment confirmations, password resets, and certificates via email — SMTP must be configured before onboarding learners.

## Links

- Open edX website: https://openedx.org/
- Tutor documentation: https://docs.tutor.edly.io/
- Tutor source: https://github.com/overhangio/tutor
- Open edX GitHub org: https://github.com/openedx/
- Tutor plugins index: https://overhang.io/tutor/plugins
- Community forum: https://discuss.openedx.org/
