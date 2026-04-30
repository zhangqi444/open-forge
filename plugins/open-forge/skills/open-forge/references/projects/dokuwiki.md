---
name: DokuWiki
description: "Flat-file wiki — PHP, no database, plain-text pages in revision-controlled plain text files. Lightweight, ACL-capable, huge plugin ecosystem, Since 2004. GPL-2.0."
---

# DokuWiki

DokuWiki is **the grandfather of self-hosted wikis** — a no-database, plain-text wiki engine written in PHP. Pages are Markdown-ish flat files on disk, versioned in plain files, ACL-controllable, plugin-extensible, internationalized, and runs on almost any PHP-capable host since 2004. Built + maintained by **Andreas Gohr (splitbrain)** + large community.

DokuWiki's selling points are **simplicity + longevity + Git-friendliness + no-DB ops burden**. Its syntax is its own (similar to MediaWiki / Creole) — mature, stable, well-documented.

Use case: team knowledge-base, personal notes, technical docs, internal company wiki, hobby fansite, homelab runbook. **When you want "wiki" without "operating a database-backed app."**

Features:

- **No database** — pages are plain-text files, metadata in flat files
- **Revision history** — per-page history built-in
- **ACLs** — fine-grained read/write/upload permissions (public/user/group/page)
- **User auth**: built-in + LDAP + Active Directory + OpenID Connect (via plugins) + SAML (via plugins)
- **Plugins** — 1800+ on <https://www.dokuwiki.org/plugin>
- **Templates** — change look + feel
- **i18n** — many interface languages
- **Full-text search**
- **File / image uploads** — inline media handling
- **Namespaces** — hierarchical organization (folder-like)
- **Interwiki links** — cross-wiki references
- **Caching** — page render cached
- **Runs on shared hosting** — PHP + no DB means works on any cheap PHP host

- Upstream repo: <https://github.com/dokuwiki/dokuwiki>
- Homepage: <https://www.dokuwiki.org>
- Docs: <https://www.dokuwiki.org/manual>
- Install instructions: <https://www.dokuwiki.org/install>
- Plugin repository: <https://www.dokuwiki.org/plugin>
- Template gallery: <https://www.dokuwiki.org/template>
- Mailing list: <https://www.dokuwiki.org/mailinglist>
- Forum: <https://forum.dokuwiki.org>
- Docker image (official): <https://hub.docker.com/r/dokuwiki/dokuwiki>
- Author: Andreas Gohr <andi@splitbrain.org>

## Architecture in one minute

- **Pure PHP**, no DB
- Pages stored as `.txt` files under `data/pages/<namespace>/` — YES, plain text on disk, Git-versionable
- Attics (revisions) as compressed `.txt.gz` files under `data/attic/`
- Media (uploads) under `data/media/`
- Metadata sidecars (last-editor, index, cache) under `data/meta/`, `data/index/`, `data/cache/`
- **Resource**: tiny — runs on 64 MB PHP hosts
- **Works on subdomain OR subdirectory** (unlike Kimai this batch)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Shared hosting     | **Upload files + PHP 7.4+**                                        | **Upstream-primary + simplest**                                                    |
| VPS                | PHP + web server (nginx/Apache/Caddy)                                    | Standard                                                                                   |
| Docker             | **Official image or community images**                                              | Works well                                                                                             |
| Bare-metal Linux   | Distro package (`dokuwiki` in Debian/Ubuntu repos)                                   | Gets dated; prefer upstream download                                                                              |
| Kubernetes         | Simple PHP deploy                                                                              | Uses PV for `data/` directory                                                                                       |

## Inputs to collect

| Input                | Example                                                        | Phase        | Notes                                                                    |
| -------------------- | -------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain / path        | `wiki.example.com` OR `example.com/wiki`                         | URL          | Both work                                                                        |
| PHP 7.4+             | with standard extensions                                                | Runtime      | Extensions: standard PHP + `xml`, `json`, `gd`                                                  |
| Admin user           | Set during installer                                                                | Bootstrap    | Create via installer at `/install.php`                                                                                 |
| ACL policy           | Public read + auth write? / Auth-only?                                                           | ACL          | Configure via admin panel                                                                                                         |
| Auth backend (opt)   | Built-in / LDAP / SAML                                                                                      | Auth         | Plugins for external IdP                                                                                                                            |
| Data dir location    | `data/` outside webroot (recommended)                                                                              | Storage      | Security: prevents direct web access to page files                                                                                                             |

## Install

### Via official Docker image

```yaml
services:
  dokuwiki:
    image: dokuwiki/dokuwiki:latest                # pin version in prod
    container_name: dokuwiki
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./data:/storage/data
      - ./conf:/storage/conf
```

### Via direct download (shared hosting / VPS)

1. Download from <https://download.dokuwiki.org/>
2. Upload + extract to webroot
3. Browse `/install.php` → enter admin user + password + wiki title + initial ACL
4. Delete `install.php` (installer warns + should auto-delete; verify)
5. Put `data/` OUTSIDE webroot + update config path (recommended security)

## First boot

1. Install → create admin user
2. Configure ACL (`admin → Access Control List`) — default policy + per-page overrides
3. Pick a template (`admin → Configuration Settings → Template`)
4. Install essential plugins (auth-LDAP / auth-SAML / auth-OpenID / backup-tools)
5. Create your first page — learn DokuWiki syntax (`====== Heading ======`, `**bold**`, etc.)
6. Put behind TLS
7. Set up regular backup of `data/` + `conf/`

## Data & config layout

