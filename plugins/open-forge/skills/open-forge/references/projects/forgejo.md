---
name: Forgejo
description: "Independent Git forge — community-owned Gitea hard fork. Git hosting, issues, PRs, wiki, releases, package registry, CI/CD (Forgejo Actions), federation roadmap. Lightweight; runs on Raspberry Pi. Go. GPL-3.0+ (since v9)."
---

# Forgejo

Forgejo (/for'd͡ʒe.jo/, Esperanto "forge") is **"community-owned Gitea"** — a soft + then hard fork of Gitea created in **December 2022** after a controversial corporate restructuring of the Gitea project (Gitea Ltd was formed, causing community concern about governance). Forgejo is stewarded by **Codeberg e.V.** (German non-profit) + a broader free-software community; **hosted on Codeberg.org** (not GitHub — deliberate). Independent Free/Libre Software **forever** is the promise.

Features (parity with + diverging from Gitea):

- **Lightweight** — runs on a Raspberry Pi
- **Git hosting** with issues, pull requests, wikis, **kanban boards**
- **Releases** + **package registry** (Docker, npm, Maven, PyPI, RubyGems, NuGet, Conan, Composer, Go, Helm, Cargo, etc.)
- **Forgejo Actions** — GitHub Actions-compatible CI/CD (runs on `forgejo-runner`)
- **Code Search**
- **Organizations + teams + LDAP / OAuth / OIDC**
- **Config switches** galore
- **Privacy-first defaults** — update-checker off, no external calls by default
- **Federation (WIP)** — ActivityPub-based cross-instance collaboration roadmap

Use cases: (a) self-host all your repos (b) run a community code-forge like Codeberg (c) GitHub alternative for orgs wanting sovereignty (d) lightweight CI with `forgejo-runner`.

- Upstream repo: <https://codeberg.org/forgejo/forgejo>
- Homepage: <https://forgejo.org>
- Documentation: <https://forgejo.org/docs/latest/>
- Hosted instance: <https://codeberg.org>
- Matrix chat: <https://matrix.to/#/#forgejo-chat:matrix.org>
- Fediverse: <https://floss.social/@forgejo>
- Governance: <https://codeberg.org/forgejo/governance>
- Forgejo Runner (CI): <https://code.forgejo.org/forgejo/runner>
- Container images: <https://codeberg.org/forgejo/-/packages/container/forgejo/>
- Releases: <https://codeberg.org/forgejo/forgejo/releases>

## Architecture in one minute

- **Go** single binary + web UI
- **DB**: SQLite (default; solo), MySQL/MariaDB, PostgreSQL
- **Git storage**: local filesystem (standard)
- **Git LFS**: supported
- **Resource**: very small — ~100 MB RAM for small instances; scales well
- **SSH server**: built-in Go SSH server OR use system OpenSSH (configurable)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | `codeberg.org/forgejo/forgejo` (primary registry)              | **Upstream-primary**                                                               |
| Bare-metal binary  | Download single binary + systemd                                           | Classic install                                                                            |
| Helm / K8s         | Community Helm chart                                                                   | Works                                                                                                  |
| Raspberry Pi       | ARM images first-class                                                                                 | Upstream tested                                                                                                    |
| Gitea migration    | **Direct in-place migration** — Gitea DB + data work in Forgejo                                                       | For fleeing Gitea users                                                                                              |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `git.example.com`                                               | URL          | TLS via reverse proxy                                                                    |
| Data dir             | `/var/lib/forgejo` or `/data`                                           | Storage      | Persistent volume                                                                                  |
| DB                   | SQLite (default) / Postgres / MySQL                                            | DB           | Postgres for teams; SQLite for personal                                                                    |
| `SECRET_KEY`         | Random — session encryption                                                                 | Secret       | **Immutable** once instance has data                                                                      |
| `INTERNAL_TOKEN`     | Random — internal API                                                                         | Secret       | **Immutable** once set                                                                                      |
| Admin user           | First-registered user OR explicit initial admin                                                              | Bootstrap    | Lock down registrations after bootstrap                                                                     |
| SMTP                 | For notifications + password reset                                                                                   | Email        | Strongly recommended                                                                                                      |
| SSH port             | 22 (system) or 2222 (Forgejo internal)                                                                                  | Network      | Built-in SSH server is simpler for single-service hosts                                                                                                              |
| OIDC (opt)           | Keycloak / Authentik / Kanidm                                                                                                      | Auth         | For team deployments                                                                                                                                 |

## Install via Docker Compose

```yaml
services:
  forgejo:
    image: codeberg.org/forgejo/forgejo:15                # pin major version
    restart: always
    environment:
      USER_UID: 1000
      USER_GID: 1000
      FORGEJO__database__DB_TYPE: postgres
      FORGEJO__database__HOST: db:5432
      FORGEJO__database__NAME: forgejo
      FORGEJO__database__USER: forgejo
      FORGEJO__database__PASSWD: ${DB_PASSWORD}
    volumes:
      - ./forgejo-data:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"     # web
      - "2222:22"       # SSH
    depends_on: [db]
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: forgejo
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: forgejo
    volumes: [pg_data:/var/lib/postgresql/data]

volumes:
  pg_data:
```

## First boot

1. Start container → browse URL → web installer
2. Fill: DB details, domain, admin username/password
3. First user = admin
4. Disable open registration (Admin panel → Settings) after bootstrap
5. Configure SMTP for notifications
6. (opt) Configure OIDC for SSO
7. Install `forgejo-runner` on a separate machine for CI
8. Put behind TLS reverse proxy
9. Back up data directory + DB

## Data & config layout

- `/data/` — Git repos + LFS + attachments + SQLite (if using)
- `/data/gitea/conf/app.ini` — config file
- `/data/ssh/` — SSH host keys
- DB — users, issues, PRs, organizations

## Backup

```sh
# Stop for consistency (or dump DB online)
docker compose exec forgejo forgejo dump -c /data/gitea/conf/app.ini
# Produces a .zip with DB dump + repos + attachments

# Or classic DB dump + tar data dir:
pg_dump -Fc -U forgejo forgejo > forgejo-db-$(date +%F).dump
sudo tar czf forgejo-data-$(date +%F).tgz forgejo-data/
```

## Upgrade

1. Releases: <https://codeberg.org/forgejo/forgejo/releases>. Quarterly major versions; patch releases more often.
2. **Major versions align with Gitea but diverge over time** — read release notes carefully.
3. Docker: bump tag; migrations run automatically.
4. **Back up FIRST.** Database migrations can be irreversible.
5. **Migrating from Gitea**: pre-v9 Forgejo was soft-fork (drop-in compatible). v9+ is hard-fork GPL (from MIT) — in-place migration still supported but READ the migration notes. Migrating back to Gitea from Forgejo v9+ is NOT supported.

## Gotchas

- **Gitea vs Forgejo is a governance + licensing choice.** Technically both descend from Gogs; both are 95% feature-compatible. Differences:
  - **Gitea**: Gitea Ltd (commercial company) + Gitea Cloud; MIT; primary GitHub dev; accepts commercial sponsorship directly
  - **Forgejo**: Codeberg e.V. (non-profit) + community; **GPL-3.0+ since v9** (from MIT); all development on Codeberg; governance-by-community
  - Pick based on values + licensing needs. Both are fine technically.
- **"Forever free/libre" is the Forgejo thesis.** The GPL relicensing (v9) was deliberate: prevents future proprietary relicensing even if maintainers change. Worth knowing this is a *values-choice*, not a performance one.
- **Codeberg.org is the flagship instance** — run by Codeberg e.V. non-profit; hosts FOSS projects at no cost; funded by donations. Worth supporting financially if your project lives there.
- **Forgejo Actions compatibility with GitHub Actions** is strong but NOT 100%. Actions that hardcode `github.com/` URLs, GitHub API calls, or specific GitHub metadata may need tweaking. Test your workflows. `forgejo-runner` is the runner daemon (separate binary).
- **Git LFS**: built-in; works. Configure storage backend (local or S3). Watch disk growth.
- **SSH server options**: (a) Forgejo's built-in Go SSH server on port 22 or 2222 (simpler; better for containers) (b) system OpenSSH with `authorized_keys` integration (more flexible; required for gitolite-style advanced setups). Built-in is the default + recommended.
- **Registration control**: default allows open registration. For personal/org instances, disable immediately via Admin panel.
- **Federation (WIP)**: ActivityPub-based cross-instance PRs + issues are in-development. Not production-ready yet. Exciting roadmap but don't depend on it until shipped.
- **Package registry is FIRST-CLASS**: Docker registry, npm, PyPI, Maven, NuGet, RubyGems, Go proxy, Helm, Conan, Cargo. Useful for internal package-hosting without running separate registries. Pin + verify.
- **Raspberry Pi deployments** are legit — Forgejo runs on ~100 MB RAM. Perfect for homelab.
- **SECRET_KEY + INTERNAL_TOKEN immutability** — don't rotate after data exists; invalidates encrypted fields. Same immutability-of-secrets class as other tools (Statamic APP_KEY 77, Wakapi salt 81, Nexterm ENCRYPTION_KEY 81).
- **Privacy-first defaults** — no update checker calling home by default; no telemetry. Compare to GitLab CE which phones home by default.
- **2FA**: TOTP supported; webauthn/passkeys supported. Enforce for admins.
- **Git hooks** — server-side pre-receive/post-receive hooks supported (admin-only); useful for enforcing commit conventions.
- **Bus-factor**: Codeberg e.V. (non-profit entity) + community governance + GPL = institutional-grade bus-factor mitigation. Stronger governance than most solo-maintained forges. Comparable to NLnet Labs (Unbound batch 80).
- **License**: **GPL-3.0+ since v9**; MIT for v8 and earlier. Modifying + running internally = fine; redistributing modified versions = GPL obligations.
- **Ethical support**: Codeberg e.V. accepts donations; Forgejo accepts sponsorship via OpenCollective + Liberapay. Consider supporting if you use it commercially.
- **Alternatives worth knowing:**
  - **Gitea** — sibling project; technically similar; Gitea Ltd governance
  - **GitLab CE** — heavier; many more features (CI, container registry, security scans); enterprise-feel
  - **Gogs** — original project both Gitea + Forgejo descend from; slower development
  - **Sourcehut** — minimalist; mailing-list-based PR workflow; philosophically different
  - **Radicle** — peer-to-peer Git
  - **GitBucket** — JVM-based
  - **Fossil** — distributed version control + issue tracker + wiki in one binary (Richard Hipp / SQLite author)
  - **OneDev** — JVM-based; feature-rich
  - **Choose Forgejo if:** want community-governed + GPL + non-profit-stewarded Gitea heritage.
  - **Choose Gitea if:** want commercial company governance + MIT + hosted Cloud option.
  - **Choose GitLab CE if:** want all-in-one DevOps + willing to run heavier infra.
  - **Choose Sourcehut if:** minimalist email-driven workflow + terminal-first.
- **Project health**: Codeberg e.V. + active community + quarterly major releases + donation-funded. Excellent long-term bet for sovereign Git-hosting.

## Links

- Repo: <https://codeberg.org/forgejo/forgejo>
- Homepage: <https://forgejo.org>
- Docs: <https://forgejo.org/docs/latest/>
- Codeberg (flagship instance): <https://codeberg.org>
- Releases: <https://codeberg.org/forgejo/forgejo/releases>
- Forgejo Runner: <https://code.forgejo.org/forgejo/runner>
- Matrix: <https://matrix.to/#/#forgejo-chat:matrix.org>
- Fediverse: <https://floss.social/@forgejo>
- Governance: <https://codeberg.org/forgejo/governance>
- Blog (Hello Forgejo 2022): <https://forgejo.org/2022-12-15-hello-forgejo/>
- Donate to Codeberg e.V.: <https://docs.codeberg.org/improving-codeberg/donate/>
- Gitea (alt): <https://gitea.com>
- GitLab CE (alt): <https://about.gitlab.com/install/ce-or-ee/>
- Sourcehut (alt): <https://sourcehut.org>
- Gogs (origin): <https://gogs.io>
