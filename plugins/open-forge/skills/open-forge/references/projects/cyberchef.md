---
name: cyberchef-project
description: CyberChef recipe for open-forge. Apache-2.0 "Cyber Swiss Army Knife" by GCHQ — web-based data manipulation and analysis tool for encoding/decoding, encryption, hashing, compression, parsing, and 300+ other operations. 100% client-side static SPA — no backend, no DB, no secrets. Self-host = serve a static bundle. Covers the prebuilt Docker image (`ghcr.io/gchq/cyberchef`), building from source, npm install, and the "just unzip the release into a webroot" path. Zero-config, zero-state — the simplest self-host recipe in the forge.
---

# CyberChef

Apache-2.0 "Cyber Swiss Army Knife" by GCHQ (UK intelligence agency). Upstream: <https://github.com/gchq/CyberChef>. Live demo: <https://gchq.github.io/CyberChef/>.

A data manipulation web app with 300+ operations: base64/URL/hex/UTF encoding, AES/DES/Blowfish/RSA crypto, MD5/SHA hashing, gzip/bzip2/tar (de)compression, JSON/XML/YAML/CSV parsing, IPv6/X.509/PEM/ASN.1 decoding, shellcode disassembly, regex, time conversions, OCR, QR codes, data diff, and more.

**100% client-side.** Everything runs in the browser via JavaScript. No backend, no database, no cookies by default, no data leaves your browser. Self-host = serve a static bundle behind any HTTP server.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Prebuilt Docker image (`ghcr.io/gchq/cyberchef`) | GitHub Container Registry | ✅ Recommended | The simplest path. One container, port 8080. |
| Build Docker image yourself | `docker build .` from the repo | ✅ | If you don't trust prebuilt images or want to inspect the build. |
| Static release tarball | <https://github.com/gchq/CyberChef/releases> | ✅ | Unzip into any webroot (nginx, Apache, Caddy, GitHub Pages, S3). Zero moving parts. |
| npm package | `npm install cyberchef` | ✅ | Embedding CyberChef as a dependency in another app. |
| Build from source | `npm ci && npx grunt prod` | ✅ | Dev / custom builds with added operations. |
| GitHub Pages mirror | Various forks | ⚠️ Community | Not self-host. Ignore for open-forge. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-prebuilt` / `docker-build` / `static-zip` / `npm-source` | Drives section. |
| dns | "Public domain?" | Free-text | For reverse proxy. |
| tls | "Reverse proxy / TLS terminator?" | `AskUserQuestion` | Optional but recommended for any public deploy. |

That's it. CyberChef has no users, no secrets, no database, nothing else to configure.

## Install — Prebuilt Docker image (recommended)

```bash
docker run -d \
  --name cyberchef \
  -p 8080:8080 \
  --restart unless-stopped \
  ghcr.io/gchq/cyberchef:latest
```

Open `http://<host>:8080/` — done.

### Docker Compose

```yaml
services:
  cyberchef:
    image: ghcr.io/gchq/cyberchef:latest
    container_name: cyberchef
    restart: unless-stopped
    ports:
      - "8080:8080"
    read_only: true        # CyberChef is 100% static — no writes needed
```

## Install — Build Docker image yourself

```bash
git clone https://github.com/gchq/CyberChef.git
cd CyberChef
docker build --tag cyberchef --ulimit nofile=10000 .
docker run -d -p 8080:8080 --name cyberchef cyberchef
```

The `--ulimit nofile=10000` is per upstream README — the npm build opens many files.

## Install — Static release (unzip to webroot)

```bash
# 1. Grab the latest release
VERSION=$(curl -s https://api.github.com/repos/gchq/CyberChef/releases/latest | grep tag_name | cut -d'"' -f4)
curl -L -O "https://github.com/gchq/CyberChef/releases/download/${VERSION}/CyberChef_${VERSION}.zip"

# 2. Extract into your webroot
sudo mkdir -p /var/www/cyberchef
sudo unzip "CyberChef_${VERSION}.zip" -d /var/www/cyberchef

# 3. Point nginx/Apache/Caddy at it
```

### Caddy example

```caddy
cyberchef.example.com {
    root * /var/www/cyberchef
    file_server
    encode gzip
}
```

### nginx example

```nginx
server {
    listen 80;
    server_name cyberchef.example.com;
    root /var/www/cyberchef;
    index CyberChef_*.html;

    location / {
        try_files $uri $uri/ =404;
    }

    # The bundled JS is ~10MB gzipped; ensure gzip + caching on
    gzip on;
    gzip_types application/javascript text/css text/html;
    expires 7d;
}
```

### GitHub Pages / S3 / any CDN

