# Evergreen

**Highly-scalable Integrated Library System (ILS)** — open source library software for patron catalog discovery, circulation, cataloging, and library management. Used by hundreds of public library systems. Backed by a PL/pgSQL (PostgreSQL) data layer.

**Official site:** https://evergreen-ils.org  
**Source:** https://github.com/evergreen-library-system/Evergreen  
**Docs:** https://docs.evergreen-ils.org  
**License:** GPL-2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Debian/Ubuntu | Native (recommended) | Official install path; deb packages available |
| Linux | Source install | Full documentation at docs.evergreen-ils.org |

> No official Docker image. Evergreen is a complex multi-service stack typically installed on bare metal or VMs using the official install scripts.

---

## System Requirements

- Debian or Ubuntu Linux (officially supported)
- PostgreSQL 12+
- Apache web server with mod_perl
- OpenSRF (Evergreen's middleware framework)
- Perl and dependencies
- Node.js (for some components)

---

## Inputs to Collect

| Input | Description |
|-------|-------------|
| Hostname / domain | Public URL for the OPAC (catalog) |
| PostgreSQL credentials | Database superuser for install |
| Organization name | Library / consortium name |
| Admin credentials | Initial Evergreen admin user |
| Time zone | Server timezone |

---

## Software-layer Concerns

### Installation (Debian/Ubuntu)
Evergreen provides official install scripts:
```bash
# Install dependencies (from official docs)
sudo apt-get install -y make
sudo make -f Open-ILS/src/extras/Makefile.install ubuntu-focal  # adjust for your OS

# Configure and build
./configure --prefix=/openils --sysconfdir=/openils/conf
make
sudo make install

# Database setup
cd Open-ILS/src/sql/Pg
sudo -u postgres psql -f pg_schema/db_schema.sql
```

Full step-by-step: https://docs.evergreen-ils.org/eg/docs/latest/installation/server_installation.html

### Architecture
| Component | Purpose |
|-----------|---------|
| **OPAC** | Public-facing catalog for patrons |
| **Staff client** | Librarian/admin interface (web-based) |
| **OpenSRF** | Service-oriented middleware layer |
| **PostgreSQL** | All data storage |
| **Apache + mod_perl** | Web server layer |
| **Opensrf gateway** | API/service gateway |

### Key features
- Patron catalog (OPAC) with faceted search
- Circulation (checkouts, renewals, holds, fines)
- Cataloging (MARC records, Z39.50 import)
- Acquisitions and serials management
- Multi-branch and multi-library consortium support
- SIP2 support for self-checkout machines
- NCIP support for inter-library loan

---

## Upgrade Procedure

Follow the official upgrade guide: https://docs.evergreen-ils.org/eg/docs/latest/installation/upgrades.html

Major upgrades require database schema migrations run via provided SQL scripts.

---

## Gotchas

- **Not a simple self-hosted app.** Evergreen is enterprise library infrastructure. Plan for dedicated server(s), professional installation, and ongoing system administration.
- **Debian/Ubuntu only officially supported.** Other distros require adaptation.
- **OpenSRF dependency.** Evergreen requires OpenSRF, which must be installed first. The two projects release in tandem.
- **No Docker support.** Community Docker efforts exist but are not officially maintained.
- **Consortium-capable.** Designed to serve entire library networks (hundreds of branches) with a single installation.
- **Active development:** 62 commits in April 2026 — check release notes before upgrading.

---

## References

- Install guide: https://docs.evergreen-ils.org/eg/docs/latest/installation/server_installation.html
- Upgrade guide: https://docs.evergreen-ils.org/eg/docs/latest/installation/upgrades.html
- Official docs: https://docs.evergreen-ils.org
- Upstream README: https://github.com/evergreen-library-system/Evergreen#readme
