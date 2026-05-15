---
name: labca
description: LabCA recipe for open-forge. Private ACME Certificate Authority for internal use, built on Let's Encrypt's Boulder engine. Docker Compose deploy with web GUI. Source: https://github.com/hakwerk/labca
---

# LabCA

A private Certificate Authority for internal (homelab / intranet) use, built on top of Let's Encrypt's open-source Boulder ACME engine. Provides an automated ACME endpoint so internal clients can obtain trusted TLS certificates via standard certbot / acme.sh / lego clients — without exposing a domain publicly or paying for commercial certs. Upstream: <https://github.com/hakwerk/labca>.

LabCA wraps Boulder in a single Docker Compose stack and adds a web GUI for cert management, revocation, and backups. All data is stored in Docker volumes.

> **Not for Raspberry Pi / ARM.** Boulder (the underlying engine) cannot run on ARM architectures.
>
> **FQDN required.** LabCA must have a proper DNS name — it cannot run on an IP address alone. Boulder requires a resolvable hostname to issue certificates.

## Compatible deploy methods

| Method | Notes |
|---|---|
| Docker Compose (standard) | Primary supported method |
| Docker Compose (pinned version) | Use LABCA_IMAGE_VERSION env to pin instead of :latest |
| Standalone / step-ca mode | Community-maintained variant; uses step-ca instead of Boulder |

## System requirements

- x86-64 Linux (ARM not supported)
- Docker with the Compose plugin (`docker compose` v2)
- A resolvable FQDN in local DNS pointing to the LabCA host IP
- Ports 80 and 443 accessible from clients that will request certs

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | What FQDN will LabCA be accessible at? (e.g. labca.internal.example.com) | Must resolve in DNS before starting. Set as LABCA_FQDN |
| preflight | Is that hostname already in your local DNS? | LabCA will fail setup if DNS doesn't resolve |
| deploy | Pin to a specific version, or use :latest? | :latest auto-updates; pinned version via LABCA_IMAGE_VERSION=v26.04 |

---

## Install

Install Docker and the Compose plugin (Ubuntu/Debian):

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

Clone the repo and start:

```bash
git clone https://github.com/hakwerk/labca.git
cd labca/build
export LABCA_FQDN=labca.example.com
docker compose up -d
```

> If you forget to export LABCA_FQDN before running `docker compose up`, containers fail to start with: `exec: "labca/entrypoint.sh": no such file or directory`. Fix: export the variable and rerun.

Tail logs during startup (Boulder takes 30-60 seconds to initialise):

```bash
docker compose logs -f
```

---

## Web setup

After containers are up, open `https://${LABCA_FQDN}` in a browser. The first-run setup wizard walks through:

1. Admin account creation (email + password)
2. Root CA certificate configuration (org name, key type, validity period)
3. Issuing CA certificate configuration
4. DNS check confirmation

After setup completes: **export and back up your Root CA and Issuer certificates immediately** (Certificates tab → Manage page). Store the backup files off-server — losing them means losing the ability to verify or revoke issued certificates.

---

## Pinning to a specific version

To avoid auto-pulling `:latest` on each restart, set a version via `.env`:

```bash
echo "LABCA_IMAGE_VERSION=v26.04" > labca.env
```

Or export before running compose:

```bash
export LABCA_IMAGE_VERSION=v26.04
docker compose up -d
```

Check available versions: https://github.com/hakwerk/labca/releases

---

## Using LabCA as an ACME endpoint

After setup, configure ACME clients to point at your LabCA instance instead of Let's Encrypt. Example with certbot:

```bash
certbot certonly \
  --server https://labca.example.com/acme/v2/directory \
  --standalone \
  -d myapp.internal.example.com
```

With acme.sh:

```bash
acme.sh --issue \
  --server https://labca.example.com/acme/v2/directory \
  -d myapp.internal.example.com \
  --standalone
```

> All client machines must trust your LabCA Root CA certificate. Export it from the web UI (Certificates → Root CA → Download) and install it into the OS trust store / browser on each client.

### Installing the Root CA on clients

```bash
# Linux (Debian/Ubuntu)
sudo cp labca-root.crt /usr/local/share/ca-certificates/labca-root.crt
sudo update-ca-certificates

# Linux (RHEL/Fedora)
sudo cp labca-root.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```

---

## Upgrade

```bash
cd labca/build
docker compose down
git pull
docker compose pull
docker compose up -d --remove-orphans
docker image prune
```

Or use Watchtower for automatic image updates: https://containrrr.dev/watchtower/
Or use Diun for update notifications: https://crazymax.dev/diun/

---

## Backup

From the web UI: Manage page → Backup tab → Create backup. Download the backup file and store off-server. Also export Root CA and Issuer certificates from the Certificates tab.

All persistent data lives in Docker named volumes. Include those volumes in your regular backup strategy:

```bash
docker volume ls | grep labca
# Back up each volume (example with docker cp into a tarball)
docker run --rm -v labca_data:/source -v $(pwd):/backup alpine \
  tar czf /backup/labca-data-$(date +%F).tar.gz -C /source .
```

---

## Gotchas

- **ARM not supported.** Boulder (the ACME CA engine LabCA wraps) cannot run on Raspberry Pi or other ARM hosts. x86-64 only.
- **FQDN required, IP won't work.** Boulder's internal validation requires a proper hostname in local DNS. LabCA will refuse to start or fail setup if you try to use an IP address.
- **`LABCA_FQDN` must be exported before `docker compose up`.** Forgetting it causes entrypoint.sh resolution failures — the containers start but immediately error with a missing script message.
- **DNS must resolve before setup.** The web setup wizard validates that the FQDN resolves correctly. If DNS isn't set up yet, step through the DNS setup first, then run `docker compose up`.
- **Port 80 is required for HTTP-01 ACME challenges.** Even if LabCA itself serves HTTPS, the Boulder engine uses port 80 for the HTTP-01 challenge type. Ensure port 80 is open from the client subnet.
- **Root CA backup is critical.** If you lose the Root CA key (stored in Docker volumes), you cannot reissue or revoke existing certificates under it. Back up immediately after initial setup and after any CA key rotation.
- **`:latest` tag means silent updates.** The default compose file uses `:latest` image tags. When you run `docker compose pull` + `docker compose up -d`, you may get a new LabCA version. Use `LABCA_IMAGE_VERSION` to pin if you need version stability.
- **Clients must trust your Root CA.** Browsers and OS trust stores do not know about your private CA by default. Distribute and install the Root CA cert to every machine that will use LabCA-issued certificates.
- **Not for public internet CA use.** LabCA is designed for internal / homelab networks only. It does not chain to any public root, so certificates it issues will not be trusted by default outside your network.

---

## Links

- GitHub: https://github.com/hakwerk/labca
- Releases: https://github.com/hakwerk/labca/releases
- Boulder (ACME engine): https://github.com/letsencrypt/boulder
- Watchtower (auto-updates): https://containrrr.dev/watchtower/
- Diun (update notifications): https://crazymax.dev/diun/
