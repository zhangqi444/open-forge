# motion.tools (Antragsgrün)

**Online motion and amendment management tool** for NGOs, political parties, and social initiatives. Collaboratively draft resolutions and party platforms, manage candidacies, run online votings, and coordinate speaking lists at conventions and assemblies.

**Official sites:** https://motion.tools (EN), https://antragsgruen.de (DE), https://discuss.green (multilingual)  
**Source:** https://github.com/CatoTH/antragsgruen  
**Demo:** https://sandbox.motion.tools/createsite  
**License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux | PHP 8.2+ + MySQL/MariaDB + Apache/nginx | Primary install (pre-bundled ZIP) |
| Any | Docker | Official Docker image available |
| Any | Source build (PHP + Node.js) | For development or custom builds |

---

## System Requirements

- PHP ≥ 8.2 (8.4+ recommended)
- PHP extensions: `intl`, `gd`, `mysql`, `opcache`, `curl`, `xml`, `mbstring`, `zip`, `iconv`
- MySQL or MariaDB
- Apache or nginx web server
- Composer (PHP) + npm (for source builds)

---

## Inputs to Collect

### Provision phase
| Input | Description |
|-------|-------------|
| `DB_HOST` / `DB_NAME` / `DB_USER` / `DB_PASS` | Database connection |
| `APP_URL` | Public URL |
| Admin email / password | Initial site administrator |

---

## Software-layer Concerns

### Install (pre-bundled ZIP — recommended)
```bash
# Download latest release ZIP from GitHub releases
wget https://github.com/CatoTH/antragsgruen/releases/latest/download/antragsgruen.zip
unzip antragsgruen.zip -d /var/www/antragsgruen
chown -R www-data:www-data /var/www/antragsgruen
# Browse to http://your-domain/antragsgruen/ and run the web installer
```

### Install (from source)
```bash
git clone https://github.com/CatoTH/antragsgruen.git
cd antragsgruen
curl -sS https://getcomposer.org/installer | php
./composer.phar install --prefer-dist
npm install && npm run build
# Configure config/config.json (or use web installer)
```

### Docker
```bash
docker pull ghcr.io/catoth/antragsgruen:latest
docker run -d \
  -p 80:80 \
  -e ANTRAGSGRUEN_DB_HOST=your-db-host \
  -e ANTRAGSGRUEN_DB_NAME=antragsgruen \
  -e ANTRAGSGRUEN_DB_USER=antragsgruen \
  -e ANTRAGSGRUEN_DB_PASSWORD=secret \
  ghcr.io/catoth/antragsgruen:latest
```

See the [Docker documentation](https://github.com/CatoTH/antragsgruen/blob/master/docs/docker.md) for full configuration.

### Features
- Submit and amend motions online
- Amendment diff view (tracked changes)
- Draft resolutions with version history
- Online votings
- Speaking list management
- Candidacy management
- Multiple export formats (PDF, ODT, HTML, LaTeX)
- Multi-site installation
- WCAG AA accessibility compliance
- Available in: German, English, French, Dutch, Catalan, and more

### nginx config
Sample nginx config at `docs/nginx.sample.conf` in the repository.

---

## Upgrade Procedure

1. Download the new release ZIP and extract over the existing installation
2. Keep `config/config.json` (database credentials and settings)
3. Run database migrations: browse to `http://your-domain/antragsgruen/update` or run `php yii migrate`

---

## Gotchas

- **Web installer** simplifies first setup. Use it unless you have specific requirements.
- **Multi-site** — one installation can host multiple independent "sites" for different organizations.
- **AGPL-3.0** — any modifications must be open-sourced if deployed publicly.
- **Hosted version available** at https://motion.tools / https://antragsgruen.de for organizations that don't want to self-host.
- **Used by major organizations:** European Green Party, German Federal Youth Council, European Youth Forum.

---

## References

- Upstream README: https://github.com/CatoTH/antragsgruen#readme
- Demo: https://sandbox.motion.tools/createsite
- Official site: https://motion.tools
