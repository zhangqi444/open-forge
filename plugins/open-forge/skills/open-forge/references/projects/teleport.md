---
name: Teleport (Community Edition)
description: Identity-aware access proxy + CA + audit for SSH, Kubernetes, databases, web apps, RDP, and MCP servers. AGPL Community Edition; managed cloud + commercial Enterprise also available.
---

# Teleport

Teleport is a single Go binary that runs three cooperating services — an **Auth Service** (certificate authority + user store), a **Proxy Service** (public ingress, session forwarder), and optional resource services (SSH, Kubernetes, Database, App, Desktop, MCP) — plus agents (`teleport`, `tbot`) installed on target machines to register them with the cluster. Users get short-lived certificates issued by Teleport instead of long-lived SSH keys, passwords, or kubeconfigs.

- Upstream repo: <https://github.com/gravitational/teleport>
- Community install guide: <https://goteleport.com/docs/get-started/deploy-community/>
- Binary install script: <https://goteleport.com/docs/installation/>
- Helm chart (recommended for K8s): <https://goteleport.com/docs/reference/helm-reference/>
- Image: `public.ecr.aws/gravitational/teleport:<ver>` (Community); also on Docker Hub at `gravitational/teleport`

## Compatible install methods

| Infra              | Runtime                          | Notes                                                                         |
| ------------------ | -------------------------------- | ----------------------------------------------------------------------------- |
| Linux VM           | Package + systemd                | **Recommended** upstream path; single binary, systemd unit                    |
| Linux VM           | Install script                   | `curl … \| bash` fetches correct package for your distro                      |
| Kubernetes         | Official Helm chart              | `teleport-cluster` chart; production-grade                                    |
| Docker             | Official image                   | Supported but upstream docs prefer systemd/Helm for the cluster itself        |
| Bare metal         | Tarball + systemd unit           | Fine for air-gapped installs                                                  |

**There is no upstream-blessed `docker-compose.yml` for the Teleport cluster.** The Docker image is primarily for the `teleport` binary itself; self-hosters are expected to use systemd (small scale) or Helm (K8s).

## Inputs to collect

| Input                  | Example                               | Phase     | Notes                                                                       |
| ---------------------- | ------------------------------------- | --------- | --------------------------------------------------------------------------- |
| Cluster name           | `teleport.example.com`                | Bootstrap | Permanent; changing later requires rebuilding the cluster                   |
| Public address         | `teleport.example.com:443`            | Bootstrap | The FQDN users + agents connect to                                          |
| Wildcard DNS           | `*.teleport.example.com → <VM IP>`    | DNS       | Needed for Application Access (each app gets a subdomain)                   |
| TLS strategy           | Let's Encrypt (`--acme`) / own certs  | TLS       | `--acme` auto-provisions on port 443; else mount your own cert/key          |
| ACME email             | `admin@example.com`                   | TLS       | Required if using `--acme`                                                  |
| Storage backend        | SQLite (local) / etcd / DynamoDB / Postgres | Runtime | Community default: SQLite on local disk. HA needs external backend         |
| Session recording      | local / S3 / GCS                      | Runtime   | `audit_sessions_uri`; S3 recommended for retention + multi-proxy HA         |
| Port 443/TCP open      | firewall                              | Network   | Only port required for a minimal cluster                                    |
| Port 3080 (optional)   | local container                       | Network   | Only used in the Docker-local demo flow                                     |

## Install via package + systemd (recommended, single-node Community)

Per <https://goteleport.com/docs/get-started/deploy-community/>:

```sh
# 1. Point DNS: teleport.example.com + *.teleport.example.com → VM public IP.
# 2. Install Teleport (pick a specific version pin on the command line; check latest at the link below):
curl https://cdn.teleport.dev/install-v18.0.0.sh | bash -s 18.0.0

# 3. Generate config (Let's Encrypt flow):
sudo teleport configure -o file \
  --acme --acme-email=admin@example.com \
  --cluster-name=teleport.example.com

# 4. Enable + start:
sudo systemctl enable --now teleport

# 5. Create your first admin (issues a one-time signup URL):
sudo tctl users add admin --roles=editor,access --logins=root,ubuntu
```

Browse the signup URL → set password → enroll a hardware key or TOTP → log in. Download the `tsh` client from <https://goteleport.com/download/> to SSH via `tsh ssh root@<node>` after enrolling resources.

Check the latest version/release notes here:

- <https://goteleport.com/download/>
- <https://github.com/gravitational/teleport/releases>

## Install via Helm (recommended for K8s / HA)

```sh
helm repo add teleport https://charts.releases.teleport.dev
helm repo update

helm install teleport-cluster teleport/teleport-cluster \
  --create-namespace --namespace teleport-cluster \
  --set clusterName=teleport.example.com \
  --set acme=true \
  --set acmeEmail=admin@example.com
```

See <https://goteleport.com/docs/reference/helm-reference/teleport-cluster/> for HA backends (DynamoDB/S3 on AWS; Firestore/GCS on GCP; Postgres + S3-compatible for bare-metal HA).

