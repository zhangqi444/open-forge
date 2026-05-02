# Hyvor Relay

**What it is:** Self-hosted, open-source email API for developers. A self-hosted alternative to AWS SES, Mailgun, and SendGrid. Uses your own SMTP infrastructure to send transactional and bulk emails, with multi-tenancy, queuing, bounce handling, DNS automation, and Prometheus/Grafana observability.

**Official site:** https://relay.hyvor.com  
**Self-Hosting Docs:** https://relay.hyvor.com/hosting  
**Product Docs:** https://relay.hyvor.com/docs  
**GitHub:** https://github.com/hyvor/relay  
**License:** AGPL-3.0 (enterprise licenses available)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended deployment method |
| Docker Swarm | Docker Swarm | Supported for horizontal scaling |

---

## Architecture

| Component | Tech | Role |
|-----------|------|------|
| API backend | PHP + Symfony | REST API |
| Frontend | SvelteKit | Web dashboard |
| Workers | Go (single binary) | Email workers, webhook handlers, DNS server, incoming SMTP |
| Database / Queue | PostgreSQL | Storage and job queue |

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| Domain name | Domain to send email from — requires DNS setup |
| SMTP credentials | Outbound SMTP server(s) credentials for sending |
| PostgreSQL password | DB password for the relay database |
| App URL | Public URL for the Relay web console |

### Phase: Optional

| Item | Description |
|------|-------------|
| Prometheus endpoint | Expose metrics for monitoring |
| Grafana dashboards | Pre-built dashboards available for observability |
| DNS delegation | Point domain NS records to Relay's built-in DNS server to automate SPF/DKIM/DMARC |

---

## Software-Layer Concerns

- **PostgreSQL is both database and queue** — no separate Redis/RabbitMQ needed
- **Go worker binary** handles the performance-critical path: sending, retries, webhooks, DNS
- **Two email queues:** transactional vs. distributional — separate IP reputation pools
- **Bounce handling and feedback loops** are automated; suppressions managed automatically
- **Greylisting and retries** handled transparently by the worker
- **DNS automation:** Relay includes a built-in DNS server; delegate your domain's NS records to it for zero-touch SPF/DKIM/DMARC management
- **Multi-tenancy:** Multiple tenants with scoped API keys; each tenant manages isolated projects
- **Logs retained up to 30 days** (send logs + SMTP conversations)
- **License:** AGPL-3.0 — commercial/enterprise license available if AGPL is a concern

---

## Upgrade Procedure

Per the self-hosting docs at https://relay.hyvor.com/hosting:
1. Pull new images: `docker compose pull`
2. Restart: `docker compose up -d`
3. Migrations run automatically on startup

---

## Gotchas

- **AGPL-3.0 license** — if you modify and expose over a network, you must publish your changes; enterprise license available for exemption
- **Deliverability depends on IP reputation** — new IPs need warm-up; consider starting with a shared/reputable SMTP relay
- **DNS delegation is optional** but strongly recommended for automated SPF/DKIM/DMARC; without it you manage DNS records manually
- **Horizontal scaling** requires Docker Swarm or similar orchestration — add more worker replicas as volume grows
- **PostgreSQL** must be backed up separately; it holds all email logs and queue state

---

## Links

- Self-Hosting Docs: https://relay.hyvor.com/hosting
- Product Docs: https://relay.hyvor.com/docs
- GitHub: https://github.com/hyvor/relay
- Roadmap: https://github.com/hyvor/relay/blob/main/ROADMAP.md
- Community: https://hyvor.community
