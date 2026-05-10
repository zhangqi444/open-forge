---
name: pypiserver
description: Recipe for self-hosting pypiserver, a minimal PyPI-compatible package server for uploading and downloading Python packages with pip. Based on upstream documentation at https://github.com/pypiserver/pypiserver.
---

# pypiserver

Minimal self-hosted PyPI server. Lets you upload private Python packages and install them with `pip` using `--extra-index-url`. Supports optional htpasswd authentication for uploads and downloads. Upstream: <https://github.com/pypiserver/pypiserver>. Stars: 2k+. License: MIT + zlib/libpng. Current stable: v2.4.1.

Useful for: private package distribution within a company or homelab, air-gapped environments, caching PyPI packages locally.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Recommended |
| Any Linux host | pip install + systemd | Lightweight alternative |
| Any host | Docker run | Quick start |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Package directory path | Host path for .whl/.tar.gz files |
| optional | htpasswd file | For upload/download authentication |
| optional | Authentication scope | uploads only vs all access |

## Docker Compose deployment

### Default (no authentication)

```yaml
services:
  pypiserver:
    image: pypiserver/pypiserver:latest
    container_name: pypiserver
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./packages:/data/packages
```

### With htpasswd authentication

```yaml
services:
  pypiserver:
    image: pypiserver/pypiserver:latest
    container_name: pypiserver
    restart: unless-stopped
    volumes:
      - ./packages:/data/packages
      - ./auth/.htpasswd:/data/auth/.htpasswd
    command: run -P /data/auth/.htpasswd -a update,download,list /data/packages
    ports:
      - "8080:8080"
```

```bash
# Create packages and auth directories
mkdir -p packages auth

# Create htpasswd file (requires apache2-utils or httpd-tools)
htpasswd -sc auth/.htpasswd myuser
# Or use passlib: pip install passlib && python -c "from passlib.apache import HtpasswdFile; f=HtpasswdFile('auth/.htpasswd',new=True); f.set_password('myuser','mypassword'); f.save()"

docker compose up -d
```

## Using the server

### Install packages

```bash
# From pypiserver instance
pip install --extra-index-url http://localhost:8080/simple/ mypackage

# With authentication
pip install --extra-index-url http://myuser:mypassword@localhost:8080/simple/ mypackage
```

Configure pip to always use the private index in `~/.pip/pip.conf` or `pip.ini`:

```ini
[global]
extra-index-url = http://myuser:mypassword@localhost:8080/simple/
```

### Upload packages

Using twine:

```bash
pip install twine
twine upload --repository-url http://localhost:8080/ dist/*
# With auth: twine upload --repository-url http://localhost:8080/ -u myuser -p mypassword dist/*
```

Using setuptools:

```bash
python setup.py sdist upload -r http://localhost:8080/
```

## Authentication options

The `-a` flag controls which operations require authentication:

| Value | Meaning |
|---|---|
| `update` | Require auth for uploads only (downloads are public) |
| `update,download,list` | Require auth for all operations |
| `.` | No authentication required |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

No database — packages are plain files on disk. Upgrades are safe and stateless.

## Gotchas

- pypiserver does **not** enforce package signing or integrity checks — it's a simple file server. Use it on a trusted network or behind TLS.
- By default, packages not found locally are redirected to pypi.org (`--fallback-url`). Disable with `--disable-fallback` for fully air-gapped deployments.
- The htpasswd file must use bcrypt or MD5 hashing that `passlib` supports — SHA1 may not work depending on the passlib version.
- Package files must be named following Python packaging conventions (e.g. `mypackage-1.0.0.tar.gz`) to be recognized.
- Serving thousands of packages: pypiserver scans the packages directory on each request by default. Use `--cache-control` or a caching reverse proxy for large indexes.

## Upstream docs

- README: https://github.com/pypiserver/pypiserver/blob/main/README.md
- Docker Compose examples: https://github.com/pypiserver/pypiserver/blob/main/docker-compose.yml
- PyPI: https://pypi.org/project/pypiserver/
