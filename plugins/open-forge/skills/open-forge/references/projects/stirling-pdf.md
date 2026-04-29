---
name: stirling-pdf-project
description: Stirling PDF recipe for open-forge. Open-core PDF editing platform — 50+ PDF tools (edit, merge, split, sign, redact, convert, OCR, compress) runnable as a single-container Spring Boot app. Covers the minimal `docker run`, full compose with OCR (tessdata) volume, key SYSTEM_ / SECURITY_ / UI_ env vars, and the typical 4 GB memory limit.
---

# Stirling PDF (self-hosted PDF platform)

Open-core (MIT for core; some Enterprise features paid) self-hosted PDF platform. 50+ tools — edit, merge, split, sign, redact, OCR, compress, convert. Web UI + REST API. Runs as a single Java/Spring Boot container.

**Upstream README:** https://github.com/Stirling-Tools/Stirling-PDF/blob/main/README.md
**Docs:** https://docs.stirlingpdf.com
**Example compose:** https://github.com/Stirling-Tools/Stirling-PDF/blob/master/exampleYmlFiles/docker-compose-latest.yml
**Docker Hub / GHCR:** `docker.stirlingpdf.com/stirlingtools/stirling-pdf` (primary) or `ghcr.io/stirling-tools/stirling-pdf`

## Compatible combos

| Infra | Runtime | Status | Notes |
|---|---|---|---|
| localhost | Docker | ✅ default | One container, one port |
| localhost | Docker Compose | ✅ | Recommended — adds persistent config/OCR volumes |
| byo-vps | Docker | ✅ | 4 GB RAM recommended (OCR + LibreOffice conversions are heavy) |
| aws/ec2 | Docker | ✅ | `t3.medium` minimum |
| hetzner/cloud-cx | Docker | ✅ | CX22 works; CX32 for heavy OCR |
| kubernetes | community Helm | ⚠️ | Upstream docs mention k8s but no first-party chart in the main repo. Community charts exist. |
| desktop client | native | ✅ | Upstream ships a desktop build too (mentioned in README as "Desktop client"); not a typical self-host path |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| dns | "Domain to host Stirling PDF on?" | Free-text | e.g. `pdf.example.com` |
| tls | "Email for Let's Encrypt notices?" | Free-text | |
| auth | "Enable login (multi-user)?" | AskUserQuestion: Yes / No | `SECURITY_ENABLELOGIN` — no by default; enable if exposing publicly |
| i18n | "UI language(s)?" | Free-text | `LANGS` env var, comma-separated (40+ supported) |
| storage | "Persist OCR data / config / logs?" | AskUserQuestion: Yes (bind mount) / No (ephemeral) | Volumes for `/usr/share/tessdata`, `/configs`, `/logs` |
| limits | "Max upload file size (MB)?" | Free-text (default 100) | `SYSTEM_MAXFILESIZE` |

## Install methods

### 1. Docker (quick-start, from README)

```bash
docker run -d --name stirling-pdf \
  -p 8080:8080 \
  --restart unless-stopped \
  docker.stirlingpdf.com/stirlingtools/stirling-pdf:latest
```

Dashboard: `http://localhost:8080`.

### 2. Docker Compose (recommended — from upstream example)

Source: https://github.com/Stirling-Tools/Stirling-PDF/blob/master/exampleYmlFiles/docker-compose-latest.yml

Stripped-down production-oriented variant (the upstream file targets their demo site with `-test:latest` tag + some demo-specific env vars):