- `data/pages/<namespace>/<page>.txt` — current page text
- `data/attic/<namespace>/<page>.<timestamp>.txt.gz` — revisions
- `data/media/` — uploads
- `data/meta/` — metadata sidecars
- `data/index/` — search index
- `data/cache/` — render cache (regeneratable)
- `conf/users.auth.php` — user accounts (hashed passwords) in plain-text file
- `conf/acl.auth.php` — ACL rules
- `conf/local.php` — site-wide settings

## Backup

```sh
# DokuWiki IS the files — just copy them
sudo tar czf dokuwiki-$(date +%F).tgz data/ conf/

# Or for point-in-time safety on live site:
rsync -av /var/www/dokuwiki/data/ /backup/dokuwiki-data-$(date +%F)/
```

**Git-version the `data/` directory** for free version history beyond DokuWiki's built-in attic:

```sh
cd data/
git init
git add .
git commit -m "snapshot"
# cron nightly commit+push for off-site versioned backup
```

## Upgrade

1. Releases: <https://download.dokuwiki.org>. LTS pattern.
2. Standard upgrade:
   - Back up `data/` + `conf/`
   - Download new tarball
   - Extract over existing install (OVERWRITE code; do NOT touch `data/`, `conf/`)
3. Docker: bump tag → restart.
4. **Plugins need separate update** — some break between DW versions; check plugin's compatibility status.

## Gotchas

- **PAGES ARE FLAT FILES** — edit `data/pages/.../mypage.txt` with any text editor, git-track them, grep them, bulk-edit with sed. Power-user feature + Git-native discipline.
- **`data/` MUST NOT be web-accessible** or anyone can read raw page files. Move outside webroot + set `$conf['savedir']` appropriately. Standard install puts it OK but some deployments get this wrong.
- **`conf/users.auth.php` contains password hashes** in plain-text file. Permissions: webserver-readable, not world-readable. Classic PHP-app hardening.
- **ACL configuration is POWERFUL but tricky**. Default = public-read, user-write. If you want authenticated-read-only: configure `@ALL` = none, `@user` = read. Test with a logged-out browser to verify. Misconfigured ACL = accidental public exposure. Use ACL checker in admin.
- **Plugin trust**: 1800+ plugins. Some abandoned. Read plugin info (last update, compatibility) before installing. Never install plugins from non-official sources — running arbitrary PHP on your server.
- **DokuWiki syntax is NOT Markdown**. `**bold**` + `//italic//` + `====== Heading ======` + `[[link]]` + `{{image.jpg}}` — its own flavor. Short learning curve; then very fast. Plugins can add Markdown support if needed.
- **Search index can corrupt / fall out of sync** on rare occasions. Admin → Maintenance → Rebuild Indexes fixes it.
- **Scales to ~thousands of pages comfortably**. Beyond, the flat-file model + `data/pages/` directory listing slows down somewhat. Still functional but consider DB-backed wikis (MediaWiki, BookStack) for 100,000+ pages.
- **Not the best fit for highly-structured documentation** — DokuWiki is open-format. Use MkDocs/Hugo/Antora if your docs need rigid structure + publish-pipeline + code-embed.
- **Git-versioning `data/`** = your entire wiki history in Git → diff / blame / history across pages. Run cron: `git add -A && git commit -m "$(date)"` nightly. Pair with off-site git push for off-site backup.
- **Template ecosystem** active-ish. Many older templates still work (DW's stability is a virtue). Admin → Template Installer.
- **Long-term project stability**: 2004→present, same author + community. Bus-factor healthy. Many cautious-IT-deployments use it precisely because it's been around forever.
- **License**: **GPL-2.0** (check COPYING). Plugins have individual licenses.
- **Alternatives worth knowing:**
  - **MediaWiki** — Wikipedia engine; PHP + DB; much more feature-rich but heavier
  - **BookStack** — Laravel + DB; modern UI; book/chapter/page structure
  - **Outline** — Node + PG; modern team knowledge base
  - **MkDocs / Docusaurus / Hugo** — static-site doc generators (different category)
  - **TiddlyWiki** — single-HTML-file personal wiki
  - **Wiki.js** — Node + DB; modern; more like Notion
  - **SilverBullet** (batch 73) — Markdown + Git-backed filesystem
  - **Obsidian / Logseq** — local-first personal notes; not wiki-per-se
  - **Choose DokuWiki if:** low-ops + flat-file + long-stable + run on shared PHP hosting + team knowledge base.
  - **Choose BookStack if:** modern UI + book/chapter structure + Laravel comfort.
  - **Choose MediaWiki if:** maximum feature set + familiar to Wikipedia editors.
  - **Choose Outline / Wiki.js if:** Node-stack + modern UX + DB comfort.

## Links

- Repo: <https://github.com/dokuwiki/dokuwiki>
- Homepage: <https://www.dokuwiki.org>
- Manual: <https://www.dokuwiki.org/manual>
- Install: <https://www.dokuwiki.org/install>
- Download: <https://download.dokuwiki.org>
- Plugins: <https://www.dokuwiki.org/plugin>
- Templates: <https://www.dokuwiki.org/template>
- Syntax reference: <https://www.dokuwiki.org/wiki:syntax>
- Forum: <https://forum.dokuwiki.org>
- Docker Hub: <https://hub.docker.com/r/dokuwiki/dokuwiki>
- Releases: <https://www.dokuwiki.org/changes>
- Author's blog: <https://splitbrain.org>
- MediaWiki (alt): <https://www.mediawiki.org>
- BookStack (alt): <https://www.bookstackapp.com>
- Wiki.js (alt): <https://wiki.js.org>
- Outline (alt): <https://www.getoutline.com>
