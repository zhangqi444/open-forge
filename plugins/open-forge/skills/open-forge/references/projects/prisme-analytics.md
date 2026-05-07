# Prisme Analytics

**Privacy-focused, cookieless web analytics built on Grafana** — open-source analytics service that collects only anonymized data, is GDPR/PECR/ePrivacy compliant, and uses Grafana for dashboards, user management, and custom visualizations. Lightweight tracking script (~2 kB).

**Official site:** https://www.prismeanalytics.com
**Source:** https://github.com/prismelabs/analytics
**License:** AGPL-3.0 / MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Docker Compose | Recommended self-host path |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain / hostname for the Prisme instance
- Whether to use Prisme Cloud or self-host

### Phase 2 — Deploy
- Database credentials (ClickHouse, configured in Compose)
- Grafana admin credentials
- SMTP config (optional, for Grafana alerts/invites)

---

## Software-Layer Concerns

- **Stack:** Go backend, ClickHouse for event storage, Grafana for dashboards
- **Config:** Environment variables in `docker-compose.yml`; see upstream self-host guide
- **Data dir:** ClickHouse data volume; Grafana provisioning directory
- **Tracking script:** Add `<script src="https://<your-instance>/static/wa.js" defer></script>` to tracked pages
- **Noscript tracking:** `<img src="https://<your-instance>/api/v1/noscript/events/pageviews">` for JS-disabled visitors
- **SPA support:** Works automatically with pushState-based routers (React, Vue, Next.js, etc.)
- **Custom events:** Supported via JS API for beyond-pageview tracking
- **Bot filtering:** Automatic; bots, scrapers, and spam traffic are filtered from metrics

---

## Deployment

Follow the official guide:
https://www.prismeanalytics.com/docs/guides/self-host-prisme-docker/

Add tracking to your site:
```html
<script src="https://<your-prisme-instance>/static/wa.js" defer></script>
<noscript>
  <img src="https://<your-prisme-instance>/api/v1/noscript/events/pageviews"
       style="position:absolute;top:-100px">
</noscript>
```

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **ClickHouse dependency** — requires more RAM than lightweight SQLite-based analytics tools; plan for at least 2 GB RAM
- **Grafana-based UI** — dashboards are Grafana; user/team/org management is Grafana's built-in system
- **No cookies, no fingerprinting** — by design; sessions are approximated via anonymized data
- **Custom dashboards** — possible via Grafana; default Web Analytics dashboard is provisioned automatically
- **AGPL license** applies to the core analytics server; frontend SDKs are MIT

---

## Links

- Upstream README: https://github.com/prismelabs/analytics#readme
- Self-host guide: https://www.prismeanalytics.com/docs/guides/self-host-prisme-docker/
- Documentation: https://www.prismeanalytics.com/docs
- Live demo: https://app.prismeanalytics.com/grafana