```yaml
services:
  stirling-pdf:
    image: docker.stirlingpdf.com/stirlingtools/stirling-pdf:latest
    container_name: Stirling-PDF
    deploy:
      resources:
        limits:
          memory: 4G
    ports:
      - "8080:8080"
    volumes:
      - ./stirling/data:/usr/share/tessdata:rw
      - ./stirling/config:/configs:rw
      - ./stirling/logs:/logs:rw
    environment:
      SECURITY_ENABLELOGIN: "false"
      LANGS: "en_US"
      SYSTEM_DEFAULTLOCALE: en-US
      UI_APPNAME: Stirling-PDF
      SYSTEM_MAXFILESIZE: "100"
      METRICS_ENABLED: "true"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8080/api/v1/info/status | grep -q 'UP'"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### 3. Other install options

Per https://docs.stirlingpdf.com/#documentation-guide — upstream documents a desktop client (same codebase, packaged as a local app) and Kubernetes deployment. Details live at docs.stirlingpdf.com (not mirrored in the repo).

## Software-layer concerns

### Image options

| Image | Purpose |
|---|---|
| `docker.stirlingpdf.com/stirlingtools/stirling-pdf:latest` | Primary (Stirling's own registry) |
| `docker.stirlingpdf.com/stirlingtools/stirling-pdf:X.Y.Z` | Pinned |
| `ghcr.io/stirling-tools/stirling-pdf` | GHCR mirror |
| `ghcr.io/stirling-tools/stirling-pdf-test` | Upstream demo builds (don't use in prod) |

There are historically also `-ultra-lite`, `-fat` variants that differ in which Java runtime + OCR languages are bundled. Check docs.stirlingpdf.com for the current inventory.

### Key env vars

From the compose example. Full reference at https://docs.stirlingpdf.com.

| Var | Default | Purpose |
|---|---|---|
| `SECURITY_ENABLELOGIN` | `false` | Multi-user auth. **Must be `true` if publicly exposed.** |
| `SYSTEM_MAXFILESIZE` | `100` (MB) | Upload size cap |
| `SYSTEM_DEFAULTLOCALE` | `en-US` | Default UI locale |
| `LANGS` | varies | Comma-separated list of UI languages to load |
| `UI_APPNAME` | `Stirling PDF` | Display name |
| `UI_HOMEDESCRIPTION` | | Shown on the home page |
| `UI_APPNAMENAVBAR` | | Navbar title |
| `METRICS_ENABLED` | | Exposes Prometheus metrics at `/actuator/prometheus` |
| `SYSTEM_GOOGLEVISIBILITY` | `false` | `true` = allow search engines to index; `false` = `X-Robots-Tag: none` |
| `SHOW_SURVEY` | | Suppress the feedback survey popup |

### Volumes

| Host path | Container path | Purpose |
|---|---|---|
| `./stirling/data/` | `/usr/share/tessdata` | OCR language data (downloaded on first OCR if not provided; volumes allow persistence between rebuilds) |
| `./stirling/config/` | `/configs` | Runtime config files, user accounts (if login enabled) |
| `./stirling/logs/` | `/logs` | Application logs |

### Ports

- `8080/tcp` — web UI + REST API

### Reverse proxy

```caddy
pdf.example.com {
  reverse_proxy 127.0.0.1:8080

  request_body {
    max_size 100MB
  }
}
```

Raise Nginx / Caddy / CloudFront body-size to match `SYSTEM_MAXFILESIZE`, otherwise large uploads fail with 413 before reaching Stirling.

### Memory

The compose file declares `memory: 4G`. OCR + LibreOffice conversions (DOCX→PDF, ODT→PDF, etc.) are memory-hungry — 4 GB is a reasonable floor. On 2 GB hosts, most tools work but OCR on large scans can OOM.

### API

REST endpoints at `/api/v1/*`. Scalar docs at https://registry.scalar.com/@stirlingpdf/apis/stirling-pdf-processing-api/. Useful for "batch-OCR every PDF in a directory" automation via a script.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Or manual:

```bash
docker pull docker.stirlingpdf.com/stirlingtools/stirling-pdf:latest
docker stop stirling-pdf && docker rm stirling-pdf
docker run ... (re-run install)
```

Stateless app — upgrades are trivial as long as the `/configs` volume survives. The OCR `tessdata` volume persists language data across upgrades.

Release notes: https://github.com/Stirling-Tools/Stirling-PDF/releases

## Gotchas

- **`SECURITY_ENABLELOGIN=false` means everyone who reaches the URL can use it.** If you reverse-proxy onto the public internet without login, anyone can burn your CPU doing OCR on random PDFs. Either enable login or gate at the proxy layer (Cloudflare Access / basic auth / Tailscale).
- **First OCR run downloads language packs.** Expect the first OCR operation to take a bit — tessdata is pulled if not already mounted. Mounting a pre-warmed volume avoids this.
- **Memory spike on large PDFs.** Redacting or OCR'ing a 500-page PDF can push Java past 2 GB. Raise `JAVA_OPTS` heap and the container memory limit for heavy workloads.
- **LibreOffice conversions sandboxed differently.** Some DOCX → PDF paths shell out to a LibreOffice subprocess; it's sandboxed but occasionally crashes on malformed input. Errors surface as 500 responses.
- **`-test:latest` is the demo tag.** The upstream compose file defaults to it because that compose file is literally what powers `demo.stirlingpdf.com`. For prod, use `-latest` or `-X.Y.Z` on the `stirlingtools/stirling-pdf` tag, not `-test:*`.
- **Prometheus endpoint only if `METRICS_ENABLED=true`.** Path is `/actuator/prometheus`. Gate it with reverse-proxy access control if exposed.
- **URL-based features can leak path metadata.** Tools like "merge by URL" will fetch user-supplied URLs from inside the container. If Stirling can reach private LAN services, SSRF risk. Consider egress firewalls or disabling URL-import features.
- **Primary image registry is `docker.stirlingpdf.com`.** If your CI mirrors Docker Hub, add this registry; or pull from `ghcr.io` instead.
- **Not OSS-pure.** Some features are paywalled (SSO, auditing, enterprise settings). Core PDF tools are MIT. Check `LICENSE` at the version you pull.
- **`SYSTEM_GOOGLEVISIBILITY=true` will index your instance.** If you're the only user, leave it `false`.

## TODO — verify on subsequent deployments

- [ ] Confirm which image variant is current "lite" vs "full" at next install (upstream re-orgs image names occasionally).
- [ ] Test OCR with pre-warmed tessdata volume for languages beyond English.
- [ ] Exercise the REST API for batch workflows; confirm auth-token shape when login is enabled.
- [ ] Community Helm chart — identify most-active.
- [ ] Enterprise / paid features gate — clarify boundary at first-deploy time.
