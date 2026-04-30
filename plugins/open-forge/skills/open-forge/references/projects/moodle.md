---
name: Moodle
description: "World's most widely-deployed open-source learning management system (LMS). Courses, enrollments, quizzes, gradebook, assignments, forums, SCORM, LTI, BigBlueButton integration. PHP + MySQL/MariaDB/Postgres. Used by universities, schools, enterprises globally. GPL-3.0."
---

# Moodle

Moodle is **the world's most widely-deployed open-source Learning Management System (LMS)** — the default choice for universities, secondary schools, corporate training, and online courses globally. If you've taken an online class at a public university, chances are you've used Moodle.

Feature breadth:

- **Courses + categories** — hierarchical course catalogue
- **Enrollments** — self, manual, cohort, LDAP, IMS, PayPal, Stripe, meta
- **Activities** — Assignments, Quizzes (many question types), Forums, Wikis, Glossaries, Databases, Workshops (peer review), Lessons, Choice (polls), Feedback, Chat
- **Resources** — Pages, Books, Files, Folders, URLs, Labels, IMS content
- **Gradebook** — weighted categories, rubrics, marking guides, outcomes
- **Competencies / Learning plans** — track skill progression
- **Completion tracking** — activity + course completion
- **Cohorts + groups + groupings** — flexible audience management
- **Reports** — logs, live logs, participation, course completion, competency, Moodle report builder
- **Messaging + notifications** — in-app + email + mobile push
- **Mobile app** — official Moodle Mobile (iOS/Android), offline-capable
- **Integrations** — LTI 1.3 (consume + provide), SCORM 1.2/2004, BigBlueButton, Zoom, Microsoft Teams, Turnitin, SSO (LDAP/SAML/OAuth/CAS/Shibboleth)
- **Plugins** — 2000+ in the Moodle Plugins Directory
- **Accessibility** — WCAG 2.1 AA targeted
- **Multi-language** — 100+ language packs
- **Multi-tenancy** (via MNet legacy or Moodle Workplace commercial variant)

- Upstream repo: <https://github.com/moodle/moodle>
- Website: <https://moodle.org>
- Docs: <https://docs.moodle.org>
- Developer docs: <https://moodledev.io>
- Download: <https://download.moodle.org>
- Demo: <https://sandbox.moodledemo.net>
- Plugins directory: <https://moodle.org/plugins/>
- MoodleCloud (hosted): <https://moodle.com/cloud>
- Partners: <https://moodle.com/partners>

## Architecture in one minute

- **PHP 8.1+** (check current Moodle release for minimum)
- **DB**: MySQL 8.0+ / MariaDB 10.6+ / Postgres 13+ / SQL Server / Oracle
- **Web server**: Apache / Nginx + PHP-FPM
- **Moodle codebase**: 30+ MB of PHP; vast component architecture (plugins are core to Moodle)
- **Moodledata**: non-public directory holding uploads, caches, temp (can be HUGE)
- **Cron job**: **mandatory** — runs scheduled tasks (enrollments, grade processing, notifications) every minute
- **Cache backends**: files (default) / Redis / Memcached
- **Sessions**: files (default) / Redis / DB
- **Optional**: **Elasticsearch / Solr** for global search; message queue for scheduled tasks on large instances

## Compatible install methods

| Infra         | Runtime                                              | Notes                                                                        |
| ------------- | ---------------------------------------------------- | ---------------------------------------------------------------------------- |
| Single VM     | **Bitnami Moodle Docker image** or native LAMP/LEMP        | Common for small-to-medium                                                            |
| Single VM     | `moodlehq/moodle-docker` (upstream)                                | Good for dev + small prod                                                                           |
| Multi-node    | Load-balanced PHP + shared DB + shared moodledata + Redis      | Reference for universities                                                                           |
| Kubernetes    | Bitnami Moodle Helm chart / custom                                             | Works at scale                                                                                               |
| Managed       | **MoodleCloud** (official SaaS) / Moodle Partners                                  | Partners offer compliant hosting + support                                                                           |
| Raspberry Pi  | Possible for homelab / classroom                                                          | Slow on heavy courses                                                                                                |

## Inputs to collect

