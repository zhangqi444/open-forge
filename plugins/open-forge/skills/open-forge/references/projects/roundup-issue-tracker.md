---
name: roundup-issue-tracker-project
description: Roundup Issue Tracker recipe for open-forge. Python-based issue tracker / project management tool with web, email, and CLI interfaces. Covers pip install and Docker. Based on upstream docs at https://www.roundup-tracker.org and source at https://www.roundup-tracker.org/code.html.
---

# Roundup Issue Tracker

Highly customisable, Python-based issue tracking system with web, email, and command-line interfaces. Uses multiple backend databases (SQLite, PostgreSQL, MySQL). MIT. Upstream: https://www.roundup-tracker.org. Source: https://www.roundup-tracker.org/code.html (Mercurial). PyPI: https://pypi.org/project/roundup/.

Roundup is schema-driven: each tracker instance has a configurable data schema (issues, users, messages, files) defined in Python. It ships with several "templates" (classic, minimal, jinja2) to bootstrap a new tracker.

## Compatible install methods

| Method | When to use |
|---|---|
| pip install (Python) | Standard; recommended for most self-hosted setups |
| Docker (community image) | Containerised deployment |
| Source install (Mercurial) | For development or latest features |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which tracker template?" | classic / minimal / jinja2 | classic is most complete; jinja2 for modern UI |
| config | "Tracker name / title?" | Free-text | Used in web UI and email subjects |
| config | "Admin password?" | Free-text (sensitive) | Set during roundup-admin init |
| database | "Database backend?" | sqlite / postgresql / mysql | SQLite is simplest for small teams |
| network | "Port to expose?" | Number (default 8080) | Roundup's built-in server port |
| smtp | "SMTP server for email integration?" | host, port, user, pass | Optional; enables email-to-issue creation |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Python 3.x |
| Install | pip install roundup |
| Tracker directory | Self-contained directory with config, schema, and data |
| Config file | <tracker>/config.ini — main config after init |
| Database | Configured at init time; SQLite is default |
| Web server | Built-in server (roundup-server) or WSGI (gunicorn, mod_wsgi, uWSGI) |
| Email | Optional inbound (roundup-mailgw) and outbound SMTP integration |
| Upgrade | pip install --upgrade roundup + roundup-admin migrate |

## Install: pip

Source: https://www.roundup-tracker.org/docs/installation.html

```bash
pip install roundup
# Optionally install Jinja2 for jinja2 template:
pip install jinja2
```

### Initialize a tracker

```bash
mkdir /opt/trackers
roundup-admin install /opt/trackers/mytracker classic   # or minimal / jinja2
# Follow interactive prompts:
#  - Database backend (sqlite/postgresql/mysql)
#  - Admin login and password
roundup-admin initialise /opt/trackers/mytracker
```

### Start the built-in web server

```bash
roundup-server -p 8080 mytracker=/opt/trackers/mytracker
```

Access at http://localhost:8080/mytracker/

### Production: run with Gunicorn

```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:8080 "roundup.wsgi:application(tracker_home='/opt/trackers/mytracker')"
```

### systemd service

```ini
[Unit]
Description=Roundup Issue Tracker
After=network.target

[Service]
User=roundup
WorkingDirectory=/opt/trackers
ExecStart=/usr/local/bin/roundup-server -p 8080 mytracker=/opt/trackers/mytracker
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Email integration (optional)

Roundup can create issues from inbound email:

```bash
# Pipe incoming mail through roundup-mailgw:
# In /etc/aliases:
mytracker: "|/usr/local/bin/roundup-mailgw /opt/trackers/mytracker"
```

Configure outbound SMTP in /opt/trackers/mytracker/config.ini under [mail].

## Upgrade procedure

Source: https://www.roundup-tracker.org/docs/upgrading.html

```bash
pip install --upgrade roundup
# Migrate the tracker database:
roundup-admin -i /opt/trackers/mytracker migrate
```

Always review the upgrade notes for the new version before migrating: https://www.roundup-tracker.org/docs/upgrading.html

Back up the tracker directory before upgrading:
```bash
cp -r /opt/trackers/mytracker /backup/mytracker-$(date +%Y%m%d)
```

## Gotchas

- Tracker directory is self-contained: The entire tracker (config, data, schema) lives in one directory. Back it up as a unit.
- Schema changes require migration: Modifying detectors.py or schema.py after initialisation requires running roundup-admin migrate.
- roundup-server is not production-grade: The built-in server is fine for small teams but use Gunicorn or mod_wsgi for larger deployments.
- Email setup requires MTA cooperation: Inbound email-to-issue requires your MTA to pipe to roundup-mailgw. Test this separately.
- Multiple trackers: A single roundup-server instance can serve multiple trackers (e.g. roundup-server tracker1=/path1 tracker2=/path2).

## Links

- Docs: https://www.roundup-tracker.org/docs/
- Installation: https://www.roundup-tracker.org/docs/installation.html
- Upgrading: https://www.roundup-tracker.org/docs/upgrading.html
- PyPI: https://pypi.org/project/roundup/
- Source (Mercurial): https://www.roundup-tracker.org/code.html