Works out of the box. CyberChef's `index.html` references all JS/CSS as relative paths. Upload the contents of the unzipped release to any static-hosting service.

## Install — npm / build from source

```bash
# Node.js + npm required (per upstream package.json, current LTS)
git clone https://github.com/gchq/CyberChef.git
cd CyberChef
npm ci
npx grunt prod      # build production bundle into build/prod/
npx grunt dev       # dev server with live reload on :8080
```

The `build/prod/` directory contains the static bundle — copy it anywhere and serve.

## Data layout

**None.** CyberChef writes nothing to disk. Recipes the user saves live in `localStorage` in their browser. Uploaded files (via drag-and-drop) are processed client-side and never reach your server.

**Backup** = back up the container image tag / release version number you're running. That's it. No user data to lose.

## Configuration

**None.** Upstream exposes no runtime config. The only "configuration" is which CyberChef version you pin.

Advanced: if you fork the repo to add custom operations, rebuild and serve your fork. See `src/core/operations/` for how operations are structured.

## Upgrade procedure

### Docker

```bash
docker pull ghcr.io/gchq/cyberchef:latest
docker stop cyberchef && docker rm cyberchef
# Re-run the docker run command above
```

### Static

```bash
VERSION=$(curl -s https://api.github.com/repos/gchq/CyberChef/releases/latest | grep tag_name | cut -d'"' -f4)
curl -L -O "https://github.com/gchq/CyberChef/releases/download/${VERSION}/CyberChef_${VERSION}.zip"
sudo rm -rf /var/www/cyberchef/*
sudo unzip "CyberChef_${VERSION}.zip" -d /var/www/cyberchef
```

No data migration ever. Just replace the bundle.

## Gotchas

- **Upstream README warns: "Cryptographic operations in CyberChef should not be relied upon to provide security in any situation. No guarantee is offered for their correctness."** Use it for analysis and learning, not as a primary crypto tool for production secrets. Specifically, it runs in a browser JS VM with all the side-channel caveats that implies.
- **Large file operations are browser-limited.** The README says 2GB files can be loaded, but in practice >500MB makes most browsers choke. For big data, split or use a server-side tool.
- **It's a SPA.** Deep-links like `https://cyberchef.example.com/#recipe=...` work because CyberChef encodes the whole recipe + input into the URL fragment. The fragment never hits the server, so sharing URLs is privacy-preserving — EXCEPT that browser history / referer headers may leak them. Treat shared recipe URLs as equivalent to sharing the input data.
- **Default bundle is ~10MB gzipped, ~40MB uncompressed.** First page load on a cold CDN can take a few seconds. Enable gzip/brotli + long-lived cache headers. After first load it's instant.
- **No built-in auth.** If you need to restrict access, put it behind a reverse proxy with basic auth, or an auth-proxy like oauth2-proxy / Authelia. CyberChef has no concept of users.
- **"Magic" auto-decode is heuristic.** The "magic" operation tries to guess encodings iteratively; it's often wrong on short inputs or adversarial data. Verify decodings match your expectations.
- **Input history is kept in localStorage.** If you work on sensitive data on a shared machine, clear browser storage before leaving, OR use incognito/private mode. Anyone with browser access can see your last inputs.
- **Operations can have side effects on the DOM only.** No fetches, no network calls, no file writes. This is by design — the entire app is air-gappable. If you want network-aware ops (e.g. "look up this CVE"), CyberChef won't do it — use a different tool.
- **GCHQ ownership.** Don't let the author throw off your threat model — the repo is Apache-2.0 open source with public CI/CD, but some organizations have policies about tools from specific governments. If that matters, pin to a known-good commit SHA and build your own image from source.
- **Prebuilt image on `ghcr.io/gchq/cyberchef`** — that's upstream's canonical image. Some older guides reference `mpepping/cyberchef` (community mirror) — fine but not upstream; prefer `ghcr.io/gchq/cyberchef` for supply-chain hygiene.
- **Still actively developed despite "finished product" vibes.** GCHQ ships regular releases with new ops + bugfixes. Pin a version; update deliberately.

## Links

- Upstream repo: <https://github.com/gchq/CyberChef>
- Live demo: <https://gchq.github.io/CyberChef/>
- Releases: <https://github.com/gchq/CyberChef/releases>
- Docker image: <https://github.com/gchq/CyberChef/pkgs/container/cyberchef>
- npm: <https://www.npmjs.com/package/cyberchef>
- Automatic magic detection wiki: <https://github.com/gchq/CyberChef/wiki/Automatic-detection-of-encoded-data-using-CyberChef-Magic>
- Contributing: <https://github.com/gchq/CyberChef/blob/master/CONTRIBUTING.md>
