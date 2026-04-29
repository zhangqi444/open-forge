---
name: caddy-project
description: Caddy recipe for open-forge. Apache-2.0 extensible web server with automatic HTTPS by default. Covers the native install (apt/brew/winget + systemd), official Docker image, Caddyfile config, dynamic JSON API, and the crucial infra-layer role Caddy plays across open-forge — many other recipes (Ghost, n8n, Immich, Syncthing, Uptime-Kuma, etc.) reference Caddy as the recommended reverse proxy.
---

# Caddy (web server + automatic HTTPS)

Apache-2.0 modular web server written in Go. Automatic HTTPS via Let's Encrypt / ZeroSSL. HTTP/1.1, HTTP/2, HTTP/3 support by default. Used by many of the other open-forge recipes as the reverse-proxy in front of their apps.

**Upstream README:** https://github.com/caddyserver/caddy/blob/master/README.md
**Docs:** https://caddyserver.com/docs/
**Install docs:** https://caddyserver.com/docs/install
**Caddyfile reference:** https://caddyserver.com/docs/caddyfile
**Official Docker image:** `caddy` on Docker Hub
**Docker guide:** https://github.com/caddyserver/caddy-docker

> [!NOTE]
> Caddy occupies a dual role in open-forge: it's **a project you can self-host** (e.g. as a static-file server) and **an infrastructure module** (reverse proxy in front of other apps). Many project recipes reference `references/modules/tls.md` which should document Caddy patterns. This recipe documents the software-layer concerns; the reverse-proxy module should live in `modules/`.

## What Caddy does

- **Automatic HTTPS** — obtains + renews Let's Encrypt / ZeroSSL certs automatically for public names; uses a local CA for internal names + IPs
- **Reverse proxy** — common use for self-hosters: put Caddy in front of an app listening on `127.0.0.1:<port>`
- **Static file server** — serve a directory over HTTP(S)
- **Modular** — custom modules for DNS providers, auth, storage backends, etc. via `xcaddy` build tool

## Compatible combos

| Infra | Runtime | Status | Notes |
|---|---|---|---|
| localhost | native (apt/brew/winget) | ✅ | Upstream ships packages for all major OSes |
| localhost | Docker | ✅ | `docker run caddy` |
| byo-vps | native | ✅ default | Standard pattern: `apt install caddy` + Caddyfile |
| byo-vps | Docker | ✅ | Common in compose stacks fronting other containers |
| aws/ec2 | native | ✅ | |
| hetzner/cloud-cx | native | ✅ | |
| kubernetes | community chart / caddy-ingress | ⚠️ | Caddy Ingress Controller exists but is less common than nginx-ingress / Traefik. |
| raspberry-pi | native | ✅ | arm64 packages ship |
| Windows | winget / chocolatey / exe | ✅ | First-class support |
| FreeBSD | pkg | ✅ | |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| dns | "Domain(s) Caddy will serve?" | Free-text | Must resolve to the host before Caddy can get certs |
| tls | "Email for Let's Encrypt notices?" | Free-text | Used in cert issuer's TOS-accept. Free LE cert requires it. |
| backends | "What are you fronting? (reverse-proxy targets)" | Free-text | e.g. `127.0.0.1:3000`, `127.0.0.1:8080` |
| http3 | "Enable HTTP/3 (QUIC)?" | AskUserQuestion: Yes (default) / No | On by default; requires UDP:443 open on firewall |
| modules | "Custom Caddy modules needed?" | Free-text | e.g. Cloudflare DNS plugin for DNS-01 challenge. Requires xcaddy build. |

## Install methods

### 1. Native packages (upstream-official)

Source: https://caddyserver.com/docs/install

