---
name: apache-http-server
description: Apache HTTP Server recipe for open-forge. The world's most widely used web server. Secure, efficient, and extensible. Apache-2.0. Source: https://svn.apache.org/repos/asf/httpd/httpd/trunk/
---

# Apache HTTP Server

The world's most widely used web server. Provides HTTP/HTTPS services with a rich module ecosystem covering authentication, URL rewriting, proxying, caching, SSL/TLS, and virtual hosting. The gold-standard reference implementation for HTTP standards compliance. Apache-2.0 licensed. Source: <https://httpd.apache.org/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux (Debian/Ubuntu) | deb (apache2) | Standard package, well-maintained |
| Linux (RHEL/CentOS/Fedora) | rpm (httpd) | Standard package |
| Linux (any) | Build from source | For custom module sets |
| Docker | httpd:alpine or httpd:2.4 | Official Docker Hub image |
| macOS | Homebrew | `brew install httpd` |
| Windows | Apache Lounge builds | https://www.apachelounge.com/ |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain(s)?" | FQDN list | For VirtualHost configuration |
| "HTTP port?" | Number | Default 80 |
| "HTTPS port?" | Number | Default 443 |
| "TLS cert source?" | Self-signed / Let's Encrypt / Existing | mod_ssl setup |
| "Use as reverse proxy?" | Yes / No | Enables mod_proxy |
| "PHP support?" | Yes / No | libapache2-mod-php or PHP-FPM |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Document root?" | Path | Default /var/www/html |
| "Enable .htaccess?" | Yes / No | AllowOverride All in VirtualHost |
| "Access log path?" | Path | Default /var/log/apache2/access.log |

## Software-Layer Concerns

- **Configuration layout**: Debian/Ubuntu uses `/etc/apache2/` with `sites-available/`, `sites-enabled/`, `mods-available/`, `mods-enabled/` — use `a2ensite`, `a2dissite`, `a2enmod`, `a2dismod`.
- **RHEL/CentOS layout**: Single `/etc/httpd/conf/httpd.conf` with includes from `conf.d/`.
- **Module loading**: Modules are compiled-in or dynamically loaded (DSO). Use `apxs` to build third-party modules.
- **Worker MPM**: Choose MPM based on workload — `prefork` for PHP mod_php, `event` for high concurrency (PHP-FPM).
- **mod_rewrite**: Required for most CMS clean URLs — ensure `AllowOverride All` or `AllowOverride FileInfo` in the VirtualHost.
- **SELinux/AppArmor**: On RHEL/Ubuntu, file contexts and profiles may need adjustment for non-default document roots.
- **Graceful reload**: `apachectl graceful` or `systemctl reload apache2` reloads config without dropping connections.

## Deployment

### Linux — package install (Debian/Ubuntu)

```bash
apt install apache2

# Enable common modules
a2enmod ssl rewrite headers proxy proxy_http

# Create a VirtualHost
cat > /etc/apache2/sites-available/example.conf << 'EOF'
<VirtualHost *:80>
    ServerName example.com
    DocumentRoot /var/www/example
    <Directory /var/www/example>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/example-error.log
    CustomLog ${APACHE_LOG_DIR}/example-access.log combined
</VirtualHost>
EOF

a2ensite example.conf
systemctl reload apache2
```

### Linux — package install (RHEL/CentOS)

```bash
dnf install httpd mod_ssl

systemctl enable --now httpd

# Config at /etc/httpd/conf.d/example.conf
```

### Docker

```yaml
# docker-compose.yml
services:
  httpd:
    image: httpd:2.4-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./html:/usr/local/apache2/htdocs/
      - ./httpd.conf:/usr/local/apache2/conf/httpd.conf
```

```bash
docker compose up -d
```

### TLS with Let's Encrypt (Certbot)

```bash
apt install certbot python3-certbot-apache
certbot --apache -d example.com
# Auto-renew via systemd timer (installed by certbot)
```

## Upgrade Procedure

- **Packages**: `apt upgrade apache2` (Debian) or `dnf upgrade httpd` (RHEL)
- **Docker**: Pull new tag (`httpd:2.4-alpine`), `docker compose pull && docker compose up -d`
- **Source**: Build new version, `make install`, then `apachectl restart`

## Gotchas

- **prefork vs event MPM**: `mod_php` requires prefork MPM. For better performance with PHP-FPM, switch to `event` MPM (`a2dismod php8.x && a2enmod proxy_fcgi && a2enconf php8.x-fpm`).
- **.htaccess performance**: `AllowOverride All` causes a filesystem stat for `.htaccess` on every request — disable for production if possible, use VirtualHost directives instead.
- **Port conflicts**: If NGINX is also installed, ensure they don't both bind port 80/443.
- **SELinux**: On RHEL, custom document roots require `chcon -R -t httpd_sys_content_t /your/path` or `setsebool httpd_can_network_connect on` for proxying.
- **mod_rewrite loop protection**: Always add `RewriteOptions InheritDownBefore` or check for infinite loops when nesting includes.
- **ServerName required**: Without `ServerName` in main config, Apache logs a warning and uses system hostname — set it explicitly.

## Links

- Website: https://httpd.apache.org/
- Documentation: https://httpd.apache.org/docs/current/
- Module index: https://httpd.apache.org/docs/current/mod/
- Docker Hub: https://hub.docker.com/_/httpd
- Debian wiki: https://wiki.debian.org/Apache
