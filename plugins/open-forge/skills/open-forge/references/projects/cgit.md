---
name: cgit
description: Cgit recipe for open-forge. Hyperfast, lightweight CGI web interface for Git repositories, written in C with built-in caching. Source: https://git.zx2c4.com/cgit/
---

# Cgit

A hyperfast, lightweight web interface for Git repositories written in C. Uses a built-in cache to minimize server I/O. Renders repository browsing, commit logs, diffs, blame, tags, and atom feeds. No JavaScript required. GPL-2.0 licensed. Upstream: <https://git.zx2c4.com/cgit/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS | C binary + Apache/NGINX (CGI or FastCGI) | Compiled from source or OS package |
| Debian/Ubuntu | APT package + Apache/NGINX | `apt install cgit` |
| Arch Linux | AUR package | `pacman -S cgit` or AUR |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for cgit?" | FQDN | e.g. git.example.com |
| "Path to git repositories?" | Directory | e.g. /srv/git or /home/git — where bare repos live |
| "Install via package or build from source?" | package / source | APT/pacman for common distros; source for others |
| "Web server?" | Apache / NGINX | CGI or FastCGI configuration differs |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Instance name?" | String | Shown in page header (cgitrc: root-title) |
| "Syntax highlighting?" | Yes / No | Requires highlight or python-pygments installed |
| "Clone URL prefix?" | URL prefix | Shown on repo pages for git clone instructions |

## Software-Layer Concerns

- **CGI binary**: `cgit.cgi` installed to the web root; the webserver invokes it per request. FastCGI is also supported for better performance.
- **cgitrc**: Main config file (typically `/etc/cgitrc` or `/var/www/cgit/cgitrc`). Controls all settings — root title, repos, cache size, filters, etc.
- **Cache**: Built-in file cache reduces server load. Cache dir configured in cgitrc (`cache-root`).
- **Syntax highlighting**: Optional; works with `highlight` or `python-pygments` as an external filter.
- **No write operations**: Cgit is read-only — browsing only. For push/clone, configure SSH or a separate git daemon.
- **Lua filter support**: Optional Lua scripting for custom filters (email obfuscation, syntax highlight, etc.) — compile with `NO_LUA=0`.
- **Git submodule**: Source build includes Git as a submodule — must init before building.

## Deployment

### Debian/Ubuntu (via APT)

```bash
apt install cgit apache2
# or: apt install cgit nginx fcgiwrap

# Configure /etc/cgitrc:
cat > /etc/cgitrc << EOF
root-title=My Git Repositories
root-desc=Hosted with cgit
cache-size=1000
scan-path=/srv/git
EOF

# Apache config (CGI):
# Enable cgi: a2enmod cgi
# Add to vhost: ScriptAlias /cgit/ /usr/lib/cgit/cgit.cgi/
```

### NGINX + fcgiwrap

```nginx
server {
    listen 443 ssl;
    server_name git.example.com;
    root /usr/share/cgit;
    try_files $uri @cgit;

    location @cgit {
        fastcgi_pass unix:/run/fcgiwrap.socket;
        fastcgi_param SCRIPT_FILENAME /usr/lib/cgit/cgit.cgi;
        fastcgi_param PATH_INFO $uri;
        fastcgi_param QUERY_STRING $args;
        include fastcgi_params;
    }

    location ~ ^/(cgit\.css|cgit\.png|favicon\.ico) {
        root /usr/share/cgit;
    }
}
```

### Build from source

```bash
git clone https://git.zx2c4.com/cgit
cd cgit
git submodule init && git submodule update
make
sudo make install
# Installs cgit.cgi and cgit.css to /var/www/htdocs/cgit by default
# Override: make prefix=/usr CGIT_SCRIPT_PATH=/var/www/html install
```

## Upgrade Procedure

1. APT: `apt upgrade cgit`
2. Source: `git pull`, update submodule, `make && sudo make install`, restart webserver.
3. Clear the cache directory after upgrading to avoid stale cached pages.

## Gotchas

- **Read-only**: Cgit provides no write access. Git push requires separate SSH/gitolite/Gitea setup.
- **fcgiwrap required for NGINX**: NGINX cannot invoke CGI directly — needs `fcgiwrap` or equivalent.
- **Cache stale after repo changes**: Cache is time-based; set `cache-dynamic-ttl` and `cache-static-ttl` appropriately for your update frequency.
- **scan-path vs repo.url**: Use `scan-path` to auto-discover all repos in a directory, or define repos individually with `repo.url` / `repo.path` directives.
- **Lua optional**: Lua support must be compiled in — packages usually include it; source build uses `NO_LUA=1` to exclude.

## Links

- Source: https://git.zx2c4.com/cgit/
- About / documentation: https://git.zx2c4.com/cgit/about/
- cgitrc man page: https://git.zx2c4.com/cgit/tree/cgitrc.5.txt
