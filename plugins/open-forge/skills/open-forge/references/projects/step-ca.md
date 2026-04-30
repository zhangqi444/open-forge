---
name: step-ca
description: "Private, online Certificate Authority for issuing X.509 + SSH certs. ACMEv2 server (like Let's Encrypt but for your own domains). OIDC/JWT/X5C/SCEP/NTF provisioners. Pairs with `step` CLI. Go binary; tiny footprint. Apache-2.0."
---

# step-ca

step-ca is **your own private Certificate Authority (CA)** as a single Go binary. Think of it as "Let's Encrypt, but for your internal network / private domains / machine identities / SSH." Issue short-lived X.509 certificates to internal services (intranet, VPN, Kubernetes, home lab) and SSH certificates to users/hosts, all via standard protocols (ACMEv2, SCEP, OIDC, JWT) — with full automation like Let's Encrypt but without internet exposure.

This is the tool many homelabbers reach for when:

- You want HTTPS on `server.home.local` without certificate warnings (self-signed alone = warnings; step-ca = browser-trusted after you install your root CA)
- You run internal services and want automated cert rotation
- You want SSH certificate auth (short-lived, user-attested) instead of managing `authorized_keys`
- You need mutual TLS (mTLS) between internal services

step-ca is the **server**; **`step` CLI** is the companion client for requesting certs, admin, and bootstrap.

- Upstream repo: <https://github.com/smallstep/certificates>
- `step` CLI repo: <https://github.com/smallstep/cli>
- Website: <https://smallstep.com>
- Docs: <https://smallstep.com/docs/step-ca>
- CLI docs: <https://smallstep.com/docs/step-cli>
- Docker Hub: <https://hub.docker.com/r/smallstep/step-ca>

## Architecture in one minute

- **`step-ca` Go binary** — HTTPS server on (default) port 9000; stateless config + database (BoltDB or Postgres/MySQL) + keys
- **`step` CLI** — used by operators + clients to bootstrap, issue, rotate
- **Root CA** + intermediate CA keys stored encrypted
- **Provisioners** — how clients authenticate to get certs:
  - **ACMEv2** — same protocol as Let's Encrypt (certbot, lego, cert-manager, Traefik, Caddy all work)
  - **JWT/OIDC** — tokens with claims
  - **X5C** — present an existing cert as auth
  - **SCEP** — enterprise device enrollment
  - **Nebula / AWS / GCP / Azure** — cloud instance identity
- **SSH CA** mode for SSH certificates (host + user)
- Can front with Traefik/nginx if you want TLS on the CA itself + reverse proxy

## Compatible install methods

| Infra       | Runtime                                              | Notes                                                        |
| ----------- | ---------------------------------------------------- | ------------------------------------------------------------ |
| Single VM   | Native Go binary                                        | Simplest; systemd unit                                            |
| Single VM   | **Docker (`smallstep/step-ca`)**                              | **Easy**                                                              |
| Homelab Pi  | arm64 binary                                                 | Runs well on a Pi                                                          |
| Kubernetes  | Helm chart (cert-manager upstream integration)                   | Popular with cert-manager ACME issuer                                              |
| Managed     | Smallstep Hosted CA (commercial)                                     | If you don't want to run it                                                              |

## Inputs to collect

| Input               | Example                        | Phase     | Notes                                                          |
| ------------------- | ------------------------------ | --------- | -------------------------------------------------------------- |
| CA hostname         | `ca.example.local`                | DNS       | Must be resolvable from clients                                      |
| Listen address      | `0.0.0.0:9000`                     | Network   | Default port 9000                                                          |
| CA name             | `Example Homelab Root CA`           | Bootstrap | Appears in cert subject                                                                |
| Root cert lifetime  | 10 years (default)                    | Crypto    | Root CA cert; rarely rotate                                                                       |
| Intermediate cert   | 10 years default; short-lived preferred  | Crypto    | Intermediates can rotate; prevents root exposure                                                                  |
| Password            | strong passphrase                            | Auth      | Encrypts root + intermediate private keys                                                                                       |
| Provisioners        | ACME, JWT, OIDC, X5C, SCEP                      | Auth      | You'll configure at least one (ACME for most)                                                                                              |
| DB                  | BoltDB (default) / Postgres / MySQL                | Storage   | BoltDB fine for < 10k certs; Postgres/MySQL for scale                                                                                               |

## Install via `step` CLI (recommended for new installs)

