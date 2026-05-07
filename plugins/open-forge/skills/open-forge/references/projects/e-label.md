---
name: e-label
description: E-Label (Open E-Label) recipe for open-forge. Electronic wine bottle labels with QR codes for EU regulatory compliance. ASP.NET Core 8 + Docker. Source: https://github.com/filipecarneiro/ELabel
---

# E-Label (Open E-Label)

An open-source solution for electronic labels on wine bottles sold within the European Union. Generates QR codes that link to digital labels containing allergy, energy, ingredient, and nutritional information — as required by EU regulations (EU 2021/2117, EU 1169/2011). Built on ASP.NET Core 8. MIT licensed. Upstream: <https://github.com/filipecarneiro/ELabel>. Docker Hub: <https://hub.docker.com/r/fcarneiro/elabel>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS | Docker Compose | Official Docker image — recommended |
| Any Linux / Windows | .NET 8 native | Build from source with dotnet publish |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for the E-Label service?" | FQDN | QR codes embed this URL — must be stable/permanent |
| "Winery/company name?" | String | Shown on label pages |
| "Default language?" | ISO 639-1 code | e.g. en, fr, de, it — 24 EU languages supported |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Database path/connection string?" | File path or connection string | SQLite by default; path must persist |
| "Admin username and password?" | Strings (sensitive) | For the label management UI |

## Software-Layer Concerns

- **QR code URL stability**: QR codes printed on physical bottles are permanent. The domain used at deploy time is embedded in every QR code — changing it later requires reprinting labels.
- **Data dir**: SQLite database file must be on a persistent volume. Default path varies — check upstream docs.
- **Multilingual**: Supports 24 EU languages via Lokalise. Language files are bundled; no extra config needed.
- **EU compliance**: Designed to meet EU 2021/2117 requirements for wine labelling. Verify compliance with your legal team for production use.
- **Static assets**: wwwroot/ served by the ASP.NET Core Kestrel server; no separate web server needed for small deployments.
- **HTTPS required for production**: QR codes should resolve over HTTPS — use a reverse proxy (Caddy / NGINX) in front.

## Deployment

### Docker Compose

```yaml
services:
  elabel:
    image: fcarneiro/elabel:latest
    ports:
      - "8080:80"
    volumes:
      - elabel_data:/app/data
    environment:
      ASPNETCORE_ENVIRONMENT: Production
      # Set connection string if not using default SQLite path
    restart: unless-stopped

volumes:
  elabel_data:
```

Place behind Caddy or NGINX for HTTPS termination, pointing to the domain used in QR codes.

### Reverse proxy (Caddy example)

```
labels.yourwinery.com {
  reverse_proxy elabel:80
}
```

## Upgrade Procedure

1. Pull new image: docker compose pull && docker compose up -d
2. Backup the data volume (SQLite file) before upgrading.
3. Check release notes at https://github.com/filipecarneiro/ELabel/releases for any migration steps.

## Gotchas

- **Permanent QR code URLs**: Think carefully about your domain before printing any bottles. A domain change means reprinting all physical labels.
- **EU regulatory scope**: E-Label targets EU wine regulations specifically. Non-EU use is possible but the compliance framing is EU-centric.
- **Low activity**: As of early 2026 the repo shows minimal recent commits — verify the project is still maintained before production use.
- **ASP.NET Core**: Requires .NET 8 runtime if building natively; Docker image bundles the runtime.
- **Admin setup**: First-run admin account creation — follow upstream README for initial setup steps.

## Links

- Source: https://github.com/filipecarneiro/ELabel
- Website: https://filipecarneiro.github.io/ELabel/
- Docker Hub: https://hub.docker.com/r/fcarneiro/elabel
- Releases: https://github.com/filipecarneiro/ELabel/releases
- EU Regulation 2021/2117: https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:02021R2117-20211206