**Debian/Ubuntu** (Cloudsmith repo — upstream publishes here):

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install -y caddy
sudo systemctl enable --now caddy
```

**Fedora/RHEL:**

```bash
sudo dnf install 'dnf-command(copr)'
sudo dnf copr enable @caddy/caddy
sudo dnf install caddy
```

**macOS:**

```bash
brew install caddy
```

**Windows:**

```powershell
winget install CaddyServer.Caddy
```

Config at `/etc/caddy/Caddyfile` (systemd unit looks there). Edit, then `sudo systemctl reload caddy`.

### 2. Docker (upstream image)

Source: https://github.com/caddyserver/caddy-docker

```bash
docker run -d --name caddy \
  --restart unless-stopped \
  --network host \
  -v $PWD/Caddyfile:/etc/caddy/Caddyfile \
  -v caddy_data:/data \
  -v caddy_config:/config \
  caddy:latest
```

Or non-host-networking:

```bash
docker run -d --name caddy \
  -p 80:80 -p 443:443 -p 443:443/udp \
  -v $PWD/Caddyfile:/etc/caddy/Caddyfile \
  -v caddy_data:/data \
  -v caddy_config:/config \
  caddy:latest
```

`caddy_data` must persist — it holds issued certs and the local CA root key. **Losing it triggers re-issuance** (fine, but counts against Let's Encrypt rate limits).

### 3. Standalone binary

Download from https://github.com/caddyserver/caddy/releases, drop on `$PATH`:

```bash
caddy run --config Caddyfile  # foreground
caddy start --config Caddyfile  # background (writes PID file)
caddy stop
caddy reload --config Caddyfile  # hot-reload, no dropped connections
```

### 4. Build with custom modules (xcaddy)

Required for DNS provider plugins (used for DNS-01 challenges on wildcard certs):

```bash
# Install xcaddy
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

# Build with Cloudflare DNS module
xcaddy build --with github.com/caddy-dns/cloudflare
# Outputs ./caddy with the module baked in
```

Or use `caddy-builder` Docker image for same purpose without a Go install.

## Software-layer concerns

### Caddyfile (recommended config)

Simple syntax. Example — reverse-proxy + auto HTTPS for two apps:

```caddy
# Global options
{
  email admin@example.com
}

n8n.example.com {
  reverse_proxy 127.0.0.1:5678
}

grafana.example.com {
  reverse_proxy 127.0.0.1:3000
}

# Static site
static.example.com {
  root * /srv/static
  file_server
  encode gzip zstd
}

# Basic auth
uptime.example.com {
  basicauth {
    admin <bcrypt-hash-from-`caddy hash-password`>
  }
  reverse_proxy 127.0.0.1:3001
}
```

Reload: `sudo systemctl reload caddy` or `caddy reload --config /etc/caddy/Caddyfile`.

### Automatic HTTPS — what you need

- Domain(s) in Caddyfile resolve to this host's public IP (A / AAAA records)
- Ports 80 + 443 reachable from the internet
- Email set (globally or per-site block) — required for Let's Encrypt ACME account

Caddy tries HTTP-01 first (needs :80), falls back to TLS-ALPN (needs :443). For wildcards, use DNS-01 (requires a DNS plugin built in with xcaddy).

### Paths

| Thing | Path (native) | Path (Docker) |
|---|---|---|
| Config | `/etc/caddy/Caddyfile` | `/etc/caddy/Caddyfile` |
| Data (certs, CA root, etc.) | `/var/lib/caddy/` | `/data` |
| Runtime config cache | `/var/lib/caddy/.local/share/caddy/` | `/config` |
| Logs | systemd journal (`journalctl -u caddy`) or file per Caddyfile | stdout/stderr |

**Back up `/data`.** It contains issued certs + the local CA root used for internal hostnames. Losing it = re-issuance for public certs (rate-limited), and new CA root for internal certs (clients must re-trust).

### Config reload

`caddy reload` does graceful reload — no dropped connections. For large Caddyfiles, reload can take a second or two.

### JSON API

`http://localhost:2019/` (admin endpoint, default bind 127.0.0.1 only — safe). Programmatic config updates:

