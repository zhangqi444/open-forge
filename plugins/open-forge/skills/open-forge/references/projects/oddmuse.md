# Oddmuse

**Simple, single-file Perl wiki engine** — no database required, no installation wizard. Drop one Perl CGI script into your web server's cgi-bin, set a data directory, and you have a working wiki. Minimalist by design.

**Official site:** https://oddmuse.org
**Source:** https://github.com/kensanata/oddmuse
**License:** GPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Apache + Perl | Classic CGI setup; Apache with mod_cgi |
| Any VPS / bare metal | Nginx + fcgiwrap | Nginx with FastCGI wrapper for CGI scripts |

---

## Inputs to Collect

### Phase 1 — Planning
- Web server type (Apache recommended by upstream)
- Data directory path (e.g. `/var/local/oddmuse`)
- Public URL / domain

### Phase 2 — Deploy
- Web server user (e.g. `www-data` on Debian/Ubuntu, `wwwrun` on SUSE)
- Data directory writable by web server user

---

## Software-Layer Concerns

- **Single file:** Entire wiki is one Perl script (`wiki.pl`) — copy to `cgi-bin`, make executable
- **No database:** Pages stored as flat files in the data directory
- **Data dir:** Default is `/tmp/oddmuse` — change to a persistent path via `WikiDataDir` env var
- **Apache config:** Set `SetEnv WikiDataDir /var/local/oddmuse` in the virtual host config
- **Dependencies (Debian):** `perl libwww-perl libxml-rss-perl diffutils` (plus `apache2` and `coreutils`)

---

## Deployment (Debian/Ubuntu + Apache)

```bash
# Install dependencies
sudo apt-get install coreutils apache2 sudo wget perl libwww-perl libxml-rss-perl diffutils

# Install wiki.pl
sudo wget -O /usr/lib/cgi-bin/wiki.pl \
  http://git.savannah.gnu.org/cgit/oddmuse.git/plain/wiki.pl
sudo chmod +x /usr/lib/cgi-bin/wiki.pl
sudo chown www-data:www-data /usr/lib/cgi-bin/wiki.pl

# Create persistent data directory
sudo mkdir -p /var/local/oddmuse
sudo chown www-data:www-data /var/local/oddmuse

# Set data directory in Apache config
# Add to /etc/apache2/sites-available/000-default.conf:
# SetEnv WikiDataDir /var/local/oddmuse

sudo a2ensite default
sudo service apache2 reload
```

Visit: `http://your-server/cgi-bin/wiki.pl`

---

## Upgrade Procedure

```bash
# Replace wiki.pl with latest version
sudo wget -O /usr/lib/cgi-bin/wiki.pl \
  http://git.savannah.gnu.org/cgit/oddmuse.git/plain/wiki.pl
sudo chmod +x /usr/lib/cgi-bin/wiki.pl
sudo chown www-data:www-data /usr/lib/cgi-bin/wiki.pl
```

No database migrations needed — flat file storage.

---

## Gotchas

- **Default data dir is `/tmp/oddmuse`** — pages will be lost on reboot unless `WikiDataDir` is set to a persistent path
- **SUSE web server user is `wwwrun`** (not `www-data`) — adjust `chown` accordingly
- **CGI performance** — each request spawns a new Perl process; fine for low-traffic wikis, not suitable for high load
- **No Docker image** — designed for traditional CGI hosting; containerization is non-trivial
- **Minimal feature set by design** — extensions/modules available but core is intentionally simple

---

## Links

- Upstream README: https://github.com/kensanata/oddmuse#readme
- Official site & docs: https://oddmuse.org
