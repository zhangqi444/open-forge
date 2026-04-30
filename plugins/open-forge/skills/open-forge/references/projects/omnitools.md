---
name: OmniTools
description: Self-hosted web app offering hundreds of online "utility" tools — image/video/audio/PDF converters, text transformers, JSON/YAML tools, calculators, QR/barcode, encoding/hashing. 100% client-side processing (no file leaves your browser). Static SPA. ~28 MB Docker image. MIT.
---

# OmniTools

OmniTools is the self-hosted answer to "I need a quick utility tool — a JSON formatter, an image resizer, a PDF splitter, a password generator — but I don't want to paste my data into randomwebsite.com." It bundles **hundreds of small utility tools into a single web app**, all running **100% in your browser** — files never leave your device.

Categories:

- **Image/Video/Audio** — resizer, converter, editor, video trimmer, video reverser
- **PDF** — splitter, merger, editor, extract text/images
- **Text** — case converter, lorem ipsum, word counter, regex tester, diff, ASCII-art
- **JSON / YAML / XML / CSV** — validate, format, convert, flatten, escape/unescape
- **Numbers / math** — calculators, converters, random generators
- **Encoding / crypto** — base64, URL encode, hashing (MD5, SHA-1/256/512), JWT decode
- **Dev tools** — cURL generator, SQL formatter, HTML/CSS/JS minify, UUID, timestamps
- **Graphics / color** — color picker, palette generator, hex/RGB/HSL converters
- **QR / barcode** — generator + decoder
- **Time** — timezone converter, stopwatch, countdown
- **...and growing** — community-contributed tool plugins

- Upstream repo: <https://github.com/iib0011/omni-tools>
- Website: <https://omnitools.app> (demo / hosted version)
- Docker Hub: <https://hub.docker.com/r/iib0011/omni-tools>
- Discord: <https://discord.gg/SDbbn3hT4b>

## Architecture in one minute

- **Pure static SPA** — built from React/TypeScript/Vite
- **No backend** — everything runs in the browser (WebAssembly for heavier stuff: FFmpeg, ImageMagick, pdf.js)
- **Docker image is just nginx serving the static build** (~28 MB)
- **No database, no persistent state server-side**
- Trivial to host — basically a fancy static website

## Compatible install methods

| Infra       | Runtime                                   | Notes                                                               |
| ----------- | ----------------------------------------- | ------------------------------------------------------------------- |
| Single VM   | Docker (`iib0011/omni-tools`)               | **Simplest**                                                          |
| Single VM   | Any static-file web server                   | nginx, Caddy, Apache — just serve the built assets                       |
| Kubernetes  | Minimal nginx pod + PVC (no PVC needed)        | Stateless                                                                 |
| Edge/CDN    | Cloudflare Pages / Netlify / Vercel / GitHub Pages | Serve the build output directly                                            |
| NAS         | Synology / QNAP Docker                             | Tiny footprint                                                                 |
| Raspberry Pi | ARMv7/arm64 Docker                                 | Runs fine                                                                          |

## Inputs to collect

| Input        | Example                      | Phase    | Notes                                        |
| ------------ | ---------------------------- | -------- | -------------------------------------------- |
| Port         | `80` or `3000`                | Network  | Behind reverse proxy with TLS optional         |
| Domain       | `tools.example.com`            | URL      | Personal / team tools hub                         |
| TLS          | Let's Encrypt                   | Security | Optional — nothing crosses the network anyway     |
| Access control | IP allowlist / VPN / Basic auth | Security | Optional — most people leave it open             |

## Install via Docker

```sh
docker run -d --name omnitools \
  --restart unless-stopped \
  -p 8080:80 \
  iib0011/omni-tools:0.6.x    # pin specific version; check Docker Hub
```

Browse `http://<host>:8080`. That's it.

## Install via Docker Compose

```yaml
services:
  omnitools:
    image: iib0011/omni-tools:0.6.x
    container_name: omnitools
    restart: unless-stopped
    ports:
      - "8080:80"
```

Front with Caddy for TLS (optional):

```
tools.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

## Install as static files

```sh
# Grab the latest release's `dist` directory from GitHub Releases
wget https://github.com/iib0011/omni-tools/releases/download/vX.Y.Z/omni-tools-vX.Y.Z.tar.gz
tar -xzf omni-tools-vX.Y.Z.tar.gz -C /var/www/omnitools

