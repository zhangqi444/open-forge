---
name: yopass
description: Yopass recipe for open-forge. Covers Docker Compose (behind reverse proxy) and Docker Compose with bundled nginx + Let's Encrypt. Yopass is a one-time secret sharing tool with end-to-end OpenPGP encryption in-browser — no accounts, no plaintext storage.
---

# Yopass

One-time secret and file sharing with end-to-end encryption. Secrets are encrypted in the browser using OpenPGP before being sent to the server — the decryption key never leaves your machine. Each secret gets a one-time URL that expires automatically. No accounts, no tracking, no plaintext storage. Upstream: <https://github.com/jhaals/yopass>. Demo: <https://yopass.se>.

**License:** Apache-2.0 · **Language:** Go + React · **Default port:** 80 · **Stars:** ~2,800

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (behind reverse proxy) | <https://github.com/jhaals/yopass/tree/master/deploy/docker-compose/insecure> | ✅ | When you already have nginx/Caddy handling TLS. Simplest setup. |
| Docker Compose + nginx + Let's Encrypt | <https://github.com/jhaals/yopass/tree/master/deploy/with-nginx-proxy-and-letsencrypt> | ✅ | Bundled TLS stack — good for a standalone server with no existing proxy. |
| Docker (standalone) | <https://github.com/jhaals/yopass#docker> | ✅ | Manual TLS + Redis setup without Compose. |
| Kubernetes | <https://github.com/jhaals/yopass/tree/master/deploy/kubernetes> | ✅ | Helm-style manifests for cluster deployments. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method — behind existing proxy, or bundled nginx+LetsEncrypt?" | AskUserQuestion | Drives which section below. |
| domain | "What domain will Yopass be served on?" | Free-text | Both Docker Compose methods. |
| tls | "TLS email for Let's Encrypt expiration notices?" | Free-text | Bundled nginx+LetsEncrypt method only. |
| storage | "Use Redis (default) or Memcached as backend storage?" | AskUserQuestion: Redis / Memcached | Both methods — Redis is default in upstream Compose files. |
| expiry | "Default secret max-expiry (hours/days/weeks) — or leave as upstream default?" | Free-text | Optional config tweak. |

## Install — Docker Compose (behind existing reverse proxy)

Reference: <https://github.com/jhaals/yopass/tree/master/deploy/docker-compose/insecure>

```bash
git clone https://github.com/jhaals/yopass.git
cd yopass/deploy/docker-compose/insecure
docker compose up -d
```

Yopass listens on `127.0.0.1:80`. Point your reverse proxy (nginx/Caddy) to that address.

Example nginx location block:

```nginx
server {
    listen 443 ssl;
    server_name secrets.example.com;

    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Install — Docker Compose + bundled nginx + Let's Encrypt

Reference: <https://github.com/jhaals/yopass/tree/master/deploy/with-nginx-proxy-and-letsencrypt>

```bash
git clone https://github.com/jhaals/yopass.git
cd yopass/deploy/with-nginx-proxy-and-letsencrypt
```

Edit `docker-compose.yml` and replace the three placeholder values:

| Variable | Value |
|---|---|
| `VIRTUAL_HOST` | `secrets.example.com` |
| `LETSENCRYPT_HOST` | `secrets.example.com` |
| `LETSENCRYPT_EMAIL` | `admin@example.com` |

Then:

```bash
# Point your domain DNS to this server's IP first
docker compose up -d
```

Yopass will be available at `https://secrets.example.com` with auto-renewing TLS.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Backend storage | Redis (default) or Memcached — stores encrypted secret blobs temporarily. Secrets auto-expire; no permanent storage. |
| Encryption | OpenPGP in-browser; server never sees the plaintext or decryption key. |
| Port | Default 80 (HTTP, for reverse proxy); 443 with bundled TLS stack. |
| Auth | None — Yopass is public by design. Restrict access at the proxy level if needed. |
| Secret expiry | Configurable per-secret (1 hour to 1 week); backend enforces TTL via Redis/Memcached TTL. |
| File uploads | Supported — files are chunked and encrypted in-browser before upload. |
| CLI | `yopass` binary available for terminal-based secret sharing against your self-hosted instance. |
| No accounts | Intentional — no user management, no persistent data beyond TTL'd blobs. |

## Upgrade procedure

```bash
cd yopass
git pull
cd deploy/docker-compose/insecure   # or your chosen deploy path
docker compose pull
docker compose up -d
```

No data migration required — all secrets are ephemeral and self-expire.

## Gotchas

- **DNS must point to server before starting bundled TLS stack:** The Let's Encrypt challenge requires the domain to resolve to the host. Start nginx+LE after DNS propagates.
- **No auth by default:** Yopass is intentionally open. If you don't want anyone on the internet to create secrets on your instance, add IP allowlisting or basic auth at the reverse proxy.
- **Redis data is ephemeral:** Secrets expire via Redis TTL. If Redis restarts without persistence, any unexpired secrets are lost — but this is by design (ephemeral sharing).
- **HTTPS required for full browser encryption:** The OpenPGP Web Crypto API requires a secure context. Don't serve Yopass over plain HTTP in production.
- **File size limits:** Large file uploads are constrained by Redis memory and browser encryption performance. For very large files, consider an alternative.

## Upstream links

- GitHub: <https://github.com/jhaals/yopass>
- Docker Compose (insecure/proxy): <https://github.com/jhaals/yopass/tree/master/deploy/docker-compose/insecure>
- Docker Compose (nginx+LE): <https://github.com/jhaals/yopass/tree/master/deploy/with-nginx-proxy-and-letsencrypt>
- Public demo: <https://yopass.se>
