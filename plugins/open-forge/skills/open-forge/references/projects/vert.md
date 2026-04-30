---
name: VERT
description: Privacy-first file conversion utility that runs WebAssembly codecs in the browser — no file ever leaves your device for image/audio/document conversion. Optional companion daemon (`vertd`) handles video (FFmpeg on the server). SvelteKit frontend + Rust daemon. AGPL-3.0 (VERT) / GPL-3.0 (vertd).
---

# VERT

VERT (vert.sh) is a client-side file converter — you upload a file into your browser, WebAssembly-compiled codecs convert it locally, and the result downloads. No cloud, no size limits, 250+ format pairs. Think "CloudConvert but self-hosted and private by default".

Video is the exception: full browser-side video conversion is impractical, so a companion Rust daemon (`vertd`) wraps FFmpeg and handles video conversion on a server you control. VERT points at `vertd` via the `PUB_VERTD_URL` build arg.

- VERT repo: <https://github.com/VERT-sh/VERT>
- vertd repo: <https://github.com/VERT-sh/vertd>
- Public instance: <https://vert.sh>
- Docker docs (VERT): <https://github.com/VERT-sh/VERT/blob/main/docs/DOCKER.md>
- Docker docs (vertd): <https://github.com/VERT-sh/vertd/blob/main/docs/DOCKER_SETUP.md>

## Architecture in one minute

**VERT** is a static SvelteKit site served by nginx inside the container. **All config is baked in at build time** via `PUB_*` environment args — they become hardcoded constants in the generated JavaScript. Runtime env-var overrides do NOT work; you must rebuild the image if you change the hostname, Plausible URL, vertd URL, etc.

**vertd** is a separate Rust HTTP server (port 24153) that receives upload + conversion params, runs FFmpeg with hardware acceleration, and returns the result. It auto-detects GPU (NVIDIA / Intel / AMD / Apple) and falls back to CPU software encoding.

Two containers, two separate repos, two separate deploy lifecycles.

## Compatible install methods

| Infra              | Runtime                                         | Notes                                                                |
| ------------------ | ----------------------------------------------- | -------------------------------------------------------------------- |
| Single VM          | Docker (build from source)                      | **Recommended** — only way to customize `PUB_*` build args             |
| Single VM          | Docker (`ghcr.io/vert-sh/vert:latest`)          | Easiest, but stuck with upstream's bake-time URLs                     |
| Single VM (+GPU)   | Docker + vertd (Intel/AMD/NVIDIA)              | Required for practical video conversion                               |
| Single VM          | VERT only (no video)                            | Image/audio/doc conversion; video button disabled                     |
| Kubernetes         | Plain Deployment + GPU-enabled node for vertd  | Niche; possible                                                        |

## Inputs to collect

| Input                                     | Example                          | Phase         | Notes                                                          |
| ----------------------------------------- | -------------------------------- | ------------- | -------------------------------------------------------------- |
| `PUB_HOSTNAME` (VERT)                     | `vert.example.com`               | Build-time    | Where VERT is served from; baked into JS                        |
| `PUB_VERTD_URL` (VERT)                    | `https://vertd.example.com`      | Build-time    | URL vertd is reachable at; baked into JS                        |
| `PUB_ENV`                                 | `production`                     | Build-time    | Controls minification + debug flags                             |
| `PUB_DISABLE_ALL_EXTERNAL_REQUESTS`       | `true` / `false`                 | Build-time    | If `true`, disables Plausible + donation-link telemetry         |
| `PUB_PLAUSIBLE_URL`                       | `` (empty) or your Plausible URL | Build-time    | Leave empty for no analytics                                     |
| `PUB_DONATION_URL`                        | `` (empty)                       | Build-time    | Hide the donation button                                         |
| GPU for vertd                             | Intel iGPU / AMD / NVIDIA        | Runtime (vertd) | `/dev/dri` (Intel/AMD) or NVIDIA Container Toolkit             |
| Ports                                     | 3000 (VERT), 24153 (vertd)       | Network       | Behind TLS-terminating reverse proxy                             |

