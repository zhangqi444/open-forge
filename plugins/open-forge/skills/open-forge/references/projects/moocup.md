---
name: moocup-project
description: Moocup recipe for open-forge. Covers Docker and static hosting deployment of this visual screenshot editor. Based on upstream README at https://github.com/jellydeck/moocup.
---

# Moocup

Visual editor for creating styled screenshots. Drop in a screenshot, apply a base style, customize, and export. Frontend-only Vite/SvelteKit app — no backend, no database. Upstream: <https://github.com/jellydeck/moocup>. Live demo: <https://moocup.jaydip.me/>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any host | Docker (single container) | Image `jellydeck/moocup:latest` from Docker Hub |
| Vercel / Railway / Netlify | Serverless / static | One-click Railway deploy button in upstream README |
| Any static host | Static files (`dist/`) | Build with Vite; serve `dist/` folder |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| deploy | "Port to expose Moocup on?" | Number | Default `8080` for Docker; app serves on port `80` inside container |
| platform | "Deployment method — Docker, Railway, Vercel, or static build?" | Choice | Drives which path below to follow |

## Software-layer concerns

Moocup is a **fully static frontend** — no environment variables, no database, no user data stored server-side.

### Docker (from upstream README)

```bash
docker pull jellydeck/moocup:latest
docker run -p 8080:80 jellydeck/moocup:latest
```

App available at <http://localhost:8080>.

### Docker Compose (minimal)

```yaml
services:
  moocup:
    image: jellydeck/moocup:latest
    container_name: moocup
    restart: unless-stopped
    ports:
      - "8080:80"
```

### Manual / Static build (from upstream README)

```bash
git clone https://github.com/jellydeck/moocup.git
cd moocup
npm install
npm run build
# Serve the dist/ folder with any static host
```

### Railway one-click deploy

Use the Railway deploy button in the upstream README: <https://railway.com/deploy/moocup?referralCode=bmgbXt>

## Upgrade procedure

```bash
docker pull jellydeck/moocup:latest
docker compose up -d   # or stop + docker run
```

## Gotchas

- Purely a frontend tool — no server-side processing. All screenshot editing happens in the browser.
- No authentication, no persistent storage — each session is ephemeral.
- The Docker container runs nginx to serve static files on port `80` internally.
- No environment variables are required or documented by upstream.
- For public-facing deployments, consider adding HTTP basic auth at the reverse proxy level if you want to restrict access.
- Export quality / format is controlled entirely within the browser UI — no server config needed.

## Links

- Upstream repo: <https://github.com/jellydeck/moocup>
- Docker Hub image: <https://hub.docker.com/r/jellydeck/moocup>
- Live demo: <https://moocup.jaydip.me/>
- Railway deploy: <https://railway.com/deploy/moocup?referralCode=bmgbXt>
