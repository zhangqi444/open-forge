---
name: it-tools-by-sharevb
description: IT Tools (sharevb fork) recipe for open-forge. Collection of handy online tools for developers — hash generators, encoders/decoders, formatters, crypto utilities, network tools, and more. Active community fork of CorentinTh/it-tools with 192+ additional PRs merged. Docker-first deployment. Source: https://github.com/sharevb/it-tools
---

# IT Tools (sharevb fork)

Active community fork of the popular IT Tools developer utility collection by CorentinTh. Provides 100+ handy browser-based tools: hash generators, base64 encoders, JWT decoders, UUID generators, cron expression parsers, color converters, regex testers, crypto utilities, network tools, and much more. No backend — all tools run client-side in the browser. Docker image served via nginx. Upstream: https://github.com/sharevb/it-tools. Demo: https://sharevb-it-tools.vercel.app/.

> **Note**: This is a fork. The original project is https://github.com/CorentinTh/it-tools — the fork includes ~192 additional PRs not yet merged upstream, more tools, full UI translation, and bug fixes.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker | Linux / macOS / Windows | Recommended. Single container, no DB. |
| Docker Compose | Linux / macOS | Multi-service setup |
| Static build (npm) | Any | Build and serve with any web server |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| deploy | "Port to expose?" | Default: 8080 (container listens on 8080, not 80) |
| optional | "Custom port via env?" | Use `-e PORT=8888` to override listen port |

## Software-layer concerns

### Docker run

  docker run --pull always --restart unless-stopped \
    -p 8080:8080 \
    sharevb/it-tools:latest

  # English-only image:
  docker run --pull always --restart unless-stopped \
    -p 8080:8080 \
    sharevb/it-tools:latest-en

  # Custom port:
  docker run --pull always --restart unless-stopped \
    -p 9090:9090 \
    -e PORT=9090 \
    sharevb/it-tools:latest

### Docker Compose

  services:
    it-tools:
      container_name: it-tools
      image: sharevb/it-tools:latest
      pull_policy: always
      restart: unless-stopped
      ports:
        - 8080:8080

  # Run:
  docker compose up -d

### Podman Quadlet

  # /etc/containers/systemd/it-tools.container
  [Unit]
  Description=IT Tools container

  [Container]
  Image=sharevb/it-tools:latest
  PublishPort=8080:8080
  AutoUpdate=registry
  Restart=always

  [Install]
  WantedBy=default.target

### Alternative image (GitHub Container Registry)

  ghcr.io/sharevb/it-tools:latest

### Build from source

  git clone https://github.com/sharevb/it-tools.git
  cd it-tools
  npm install
  npm run build
  # Serve the build/ directory with any static web server

  # Development server:
  npm start
  # Opens at http://localhost:8000

### Ports

  8080/tcp   # Web UI (default)

### IPv6

  # IPv6 support requires enabling it on the host first.
  # Or mount a custom nginx.conf without the `listen [::]:8080;` line:
  docker run ... -v "./nginx.conf:/etc/nginx/templates/default.conf.template" ...

## Upgrade procedure

  # Docker:
  docker pull sharevb/it-tools:latest
  docker stop it-tools && docker rm it-tools
  # Re-run docker run command

  # Docker Compose:
  docker compose pull && docker compose up -d

## Gotchas

- **Port changed to 8080**: the base image switched to `nginx-unprivileged`, which listens on **8080** (not 80). Update any port mappings from `8080:80` to `8080:8080`.
- **No authentication**: IT Tools is a public-facing static app with no login. If deployed on a public IP, anyone can access it. Use a reverse proxy with auth (Basic Auth, OAuth2-proxy, etc.) if needed.
- **All computation is client-side**: no data leaves the browser. Tools like PGP encryption use the WebCrypto API, which requires HTTPS. HTTP-only deployments will break those tools.
- **HTTPS recommended even internally**: some tools (PGP, crypto) require WebCrypto, which browsers only expose over HTTPS. Use a reverse proxy with TLS even on a LAN.
- **Fork vs upstream**: this fork (`sharevb/it-tools`) is more actively maintained than the original (`CorentinTh/it-tools`) as of 2024. The original has slowed down; the fork has merged 192+ additional PRs.

## References

- Fork GitHub: https://github.com/sharevb/it-tools
- Original upstream: https://github.com/CorentinTh/it-tools
- Docker Hub image: https://hub.docker.com/r/sharevb/it-tools
- GitHub Container Registry: https://github.com/sharevb/it-tools/pkgs/container/it-tools
- Demo: https://sharevb-it-tools.vercel.app/