# Any static server works:
# nginx -> root /var/www/omnitools;
# Caddy file_server
# Python's http.server for quick test: python3 -m http.server 8080
```

## Build from source

```sh
git clone https://github.com/iib0011/omni-tools.git
cd omni-tools
pnpm install
pnpm build
# Output in dist/
# Serve dist/ with any static server
```

## Data & config layout

**None on the server.** OmniTools is pure client-side. Any state (input text, uploaded images in the browser) lives only in your browser tab and disappears when you close it.

localStorage may persist a few user prefs (theme, recently-used tools).

## Backup

Nothing to back up. The Docker image is deterministic from a version tag.

If you customized the build, back up your fork of the source.

## Upgrade

1. Releases: <https://github.com/iib0011/omni-tools/releases>. Very active.
2. `docker compose pull && docker compose up -d`. No state, no migrations. Zero downtime if you run two instances.
3. New tools are added frequently — check release notes for "new tool: X".

## Gotchas

- **Truly client-side, truly no server processing.** The server never sees your files. The only time a request hits OmniTools backend is the initial page load + asset downloads. After that, everything is browser JS/WASM.
- **Big files stress the browser**, not the server. Converting a 4K video to GIF in the browser = your laptop's CPU/RAM. OmniTools cannot offload to a server because there is no server (by design).
- **WebAssembly modules are large** — FFmpeg-wasm, ImageMagick-wasm, pdf.js. First page load is ~25 MB of JS/WASM. CDN caching + service worker make subsequent visits fast.
- **Some tools depend on browser features** — WebGL, Web Audio, File System Access API, Clipboard API. Older browsers may fail to load specific tools.
- **Privacy stance is the selling point** — this is the "I don't trust random online PDF converters" replacement. For sensitive data (HIPAA-scoped PDFs, corp IP), OmniTools is a strictly better choice than SaaS tools. But:
- **You still trust the JavaScript** — a compromised build (supply-chain attack) could exfiltrate data. Running your own build (or a pinned Docker tag) mitigates this.
- **Not a workflow automation tool** — OmniTools is "one-shot" tools: paste → process → download. For batch processing, use CLI tools (ImageMagick, ffmpeg, jq, yq, etc.) directly.
- **No user accounts** — no per-user history, no favorites (beyond localStorage). This is a tool, not a product.
- **Docker image is tiny (~28 MB)** — one of the smallest "self-hosted app" images you'll find. Resource use is nearly zero at idle (just nginx serving static files).
- **PWA installable** — install as a home-screen app on phones; most tools work offline after first load.
- **Tool count grows** — new tools added regularly via PRs. If you need a specific utility, check releases or submit a PR.
- **Alternative hosting**: use Cloudflare Pages / Netlify / Vercel / GitHub Pages to host the build output for free with a custom domain. Nothing in OmniTools needs a "real" server.
- **"Small tools" category is competitive**:
  - **ittools.tech** (also OSS at <https://github.com/CorentinTh/it-tools>) — similar developer-tools collection, a bit more dev-focused
  - **devtoys (Windows)** — native Windows app; not web
  - **UtilsOps** — broader
  - Many niche single-purpose tools (json-crack, jsoncrack, cyberchef)
- **CyberChef** is another OSS utility-tool beast (by GCHQ!) — more focused on data-manipulation / crypto / forensics. Very different UX but overlapping use cases.
- **MIT license** — permissive.
- **Alternatives worth knowing:**
  - **it-tools** — devs-focused (JSON, regex, JWT, UUID, curl, base64, JWT) — smaller scope, nicer UX for developers
  - **CyberChef** — forensics-grade; chainable operations; MIT; from GCHQ
  - **Smallpdf / ILovePDF** — SaaS; convenient but sends files to their servers
  - **JSONCrack** — JSON-specific visualization tool
  - **Any CLI** — `jq`, `yq`, `ffmpeg`, `imagemagick`, `gm`, `pdftk`, `qpdf` — scriptable, deterministic, probably already on your server
  - **Choose OmniTools if:** you want a broad one-stop utility hub + privacy + trivially-hostable.
  - **Choose it-tools if:** you're a developer; similar philosophy, more dev-focused tools.
  - **Choose CyberChef if:** you need chainable crypto/forensics/data operations.

## Links

- Repo: <https://github.com/iib0011/omni-tools>
- Hosted demo: <https://omnitools.app>
- Docker Hub: <https://hub.docker.com/r/iib0011/omni-tools>
- Releases: <https://github.com/iib0011/omni-tools/releases>
- Discord: <https://discord.gg/SDbbn3hT4b>
- Similar: <https://github.com/CorentinTh/it-tools> (it-tools)
- Similar: <https://github.com/gchq/CyberChef> (CyberChef)
- FFmpeg-wasm: <https://ffmpegwasm.netlify.app>
- Trendshift: <https://trendshift.io/repositories/13055>