```bash
curl localhost:2019/load -H "Content-Type: application/json" -d @config.json
```

Used for dynamic config — on-demand cert issuance, dynamic backend lists, etc. Rarely needed for static self-host.

### HTTP/3

On by default since Caddy 2.6. Requires UDP:443 open. Verify: `curl --http3 https://your.site` or https://http3check.net.

### Module system

Caddy is modular. The default binary includes: `file_server`, `reverse_proxy`, `basicauth`, `encode` (compression), auto-HTTPS. To add:

- DNS providers for DNS-01 challenges: `caddy-dns/cloudflare`, `caddy-dns/route53`, ~30 others
- Auth modules: `greenpau/caddy-security` for OAuth/OIDC/SAML
- Logging: `caddy-encore` etc.

Built via `xcaddy build --with <module>`. Or use the `caddy:builder` Docker image.

## Upgrade procedure

**Native (apt):**

```bash
sudo apt update && sudo apt upgrade caddy
sudo systemctl restart caddy
```

**Docker:**

```bash
docker pull caddy:latest
docker compose up -d  # or re-run docker run
```

Config + certs persist across upgrades. Caddy reloads gracefully, no downtime.

**Custom build (xcaddy):** rebuild with `xcaddy build` against the new version.

Release notes: https://github.com/caddyserver/caddy/releases. Caddy follows semver; majors can change Caddyfile syntax.

## Gotchas

- **Requires email for Let's Encrypt.** Unset = no certs. Either global `{ email ... }` or per-site.
- **Needs ports 80 + 443 from the internet.** Home NAT users: port-forward both. Port 80 is **required** even for HTTPS (for ACME HTTP-01 challenges + HTTP→HTTPS redirect).
- **HTTP/3 needs UDP:443.** Many firewalls block UDP. Symptoms: site works, but slow / HTTP/2-only. `caddy reload` won't fix, but verify firewall.
- **Rate limits on re-issuance.** Let's Encrypt: 5 certs per week per domain. Losing `/data` and re-running on 6 subdomains = you're fine, but burn it 5 times and you're locked for a week. Use staging first if experimenting: `{ acme_ca https://acme-staging-v02.api.letsencrypt.org/directory }`.
- **DNS-01 for wildcards requires a custom-built Caddy.** Default binary can't. Either use xcaddy or the `caddy:builder` image.
- **Basic-auth passwords must be bcrypt.** Use `caddy hash-password` to generate. Plaintext in Caddyfile won't work.
- **Reverse proxy to IPv6-only upstream.** Use `[::1]:port` with brackets.
- **Container host networking vs port mapping.** On Docker Desktop (macOS/Windows), host networking is semi-broken. Use `-p 80:80 -p 443:443 -p 443:443/udp` instead.
- **Caddyfile reload has gotchas with changed global options.** Changing `{ email }` or ACME issuer mid-runtime sometimes needs a full `restart`, not just `reload`. Edge case.
- **Internal CA root key.** Caddy generates a local CA for private names / IPs. Clients that trust it need the root (export via `caddy trust` or copy from `/data/pki/authorities/local/root.crt`).
- **Built binary is ~30 MB.** Not small for "just a web server." Static compilation + embedded certmagic + many modules.
- **Ingress controller story is weaker than nginx.** If your k8s story depends on ingress, Traefik / nginx-ingress are better battle-tested. Caddy shines standalone.

## TODO — verify on subsequent deployments

- [ ] Worked DNS-01 example with Cloudflare module + wildcard cert.
- [ ] Caddy + OIDC via `greenpau/caddy-security` for auth-in-front-of-unauthed-apps pattern.
- [ ] Multi-backend load-balance snippet for HA.
- [ ] `caddy trust` cert-export script for internal CA distribution.
- [ ] `references/modules/tls.md` — distill the Caddy pattern there, cross-reference from every project recipe.
