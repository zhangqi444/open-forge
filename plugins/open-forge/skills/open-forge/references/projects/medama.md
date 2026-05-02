# Medama

**What it is:** Cookie-free, privacy-focused website analytics. Lightweight tracker under 1KB with no cookies, no IP addresses, and no user identifiers. GDPR/PECR compliant, self-hostable as a single binary.

**Official URL:** https://oss.medama.io  
**GitHub:** https://github.com/medama-io/medama  
**Stars:** 611

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS (256 MB+ RAM) | Single binary | No external dependencies required |
| Any Linux VPS | Docker | Official Dockerfile provided |
| Fly.io | fly.toml | Fly.io config included in repo |

---

## Inputs to Collect

### Before deploying
- Domain name for the analytics dashboard (e.g., `analytics.example.com`)
- Tracker embed target domains (websites you want to track)

### Environment / Config
- `APP_HOST` — bind address (default `0.0.0.0`)
- `APP_PORT` — port (default `8080`)
- Database file path (SQLite-based; no external DB required)

---

## Software-Layer Concerns

- **Single binary, zero dependencies:** Medama ships as a self-contained binary with embedded SQLite — no PostgreSQL, Redis, or other services needed
- **Tracker script:** Add `<script src="https://your-medama-host/tracker.js" defer></script>` to tracked websites
- **Dashboard:** Web UI served at the same host; add your sites and view real-time analytics
- **Data directory:** Persist the database file directory with a Docker volume mount
- **OpenAPI:** REST API available for integrating analytics into custom dashboards

---

## Upgrade Procedure

1. Pull new image: `docker pull ghcr.io/medama-io/medama:latest`
2. Stop and restart container: `docker compose down && docker compose up -d`
3. Database migrations run automatically on startup

---

## Gotchas

- No cookies and no fingerprinting means some metrics differ from GA/Plausible — by design
- The tracker script must be served over HTTPS to work on HTTPS sites (mixed-content blocked by browsers)
- For high-traffic sites, the embedded SQLite may become a bottleneck — check upstream docs for scaling options
- Licensed under Apache 2.0 (core + dashboard) and MIT (tracker) — different licenses per component

---

## References

- Documentation: https://oss.medama.io/introduction
- Installation guide: https://oss.medama.io/deployment/installation
- Live demo: https://demo.medama.io
- GitHub: https://github.com/medama-io/medama
