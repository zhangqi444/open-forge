# RosarioSIS

**Student Information System for K-12 school management** — comprehensive web-based SIS covering student demographics, grade book, scheduling, attendance tracking, student billing, discipline records, and food service. Built on PHP with PostgreSQL.

**Official site:** https://www.rosariosis.org
**Source:** https://gitlab.com/francoisjacquet/rosariosis/
**License:** GPL-2.0
**Demo:** https://www.rosariosis.org/demo/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | PHP + PostgreSQL | Primary supported stack |
| Any VPS / bare metal | Docker | Community Docker images available |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain / hostname
- Number of schools / district size
- Language preference (multilingual support available)

### Phase 2 — Deploy
- PostgreSQL credentials (database name, user, password, host)
- Admin account email and password
- SMTP config for notifications

---

## Software-Layer Concerns

- **Stack:** PHP, PostgreSQL
- **Active branch:** Use the `mobile` branch / latest releases — the `master` branch hosts the legacy 1.4.x version
- **Installation:** Follow the `INSTALL` file bundled with the release
- **Modules:** Students, Employees, Grades, Scheduling, Attendance, Billing, Discipline, Food Service
- **PDF generation:** Built-in; generates report cards, transcripts, handbooks via `Help.php`
- **Data dir:** File uploads and generated PDFs stored in configured data directory

---

## Deployment

1. Download latest release from https://gitlab.com/francoisjacquet/rosariosis/-/releases (use `mobile` branch / tagged releases, not `master`)
2. Follow the bundled `INSTALL` file for your platform
3. Configure database connection
4. Run the web-based installer
5. Log in and generate PDF handbooks via `Help.php`

Full documentation: https://www.rosariosis.org/documentation/

---

## Upgrade Procedure

Always back up the PostgreSQL database before upgrading. Follow the upgrade guide:
https://www.rosariosis.org/documentation/

---

## Gotchas

- **Do not use the `master` branch** — it contains the legacy 1.4.x version; use tagged releases from the `mobile` branch
- **PostgreSQL required** — MySQL is not supported
- **School year setup required** — the system requires configuring school years, marking periods, and course catalog before it's usable; follow the admin setup guide
- **PDF generation dependencies** — requires PHP extensions for PDF rendering; ensure all PHP dependencies from `INSTALL` are satisfied

---

## Links

- Upstream README: https://gitlab.com/francoisjacquet/rosariosis/-/blob/master/README.md
- Documentation: https://www.rosariosis.org/documentation/
- Demo: https://www.rosariosis.org/demo/
