---
name: it-tools-project
description: IT-Tools recipe for open-forge. GPL-3.0 collection of browser-based developer utilities (base64/JSON/JWT/hash/crypto/regex/date/network converters, 80+ tools total). Vue 3 SPA shipped as a single static nginx container — no backend, no database, no persistence, runs 100% client-side. Trivial to self-host: `docker run -p 8080:80 corentinth/it-tools`. This recipe covers the single-container install, reverse-proxy setup, the two official image registries (Docker Hub + ghcr.io), and the "all computation is client-side" security model.
---

# IT-Tools

GPL-3.0 collection of handy online tools for developers and IT folks. Upstream: <https://github.com/CorentinTh/it-tools>. Live demo: <https://it-tools.tech>.

80+ small utilities in one web UI:

- Text: base64, URL-encode, JSON prettify/minify, YAML ↔ JSON, XML formatter, JWT parser, Markdown preview, Slugify, case converter
- Crypto: hash (MD5/SHA-1/SHA-256/SHA-512), HMAC, bcrypt, UUID, Bip39 mnemonic, RSA keypair, PGP, JWT
- Network: IPv4/IPv6 subnet calculator, MAC address, URL parser, MIME type lookup
- Encoding: QR code, bar code, SVG → PNG, color converter, regex tester, cron parser
- Math: formatters, big-number arithmetic, temperature converter

**Everything runs client-side in the browser.** The container ships a Vue 3 SPA + nginx. No backend, no database, no state on the server. Once the page loads, IT-Tools could be served from a CDN with zero server involvement — the container just serves static HTML/JS/CSS.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `docker run` (Docker Hub) | README §Self host | ✅ | The canonical install — one command. |
| `docker run` (ghcr.io) | README §Self host | ✅ | Same image; use if Docker Hub is rate-limited or blocked. |
| Docker Compose | Trivial wrapper | ✅ | Nicer for managing alongside other containers. |
| Cloudron / Tipi / Unraid | App-store listings | ✅ (linked from README) | Turnkey managed hosts. |
| Source build (`pnpm install && pnpm build`) | Standard Vue 3 / Vite | ✅ | Custom modifications / air-gapped / embed in another site. |
| Static host (Netlify / Cloudflare Pages / S3+CloudFront) | Post-build `dist/` is static | ✅ | For "no-server" deploys. Upload `dist/` after `pnpm build`. |

## Inputs to collect

This is the simplest recipe in the whole forge. There's almost nothing to configure.

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-run` / `docker-compose` / `static-hosting` | Drives section. |
| ports | "Host port?" | Free-text, default `8080` | Maps to container's `80`. |
| dns | "Public domain (or skip for LAN)?" | Free-text | Only matters if exposing publicly. |
| tls | "Reverse proxy? (Caddy / nginx / Traefik / skip)" | `AskUserQuestion` | IT-Tools does not terminate TLS. |

There is **no** database config, env vars, secrets, auth, or persistent volume to set up.

## Install — `docker run`

```bash
# From Docker Hub
docker run -d --name it-tools \
  --restart unless-stopped \
  -p 8080:80 \
  corentinth/it-tools:latest

# From GitHub Container Registry
docker run -d --name it-tools \
  --restart unless-stopped \
  -p 8080:80 \
  ghcr.io/corentinth/it-tools:latest
```

Visit `http://<host>:8080` — done.

## Install — Docker Compose

```yaml
# compose.yaml
services:
  it-tools:
    image: corentinth/it-tools:latest
    container_name: it-tools
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:80"
```

```bash
docker compose up -d
```

## Install — Static hosting

```bash
git clone https://github.com/CorentinTh/it-tools.git
cd it-tools
pnpm install
pnpm build
# dist/ is now a pure-static site
```

Upload `dist/` to Netlify / Cloudflare Pages / S3+CloudFront / GitHub Pages / any static host.

## Reverse proxy

```caddy
tools.example.com {
    reverse_proxy it-tools:80
}
```

Or nginx:

```nginx
server {
    server_name tools.example.com;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    listen 443 ssl;
    # ...cert config...
}
```

## Data layout

**None.** There is no persistent state.

- No database.
- No user accounts.
- No config files worth backing up.
- Everything the user generates (hashes, QR codes, converted JSON) stays in their browser.

To "back up" IT-Tools = pin the image tag and record which version you deployed. That's it.

## Upgrade procedure

```bash
docker pull corentinth/it-tools:latest
docker rm -f it-tools
docker run -d --name it-tools --restart unless-stopped -p 8080:80 corentinth/it-tools:latest
# OR with compose:
docker compose pull && docker compose up -d
```

Breaking changes are extremely rare — it's a static site. A new version just means different/more tools in the UI.

## Gotchas

- **Client-side means "private by default" — but only if they reach the tools.** All computation happens in the user's browser. IT-Tools the server never sees the data being hashed/encoded/parsed. **However**, if users paste secrets into a third-party hosted instance (like <https://it-tools.tech>), they're trusting that instance's owner not to have modified the JavaScript. For secret-handling, always use your self-hosted copy.
- **No authentication.** By default, anyone who can reach the URL can use all tools. Usually fine (it's a developer utility, not a data store), but if you're exposing publicly you might want basic-auth at the reverse-proxy layer to avoid becoming a random stranger's QR-code generator.
- **GPL-3.0, not MIT/Apache.** If you fork + modify IT-Tools and distribute it, you must share source under GPL-3.0 as well. For internal self-host this doesn't matter.
- **No server-side features means no "recent items" / history.** Every browser tab is independent. If a user wants their tool state persisted, that's browser localStorage (some tools save state; most don't).
- **Image is hosted from author's personal accounts** (`corentinth/it-tools` on Docker Hub, `ghcr.io/corentinth/it-tools` on GHCR). Both are legitimate. If you're worried about supply-chain (one-developer project), pin to a specific version tag + audit the Dockerfile in the repo before every upgrade.
- **Alternatives listed in README** (Cloudron, Tipi, Unraid Community Apps) are third-party wrappers around the same image. Not endorsed/maintained by Corentin but kept in the README.
- **Cannot be run behind a subpath without a rebuild.** If you want `example.com/tools/` instead of `tools.example.com`, you have to rebuild with a Vite `base` config change — nginx rewrite alone won't work because the JS asset paths are baked in.
- **Homelab-ish project.** One maintainer, occasional updates. It's not going to suddenly grow enterprise SSO or history tracking. If you want those, IT-Tools isn't the right tool.

## Links

- Upstream repo: <https://github.com/CorentinTh/it-tools>
- Live instance: <https://it-tools.tech>
- Docker Hub: <https://hub.docker.com/r/corentinth/it-tools>
- GHCR: <https://github.com/CorentinTh/it-tools/pkgs/container/it-tools>
- Releases: <https://github.com/CorentinTh/it-tools/releases>
- Feature requests: <https://github.com/CorentinTh/it-tools/issues/new/choose>