## Install VERT via upstream Docker Compose (prebuilt)

From <https://github.com/VERT-sh/VERT/blob/main/docker-compose.yml>:

```yaml
services:
  vert:
    container_name: vert
    image: ghcr.io/vert-sh/vert:latest
    restart: unless-stopped
    ports:
      - ${PORT:-3000}:80
```

This uses the upstream-published image — `PUB_HOSTNAME=localhost:5173` and `PUB_VERTD_URL=` are baked in, meaning video conversion won't work unless you're OK with the default vert.sh public vertd instance.

## Install VERT with custom build args (most common self-host path)

```sh
git clone https://github.com/VERT-sh/VERT
cd VERT

docker build -t vert-sh/vert:self-hosted \
  --build-arg PUB_ENV=production \
  --build-arg PUB_HOSTNAME=vert.example.com \
  --build-arg PUB_VERTD_URL=https://vertd.example.com \
  --build-arg PUB_PLAUSIBLE_URL= \
  --build-arg PUB_DONATION_URL= \
  --build-arg PUB_DISABLE_ALL_EXTERNAL_REQUESTS=true \
  --build-arg PUB_STRIPE_KEY= \
  .

docker run -d --restart unless-stopped \
  -p 3000:80 --name vert vert-sh/vert:self-hosted
```

Put a reverse proxy (Caddy / Traefik / nginx) in front on port 443 terminating TLS to `http://localhost:3000`.

## Install vertd via Docker Compose

From <https://github.com/VERT-sh/vertd/blob/main/docs/DOCKER_SETUP.md>:

```yaml
# Intel or AMD GPU:
services:
  vertd:
    image: ghcr.io/vert-sh/vertd:latest
    container_name: vertd
    restart: unless-stopped
    ports:
      - "24153:24153"
    devices:
      - /dev/dri       # VA-API for Intel/AMD
```

NVIDIA variant:

```yaml
services:
  vertd:
    image: ghcr.io/vert-sh/vertd:latest
    container_name: vertd
    restart: unless-stopped
    ports:
      - "24153:24153"
    runtime: nvidia
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

Prereq for NVIDIA: install [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html), then `sudo nvidia-ctk runtime configure --runtime=docker && sudo systemctl restart docker`.

CPU-only (no GPU available or for Docker Desktop on Windows/macOS):

```yaml
    environment:
      - VERTD_FORCE_GPU=cpu
```

Non-default VA-API device path (e.g. renderD129 for secondary GPUs):

```yaml
    environment:
      - VERTD_VAAPI_DEVICE_PATH=/dev/dri/renderD129
