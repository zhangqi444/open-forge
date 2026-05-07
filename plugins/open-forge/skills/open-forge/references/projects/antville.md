# Antville

**High-performance blog hosting platform** — server-side JavaScript blog hosting software built on Helma Object Publisher (Java). Designed to host tens of thousands of blogs on a single server. PostgreSQL or MySQL backend, embedded Jetty web server.

**Official site:** https://antville.org
**Source:** https://github.com/antville/antville
**License:** Apache-2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Helma Object Publisher + PostgreSQL | Primary supported stack |
| Any VPS / bare metal | Helma Object Publisher + MySQL/MariaDB | Also tested |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain / hostname
- Database type (PostgreSQL recommended)
- SMTP server for email notifications

### Phase 2 — Deploy
- Java runtime (required by Helma)
- PostgreSQL or MySQL credentials
- SMTP credentials for notification emails

---

## Software-Layer Concerns

- **Runtime:** Helma Object Publisher — a Java-based server-side JavaScript web app server; embedded Jetty web server included (no separate Apache/Nginx required, though one can be added as a proxy)
- **Language:** Server-side JavaScript (Rhino engine via Helma)
- **Database:** PostgreSQL or MySQL/MariaDB
- **Multi-blog:** Single instance hosts unlimited blogs; server hardware is the only limit
- **Install guide:** Bundled `INSTALL.md` in the repository covers full setup

---

## Deployment

1. Install Java (required by Helma Object Publisher)
2. Download and set up [Helma Object Publisher](https://code.host.antville.org/antville/helma)
3. Clone Antville into the Helma apps directory
4. Configure database connection in Helma's properties
5. Start Helma — Antville runs on the embedded Jetty server

Follow the bundled `INSTALL.md`:
https://github.com/antville/antville/blob/main/INSTALL.md

---

## Upgrade Procedure

```bash
git pull
# Restart Helma
```

Follow the upgrade notes in the project site: https://project.antville.org

---

## Gotchas

- **Java required** — Helma runs on the JVM; ensure a compatible JDK is installed
- **Helma is the runtime** — Antville is not a standalone app; it runs inside Helma Object Publisher, which is a separate installation step
- **Embedded Jetty** — no external web server required, but running Nginx in front as a reverse proxy is recommended for production
- **Niche stack** — Helma + server-side Rhino JavaScript is uncommon; community resources are limited

---

## Links

- Upstream README: https://github.com/antville/antville#readme
- Install guide: https://github.com/antville/antville/blob/main/INSTALL.md
- Project site: https://project.antville.org
- Help/support: https://help.antville.org
- Helma Object Publisher: https://code.host.antville.org/antville/helma