```sh
# On the CA host (Ubuntu/Debian example):
wget https://github.com/smallstep/cli/releases/download/vX.Y.Z/step-cli_X.Y.Z_amd64.deb
sudo dpkg -i step-cli_X.Y.Z_amd64.deb

wget https://github.com/smallstep/certificates/releases/download/vX.Y.Z/step-ca_X.Y.Z_amd64.deb
sudo dpkg -i step-ca_X.Y.Z_amd64.deb

# Bootstrap a CA
step ca init \
  --name "Example Homelab" \
  --dns "ca.example.local,10.0.0.5" \
  --address ":9000" \
  --provisioner "you@example.com" \
  --acme    # enables the ACME provisioner upfront

# Start (foreground for test)
step-ca $(step path)/config/ca.json
```

Systemd unit:

```ini
[Unit]
Description=step-ca
After=network.target

[Service]
Type=simple
User=step-ca
Environment="HOME=/home/step-ca"
ExecStart=/usr/bin/step-ca /home/step-ca/.step/config/ca.json --password-file=/home/step-ca/.step/password
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Install via Docker

```yaml
services:
  step-ca:
    image: smallstep/step-ca:0.27.x      # pin; check Docker Hub
    container_name: step-ca
    restart: unless-stopped
    ports:
      - "9000:9000"
    environment:
      DOCKER_STEPCA_INIT_NAME: Example Homelab
      DOCKER_STEPCA_INIT_DNS_NAMES: ca.example.local,step-ca
      DOCKER_STEPCA_INIT_PROVISIONER_NAME: admin@example.com
      DOCKER_STEPCA_INIT_REMOTE_MANAGEMENT: "true"
      DOCKER_STEPCA_INIT_ACME: "true"      # enable ACME provisioner
      # DOCKER_STEPCA_INIT_PASSWORD: <provide via secret>
    volumes:
      - step-ca:/home/step

volumes:
  step-ca:
```

First boot initializes the CA; the password is printed (save it securely) or provide one via `DOCKER_STEPCA_INIT_PASSWORD_FILE`.

## Issue certs (ACMEv2 example)

On a client machine — use any ACME client:

```sh
# Certbot with step-ca:
certbot certonly \
  --server https://ca.example.local:9000/acme/acme/directory \
  --standalone \
  -d intranet.example.local \
  --email admin@example.com \
  --agree-tos

# Caddy: add your step-ca as ACME directory
# Traefik: acmeCA setting
# Kubernetes cert-manager: ClusterIssuer with step-ca
```

The root CA cert must be installed on every client that verifies step-ca-issued certs (OS trust store / browser / app). `step` CLI provides `step certificate install` helpers.

## Issue SSH certs

```sh
# Configure step-ca SSH provisioner (see docs)
# User requests SSH cert:
step ssh certificate alice@example.com ~/.ssh/id_ed25519.pub --sign --principal alice,root --provisioner OIDC

