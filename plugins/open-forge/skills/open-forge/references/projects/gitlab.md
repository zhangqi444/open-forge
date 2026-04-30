---
name: GitLab (self-managed)
description: "Full DevOps platform — Git hosting, CI/CD, issue tracking, wiki, container registry, package registry, security scanning, Kubernetes integration. Ruby on Rails + Go + Postgres + Redis + many services. CE (MIT) + EE (proprietary add-ons)."
---

# GitLab (self-managed)

GitLab is the **all-in-one DevOps platform**: Git hosting + CI/CD + issue tracking + wiki + container/package registry + security scanning + release management + Kubernetes integration. Self-hosted "GitLab Community Edition" (CE, MIT-licensed) covers essentially all Git workflow features; "GitLab Enterprise Edition" (EE, proprietary) adds paid features (compliance, advanced security, enterprise integrations).

The competing philosophy to "small OSS Git server + plug in other tools" (Gitea, Forgejo + Drone + Jira + Mattermost, etc.). GitLab's pitch: one app, one upgrade path, one login, one database.

> **License nuance (important):**
> - **gitlab-foss** (`gitlab-org/gitlab-foss`) is the MIT-licensed Community Edition kernel.
> - **gitlab-ee** (`gitlab-org/gitlab`) is the full edition — free to install (Free tier works fully) but code contains Enterprise code under a **proprietary license**; features above Free tier require a license key.
> - **Default install via upstream packages is GitLab EE** (you use only Free-tier features unless you buy a license). To install pure MIT CE, use the `gitlab-ce` packages.
> - **Know your tier**: Free / Premium / Ultimate; self-hosted and SaaS share the same tier model.

- Upstream repo (FOSS/CE kernel): <https://gitlab.com/gitlab-org/gitlab-foss>
- Upstream (EE with free tier): <https://gitlab.com/gitlab-org/gitlab>
- Website: <https://about.gitlab.com>
- Docs: <https://docs.gitlab.com>
- Install: <https://about.gitlab.com/install/>
- Docker image (Omnibus): <https://hub.docker.com/r/gitlab/gitlab-ce> / <https://hub.docker.com/r/gitlab/gitlab-ee>
- Charts (Kubernetes): <https://docs.gitlab.com/charts/>

## Architecture in one minute

GitLab is **a small distribution of interacting services**:

- **Rails app** (Workhorse + Puma) — web + API
- **Gitaly** — Git RPC layer (holds repo storage)
- **Postgres** — primary DB
- **Redis** — cache, sessions, queues
- **Sidekiq** — background jobs
- **nginx** — reverse proxy (bundled)
- **GitLab Pages** (optional) — static site hosting
- **Container registry** (optional) — Docker/OCI registry
- **Mattermost** (optional) — chat
- **Prometheus + Grafana** (optional) — metrics
- **LDAP/SAML/OIDC** integrations
- **GitLab Runner** — separate daemon(s) for CI/CD executors

"Omnibus" = all-in-one DEB/RPM/Docker package bundling all the above. The recommended install.

- **RAM floor**: 8 GB for tiny prod; **16+ GB realistic**; more for active CI, Pages, registry
- **Disk**: repos + artifacts + container images grow fast

## Compatible install methods

| Infra              | Runtime                                          | Notes                                                              |
| ------------------ | ------------------------------------------------ | ------------------------------------------------------------------ |
| Single VM          | **Omnibus DEB/RPM** (Ubuntu/Debian/RHEL/CentOS)     | **Upstream-recommended for single-node**                                |
| Single VM          | Omnibus Docker image (`gitlab/gitlab-ce`)                 | One big container; same Omnibus config                                     |
| Kubernetes (HA)    | **Official Helm chart**                                         | Upstream-recommended for HA                                                        |
| Multi-node VM      | Reference architectures (3+ nodes)                                 | Documented for various scale tiers                                                         |
| Managed            | GitLab SaaS (`gitlab.com`)                                                  | Upstream's hosted; free + paid tiers                                                                   |
| Raspberry Pi       | arm64 Omnibus works on Pi 4/8 GB                                                   | Slow; fine for single-user                                                                                     |

## Inputs to collect

