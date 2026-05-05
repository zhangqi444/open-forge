---
name: GO Feature Flag
description: "Lightweight, self-hosted feature flag solution with OpenFeature SDK support. Stores flags in YAML/JSON/TOML files on S3, HTTP, Kubernetes, or local disk. Relay proxy serves flags via REST API to any language. Supports A/B testing, gradual rollout, scheduled flags, and flag change notifications. Go. MIT."
---

# GO Feature Flag

**What it is:** A complete feature flag platform you host yourself. Uses a simple flat-file flag configuration (YAML, JSON, or TOML) stored wherever you like (S3, GCS, HTTP endpoint, local file, Kubernetes ConfigMap). The relay proxy exposes an OpenFeature-compatible REST API so any language/SDK can evaluate flags.

**Official site:** https://gofeatureflag.org  
**GitHub:** https://github.com/thomaspoignant/go-feature-flag  
**Docs:** https://gofeatureflag.org/docs  
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux/macOS | Binary | Single Go binary; download from releases |
| Docker | docker compose | Recommended for self-hosting |
| Kubernetes | Helm chart | Available; see docs |
| Any | Go library | Embed directly in Go apps (no relay proxy needed) |

---

## Inputs to Collect

### Pre-install
- Where to store flag config file (local file, S3 bucket, HTTP URL, etc.)
- Flag file format (YAML recommended)
- Whether to use relay proxy (required for non-Go languages)
- Desired export destination for flag usage data (S3, file, stdout, etc.)
- Notification webhook URLs (optional - Slack, custom webhook)

### Runtime
- Retriever type and location for flags file
- Relay proxy listen port (default: 1031)
- Polling interval for flag file refresh (default: 60s)
- OpenTelemetry exporter config (optional)

---

## Software-Layer Concerns

### Config paths (relay proxy)
- /etc/go-feature-flag/config.yml - relay proxy config
- /app/flags.yaml - example flag file location (configure as needed)

### Relay proxy config (config.yml)
```yaml
listen: 1031
pollingInterval: 60000  # ms
retriever:
  kind: file  # or: s3, gcs, github, http, k8s-configmap
  path: /app/flags.yaml
exporter:
  kind: file
  outputDir: /tmp/flag-data/
notifier:
  - kind: slack
    webhookUrl: https://hooks.slack.com/services/xxx
```

### Flag file format (flags.yaml)
```yaml
my-feature:
  variations:
    enabled: true
    disabled: false
  defaultRule:
    variation: disabled
  targeting:
    - name: "beta-users"
      query: 'key eq "user-123"'
      variation: enabled
```

### Ports
- 1031 TCP - relay proxy REST API (default)

---

## docker-compose.yml

```yaml
services:
  go-feature-flag:
    image: thomaspoignant/go-feature-flag:latest
    ports:
      - "1031:1031"
    volumes:
      - ./config.yml:/etc/go-feature-flag/config.yml:ro
      - ./flags.yaml:/app/flags.yaml:ro
      - ./flag-data:/tmp/flag-data
    restart: unless-stopped
```

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

Flag files hot-reload automatically per pollingInterval - no restart needed for flag changes.

---

## Gotchas

- The relay proxy is required for non-Go languages (JS, Python, Ruby, Java, etc.) - Go apps can use the library directly
- Flag files are polled, not watched - changes take up to pollingInterval ms to propagate
- No built-in UI for editing flags - flags are managed as code (files in git); this is by design
- OpenFeature SDK versions must match the relay proxy API version - check compatibility matrix in docs
- Targeting rules use a simple expression language - see https://gofeatureflag.org/docs/configure_flag/target-with-flags for syntax
- For S3/GCS retrievers, IAM/service account credentials must be available via env or mounted credentials

---

## Upstream Docs

- Getting started: https://gofeatureflag.org/docs/getting_started/using-relay-proxy
- Flag format reference: https://gofeatureflag.org/docs/configure_flag/flag_format
- Targeting rules: https://gofeatureflag.org/docs/configure_flag/target-with-flags
- Retriever options: https://gofeatureflag.org/docs/configure_flag/store_your_flags
- Rollout strategies: https://gofeatureflag.org/docs/configure_flag/rollout-strategies/progressive
- SDK list: https://gofeatureflag.org/docs/sdk
