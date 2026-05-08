---
name: mediagoblin-project
description: MediaGoblin recipe for open-forge. Federated media publishing platform (photos, video, audio) in Python. Covers virtualenv-based install. Based on upstream docs at https://mediagoblin.readthedocs.io and source at https://git.savannah.gnu.org/cgit/mediagoblin.git.
---

# MediaGoblin

Federated media publishing platform for photos, video, and audio. Python/Flask, SQLite/PostgreSQL, ActivityPub-capable. AGPL-3.0. Upstream: https://mediagoblin.org. Docs: https://mediagoblin.readthedocs.io. Source: https://git.savannah.gnu.org/cgit/mediagoblin.git.

MediaGoblin lets individuals and communities run their own media hosting ("be your own Flickr/YouTube"). Supports image, video, audio, and other media types via plugins. Federation with other GNU MediaGoblin and ActivityPub instances is supported.

Note: MediaGoblin is mature but has had limited active development in recent years. It remains functional and deployable.

## Compatible install methods

| Method | When to use |
|---|---|
| Virtualenv (Python) | Standard; recommended in upstream docs |
| Docker (community) | Containerised; no official image |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| config | "Domain name for this instance?" | FQDN | Used in mediagoblin.ini |
| config | "Admin email?" | email | Set during admin user creation |
| config | "Admin password?" | Free-text (sensitive) | Set during admin user creation |
| database | "SQLite (simple) or PostgreSQL (production)?" | SQLite / PostgreSQL | SQLite for dev; PostgreSQL recommended for multi-user production |
| smtp | "SMTP config for email?" | host, port, user, pass | Optional; for password reset and notifications |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Python 2.7 / 3.x (check current release for Python 3 status) |
| Config file | mediagoblin.ini + paste.ini |
| Database | SQLite (default) or PostgreSQL |
| Media storage | User-uploaded files stored in user_dev/ by default |
| Media processing | Requires Celery worker for async transcoding (video/audio plugins) |
| Web server | Paste (dev) or nginx + uWSGI / gunicorn (production) |
| Plugins | Audio, video, PDF, OpenDocument, STL, and more — enable per plugin docs |

## Install: Virtualenv

Source: https://mediagoblin.readthedocs.io/en/stable/siteadmin/deploying.html

### 1. System dependencies

```bash
sudo apt-get install git python3 python3-dev python3-virtualenv \
  python3-lxml libjpeg-dev zlib1g-dev \
  npm nodejs
# For video processing (optional):
sudo apt-get install gstreamer1.0-tools gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-ugly gstreamer1.0-libav python3-gst-1.0
```

### 2. Create a dedicated user

```bash
sudo adduser --system mediagoblin --group --shell /bin/bash
sudo mkdir -p /srv/mediagoblin
sudo chown mediagoblin:mediagoblin /srv/mediagoblin
```

### 3. Clone and bootstrap

```bash
sudo -u mediagoblin bash
cd /srv/mediagoblin
git clone https://git.savannah.gnu.org/cgit/mediagoblin.git/
cd mediagoblin
git submodule update --init --force
python3 -m virtualenv --system-site-packages venv
./bin/python setup.py develop
./bin/pip install wtforms
```

### 4. Configure

```bash
cp mediagoblin.ini.example mediagoblin.ini
cp paste.ini.example paste.ini
```

Edit mediagoblin.ini — set at minimum:
- email_sender_address
- db_conn_url (for PostgreSQL: postgresql://user:pass@localhost/mediagoblin)
- direct_remote_path and base_url for your domain

### 5. Set up database and admin

```bash
./bin/gmg dbupdate
./bin/gmg adduser --username admin --password adminpass --email admin@example.com
./bin/gmg makeadmin admin
```

### 6. Start (development)

```bash
./lazyserver.sh --server-name=broadcast
```

Access at http://0.0.0.0:6543

### 7. Production with nginx + Celery

For production, run with uWSGI or gunicorn behind nginx, and start Celery workers for media processing. Full guide: https://mediagoblin.readthedocs.io/en/stable/siteadmin/deploying.html

## Upgrade procedure

```bash
sudo -u mediagoblin bash
cd /srv/mediagoblin/mediagoblin
git pull
git submodule update --init --force
./bin/python setup.py develop
./bin/gmg dbupdate
# Restart uWSGI / gunicorn workers
```

## Gotchas

- Python 2 vs 3: Check the current release notes for Python 3 compatibility status before installing.
- Celery required for media processing: Video/audio transcoding is async and requires a running Celery worker. Without it, uploads appear to hang.
- user_dev/ must be persistent: All uploaded media is stored in user_dev/. Back it up and persist it across deployments.
- Limited recent development: Check the mailing list and issue tracker for current maintenance status before deploying in production.
- npm/Node required: Frontend assets require Node.js and npm for building.
- gmg commands: Most admin actions (add user, make admin, db updates) are done via the gmg CLI tool.

## Links

- Docs: https://mediagoblin.readthedocs.io
- Deployment guide: https://mediagoblin.readthedocs.io/en/stable/siteadmin/deploying.html
- Source (Savannah): https://git.savannah.gnu.org/cgit/mediagoblin.git
- GitHub mirror: https://github.com/mediagoblin/mediagoblin
- Official site: https://mediagoblin.org
