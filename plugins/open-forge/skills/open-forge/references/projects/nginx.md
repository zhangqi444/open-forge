---
name: nginx
description: NGINX recipe for open-forge. Covers package manager install (deb/rpm), Docker, and build from source. NGINX is the world's most popular web server, reverse proxy, and load balancer. Based on upstream docs at https://nginx.org/en/docs/.
---

# NGINX

High-performance HTTP web server, reverse proxy, load balancer, and TCP/UDP proxy. Used as a standalone server or as a front-end proxy for application servers (Node.js, Python, Ruby, etc.). Upstream: <https://github.com/nginx/nginx>. Docs: <https://nginx.org/en/docs/>.

NGINX is available as official stable and mainline release branches. Enterprise support and enhanced features are available from F5 (NGINX Plus) — those are out of scope here; this recipe covers the open-source BSD-licensed NGINX.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| APT / prebuilt deb | https://nginx.org/en/docs/install.html | Yes | Debian/Ubuntu. Official NGINX repo, not distro-packaged version. |
| YUM / prebuilt rpm | https://nginx.org/en/docs/install.html | Yes | RHEL/CentOS/Fedora/AlmaLinux. |
| Docker (official image) | https://hub.docker.com/_/nginx | Yes | Containerized deployments. |
| Build from source | https://nginx.org/en/docs/configure.html | Yes | Custom modules, specific compile flags. |
| Distro package | apt install nginx / dnf install nginx | Distro-maintained | Quick dev setup. Usually older version than official repo. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | Which install method? | Choose from table above | Drives which section loads |
| role | What role will NGINX serve? (web server / reverse proxy / load balancer) | Choose | Determines config template to use |
| domain | Domain name(s) to serve | Free-text | All public-facing installs |
| tls | Use Let's Encrypt TLS? | Yes/No | All public-facing installs |
| backend | Backend address(es) to proxy to (e.g. http://localhost:3000) | Free-text | Reverse proxy / LB role |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config file | /etc/nginx/nginx.conf (main), /etc/nginx/conf.d/*.conf (site includes), /etc/nginx/sites-available/ + sites-enabled/ (Debian convention) |
| Default port | 80 (HTTP), 443 (HTTPS) |
| Worker processes | auto in config = one per CPU core. Tune worker_connections for high load. |
| Log files | Access: /var/log/nginx/access.log, Error: /var/log/nginx/error.log |
| PID file | /run/nginx.pid |
| Modules | Static (compiled-in) or dynamic (.so). Dynamic modules loaded with load_module directive. |
| TLS | NGINX handles TLS natively. Use certbot for Let's Encrypt cert provisioning and renewal. |
| Test config | nginx -t validates config syntax before reload. Always run before reloading. |

## Method — APT (Debian/Ubuntu, official repo)

Source: https://nginx.org/en/docs/install.html

    # Install prereqs
    apt-get install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring

    # Import NGINX signing key
    curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
      | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

    # Add repo (stable branch)
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
      http://nginx.org/packages/debian $(lsb_release -cs) nginx" \
      | tee /etc/apt/sources.list.d/nginx.list

    apt-get update
    apt-get install -y nginx

    # Enable + start
    systemctl enable nginx
    systemctl start nginx

Verify: curl -I http://localhost/ should return 200 with "nginx" Server header.

## Method — YUM/DNF (RHEL/CentOS/AlmaLinux/Fedora)

Source: https://nginx.org/en/docs/install.html

    # Create repo file
    cat > /etc/yum.repos.d/nginx.repo << 'EOF'
    [nginx-stable]
    name=nginx stable repo
    baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
    gpgcheck=1
    enabled=1
    gpgkey=https://nginx.org/keys/nginx_signing.key
    module_hotfixes=true
    EOF

    dnf install -y nginx
    systemctl enable --now nginx

## Method — Docker

Source: https://hub.docker.com/_/nginx

Quick start (static file serving):

    docker run -d \
      --name nginx \
      -p 80:80 \
      -v /path/to/html:/usr/share/nginx/html:ro \
      nginx:stable-alpine

With custom config:

    docker run -d \
      --name nginx \
      -p 80:80 -p 443:443 \
      -v /path/to/nginx.conf:/etc/nginx/nginx.conf:ro \
      -v /path/to/html:/usr/share/nginx/html:ro \
      -v /path/to/certs:/etc/nginx/certs:ro \
      nginx:stable-alpine

Docker Compose example (reverse proxy):

    services:
      nginx:
        image: nginx:stable-alpine
        restart: unless-stopped
        ports:
          - "80:80"
          - "443:443"
        volumes:
          - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
          - ./certs:/etc/nginx/certs:ro

## Common config patterns

Reverse proxy to a backend app:

    server {
        listen 80;
        server_name example.com;

        location / {
            proxy_pass http://localhost:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }

Static file server:

    server {
        listen 80;
        server_name example.com;
        root /var/www/html;
        index index.html;

        location / {
            try_files $uri $uri/ =404;
        }
    }

## Upgrade procedure

APT:

    apt-get update && apt-get upgrade nginx

YUM/DNF:

    dnf upgrade nginx

Docker: pull new image and recreate container:

    docker pull nginx:stable-alpine
    docker compose up -d  # or docker stop/rm/run with new image

After upgrading, always: nginx -t && systemctl reload nginx (or docker exec nginx nginx -s reload)

## Gotchas

- Always nginx -t before reload: a bad config causes reload to fail and the old config stays live. With Docker, test in a temp container.
- Official repo vs distro package: distro-packaged nginx (apt-get install nginx without the official repo) is often 1-2 major versions behind. Use the official nginx.org repo for production.
- worker_processes auto: set to auto in nginx.conf to use all CPU cores. If NGINX is running in Docker with limited CPUs, auto correctly detects the container's CPU limit.
- Large file uploads: default client_max_body_size is 1m. Increase for file upload endpoints: client_max_body_size 100m;
- Reload vs restart: nginx -s reload (or systemctl reload nginx) applies config changes with zero downtime by gracefully draining existing connections. Only use restart if reload fails.
- HTTP/2: enable with listen 443 ssl http2; in the server block (requires TLS). HTTP/3/QUIC support is in mainline branch (listen 443 quic;).
- Certbot integration: use certbot --nginx for automatic cert provisioning and renewal config injection into NGINX vhosts.

## Links

- Install docs: https://nginx.org/en/docs/install.html
- Full docs: https://nginx.org/en/docs/
- Beginner's guide: https://nginx.org/en/docs/beginners_guide.html
- Directive reference: https://nginx.org/en/docs/dirindex.html
- GitHub: https://github.com/nginx/nginx
- Docker Hub: https://hub.docker.com/_/nginx
