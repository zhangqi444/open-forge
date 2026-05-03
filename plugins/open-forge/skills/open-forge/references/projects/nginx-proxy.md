---
name: nginx-proxy
description: Automated Docker reverse proxy — watches the Docker socket and auto-generates nginx vhost config for any container with a `VIRTUAL_HOST` env var.
---

# nginx-proxy

`nginx-proxy` bundles nginx + [docker-gen](https://github.com/nginx-proxy/docker-gen) in a single container. docker-gen listens to Docker events, renders an nginx vhost template for each running container that declares `VIRTUAL_HOST`, and signals nginx to reload. It's the classic "just put my containers online on port 80" reverse proxy. Pair with the official [acme-companion](https://github.com/nginx-proxy/acme-companion) for automatic Let's Encrypt.

- Upstream repo: <https://github.com/nginx-proxy/nginx-proxy>
- ACME companion: <https://github.com/nginx-proxy/acme-companion>
- Docs: <https://github.com/nginx-proxy/nginx-proxy/tree/main/docs>
- Image: `nginxproxy/nginx-proxy` on Docker Hub (Debian) and `nginxproxy/nginx-proxy:<ver>-alpine`

## Compatible install methods

| Infra              | Runtime                                       | Notes                                                              |
| ------------------ | --------------------------------------------- | ------------------------------------------------------------------ |
| Single Docker host | Docker / Compose (single container)           | Default; mounts `/var/run/docker.sock` read-only                   |
| Single Docker host | Separate `nginx` + `docker-gen` + `acme-companion` | Three-container pattern — lets you use the official nginx image |
| Multi-host / Swarm | Not supported natively                        | docker-gen only sees events from the local daemon                   |
| Kubernetes         | Use ingress-nginx instead                     | `nginx-proxy` is not designed for K8s                              |

## Inputs to collect

| Input                  | Example                                    | Phase     | Notes                                                                    |
| ---------------------- | ------------------------------------------ | --------- | ------------------------------------------------------------------------ |
| Exposed ports          | 80/tcp (+ 443/tcp for TLS)                 | Network   | Hostside ports for the proxy container                                   |
| DNS                    | `A <host> → your VM IP`                    | DNS       | Plus any subdomains you plan to `VIRTUAL_HOST` against                   |
| TLS strategy           | acme-companion / own certs / none          | TLS       | For LE, deploy `acme-companion` alongside                                 |
| Image pin              | `nginxproxy/nginx-proxy:1.10.1`              | Install   | **Never use `:latest` or `:alpine` in production** — per upstream README |
| Shared network         | bridge network                             | Runtime   | Proxied containers must share a docker network with nginx-proxy          |

## Install via Docker Compose (single-container, most common)

Upstream's minimal compose (at <https://github.com/nginx-proxy/nginx-proxy/blob/main/docker-compose.yml>), adapted with a pinned tag:

```yaml
services:
  nginx-proxy:
    image: nginxproxy/nginx-proxy:1.10.1   # pin; see releases for latest
    container_name: nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - certs:/etc/nginx/certs:ro
      - vhost:/etc/nginx/vhost.d
      - html:/usr/share/nginx/html
    restart: unless-stopped

  # Example proxied app — declares VIRTUAL_HOST:
  whoami:
    image: jwilder/whoami
    expose:
      - "8000"
    environment:
      VIRTUAL_HOST: whoami.example.com
      VIRTUAL_PORT: "8000"
      # For HTTPS via acme-companion:
      LETSENCRYPT_HOST: whoami.example.com
      LETSENCRYPT_EMAIL: admin@example.com

volumes:
  certs:
  vhost:
  html:
```

### Adding Let's Encrypt (acme-companion)

```yaml
  acme-companion:
    image: nginxproxy/acme-companion:2.6.3
    container_name: acme-companion
    volumes_from:
      - nginx-proxy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - acme:/etc/acme.sh
    environment:
      DEFAULT_EMAIL: admin@example.com
    restart: unless-stopped
```

Proxied containers then set `LETSENCRYPT_HOST` (and optionally `LETSENCRYPT_EMAIL`) alongside `VIRTUAL_HOST`. acme-companion ensures certs appear in the shared `certs` volume and nginx-proxy picks them up automatically.

See the full guide: <https://github.com/nginx-proxy/acme-companion/blob/main/docs/Let's-Encrypt-and-ACME.md>.

### Separate-containers variant

If you'd rather use the official `nginx` image (and keep docker-gen in its own container), see <https://github.com/nginx-proxy/nginx-proxy/blob/main/docker-compose-separate-containers.yml>. The key: docker-gen gets the socket + a shared `nginx_conf` volume, nginx only mounts that volume read-only.

## How containers advertise themselves

Set on the **proxied** container:

- `VIRTUAL_HOST=app.example.com` — required; can be comma-sep multi-host
- `VIRTUAL_PORT=8000` — pick the container-internal port to proxy to (auto-detected if the container `EXPOSE`s exactly one port)
- `VIRTUAL_PATH=/api/` — optional path routing
- `VIRTUAL_PROTO=https` — upstream uses HTTPS instead of HTTP
- `HTTPS_METHOD=redirect|noredirect|nohttp|nohttps` — per-vhost HTTPS policy
- `LETSENCRYPT_HOST` / `LETSENCRYPT_EMAIL` — acme-companion inputs

Full reference: <https://github.com/nginx-proxy/nginx-proxy/blob/main/docs/README.md>.

## Data & config layout

- `/etc/nginx/certs/` — certs (injected by acme-companion or bind-mounted)
- `/etc/nginx/vhost.d/` — per-vhost custom snippets (e.g. client_max_body_size)
- `/etc/nginx/conf.d/` — generated vhost configs (rewritten on every container event)
- `/usr/share/nginx/html/` — shared ACME http-01 challenge dir

Back up `certs/` + `vhost.d/` (or just snapshot volumes) — `conf.d/` is regenerated on every boot.

## Upgrade

1. Read release notes: <https://github.com/nginx-proxy/nginx-proxy/releases> (and <https://github.com/nginx-proxy/acme-companion/releases>).
2. Bump the image tag in compose; `docker compose pull && docker compose up -d`.
3. Template changes occasionally require updating custom per-vhost snippets in `vhost.d/`.

## Gotchas

- **Do not use `:latest` or `:alpine`** in production. Upstream README explicitly calls this out — those tags float with `main` and can pull in breaking changes. Always pin (e.g. `:1.10`).
- **Docker socket access = root-equivalent on the host.** Treat the nginx-proxy container's boundary as trusted. Mount the socket `:ro` (reads still expose enough to pivot; be aware).
- **Proxied container must share a docker network** with nginx-proxy. If you use a custom network, either attach nginx-proxy to it or use `network_mode: bridge` on both.
- **Port in `VIRTUAL_HOST` is not supported.** Use `VIRTUAL_PORT` env var instead; or use the "virtual ports" feature for exposing the same vhost on multiple external ports (<https://github.com/nginx-proxy/nginx-proxy/tree/main/docs#virtual-ports>).
- **Proxied containers must `EXPOSE`** the target port (either in their Dockerfile or via `expose:` in compose). Published ports aren't required.
- **Trusting downstream proxies.** If nginx-proxy itself is behind another proxy (e.g. Cloudflare), set `TRUST_DOWNSTREAM_PROXY=true` and define `SET_REAL_IP_FROM` so `X-Forwarded-For` passes through correctly.
- **Large uploads** fail silently at 1 MB by default. Drop a snippet in `vhost.d/<host>`:

  ```nginx
  client_max_body_size 100M;
  ```
- **Basic auth per-host** via an `htpasswd` file in `/etc/nginx/htpasswd/<host>` — see upstream docs.
- **ACME rate limits.** acme-companion uses Let's Encrypt production by default; for testing set `ACME_CA_URI` to the staging endpoint.
- **Multiple containers claiming the same `VIRTUAL_HOST`** will round-robin load-balance — intentional, but surprising if you typo a hostname.
- **IPv6** requires `ENABLE_IPV6=true` on the nginx-proxy container AND the docker daemon started with IPv6 support.
- **Not for Swarm / K8s.** docker-gen only sees events from a single daemon. Use Traefik / ingress-nginx for orchestrators.

## Links

- Main docs: <https://github.com/nginx-proxy/nginx-proxy/tree/main/docs>
- ACME companion: <https://github.com/nginx-proxy/acme-companion>
- Releases (proxy): <https://github.com/nginx-proxy/nginx-proxy/releases>
- Releases (acme): <https://github.com/nginx-proxy/acme-companion/releases>
- Image: <https://hub.docker.com/r/nginxproxy/nginx-proxy>
- Custom config cookbook: <https://github.com/nginx-proxy/nginx-proxy/blob/main/docs/README.md>
