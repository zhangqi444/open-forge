# AnonymousOverflow

AnonymousOverflow is a privacy-focused frontend proxy for StackOverflow. It lets you read StackOverflow threads without exposing your IP address, browser fingerprint, or browsing habits to StackOverflow's analytics and third-party trackers. Built with Go, serving lightweight SSR HTML with no JavaScript required on the client.

- **Official site:** https://github.com/httpjamesm/AnonymousOverflow
- **Docker image:** `ghcr.io/httpjamesm/anonymousoverflow:release`
- **License:** Open-source (MPL-2.0)
- **Public instances:** https://aohub.httpjames.space

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Single container, minimal resources |
| Any Docker host | docker run | Single command deploy |

---

## Inputs to Collect

### Deploy Phase
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `APP_URL` | **Yes** | — | Public URL of your instance (e.g. `https://overflow.example.com`) |
| `JWT_SIGNING_SECRET` | **Yes** | `secret` | Random JWT signing secret — **change this!** |

---

## Software-Layer Concerns

### Config
- Configured entirely via environment variables
- No config file required

### Data Directories
- No persistent data — fully stateless proxy

### Ports
- `8080` (internal) — configurable host port mapping

---

## Minimal docker-compose.yml

```yaml
services:
  anonymousoverflow:
    container_name: anonymousoverflow
    image: ghcr.io/httpjamesm/anonymousoverflow:release
    environment:
      - APP_URL=https://your-domain.com
      - JWT_SIGNING_SECRET=replace_with_random_secret
    ports:
      - "8080:8080"
    restart: always
```

---

## Upgrade Procedure

```bash
docker compose pull anonymousoverflow
docker compose up -d anonymousoverflow
```

Stateless — no data to migrate.

---

## Gotchas

- **`JWT_SIGNING_SECRET`:** Change from the default `secret` — used for any session tokens; short/guessable values are insecure
- **`APP_URL` must be accurate:** Used for OAuth redirects and self-referencing links; wrong value breaks redirects
- **No JavaScript required:** The frontend is fully SSR — works in browsers with JS disabled or in text-only browsers
- **StackOverflow API limits:** AnonymousOverflow proxies StackOverflow's existing endpoints; heavy usage may trigger rate limits from StackOverflow's side
- **Port 80 option:** The example docker-compose maps to host port 80 (`80:8080`) — change to another port if 80 is in use
- **Libredirect integration:** The [Libredirect](https://github.com/libredirect/libredirect) browser extension can automatically redirect StackOverflow links to your AnonymousOverflow instance
- **Deployment wiki:** Additional setup details at https://github.com/httpjamesm/AnonymousOverflow/wiki/Deployment

---

## References
- README: https://github.com/httpjamesm/AnonymousOverflow
- Deployment wiki: https://github.com/httpjamesm/AnonymousOverflow/wiki/Deployment
- Public instances hub: https://aohub.httpjames.space
- Docker image: https://github.com/httpjamesm/anonymousoverflow/pkgs/container/anonymousoverflow