| Input                | Example                                  | Phase      | Notes                                                          |
| -------------------- | ---------------------------------------- | ---------- | -------------------------------------------------------------- |
| External URL         | `https://git.example.com`                  | URL        | `external_url` in `gitlab.rb`                                       |
| Registry URL         | `https://registry.example.com`                | URL        | If registry enabled                                                    |
| Pages URL            | `https://pages.example.com` (wildcard DNS ideal)    | URL        | If Pages enabled                                                                  |
| DB                   | bundled Postgres (default) or external             | DB         | External for HA                                                                          |
| Object storage       | S3-compatible (recommended for artifacts / uploads / LFS) | Storage    | Otherwise fills local disk                                                                       |
| SMTP                 | for notifications                                          | Email      | Transactional email                                                                                      |
| Admin account        | `root` / password set on first visit                                | Bootstrap  | Change immediately                                                                                              |
| TLS                  | Let's Encrypt                                                          | Security   | Omnibus supports ACME built-in                                                                                                   |
| Runners              | deploy separately (shell/Docker/K8s executor)                                     | CI         | Needed to actually run pipelines                                                                                                                  |

## Install via Omnibus (Ubuntu 22.04 example)

```sh
sudo apt install -y curl openssh-server ca-certificates tzdata perl
# Add repo
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
# Set URL and install
sudo EXTERNAL_URL="https://git.example.com" apt install gitlab-ce
# Omnibus installs, configures, starts everything
sudo gitlab-ctl status
# First-time root password printed to /etc/gitlab/initial_root_password
sudo cat /etc/gitlab/initial_root_password
```

## Install via Docker (Omnibus image)

```yaml
services:
  gitlab:
    image: gitlab/gitlab-ce:16.x              # pin specific version
    container_name: gitlab
    restart: unless-stopped
    hostname: git.example.com
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://git.example.com'
        # letsencrypt['enable'] = true
        # gitlab_rails['smtp_enable'] = true
        # gitlab_rails['smtp_address'] = "smtp.example.com"
        # ... etc
    ports:
      - "80:80"
      - "443:443"
      - "22:22"            # Git SSH
    volumes:
      - ./config:/etc/gitlab
      - ./logs:/var/log/gitlab
      - ./data:/var/opt/gitlab
    shm_size: '256m'
```

Initial root password: `docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password`.

## Install via Helm (Kubernetes)

```sh
helm repo add gitlab https://charts.gitlab.io/
helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab --create-namespace \
  --set global.hosts.domain=example.com \
  --set global.hosts.externalIP=<ingress-ip> \
  --set certmanager-issuer.email=admin@example.com
```

## First boot

1. Browse `https://git.example.com` → set root password (prompt) or log in with `/etc/gitlab/initial_root_password`
2. Admin → Settings → Sign-up restrictions (disable open signup for private instances)
3. Admin → Users → + New user or let users register
4. Create a group → create a project → push code:
   ```sh
   git remote add origin git@git.example.com:group/project.git
   git push -u origin main
   ```
5. **Install a Runner** for CI:
   ```sh
   # On a separate host (or same)
   sudo apt install gitlab-runner
   sudo gitlab-runner register
   # Follow prompts; get token from GitLab UI → Settings → CI/CD → Runners
   ```
6. Add a `.gitlab-ci.yml` to your repo → first pipeline runs
7. Container registry, Pages, issues, MRs, wiki — all available per-project

## Data & config layout

- `/etc/gitlab/gitlab.rb` — Omnibus main config
- `/etc/gitlab/gitlab-secrets.json` — **critical secrets** (encryption keys); back up separately
- `/var/opt/gitlab/git-data/` — Git repositories (HUGE, grows forever)
- `/var/opt/gitlab/postgresql-data/` — bundled Postgres
- `/var/opt/gitlab/gitlab-rails/uploads/` — user uploads
- `/var/opt/gitlab/gitlab-rails/shared/artifacts/` — CI artifacts
- `/var/opt/gitlab/registry/` — container registry (if enabled)
- `/var/opt/gitlab/gitlab-pages/` — Pages content

## Backup

```sh
# Omnibus built-in backup (app data, repos, CI artifacts, registry)
sudo gitlab-backup create STRATEGY=copy

# Backup /etc/gitlab SEPARATELY — contains secrets
sudo tar czf gitlab-etc-$(date +%F).tgz /etc/gitlab

# Docker variant
docker exec gitlab gitlab-backup create
```

**The `/etc/gitlab/gitlab-secrets.json` is NOT in the gitlab-backup tarball — back it up separately.** Without it, restored DB is unreadable (CI secrets, 2FA keys, etc. are encrypted with it).

Rotate backups daily; retain N days; offsite.

## Upgrade

1. Releases: <https://about.gitlab.com/releases/categories/releases/>. Monthly major bumps.
2. **One-minor-version-at-a-time** for major upgrades: the GitLab upgrade path often requires stopping at specific versions (12.x → 12.10 → 13.0 → ...). See the upgrade path tool: <https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/>.
3. **Back up /etc/gitlab + gitlab-backup create before every upgrade.**
4. Omnibus: `apt upgrade gitlab-ce` (on Ubuntu/Debian) / `yum update` on RHEL.
5. Docker: bump tag. CAUTION: upgrade path rules apply — don't skip multiple majors at once.
6. Background migrations can run for hours post-upgrade on large instances; monitor Admin → Background Jobs.

