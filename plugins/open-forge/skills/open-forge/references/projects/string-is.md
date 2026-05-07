---
name: string-is
description: string.is recipe for open-forge. Privacy-friendly online string toolkit for developers. Encode/decode, hash, format, convert, inspect strings. No cookies, strict CSP. Node.js + Docker. Source: https://github.com/recurser/string-is
---

# string.is

Open-source, privacy-friendly string toolkit for developers. Encode/decode, hash, format, convert, inspect, and transform strings — all in the browser. Automatically detects input format and suggests relevant output options. No cookies, no tracking, strict Content Security Policy. Next.js (Node.js). AGPL-3.0 licensed.

Live demo: <https://string.is> | Upstream: <https://github.com/recurser/string-is>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker | Build image locally; no official DockerHub image |
| Any | Node.js (Next.js) | Direct `yarn dev` or `yarn build` |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Port | Default: 3000 |

## Software-layer concerns

### Architecture

- Next.js app — all string processing runs client-side in the browser
- No database, no external API calls — purely static/SSR frontend
- Zero cookies, strict Content Security Policy

### Supported operations (partial list)

Encoding/decoding: Base64, URL encoding, HTML entities, JWT, hex, binary, Morse code  
Hashing: MD5, SHA-1, SHA-256, SHA-512, bcrypt, etc.  
Formatting: JSON, XML, SQL, CSS, YAML pretty-print  
Conversion: Timestamps, color codes, unicode, regex  
Inspection: String length, character codes, lorem ipsum generation

## Install — Docker

```bash
git clone https://github.com/recurser/string-is.git
cd string-is

# Build image
docker build -t string-is .

# Run
docker run -d \
  --name string-is \
  --restart unless-stopped \
  -p 3000:3000 \
  string-is
```

Access at http://localhost:3000.

## Install — Docker Compose

```bash
git clone https://github.com/recurser/string-is.git
cd string-is
docker compose up -d
```

## Install — Node.js (dev)

```bash
git clone https://github.com/recurser/string-is.git
cd string-is
yarn install
yarn husky install

# Development
yarn dev
# Open http://localhost:3000

# Production build
yarn build
yarn start
```

## Upgrade procedure

```bash
git pull
yarn install
docker build -t string-is .
docker compose up -d
```

## Gotchas

- No official pre-built Docker image on DockerHub — you must build it locally from source. The build takes a few minutes.
- Node.js + yarn is required to build the Docker image (the Dockerfile runs `yarn build` during build); pre-installed in the container.
- No configuration needed — the app has no settings, no database, no external services. Drop it behind a reverse proxy and it works.
- All processing runs in the browser — data never leaves the client, which is the whole privacy point. This also means no server-side state or persistence.

## Links

- Source: https://github.com/recurser/string-is
- Live demo: https://string.is
- Releases: https://github.com/recurser/string-is/releases