## Install via Docker (single-node demo only)

For an evaluation, upstream documents a Docker-run pattern at <https://goteleport.com/docs/installation/docker/>:

```sh
docker run -d --name teleport \
  -v /path/to/teleport.yaml:/etc/teleport.yaml \
  -v teleport-data:/var/lib/teleport \
  -p 443:443 -p 3023:3023 -p 3024:3024 -p 3025:3025 \
  public.ecr.aws/gravitational/teleport:18.0.0 \
  teleport start -c /etc/teleport.yaml
```

Generate the `teleport.yaml` via `teleport configure -o stdout …` on a host that has the binary, or copy one out of a running systemd install. Community `latest` tags do exist but pin a version.

## Enrolling resources (agents)

Each machine (or k8s cluster, database) runs a smaller `teleport` agent with its own minimal config that points at the Proxy and is authorized by a join token. See:

- SSH nodes: <https://goteleport.com/docs/enroll-resources/server-access/introduction/>
- Kubernetes: <https://goteleport.com/docs/enroll-resources/kubernetes-access/introduction/>
- Databases: <https://goteleport.com/docs/enroll-resources/database-access/>
- Applications: <https://goteleport.com/docs/enroll-resources/application-access/>
- Windows desktops: <https://goteleport.com/docs/enroll-resources/desktop-access/>

## Data & config layout

- `/etc/teleport.yaml` — main config (systemd) or bind-mounted into the container
- `/var/lib/teleport/` — cluster state (SQLite backend, CA keys, session recordings if local)
- `/var/lib/teleport/backend/` — storage backend data
- `~/.tsh/` on each **client** — cached certs + cluster metadata (not secret-free; rotate on compromise)

## Backup

- **Stop Teleport** (or snapshot the underlying disk) and back up `/var/lib/teleport/` in full — CA private keys live here.
- Or export via `tctl auth export` for the CA and `tctl get <resource-kind>` for cluster configuration, plus a backup of your storage backend (Dynamo/Postgres/etc.) when using HA.
- Losing the CA keys = every `tsh login` on every client needs to re-trust a new CA.

## Upgrade

1. Read release notes: <https://github.com/gravitational/teleport/releases> — **Teleport only supports upgrades within one major version at a time** (e.g. 16 → 17, not 16 → 18).
2. `sudo apt-get update && sudo apt-get install --only-upgrade teleport` (or equivalent for your distro / re-run install script with new version).
3. `sudo systemctl restart teleport` — auth migrations run at startup.
4. Upgrade agents on enrolled nodes next (agents may lag the cluster by one major version but not more).
5. On HA clusters: upgrade one Auth instance, let it stabilize, then rolling-upgrade the Proxies, then agents.

## Gotchas

- **One major version at a time.** Skipping majors (e.g. 15 → 17) is not supported and often breaks the cluster.
- **Cluster name is permanent.** Picking `teleport.example.com` bakes that into every user's `~/.tsh` and every agent's config; changing it effectively means a new cluster.
- **`--acme` binds port 443 and 80 during challenge.** If you already run a reverse proxy, either use DNS-01 with your own certs or put Teleport on a dedicated host/IP.
- **SQLite backend ≠ HA.** Single-node Community is fine for small teams; for HA set up etcd/DynamoDB/Postgres per <https://goteleport.com/docs/reference/backends/>.
- **Session recording defaults to the Auth node's disk.** Enable S3 (`audit_sessions_uri: s3://...`) before enrolling real users if you need retention or multi-proxy HA.
- **Clients need matching CA.** `tsh login` fetches CA info once; if you rotate CAs without `tctl auth rotate`, clients silently break.
- **Community is AGPL.** Enterprise features (SSO to Azure AD/Okta/Google Workspace, Access Requests with approval, Session Moderation, FIPS) require a paid license. Some tutorials assume Enterprise — check feature availability at <https://goteleport.com/pricing/>.
- **Passwordless / Touch ID** second factor requires HTTPS and a non-`localhost` hostname.
- **Wildcard DNS is required for Application Access.** Each app gets `<name>.teleport.example.com`; without `*.teleport.example.com` the browser redirect loop fails.
- **Don't mix install methods.** Running the systemd service *and* the Docker container against the same `/var/lib/teleport` corrupts the backend.
- **Firewalls and split-DNS:** the Proxy needs one reachable FQDN, but agents + clients also need reverse-tunnel connectivity (port 443). If you NAT, make sure the external address in config matches what clients hit.

## Links

- Community install: <https://goteleport.com/docs/get-started/deploy-community/>
- Install methods: <https://goteleport.com/docs/installation/>
- Docker install: <https://goteleport.com/docs/installation/docker/>
- Helm reference: <https://goteleport.com/docs/reference/helm-reference/>
- Upgrade guide: <https://goteleport.com/docs/upgrading/>
- Releases: <https://github.com/gravitational/teleport/releases>
- Downloads (tsh, tctl, teleport): <https://goteleport.com/download/>
- Architecture: <https://goteleport.com/docs/reference/architecture/>