## Gotchas

- **GitLab is heavy.** 8-16 GB RAM is "small." If you just want Git hosting, consider Gitea/Forgejo (100 MB RAM).
- **CE vs EE**: install `gitlab-ce` to ensure MIT-licensed kernel only. `gitlab-ee` Free tier has all needed features for most but is dual-licensed. For purist open-source shops, use CE.
- **Upgrade path matters.** Skipping minor versions in major bumps WILL break. Use the upgrade path tool.
- **Background migrations** after upgrade — monitor before assuming stable.
- **Gitaly storage growth** — repos only grow; LFS + artifacts + container registry balloon. Configure retention, rotate artifacts, archive stale repos.
- **Object storage** (S3/MinIO) — for scale + reliable backups, offload artifacts/uploads/LFS/registry to S3. Omnibus supports this natively.
- **Runners cost** — CI runners run on compute you pay for. Shared runners on gitlab.com have quota; self-hosted runners = your infra.
- **Container registry** needs separate hostname + TLS cert. Enable in `gitlab.rb`.
- **Pages** needs wildcard DNS (`*.pages.example.com`) + wildcard TLS cert. Certbot wildcard via DNS-01.
- **Email deliverability**: GitLab sends a lot of email (notifications, password resets). Use a reputable SMTP relay (Mailgun, Postmark, SES).
- **SSH port conflicts**: Omnibus default SSH is 22; if your host already uses 22, change GitLab SSH to 2222.
- **Backup restore** — restoring requires same GitLab version that created the backup. Cross-version restore: upgrade backup server first.
- **Disaster recovery**: two-site DR is possible with Geo (EE feature); CE = restore from backup.
- **LDAP/SAML/OIDC** — GitLab supports all; configure in `gitlab.rb` or UI.
- **2FA**: require for admins; project/group can require for members.
- **Admin Mode** (new in 13+) — admins must opt into "Admin Mode" to do admin actions; reduces accidental admin access.
- **Secrets management**: GitLab CI has its own masked-variables feature; pair with Vault for production secrets.
- **CI minutes on gitlab.com Free tier are limited**; self-hosted = unlimited.
- **Feature flags** — many GitLab features are behind feature flags; check for `application_setting.update!` or flag toggles.
- **Frequent releases** — monthly majors; every 22nd. Read release posts; some break workflows.
- **License**: CE is MIT; EE is proprietary with free tier. Review the licensing section of docs before forking/redistributing.
- **Alternatives worth knowing:**
  - **Gitea** — simple Go Git server; much lighter; great for homelab (separate recipe)
  - **Forgejo** — community fork of Gitea; similar feel (separate recipe)
  - **Gogs** — older, minimal
  - **Bitbucket Server / Data Center** — Atlassian; commercial; on-prem
  - **Azure DevOps Server (TFS)** — Microsoft; on-prem
  - **GitHub Enterprise Server** — on-prem GitHub
  - **Sourcehut** — minimalist; mailing-list workflow; federated future
  - **Choose GitLab if:** you want the full DevOps stack in one app — Git + CI/CD + registry + issues + wiki — with a known upgrade path.
  - **Choose Gitea/Forgejo if:** you want Git hosting + light CI without the RAM tax.
  - **Choose GitHub (SaaS) or GitLab SaaS if:** you don't want the ops.

## Links

- Repo (FOSS): <https://gitlab.com/gitlab-org/gitlab-foss>
- Repo (EE): <https://gitlab.com/gitlab-org/gitlab>
- Website: <https://about.gitlab.com>
- Docs: <https://docs.gitlab.com>
- Install docs: <https://about.gitlab.com/install/>
- Omnibus repo: <https://gitlab.com/gitlab-org/omnibus-gitlab>
- Kubernetes chart: <https://docs.gitlab.com/charts/>
- Upgrade path tool: <https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/>
- Reference architectures: <https://docs.gitlab.com/ee/administration/reference_architectures/>
- Docker CE image: <https://hub.docker.com/r/gitlab/gitlab-ce>
- Docker EE image: <https://hub.docker.com/r/gitlab/gitlab-ee>
- Pricing / tiers: <https://about.gitlab.com/pricing/>
- Security releases: <https://about.gitlab.com/releases/categories/security-releases/>
- Release cadence: <https://docs.gitlab.com/ee/policy/maintenance.html>
