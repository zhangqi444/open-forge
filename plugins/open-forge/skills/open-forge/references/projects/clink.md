---
name: clink
description: clink recipe for open-forge. Super-minimal URL shortener written in pure C, focusing on small executable size, portability, and ease of configuration. AGPL-3.0. Source: https://git.crueter.xyz/crueter/clink
---

# clink

A super-minimal URL shortening service written in pure C. Focuses on small executable size, portability, and ease of configuration. No database required. AGPL-3.0 licensed. Upstream: <https://git.crueter.xyz/crueter/clink>. Demo: <https://short.crueter.xyz>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Native C binary | Build from source; no Docker image provided |
| Any Linux | With reverse proxy | NGINX/Caddy recommended for HTTPS |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for the URL shortener?" | FQDN | e.g. short.example.com |
| "Port to listen on?" | Number | Configured at build/run time |
| "Storage for shortened URLs?" | Directory path | File-based — no database |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Reverse proxy?" | NGINX / Caddy / none | Recommended for HTTPS and domain routing |

## Software-Layer Concerns

- **Pure C**: No runtime dependencies beyond libc — tiny binary, very portable.
- **File-based storage**: Shortened URLs stored as flat files — no database required.
- **Minimal feature set**: By design — basic URL shortening only. No analytics, no dashboards, no user accounts.
- **Self-hosted Gitea**: Source hosted on a self-hosted Gitea instance (git.crueter.xyz), not GitHub/GitLab.
- **Build from source**: No pre-built binaries or Docker images — requires C compiler (gcc/clang) and make.

## Deployment

### Build from source

```bash
# Clone from upstream Gitea instance
git clone https://git.crueter.xyz/crueter/clink.git
cd clink

# Build
make

# Install binary
sudo install -m755 clink /usr/local/bin/clink

# Run (check README for config options and flags)
clink --port 8080 --data /var/lib/clink/
```

### NGINX reverse proxy

```nginx
server {
    listen 443 ssl;
    server_name short.example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### systemd service

```ini
[Unit]
Description=clink URL shortener
After=network.target

[Service]
ExecStart=/usr/local/bin/clink --port 8080 --data /var/lib/clink/
Restart=on-failure
User=clink

[Install]
WantedBy=multi-user.target
```

## Upgrade Procedure

1. `git pull` from upstream.
2. `make` to rebuild.
3. Stop service, replace binary, restart.
4. Shortened URL data in `--data` directory persists across upgrades.

## Gotchas

- **Build required**: No pre-built binaries — must compile from source with a C toolchain.
- **Self-hosted upstream**: Source is on a self-hosted Gitea at git.crueter.xyz — if that instance goes offline, source access is interrupted. Consider forking.
- **Minimal by design**: No auth, no analytics, no management UI — suitable for personal or small private use. Not for multi-user public deployments without additional protection.
- **Check upstream README**: Config flags and storage format are best confirmed from the current README at https://git.crueter.xyz/crueter/clink — the project is small and details may change.

## Links

- Source: https://git.crueter.xyz/crueter/clink
- Demo: https://short.crueter.xyz