# Hosts: configure sshd with TrustedUserCAKeys pointing at step-ca's SSH user CA
```

## Data & config layout

Under `$(step path)` (typically `~/.step`):

- `config/ca.json` — CA config (provisioners, DB, listen)
- `secrets/` — encrypted root + intermediate private keys + passwords
- `certs/` — root + intermediate certificates
- `db/` — BoltDB (default) with issued certs, ACME challenges

## Backup

```sh
# CRITICAL — root + intermediate keys + DB
tar czf step-ca-$(date +%F).tgz ~/.step
# Encrypt the tarball — it contains your CA's private keys
gpg -c step-ca-$(date +%F).tgz
```

Treat this backup like gold — losing the root key means you lose the ability to prove continuity of your CA. Losing the password means you can't decrypt the keys. Store offline.

## Upgrade

1. Releases: <https://github.com/smallstep/certificates/releases>. Very active.
2. Binary swap: download new `step-ca` + `step` → stop service → replace binary → start. Migrations rare but automated.
3. Docker: pin, `docker compose pull && docker compose up -d`.
4. Breaking changes listed in release notes; minor bumps generally safe.

## Gotchas

- **Back up ROOT + INTERMEDIATE keys + passwords** — losing them = start over + re-distribute a new root CA to every client. Keep encrypted backups in multiple offline locations.
- **Root CA is long-lived (10y)**; intermediate CA is issued from root. Best practice: keep the root OFFLINE after bootstrap (remove from the running step-ca, keep only the intermediate online). Automated CAs can't do this trivially but it's worth considering for high-security setups.
- **Short-lived certs are the design** — step-ca defaults to 24-hour certs. This sounds scary but is the **whole point**: clients auto-renew via ACME. Long-lived (90-day like Let's Encrypt) is also fine; configure per-provisioner.
- **Clients must trust your root CA** — install your root cert into:
  - Linux: `/usr/local/share/ca-certificates/` + `update-ca-certificates`
  - macOS: `security add-trusted-cert`
  - Windows: Certificate Manager → Trusted Root CAs
  - iOS/Android: profile install + Settings toggle
  - Firefox: separate trust store — manually import
- **DNS / IP SANs** — when you bootstrap, list ALL names/IPs clients will use to reach step-ca. Can't easily add later without reissuing.
- **ACMEv2 endpoint path**: `/acme/<provisioner-name>/directory` — used by certbot/Caddy/Traefik. Default provisioner name is the email you passed.
- **Traefik + Caddy auto-HTTPS** work seamlessly with step-ca as ACME server — point them at your CA's ACME directory URL, done.
- **cert-manager in Kubernetes** — `Issuer` / `ClusterIssuer` with CA's ACME URL + bootstrap info. Widely documented pattern.
- **Smallstep Cloud / Enterprise** — commercial offerings layered on top (team mgmt, audit logs, device onboarding UI). step-ca OSS is fully functional alone.
- **Post-quantum crypto**: smallstep is exploring; not default yet.
- **DB choice**: BoltDB (default) is fine for homelab + small-to-medium deployments (up to maybe 100k certs). For HA or larger scale: Postgres or MySQL, with multiple step-ca replicas.
- **HA**: can run multiple step-ca replicas pointing at shared Postgres/MySQL DB; load-balance via reverse proxy. Root keys are the same across replicas (careful with distribution).
- **OIDC provisioner** — integrate with Google, Okta, Authelia, Keycloak, Authentik. Users log in via OIDC → receive cert. Great for SSH-cert-based login.
- **JWT provisioner** — issue certs programmatically from CI/CD with short-lived JWTs.
- **SSH CA mode** is genuinely transformative — replaces `~/.ssh/authorized_keys` management with central cert issuance + expiry. Combined with OIDC provisioner = SSO for SSH.
- **Cert revocation**: CRL + OCSP supported; but **short-lived certs often make revocation moot** — cert expires in 24h anyway. Design accordingly.
- **Rate limiting** — step-ca doesn't rate-limit by default; ACME clients may hammer on initial sync. Put a reverse proxy with rate limits if exposing.
- **Do not expose to the internet** unless you really need to. Most homelab use cases = step-ca on internal network; internal services issue/renew certs from it.
- **Comparison to HashiCorp Vault PKI**: Vault is a broader secrets platform with PKI as one feature; step-ca is CA-focused and simpler. Pick Vault if you already run it; step-ca if "just PKI" is the ask.
- **Comparison to EasyRSA / openssl manual CA**: those are manual workflows; step-ca is automated + supports standard protocols.
- **Comparison to Let's Encrypt**: Let's Encrypt is for PUBLIC domains where internet-reachable + DNS is public. step-ca is for PRIVATE domains / internal networks.
- **Apache-2.0 license** — permissive.
- **Alternatives worth knowing:**
  - **EasyRSA** — shell-script CA; manual; traditional
  - **HashiCorp Vault (PKI engine)** — full secrets platform
  - **cfssl (Cloudflare)** — Go CA toolkit; less automated than step-ca
  - **boulder** — Let's Encrypt's CA implementation; complex; public-CA-grade
  - **smallstep Cloud / Enterprise** — commercial managed step-ca
  - **Choose step-ca if:** you want an automated private CA with ACMEv2 + SSH CA + OIDC integration, simple to run.
  - **Choose Vault if:** you want PKI alongside broader secret management.
  - **Choose Let's Encrypt** (not an alternative) if your domains are public.

## Links

- Repo: <https://github.com/smallstep/certificates>
- CLI repo: <https://github.com/smallstep/cli>
- Website: <https://smallstep.com>
- Docs: <https://smallstep.com/docs/step-ca>
- Install: <https://smallstep.com/docs/step-ca/installation/>
- Getting started: <https://smallstep.com/docs/step-ca/getting-started/>
- Provisioner reference: <https://smallstep.com/docs/step-ca/provisioners/>
- ACMEv2 guide: <https://smallstep.com/docs/step-ca/acme-basics/>
- SSH CA guide: <https://smallstep.com/docs/tutorials/ssh-certificate-authentication/>
- Docker: <https://hub.docker.com/r/smallstep/step-ca>
- Releases: <https://github.com/smallstep/certificates/releases>
- Discord: <https://discord.gg/BNSpfRHZ>
- Blog: <https://smallstep.com/blog>
- Helm chart: <https://github.com/smallstep/helm-charts>
