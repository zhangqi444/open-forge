# txtdot

**HTTP proxy for text-only page rendering** — strips ads, heavy scripts, and layout cruft from web pages, returning only text, links, and images. Uses Mozilla's Readability library. Useful for low-bandwidth connections and lightweight browsing.

> ⚠️ **Note:** V1 development is discontinued. Active development is on the [v2 branch](https://github.com/TempoWorks/txtdot/tree/v2). Check the v2 branch for the latest state before deploying.

**Official site / docs:** https://tempoworks.github.io/documentation  
**Source:** https://github.com/TempoWorks/txtdot  
**Demo:** https://txt.dc09.ru  
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker Compose | Easiest path |
| Any | Node.js (npm) | Build and run directly |

---

## Inputs to Collect

### Provision phase
| Input | Description | Default |
|-------|-------------|---------|
| `HTTP_PORT` | External port to expose | `8080` |

### Configure phase
| Input | Description | Default |
|-------|-------------|---------|
| Config via `.env` | Runtime configuration (port, plugins, SearXNG URL) | See `.env.example` in repo |

---

## Software-layer Concerns

### Docker Compose
```yaml
services:
  txtdot:
    image: ghcr.io/tempoworks/txtdot:latest
    ports:
      - '8080:8080'
    restart: unless-stopped
    volumes:
      - '.env:/app/packages/server/dist/.env'
```

Create a `.env` file from the example in the repository and mount it into the container.

Access at `http://localhost:8080`.

### Node.js (production)
```bash
git clone https://github.com/TempoWorks/txtdot
cd txtdot
npm install
npm run build
npm run start
```

### Features
- Server-side page simplification via Readability
- Media proxy for images
- Image compression with Sharp
- Client-side app rendering (React, Vue, Vanilla JS) via [webder](https://github.com/tempoworks/webder)
- SearXNG integration for search
- Plugin system via `@txtdot/sdk` and `@txtdot/plugins`
- No JavaScript sent to client

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **V1 is discontinued.** If starting fresh, check the `v2` branch at https://github.com/TempoWorks/txtdot/tree/v2 for current development status and a possibly different install method.
- **`.env` must be provided** — mount it as a volume (Docker) or place it at `packages/server/dist/.env` (native). Without it, the server may start with defaults that don't match your environment.
- **Not all pages are parseable.** Sites with heavy client-side rendering may not proxy cleanly. webder integration helps but is not universal.
- **SearXNG integration is optional** — configure a SearXNG instance URL in `.env` to enable the search feature.

---

## References

- Upstream README: https://github.com/TempoWorks/txtdot#readme
- Documentation: https://tempoworks.github.io/documentation
- Public instances list: https://github.com/tempoworks/instances