```

## Data & config layout

- **VERT** — stateless. No persistent data. Re-deploy anytime.
- **vertd** — stateless between conversions. Uploaded files stored in `/tmp` during processing and cleaned up. No volume needed for most setups.

All configuration for VERT is baked at build time (the `PUB_*` args). Configuration for vertd is runtime env vars (`VERTD_FORCE_GPU`, `VERTD_VAAPI_DEVICE_PATH`).

## Backup

Nothing user-facing to back up. VERT is stateless (nginx + static JS), vertd stores no persistent state. Re-deploy = same service.

If you run Plausible or self-host analytics, that's a separate app with its own backup.

## Upgrade

1. VERT releases: <https://github.com/VERT-sh/VERT/releases>.
2. vertd releases: <https://github.com/VERT-sh/vertd/releases>.
3. **Prebuilt VERT image**: `docker pull ghcr.io/vert-sh/vert:latest && docker compose up -d`.
4. **Custom-built VERT**: re-run the `docker build` with your build args, re-tag, `docker compose up -d`.
5. **vertd**: `docker pull ghcr.io/vert-sh/vertd:latest && docker compose up -d`. GPU runtime settings persist.
6. Two repos = two release cycles; don't assume version parity between VERT and vertd. Check compatibility notes in vertd README before major upgrades.

## Gotchas

- **`PUB_*` build args are BAKED at build time.** Changing `PUB_VERTD_URL` after deploy means rebuilding the image. The prebuilt `ghcr.io/vert-sh/vert:latest` has `localhost:5173` as hostname — not production-usable unless you're OK with hardcoded upstream defaults.
- **Video requires vertd.** Without a running vertd reachable at `PUB_VERTD_URL`, the video conversion UI shows an error. For a video-capable self-host, deploy both.
- **Conversions for image/audio/doc happen IN the browser.** Large files → high client RAM use. Mobile browsers especially can OOM on multi-GB files. Audio/doc are relatively cheap; raw uncompressed image edits are memory-hungry.
- **WebAssembly + SharedArrayBuffer requires COOP/COEP headers.** Your reverse proxy MUST send `Cross-Origin-Opener-Policy: same-origin` + `Cross-Origin-Embedder-Policy: require-corp` for some codecs to work (particularly threaded WASM). Upstream's nginx config sets these; if you reverse-proxy without preserving them, threaded conversions fall back to single-threaded or break.
- **vertd Docker Desktop on Windows/macOS = CPU-only.** Hardware acceleration passthrough is unsupported per upstream. Use Linux host + native Docker Engine for GPU encoding.
- **NVIDIA Container Toolkit required for NVIDIA GPUs.** Without `sudo nvidia-ctk runtime configure --runtime=docker`, vertd starts but falls back to CPU (slow).
- **VA-API path varies by hardware.** Default is `/dev/dri/renderD128`. Dual-GPU systems (iGPU + dGPU) might put your AMD/Intel render at `renderD129`. Check `ls /dev/dri/` first. Wrong path → CPU fallback.
- **AGPL-3.0 (VERT) is network-copyleft.** Run a modified VERT as a public service = you must offer modified source to users. Same spirit as FreshRSS. If you contribute back upstream, no issue.
- **No auth / no rate-limiting built in.** Public-facing vertd will happily convert any video anyone sends to it. Put behind Caddy/Traefik with basic-auth or mTLS if it's exposed; consider rate-limiting via reverse proxy.
- **Video conversion is CPU-intensive even with GPU.** A 4K → 1080p H.265 transcode can peg an RTX 3080 for a minute. Shared public instance = risk of queue stalls.
- **vertd temp files eat disk.** Large video uploads + long transcodes can fill `/tmp` inside the container. Mount `/tmp` to a dedicated volume if you expect sustained heavy use.
- **`PUB_STRIPE_KEY` is the upstream's Stripe publishable key** (for vert.sh donations). Override to empty or a self-owned key.
- **`PUB_DISABLE_ALL_EXTERNAL_REQUESTS=true`** disables Plausible pings + any other telemetry the codebase sends. Flip this on for strict privacy deployments.
- **Mobile browsers' WebAssembly performance** varies wildly. Image conversions that take <1s on desktop can take 10–30s on mid-range Android. Manage user expectations if you deploy on a public URL.
- **Alternatives worth knowing:**
  - **Stirling-PDF** — PDF-specific, feature-rich (not just conversion)
  - **ConvertX** — different file-conversion self-host, server-side processing
  - **CloudConvert** — commercial SaaS, more formats, less private

## Links

- VERT repo: <https://github.com/VERT-sh/VERT>
- vertd repo: <https://github.com/VERT-sh/vertd>
- VERT Docker docs: <https://github.com/VERT-sh/VERT/blob/main/docs/DOCKER.md>
- vertd Docker docs: <https://github.com/VERT-sh/vertd/blob/main/docs/DOCKER_SETUP.md>
- VERT Getting Started: <https://github.com/VERT-sh/VERT/blob/main/docs/GETTING_STARTED.md>
- VERT FAQ: <https://github.com/VERT-sh/VERT/blob/main/docs/FAQ.md>
- Video conversion docs: <https://github.com/VERT-sh/VERT/blob/main/docs/VIDEO_CONVERSION.md>
- VERT container: <https://github.com/VERT-sh/VERT/pkgs/container/vert>
- vertd container: <https://github.com/VERT-sh/vertd/pkgs/container/vertd>
- Public instance: <https://vert.sh>
- Alternative ConvertX: <https://github.com/C4illin/ConvertX>
