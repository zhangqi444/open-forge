---
name: Weblate
description: "Web-based continuous localization / translation management system. Git-backed (push/pull translations as commits), glossary, translation memory, machine-translation integrations, quality checks, per-language review. Used by 2500+ FOSS projects (LibreOffice, openSUSE, Fedora, etc.). Python/Django. GPL-3.0+."
---

# Weblate

Weblate is **the web-based continuous localization platform** — used by thousands of FOSS projects (LibreOffice, openSUSE, Fedora, OpenStreetMap, F-Droid, PeerTube, etc.) and many commercial ones. Git repos contain translation files (`.po`, `.json`, `.yml`, `.xml`, `.properties`, etc.); Weblate clones your repo, presents a friendly translator UI, commits translations back as normal git commits, and handles conflict resolution + review + machine-translation suggestions + glossary + translation memory + quality checks.

Built by **Michal Čihař**, also the maintainer of gettext tools. Hosted at <https://hosted.weblate.org> (free for FOSS, paid for commercial) — or self-host.

Features:

- **Git-backed** — translations ARE git commits; all the Git tooling still works
- **100+ file formats** — gettext PO, JSON, XLIFF, XML, YAML, TS, Android resources, iOS strings, INI, CSV, Java Properties, Mozilla .lang, Windows RC, Subrip, AndroidX Resources, etc.
- **Translation memory** — reuse past translations across projects
- **Glossary** — per-project glossaries for consistent terminology
- **Machine translation** — DeepL, Google, Microsoft, Amazon, ModernMT, Yandex, LibreTranslate (self-host) — auto-suggestions
- **Quality checks** — placeholder preservation, length limits, capitalization, plural forms, custom rules
- **Review workflow** — translator → reviewer → merge
- **Comments + voting + discussion** per string
- **API** — full REST API + webhooks
- **Cross-project strings** — share single translation across projects
- **Screenshot-based context** — upload UI screenshots, link to strings for context
- **Visual HTML editor** for HTML/Markdown strings
- **Permissions** — per-language, per-project, per-component
- **Subscribe/notifications** — track changes
- **SAML/OIDC/OAuth SSO** — Google, GitHub, GitLab, Microsoft
- **Billing / quotas** (for hosting others' projects)
- **API-driven git push/pull hooks** + CI integration

- Upstream repo: <https://github.com/WeblateOrg/weblate>
- Website: <https://weblate.org>
- Hosted (free for FOSS): <https://hosted.weblate.org>
- Docs: <https://docs.weblate.org>
- Forum: <https://github.com/WeblateOrg/weblate/discussions>
- Matrix: `#weblate:matrix.org`
- Docker Hub: <https://hub.docker.com/r/weblate/weblate>

## Architecture in one minute

- **Python / Django** backend
- **Celery + Redis** for background tasks (git sync, MT, stats)
- **PostgreSQL** (preferred) or MySQL/MariaDB
- **Nginx / Apache** in front
- **Git** — Weblate runs git CLI to clone/commit/push to your upstream repos
- **Resource**: 1-2 GB RAM for small instances; scales linearly with project count + users

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                         |
| ------------------ | -------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Single VM          | **Docker Compose (`weblate/weblate`)**                             | **Upstream-recommended**                                                          |
| Single VM          | Native (Python venv + PG + Redis + Nginx)                                  | Works; more ops                                                                           |
| Kubernetes         | Helm chart (community)                                                                        | Production path                                                                                         |
| Managed            | **hosted.weblate.org**                                                                                       | Free for FOSS; **use this for FOSS projects instead of self-host**                                                        |
| Raspberry Pi       | Marginal — Celery + PG footprint                                                                                           |                                                                                                                                          |

## Inputs to collect

| Input                   | Example                             | Phase       | Notes                                                                     |
| ----------------------- | ----------------------------------- | ----------- | ------------------------------------------------------------------------- |
| Domain                  | `translate.example.com`                | URL         | Mandatory HTTPS                                                                    |
| DB                      | Postgres 15+                                | DB          | Preferred; MySQL works                                                                    |
| Secret key              | Django SECRET_KEY                              | Security    | Long random                                                                                               |
| Admin user              | created by `./manage.py createadmin`                     | Bootstrap   | Or env var WEBLATE_ADMIN_*                                                                                                 |
| SMTP                    | host/port/user/pass                                      | Email       | Required for invites + notifications                                                                                                |
| Git SSH key             | key Weblate uses to push to upstream repos                     | Integration | Add as deploy-key or to bot account                                                                                                                   |
| Machine translation     | DeepL / Google / LibreTranslate keys                                          | Feature     | At least one recommended                                                                                                                                              |
| SSO (opt)               | OAuth/SAML creds                                                                | Auth        | Nice-to-have                                                                                                                                                                 |

## Install via Docker Compose

Upstream's docker-compose template:

```sh
git clone https://github.com/WeblateOrg/docker-compose.git weblate-docker
cd weblate-docker
cp docker-compose.override.example.yml docker-compose.override.yml
# Edit override: domain, admin email, secrets
docker compose up -d
```

Key env vars (in override):

```yaml
environment:
  WEBLATE_SITE_DOMAIN: translate.example.com
  WEBLATE_ADMIN_PASSWORD: CHANGE_ME
  WEBLATE_ADMIN_EMAIL: ops@example.com
  WEBLATE_EMAIL_HOST: smtp.example.com
  WEBLATE_EMAIL_HOST_USER: mailer
  WEBLATE_EMAIL_HOST_PASSWORD: SMTP_SECRET
```

Browse `https://translate.example.com/`.

## First boot

1. Log in as admin → Admin Panel → configure site settings
2. **Projects → Add Project** → name, website URL, source license
3. Inside project, **Add Component** → point at your Git repo (HTTPS or SSH) + file mask (e.g., `locales/*.po`)
4. Weblate clones + parses → displays strings in web UI
5. Add languages + invite translators (email invite or SSO)
6. Configure machine-translation provider
7. Configure git push-back credentials (deploy key or HTTPS creds in project settings)
8. Watch translators work; merge approved translations back to your main branch

## Data & config layout

- Postgres — all Weblate metadata (users, strings, translations, reviews)
- `/app/data/` (in container) — cloned repos, cached files
- Env vars in `docker-compose.override.yml`

## Backup

```sh
# DB (CRITICAL)
docker exec weblate-db pg_dump -U weblate weblate | gzip > weblate-db-$(date +%F).sql.gz
# Weblate data (repos + cache)
docker run --rm --volumes-from weblate alpine tar czf - /app/data | gzip > weblate-data-$(date +%F).tgz
```

## Upgrade

1. Releases: <https://github.com/WeblateOrg/weblate/releases>. Active; regular minors.
2. **Back up DB + data.**
3. Docker: bump tag → migrations auto.
4. Read release notes for schema / config changes.
5. **Test on staging** for major versions.

## Gotchas

- **hosted.weblate.org is free for FOSS projects.** If your project is open-source, don't self-host — use the hosted instance; you save operational burden + support the project via its funding model. Self-host makes sense for commercial i18n pipelines or air-gapped environments.
- **Git credentials**: Weblate needs to push to your upstream repo. Use a dedicated bot account + deploy key — *not* your personal SSH key. Scope permissions tightly.
- **Merge conflicts**: when both Weblate (via translator commits) and upstream developers edit the same file simultaneously, conflicts happen. Weblate handles common cases; manual resolution sometimes needed.
- **Addon configuration**: Weblate has many "addons" per-component (commit message format, push interval, string cleanup, JSON canonicalization). Configure these early for your repo style.
- **Pre-commit hooks**: if upstream has a pre-commit hook that reformats files, it can fight Weblate. Configure Weblate's commit format to match your project's style (e.g., `msgid` order preservation for `.po`).
- **Translation memory quality**: grows over time; useful for consistency. Import existing TMs as `.tmx` if migrating.
- **Machine translation costs**: DeepL/Google Translate APIs cost money per char. Track quota. LibreTranslate is free + self-hostable (pair with Weblate).
- **Screenshots for context**: dramatically improve translator quality. Batch-upload via API + link to strings via text match.
- **Permissions**: default Weblate allows anyone to suggest; only reviewers can save. Tune per project (public FOSS vs confidential commercial).
- **Email deliverability**: registration + review notifications rely on SMTP. Use transactional email.
- **SAML/OIDC SSO**: easier than in many Django apps; but test against your IdP before rollout.
- **Billing plugin** (for hosting customer projects): Weblate supports billing-based quotas, but this is mostly relevant for hosted.weblate.org use case.
- **LibreTranslate pairing**: self-host LibreTranslate, configure as Weblate MT provider → free + private + decent quality for many languages.
- **Resource scaling**: Weblate's Celery worker count matters on large instances. Tune `CELERY_MAIN_OPTIONS` per CPU.
- **Background tasks** — git pull/push, quality checks, stats — all happen in Celery. Monitor queue depth; failed tasks silently delay.
- **License**: **GPL-3.0+** (note the "or later" clause).
- **Commercial**: hosted plans (self-host instances can optionally pay support contracts via Weblate s.r.o. in Czech Republic).
- **Pronunciation**: Weblate ≈ "web-late" (English) — Czech origin.
- **Alternatives worth knowing:**
  - **Crowdin** (SaaS) — commercial; very popular; rich ecosystem
  - **Transifex** (SaaS) — commercial; enterprise-leaning
  - **Pootle** — older Python; largely superseded by Weblate
  - **Lokalise** (SaaS) — commercial
  - **Phrase** (SaaS) — commercial
  - **POEditor** (SaaS) — commercial
  - **Tolgee** — newer open-source alternative; different focus (in-app editor)
  - **Transmart** / **Translate** plugins in static site generators — for smaller needs
  - **Choose Weblate (self-host) if:** you want git-backed, self-hostable, FOSS-friendly translation management.
  - **Choose hosted.weblate.org if:** you're an FOSS project — free + takes burden off you.
  - **Choose Crowdin/Transifex if:** commercial enterprise features, SaaS, no-ops.
  - **Choose Tolgee if:** modern in-app translation editor approach.

## Links

- Repo: <https://github.com/WeblateOrg/weblate>
- Docker compose repo: <https://github.com/WeblateOrg/docker-compose>
- Website: <https://weblate.org>
- Hosted: <https://hosted.weblate.org>
- Docs: <https://docs.weblate.org>
- Installation (Docker): <https://docs.weblate.org/en/latest/admin/install/docker.html>
- Releases: <https://github.com/WeblateOrg/weblate/releases>
- Discussions: <https://github.com/WeblateOrg/weblate/discussions>
- Matrix: `#weblate:matrix.org`
- Docker Hub: <https://hub.docker.com/r/weblate/weblate>
- Michal Čihař (author): <https://cihar.com>
- LibreTranslate (pair for free MT): <https://libretranslate.com>
- Tolgee (alt): <https://tolgee.io>
- Crowdin (alt SaaS): <https://crowdin.com>
