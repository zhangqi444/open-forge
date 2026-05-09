---
name: autokuma
description: "Automates Uptime Kuma monitor creation from Docker container labels. MIT. BigBoot. Docker Compose (single container with Docker socket access). Define monitors via container labels, JSON/TOML files, or Kubernetes CRDs. No manual Uptime Kuma UI configuration needed. Supports Uptime Kuma v1 and v2."
---

# AutoKuma

**Automates Uptime Kuma monitor creation from Docker container labels.** Add `kuma.*` labels to your Docker Compose services and AutoKuma automatically creates, updates, and deletes the corresponding monitors in your Uptime Kuma instance — no manual UI work required. MIT license.

Built + maintained by **BigBoot**.

- Upstream repo: <https://github.com/BigBoot/AutoKuma>
- Playground: <https://autokuma-playground.bigboot.dev>
- GHCR image: `ghcr.io/bigboot/autokuma:latest`

## Architecture in one minute

- Single Rust binary / Docker container
- Reads monitor definitions from Docker container labels (primary), JSON/TOML static files, or Kubernetes CRDs
- Connects to Uptime Kuma via its WebSocket API
- Requires access to the Docker socket (`/var/run/docker.sock`) to read labels
- No database; stateless (monitor state is authoritative in Uptime Kuma)

## Compatible install methods

| Method | Notes |
|--------|-------|
| **Docker Compose** | **Primary** — add alongside your existing stack |
| Pre-built binary | Linux x64/arm64; Windows x64 — from GitHub Releases |
| Kubernetes | CRD-based source (experimental, community-maintained) |

## Inputs to collect

| Input | Env var | Notes |
|-------|---------|-------|
| Uptime Kuma URL | `AUTOKUMA__KUMA__URL` | e.g. `http://uptime-kuma:3001` |
| Uptime Kuma username | `AUTOKUMA__KUMA__USERNAME` | Required unless Uptime Kuma auth is disabled |
| Uptime Kuma password | `AUTOKUMA__KUMA__PASSWORD` | Required unless auth is disabled |
| MFA token | `AUTOKUMA__KUMA__MFA_TOKEN` | Required only if MFA is enabled |
| Docker socket | volume mount | `/var/run/docker.sock:/var/run/docker.sock` |

## Install via Docker Compose

Add AutoKuma to your existing `docker-compose.yml`:

```yaml
services:
  autokuma:
    image: ghcr.io/bigboot/autokuma:latest   # For Uptime Kuma v2
    # image: ghcr.io/bigboot/autokuma:uptime-kuma-v1-latest  # For Uptime Kuma v1
    restart: unless-stopped
    environment:
      AUTOKUMA__KUMA__URL: http://uptime-kuma:3001
      AUTOKUMA__KUMA__USERNAME: admin
      AUTOKUMA__KUMA__PASSWORD: your-password
      # Optional: customize the tag AutoKuma applies to managed monitors
      # AUTOKUMA__TAG_NAME: AutoKuma
      # AUTOKUMA__TAG_COLOR: "#42C0FB"
      # Optional: apply default settings to all generated monitors
      # AUTOKUMA__DEFAULT_SETTINGS: |-
      #   http.max_redirects: 10
      #   *.max_retries: 3
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - autokuma-data:/data

volumes:
  autokuma-data:
```

## Defining monitors via container labels

Once AutoKuma is running, annotate any container with `kuma.<id>.<type>.<field>: <value>` labels:

### HTTP monitor example

```yaml
services:
  my-web-app:
    image: nginx
    labels:
      kuma.my-web-app_http.http.name: My Web App
      kuma.my-web-app_http.http.url: https://my-web-app.example.com
      kuma.my-web-app_http.http.interval: 60
```

### Docker container monitor example

```yaml
services:
  my-app:
    image: my-app:latest
    labels:
      kuma.my-app.docker.name: My App Container
      kuma.my-app.docker.docker_container: my-app
```

Label key format: `kuma.<unique-id>.<monitor-type>.<field>`

- `<unique-id>`: Arbitrary identifier used internally to track this monitor
- `<monitor-type>`: Uptime Kuma monitor type (e.g., `http`, `docker`, `ping`, `dns`, `tcp`)
- `<field>`: Uptime Kuma monitor field name

## Snippets (DRY monitor templates)

Define reusable monitor templates via `AUTOKUMA__SNIPPETS__<name>`:

```yaml
environment:
  AUTOKUMA__SNIPPETS__WEB: |-
    {{container_name}}_http.http.name: {{container_name}} HTTP
    {{container_name}}_http.http.url: https://{{ args[0] }}
    {{container_name}}_docker.docker.name: {{container_name}} Docker
    {{container_name}}_docker.docker.docker_container: {{container_name}}
```

Then use the snippet from a container label:

```yaml
labels:
  kuma.__snippet.web: my-app.example.com
```

## Static monitor files

Place `.json` or `.toml` monitor definition files in the `autokuma-data` volume path (set `AUTOKUMA__STATIC_MONITORS` to the directory path):

```toml
# /data/monitors/my-website.toml
[my-website_http]
type = "http"
name = "My Website"
url = "https://example.com"
interval = 60
```

## Key configuration variables

| Env var | Default | Description |
|---------|---------|-------------|
| `AUTOKUMA__KUMA__URL` | — | Uptime Kuma URL |
| `AUTOKUMA__KUMA__USERNAME` | — | Uptime Kuma login username |
| `AUTOKUMA__KUMA__PASSWORD` | — | Uptime Kuma login password |
| `AUTOKUMA__TAG_NAME` | `AutoKuma` | Tag applied to all AutoKuma-managed monitors |
| `AUTOKUMA__TAG_COLOR` | `#42C0FB` | Color of the AutoKuma tag in Uptime Kuma |
| `AUTOKUMA__ON_DELETE` | `delete` | What to do when a label disappears: `delete` or `keep` |
| `AUTOKUMA__DELETE_GRACE_PERIOD` | `0` | Seconds to wait before deleting a monitor after label removal |
| `AUTOKUMA__DOCKER__LABEL_PREFIX` | `kuma` | Prefix for container label scanning |
| `AUTOKUMA__STATIC_MONITORS` | — | Path to directory with static monitor definition files |

## Uptime Kuma version compatibility

| Image tag | Uptime Kuma version |
|-----------|---------------------|
| `ghcr.io/bigboot/autokuma:latest` | v2.x |
| `ghcr.io/bigboot/autokuma:uptime-kuma-v1-latest` | v1.x |

## Updating

```bash
docker compose pull
docker compose up -d
```
