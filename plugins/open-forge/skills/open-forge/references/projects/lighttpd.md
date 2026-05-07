---
name: lighttpd
description: Lighttpd recipe for open-forge. Secure, fast, and flexible web server optimized for high-performance environments. BSD-3-Clause licensed. Source: https://git.lighttpd.net/lighttpd/lighttpd1.4
---

# Lighttpd

A secure, fast, and highly flexible web server optimized for high-performance environments with low memory overhead. Excellent for serving static files, FastCGI apps (PHP, Python), and reverse proxying. First choice for resource-constrained servers. BSD-3-Clause licensed. Source: <https://git.lighttpd.net/lighttpd/lighttpd1.4>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | System package (deb/rpm) | Preferred |
| Any Linux | Build from source | For latest features |
| Docker | Docker Compose | Available on Docker Hub as `sebp/lighttpd` |
| OpenWrt/embedded | Package manager | Built for low-RAM environments |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. example.com |
| "Role?" | static / FastCGI-PHP / reverse-proxy | Determines which modules to enable |
| "TLS cert?" | Path or Let's Encrypt | e.g. /etc/letsencrypt/live/... |
| "Document root?" | Path | e.g. /var/www/html |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "PHP-FPM socket?" | Path | e.g. /run/php/php8.1-fpm.sock |
| "Upstream proxy target?" | host:port | Only if reverse proxying |

## Software-Layer Concerns

- **Module system**: Modules loaded via `server.modules` in config — only load what you need.
- **lighttpd.conf**: Main config at `/etc/lighttpd/lighttpd.conf`; Debian splits into `conf-available/` + `conf-enabled/` with `lighty-enable-mod`.
- **FastCGI vs SCGI**: Use `mod_fastcgi` for PHP-FPM (or legacy php-cgi), `mod_scgi` for WSGI apps.
- **SSL/TLS**: `mod_openssl` (since 1.4.56) replaces old `mod_gnutls` and `mod_mbedtls`; use `ssl.pemfile` pointing to combined cert+key PEM.
- **Let's Encrypt**: Use Certbot webroot plugin; lighttpd needs `mod_alias` to serve `/.well-known/acme-challenge/`.
- **URL rewrites**: `mod_rewrite` with regex; note lighttpd uses PCRE2 since 1.4.65.
- **Compression**: `mod_deflate` for on-the-fly gzip/br compression.
- **Access log**: `mod_accesslog` — disabled by default in some distros.
- **`server.max-fds`**: Raise on busy servers — default may be low for thousands of connections.

## Deployment

### 1. Install

```bash
apt install lighttpd

# For PHP support:
apt install php8.1-fpm
lighty-enable-mod fastcgi fastcgi-php
```

### 2. Basic static file server

```bash
# /etc/lighttpd/lighttpd.conf (key settings)
server.document-root = "/var/www/html"
server.port = 80
server.modules = ("mod_access", "mod_accesslog", "mod_deflate")

accesslog.filename = "/var/log/lighttpd/access.log"
mimetype.assign = (
    ".html" => "text/html",
    ".css"  => "text/css",
    ".js"   => "application/javascript",
)
```

### 3. PHP-FPM via FastCGI

```bash
# /etc/lighttpd/conf-enabled/15-fastcgi-php.conf
fastcgi.server += ( ".php" =>
    ((
        "socket" => "/run/php/php8.1-fpm.sock",
        "broken-scriptfilename" => "enable"
    ))
)
```

### 4. TLS with Let's Encrypt

```bash
# Combine cert + key into one PEM
cat /etc/letsencrypt/live/example.com/fullchain.pem \
    /etc/letsencrypt/live/example.com/privkey.pem \
    > /etc/lighttpd/ssl/example.com.pem
chmod 600 /etc/lighttpd/ssl/example.com.pem

# /etc/lighttpd/lighttpd.conf additions
server.modules += ("mod_openssl")
$SERVER["socket"] == ":443" {
    ssl.engine  = "enable"
    ssl.pemfile = "/etc/lighttpd/ssl/example.com.pem"
    ssl.ca-file = "/etc/letsencrypt/live/example.com/chain.pem"
}
```

### 5. Reverse proxy

```bash
server.modules += ("mod_proxy")
proxy.server = ( "" => (( "host" => "127.0.0.1", "port" => 3000 )) )
```

### 6. Enable and start

```bash
lighttpd -t -f /etc/lighttpd/lighttpd.conf  # test config
systemctl enable --now lighttpd
```

## Upgrade Procedure

1. `apt upgrade lighttpd`
2. `lighttpd -t -f /etc/lighttpd/lighttpd.conf` — test before reload
3. `systemctl reload lighttpd`

## Gotchas

- **Combined PEM for TLS**: Unlike NGINX/Apache, lighttpd requires cert and key concatenated in one file for `ssl.pemfile`.
- **Let's Encrypt renewal**: Add a deploy hook to recreate the combined PEM after renewal; `systemctl reload lighttpd`.
- **`mod_openssl` not `mod_gnutls`**: Since 1.4.56, `mod_openssl` is the correct SSL module. Old configs using `mod_gnutls` need updating.
- **No SNI by default**: For multiple TLS vhosts, ensure `ssl.sni-backend = "select"` is set.
- **Debian `lighty-enable-mod` wrapper**: Enables/disables module config snippets from `conf-available/` — don't hand-edit symlinks.
- **`server.max-connections` separate from `max-fds`**: Both may need raising for busy servers; check `/proc/sys/fs/file-max` too.
- **CGI deprecated**: Classic CGI is extremely slow; use FastCGI or SCGI instead.

## Links

- Website: https://www.lighttpd.net/
- Documentation: https://redmine.lighttpd.net/projects/lighttpd/wiki
- Source: https://git.lighttpd.net/lighttpd/lighttpd1.4
- Config examples: https://redmine.lighttpd.net/projects/lighttpd/wiki/Docs_ConfigurationOptions
