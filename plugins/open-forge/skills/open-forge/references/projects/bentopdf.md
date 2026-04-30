---
name: BentoPDF
description: Client-side, privacy-first PDF toolkit — 50+ tools (merge/split/OCR/compress/sign/convert) that run entirely in the browser (WebAssembly). Self-host = static web app; no server processing of documents. Dual-licensed AGPL-3.0 / commercial ($79 lifetime).
---

# BentoPDF

BentoPDF is a single-page web app that does 50+ PDF operations entirely in your browser using WebAssembly (PyMuPDF-WASM, Ghostscript-WASM, pdf-lib, CoherentPDF-WASM). Your documents never leave the browser — the "server" is just an nginx handing you static HTML/JS/WASM.

Tools include: merge, split, reorder, rotate, compress, OCR, PDF→Word/Excel/PNG/SVG, Word/Excel/PNG/JPG→PDF, redact, watermark, digital sign (PKCS#12), PDF/A convert, form fill, flatten, metadata edit, and many more.

Trade-offs:

- ✅ Total privacy — no upload
- ✅ Deploys anywhere static files live (CDN, S3 + CloudFront, GitHub Pages, Netlify, a fridge running nginx)
- ❌ Limited by browser memory — very large PDFs (1 GB+) choke
- ❌ First load pulls WASM blobs from jsDelivr CDN by default (air-gap config available)

**Strong alternative positioning vs Stirling-PDF**: Stirling PDF is server-side (files hit the backend); BentoPDF is client-side only.

- Upstream repo: <https://github.com/alam00000/bentopdf>
- Website: <https://bentopdf.com>
- Docs: <https://bentopdf.com/docs/>
- Docker (default): `ghcr.io/alam00000/bentopdf:latest`
- Docker (simple): `ghcr.io/alam00000/bentopdf-simple:latest`
- Docker Hub mirror: `bentopdfteam/bentopdf`

## Architecture in one minute

- **Static React/Vite app** served by nginx (or any HTTP server / CDN)
- **WASM modules** load on-demand from jsDelivr CDN (default) or from your own static host (air-gapped mode)
- **No backend** for document processing — zero server-side PDF code
- **Optional CORS proxy** only for digital-signature timestamping (OCSP/TSA servers need a CORS-permissive proxy in browser context)

## Compatible install methods

| Infra       | Runtime                                             | Notes                                                                |
| ----------- | --------------------------------------------------- | -------------------------------------------------------------------- |
| Single VM   | Docker (`ghcr.io/alam00000/bentopdf`)               | **Recommended** full build                                            |
| Single VM   | Docker (`ghcr.io/alam00000/bentopdf-simple`)        | Simple mode — trimmed UI for internal deployments                     |
| Static host | Netlify / Vercel / Cloudflare Pages                 | Drop the `dist/` directory                                            |
| Static host | nginx / caddy / S3+CloudFront                        | Any static file server                                                |
| Kubernetes  | Plain nginx Deployment                                | Stateless; scale trivially                                            |
| Podman      | Podman Quadlet (systemd integration)                 | Documented in upstream README                                         |

## Two image variants

| Image                                  | Use                                                                                        |
| -------------------------------------- | ------------------------------------------------------------------------------------------ |
| `ghcr.io/alam00000/bentopdf:latest`    | Default — full marketing UI, landing page, all 50+ tools                                    |
| `ghcr.io/alam00000/bentopdf-simple:latest` | "Simple mode" — stripped UI, internal-deployment-friendly, no landing page, faster first paint |

Pick `-simple` for internal company deployments where users just want the tools.

## Inputs to collect

| Input                | Example                          | Phase     | Notes                                                                |
| -------------------- | -------------------------------- | --------- | -------------------------------------------------------------------- |
| Port                 | `8080:8080`                      | Network   | nginx listens on 8080 inside container                                |
| `DISABLE_IPV6`       | `true`                           | Runtime   | For IPv4-only environments (avoids nginx bind errors)                 |
| Custom WASM base URL | `https://mycdn.example.com/wasm` | Optional  | For air-gapped deploys; override jsDelivr                             |
| CORS proxy URL       | `https://cors-proxy.example.com` | Signatures | Required ONLY if using digital-signature timestamp features           |
| Disabled tools       | CSV in `.env`                    | Optional  | Hide specific tools from UI                                           |
| Custom branding      | logo + name via env              | Optional  | White-label the tool                                                  |

## Install via Docker Compose

Minimal:

```yaml
services:
  bentopdf:
    image: ghcr.io/alam00000/bentopdf:v1.x.x    # pin; check releases
    container_name: bentopdf
    restart: unless-stopped
    ports:
      - "8080:8080"
    # For IPv4-only environments:
    # environment:
    #   - DISABLE_IPV6=true
```

Simple mode (internal):

```yaml
services:
  bentopdf:
    image: ghcr.io/alam00000/bentopdf-simple:v1.x.x
    restart: unless-stopped
    ports: ["8080:8080"]
```

## Air-gapped deployment

For environments without internet access, WASM modules must be self-hosted:

1. Download the required WASM bundles (PyMuPDF, Ghostscript, CPDF) — see <https://bentopdf.com/docs/self-hosting/wasm-configuration> for current CDN URLs
2. Host them on your internal CDN or same nginx serving BentoPDF
3. Set `VITE_WASM_BASE_URL` at build/runtime to point at your mirror

Upstream maintains a guide at <https://bentopdf.com/docs/self-hosting/air-gapped-deployment>.

## Digital Signature CORS proxy

Digital signatures need to reach OCSP responders or timestamp authority (TSA) servers from the browser. Those servers typically don't allow CORS from arbitrary origins. Solution: deploy a minimal CORS-permissive proxy that forwards:

- Request: browser POST → your proxy
- Upstream: proxy → OCSP / TSA server
- Response: proxy adds `Access-Control-Allow-Origin: *` header

Upstream ships a reference proxy template. See <https://bentopdf.com/docs/self-hosting/digital-signature-cors-proxy>.

**This is the only component that does any server-side work** — and it's stateless forwarding, not PDF processing.

## Data & config layout

Zero server-side data. The Docker image is a pure static site packaged with nginx. No volumes needed.

- `/usr/share/nginx/html/` — static assets
- `/etc/nginx/conf.d/` — nginx config
- No persistent state; no user data; no accounts

## Backup

Nothing to back up. Every instance is replaceable by pulling the image again.

## Upgrade

1. Releases: <https://github.com/alam00000/bentopdf/releases>.
2. `docker compose pull && docker compose up -d`.
3. Check release notes for breaking changes in WASM module URLs (air-gapped deploys need to re-mirror).

## Gotchas

- **Dual-licensed AGPL-3.0 / commercial.** Running as a public service under AGPL = offer source. Commercial $79 lifetime license removes AGPL obligations.
- **WASM loads from jsDelivr by default.** Browsers with strict CSP, corporate blocklists, or air-gapped networks = broken UI. Configure local WASM hosting.
- **AGPL WASM components** (PyMuPDF, Ghostscript, CoherentPDF) are loaded from CDN rather than bundled in source — upstream's legal sleight-of-hand to keep the codebase MIT-ish while still enabling AGPL features at runtime. Relying party (the browser) pulls AGPL code on-demand.
- **Browser memory limit.** Chrome typically caps a tab at ~4 GB heap. Processing 500 MB+ PDFs can OOM the tab, losing your work. Warn users.
- **Digital signatures need a CORS proxy.** Forgot to deploy that = signing silently fails with "fetch blocked by CORS" in browser console. Document this for users.
- **OCR is slow.** Tesseract-WASM runs on the CPU in a Web Worker; a multi-page OCR on a mobile browser = minutes of fan noise.
- **No persistent user data or history** — refresh the tab and you lose the current session. Document this for users who expect "history" / "recent files" like SaaS PDF tools.
- **No authentication.** If you want gated access, put behind oauth2-proxy / Authelia / LAN-only.
- **Air-gap WASM config is version-coupled.** WASM URLs in the app are tagged to specific versions (e.g. PyMuPDF 1.23 build X); rolling upgrades need to re-mirror.
- **PDF/A conversion (via Ghostscript)** works but is one of the heavier paths — large docs take 10s+.
- **Disable-specific-tools feature** lets admins hide tools via env. Good for internal use where certain features are unwanted.
- **Custom branding** supports logo + name substitution; full theme customization requires a fork/rebuild.
- **Podman Quadlet support** is first-class for systemd-integrated Podman deploys.
- **IPv6 quirk**: upstream nginx config binds IPv6 by default; `DISABLE_IPV6=true` for IPv4-only hosts.
- **Not a collaboration tool.** Single-user tab operations. No "share a signed doc link" workflow; that's what Documenso / OpenSign / DocuSeal are for.
- **Alternatives worth knowing:**
  - **Stirling-PDF** — server-side, more mature, heavier (Java)
  - **pdf.js** (Mozilla) — view-only
  - **PDF Arranger** (desktop) — organize + merge, no web UI
  - **Documenso / OpenSign / DocuSeal** — specifically for document signing workflows
  - **Commercial SaaS**: SmallPDF, iLovePDF, Adobe Acrobat Online — upload-based

## Links

- Repo: <https://github.com/alam00000/bentopdf>
- Website: <https://bentopdf.com>
- Docs: <https://bentopdf.com/docs/>
- Self-hosting (Docker): <https://bentopdf.com/docs/self-hosting/docker>
- WASM configuration: <https://bentopdf.com/docs/self-hosting/wasm-configuration>
- Air-gapped deployment: <https://bentopdf.com/docs/self-hosting/air-gapped-deployment>
- Digital signature CORS proxy: <https://bentopdf.com/docs/self-hosting/digital-signature-cors-proxy>
- Licensing: <https://bentopdf.com/licensing.html>
- Commercial license: <https://buy.polar.sh/polar_cl_ThDfffbl733x7oAodcIryCzhlO57ZtcWPq6HJ1qMChd>
- Releases: <https://github.com/alam00000/bentopdf/releases>
- Docker image: <https://github.com/alam00000/bentopdf/pkgs/container/bentopdf>
- Docker Hub mirror: <https://hub.docker.com/u/bentopdfteam>
- Discord: <https://discord.gg/Bgq3Ay3f2w>