| Input               | Example                           | Phase     | Notes                                                                  |
| ------------------- | --------------------------------- | --------- | ---------------------------------------------------------------------- |
| Site URL            | `https://moodle.example.edu`          | URL       | `$CFG->wwwroot` — lock this in; changing later breaks many URLs                   |
| DB                  | MariaDB/Postgres/MySQL creds            | DB        | MySQL/MariaDB most-tested; InnoDB + `utf8mb4`                                         |
| Admin account       | created in web installer                     | Bootstrap | Elevated admin (don't use day-to-day)                                                          |
| moodledata path     | `/var/www/moodledata` (outside webroot)         | Storage   | **Never serve via web** — permission tokens enforce access                                                    |
| SMTP                | host/port/user/pass                                 | Email     | Moodle sends a lot of email                                                                                          |
| Cron                | every 1 minute via system cron                               | Ops       | Absolutely required                                                                                                              |
| Language            | default language pack                                               | Config    | Install additional packs via admin UI                                                                                                        |
| Auth methods        | manual / email / LDAP / SAML / OAuth / Shibboleth                              | Auth      | Enable multiple in priority order                                                                                                                    |

## Install via official Moodle tarball

```sh
# Ubuntu 22.04 example
sudo apt install -y apache2 postgresql php8.1 php8.1-{fpm,cli,curl,gd,intl,mbstring,mysql,pgsql,soap,xml,zip,xmlrpc,ldap,bz2}
cd /var/www
sudo wget https://download.moodle.org/stable405/moodle-latest-405.tgz
sudo tar xzf moodle-latest-405.tgz
sudo mkdir -p /var/www/moodledata
sudo chown -R www-data:www-data /var/www/moodle /var/www/moodledata
# Configure Apache/Nginx vhost → /var/www/moodle
# Browse site → install wizard runs → fills config.php
```

## Install via Bitnami Docker

```yaml
services:
  moodle:
    image: bitnami/moodle:4.5                          # pin minor
    restart: unless-stopped
    depends_on: [db]
    environment:
      MOODLE_DATABASE_TYPE: mariadb
      MOODLE_DATABASE_HOST: db
      MOODLE_DATABASE_NAME: moodle
      MOODLE_DATABASE_USER: moodle
      MOODLE_DATABASE_PASSWORD: <strong>
      MOODLE_USERNAME: admin
      MOODLE_PASSWORD: <strong>
      MOODLE_EMAIL: admin@example.edu
      MOODLE_SITE_NAME: "Example University LMS"
      MOODLE_HOST: moodle.example.edu
      MOODLE_REVERSEPROXY: "yes"
      MOODLE_SSLPROXY: "yes"
    volumes:
      - moodle_data:/bitnami/moodle
      - moodledata:/bitnami/moodledata
    ports:
      - "8080:8080"
  db:
    image: bitnami/mariadb:11
    environment:
      MARIADB_ROOT_PASSWORD: <strong>
      MARIADB_DATABASE: moodle
      MARIADB_USER: moodle
      MARIADB_PASSWORD: <strong>
    volumes:
      - moodle_db:/bitnami/mariadb
volumes:
  moodle_data:
  moodledata:
  moodle_db:
```

Front with Caddy/Traefik for TLS.

## Cron (MANDATORY)

```cron
# /etc/cron.d/moodle
* * * * * www-data /usr/bin/php /var/www/moodle/admin/cli/cron.php >/var/log/moodle-cron.log 2>&1
```

Without this, enrollments stall, grades don't process, notifications don't send, backups don't run. **Install cron or your Moodle is broken.**

## First boot

1. Browse site → installer detects prereqs, writes `config.php`
2. Create admin account
3. Site administration → Site registration → register with moodle.net (optional, recommended for security updates)
4. Admin → Plugins → Install a few starter plugins (themes, BigBlueButton, Turnitin if needed)
5. Create a course category + first course
6. Enroll yourself as teacher; add students via email invite or cohort
7. Add an Assignment activity; test grading
8. Check `admin/environment.php` and `admin/tool/replace/index.php` for env diagnostics

## Data & config layout

- `/var/www/moodle/config.php` — core config (DB creds, `$CFG`)
- `/var/www/moodledata/` — **NOT in webroot** — all user uploads, cache, temp, session, trash; easily 100s of GB on large sites
- DB — all relational data (courses, users, grades, logs, question banks)
- `/var/www/moodle/local/`, `/var/www/moodle/mod/`, `/var/www/moodle/blocks/`, etc. — plugin directories

## Backup

Moodle has built-in course + site backup (Admin → Course backup / Site → Backup). For disaster recovery:

```sh
# DB dump (CRITICAL)
mysqldump -u root -p moodle | gzip > moodle-db-$(date +%F).sql.gz

# moodledata (the big one)
tar czf moodle-data-$(date +%F).tgz /var/www/moodledata/

# Config
cp /var/www/moodle/config.php moodle-config-$(date +%F).bak
```

Weekly offsite rotation minimum for teaching institutions. Grade data loss = legal/accreditation exposure.

## Upgrade

1. Releases: <https://moodle.org/download> + <https://github.com/moodle/moodle/releases>. LTS releases every 18 months; regular releases every 6 months.
2. **Back up DB + moodledata + config.php + /var/www/moodle.**
3. Put site into maintenance mode: `php admin/cli/maintenance.php --enable`.
4. Replace codebase (preserving config.php, local/, theme customizations).
5. Run `php admin/cli/upgrade.php --non-interactive` or visit the site to run web upgrade.
6. Disable maintenance mode.
7. Test a sample course.
8. **Upgrade path rules:** upgrade to the next LTS first for multi-major jumps. Check <https://moodledev.io/general/releases> upgrade paths.

## Gotchas

- **Cron is mandatory.** Without it, nothing scheduled works. Monitor cron (Admin → Notifications).
- **moodledata outside webroot.** Serving it via the web = leaking student data + exam questions. Moodle enforces token-based access via PHP.
- **wwwroot is sticky** — changing `$CFG->wwwroot` retroactively breaks content URLs embedded in course HTML. Plan your hostname up front.
- **Performance**: heavy courses + 1000s of students = needs Redis cache + OPcache + PHP-FPM tuned. Otherwise sluggish.
- **Session + cache backend**: default file cache is slow at scale. Move to Redis (or Memcached) for sites >100 concurrent users.
- **Global search** — Moodle's default search is DB-based; slow. Configure Elasticsearch/Solr for large sites (Admin → Server → Search).
- **Scheduled tasks** (Admin → Server → Scheduled tasks) — monitor for tasks falling behind. "Failed" tasks stall everything downstream.
- **Course backups** — built-in, stored in moodledata; can be huge. Rotate + offload.
- **Plugin quality varies.** Stick to "Plus/Essential" rated plugins from the directory; read plugin release notes before upgrading Moodle (some plugins lag).
- **Themes** — massive ecosystem; 'Boost' is the default; 'Moove' is popular community alternative.
- **Mobile app** — official Moodle Mobile requires web service + token auth enabled. Site admin → Mobile app → enable.
- **LTI** — consuming LTI (external tools like H5P.com, Kaltura) is straightforward. Providing LTI (your Moodle courses in another LMS) = enable External Tool registration.
- **SCORM** — works but old format; modern courses use H5P (bundled in recent Moodle).
- **H5P** — interactive content, native since Moodle 3.9.
- **Question bank** — quizzes rely on it; export/import via Moodle XML or GIFT formats.
- **GDPR / privacy** — Moodle 3.5+ has Data privacy tool (Admin → Users → Privacy) for DSRs.
- **Quiz security** — proctoring via third-party (Proctorio, Respondus); Safe Exam Browser integration for lockdown.
- **Accessibility** — Moodle is WCAG-conscious but themes + custom content vary. Run Accessibility Toolkit audits periodically.
- **PHP version matters** — each Moodle version supports specific PHP versions (e.g., Moodle 4.5 = PHP 8.1-8.3). Don't upgrade PHP past the tested range.
- **Commercial Moodle Workplace** — paid fork with extra features (multi-tenancy, learning paths, certifications). Separate licensing.
- **Partners** — for institutional deployments, Moodle Partners offer hosting + support + customizations (official vetted vendors).
- **License**: GPL-3.0.
- **Alternatives worth knowing:**
  - **Canvas LMS** — modern OSS LMS by Instructure; Ruby on Rails; cleaner UI (Canvas Cloud is commercial)
  - **Open edX** — MOOC-focused platform; heavier
  - **Chamilo** — simpler LMS
  - **ILIAS** — German OSS LMS
  - **LearnPress / LifterLMS / Tutor LMS** — WordPress plugins for smaller orgs
  - **Commercial**: Blackboard, D2L Brightspace, Schoology
  - **Choose Moodle if:** you need the widest feature set + plugin ecosystem + proven track record at university scale.
  - **Choose Canvas if:** UX matters more than feature count + you have Ruby ops capability.
  - **Choose MoodleCloud / Partners if:** you don't want to self-op.

## Links

- Repo: <https://github.com/moodle/moodle>
- Website: <https://moodle.org>
- Docs: <https://docs.moodle.org>
- Developer docs: <https://moodledev.io>
- Install docs: <https://docs.moodle.org/405/en/Installation_guide>
- Release notes: <https://docs.moodle.org/dev/Releases>
- Download: <https://download.moodle.org>
- Plugins directory: <https://moodle.org/plugins/>
- Demo: <https://sandbox.moodledemo.net>
- MoodleCloud (hosted): <https://moodle.com/cloud>
- Partners: <https://moodle.com/partners>
- Moodle Workplace (commercial): <https://moodle.com/workplace>
- Community forums: <https://moodle.org/course/>
- Security updates list: <https://moodle.org/security>
- Bitnami Docker: <https://hub.docker.com/r/bitnami/moodle>
