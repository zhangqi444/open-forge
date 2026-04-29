---
name: Grav
description: Fast, file-based PHP CMS — flat-file (no database), YAML/Markdown content, Twig templates, GPM (plugin/theme manager). Middleweight between Jekyll-style static generators and full CMSes like WordPress. MIT.
---

# Grav

Grav is a "flat-file CMS": content lives in Markdown + YAML files on disk, no database. Pages render through Twig templates, themes + plugins are first-class, and a built-in "Admin" plugin provides a web UI for authoring. The Grav Package Manager (`bin/gpm`) installs/updates plugins, themes, and Grav itself from <https://getgrav.org>.

Deployment is traditional PHP: a directory of PHP + YAML + Markdown on disk, served by nginx or Apache with PHP-FPM. The upstream project ships no Docker image but `lscr.io/linuxserver/grav` is the community-standard container.

- Upstream repo: <https://github.com/getgrav/grav>
- Skeleton + blueprints: <https://github.com/getgrav/grav-skeleton-*> repos (dozens of starter templates)
- Docs: <https://learn.getgrav.org/>
- Installation: <https://learn.getgrav.org/basics/installation>
- Community image: `lscr.io/linuxserver/grav` (LinuxServer.io)

## Compatible install methods

| Infra           | Runtime                              | Notes                                                             |
| --------------- | ------------------------------------ | ----------------------------------------------------------------- |
| Single VM       | Docker (`lscr.io/linuxserver/grav`)  | **Recommended for self-hosters.** LSIO image bundles nginx + PHP   |
| Shared hosting  | Upload ZIP / Composer project        | Works on any PHP-7.3.6+ host with FTP/SSH                          |
| Bare metal      | PHP-FPM + nginx/Apache               | Upstream-documented                                                |
| Static export   | GravCLI → flat HTML                 | Hybrid: author in Grav, export for CDN                             |

## Inputs to collect

| Input           | Example                          | Phase    | Notes                                                     |
| --------------- | -------------------------------- | -------- | --------------------------------------------------------- |
| `PUID` / `PGID` | `1000` / `1000`                  | Runtime  | Match host user for volume writes                          |
| Port            | `80:80`                          | Network  | No built-in TLS; behind reverse proxy for HTTPS            |
| Data volume     | `/config`                        | Data     | Entire Grav installation persists here                    |
| Admin account   | created via Admin plugin setup   | Bootstrap | First visit to `/admin` prompts for admin creation         |
| PHP extensions  | standard: curl, gd, openssl, mbstring, zip, xml | Runtime | Bundled in LSIO image                              |

## Install via Docker Compose (`lscr.io/linuxserver/grav`)

From <https://github.com/linuxserver/docker-grav>:

```yaml
services:
  grav:
    image: lscr.io/linuxserver/grav:latest
    container_name: grav
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./grav/config:/config   # entire Grav tree lives here (content, themes, plugins, logs)
    ports:
      - "8080:80"               # behind reverse proxy for TLS
```

First boot extracts a default Grav skeleton into `./grav/config/www/`. Browse `http://<host>:8080` for the default landing page; `http://<host>:8080/admin` for the admin setup (prompts for admin account if Admin plugin is installed — which it is by default in the LSIO image).

### Install via Composer (upstream)

```sh
composer create-project getgrav/grav /var/www/grav
cd /var/www/grav
bin/grav install          # fetches all plugin+theme dependencies
bin/gpm install admin     # add the web admin UI
# Configure nginx/Apache vhost pointing at /var/www/grav
```

Skeletons (`grav-skeleton-blog-site`, `…-portfolio-site`, `…-one-page-site`, etc.) are preconfigured starting points — browse <https://getgrav.org/downloads/skeletons> and download directly via `composer create-project getgrav/<skeleton-name>`.

## Updating & managing plugins/themes

All through the Grav Package Manager (`bin/gpm`):

```sh
# Inside the container:
docker exec grav bin/gpm index                    # list available plugins
docker exec grav bin/gpm install admin form email # install plugins
docker exec grav bin/gpm install antimatter       # install a theme
docker exec grav bin/gpm update                   # update all plugins + themes
docker exec grav bin/gpm selfupgrade              # upgrade Grav core
```

Or use the admin web UI if the Admin plugin is installed.

## Data & config layout

`/config/www/` (inside LSIO container) contains the entire Grav install:

- `/config/www/user/pages/` — your content (`.md` files, one per page; folder structure = URL structure)
- `/config/www/user/config/` — YAML config files (site.yaml, system.yaml)
- `/config/www/user/themes/` — installed themes
- `/config/www/user/plugins/` — installed plugins
- `/config/www/user/data/` — plugin-specific persistent data (form submissions, comments)
- `/config/www/user/accounts/` — user accounts (YAML files with hashed passwords — store carefully)
- `/config/www/logs/` — Grav + plugin logs
- `/config/www/cache/` — cleared on config change; safe to delete

## Backup

Backup = tar the `/config` volume. That's the entire site state.

```sh
docker compose stop grav
tar czf grav-$(date +%F).tgz ./grav
docker compose start grav
```

For hot backups, Grav's admin plugin also has a one-click "Backup" button — writes a ZIP to `user/backup/`.

## Upgrade

1. Releases: <https://github.com/getgrav/grav/releases>.
2. `docker compose pull && docker compose up -d` — LSIO image tracks Grav stable.
3. Or `docker exec grav bin/gpm selfupgrade` — upgrade Grav in-place.
4. Plugins/themes: `docker exec grav bin/gpm update`.
5. Upgrade guides:
   - 1.7: <https://learn.getgrav.org/17/advanced/grav-development/grav-17-upgrade-guide>
   - 1.6 and earlier: older upgrade guides on the same doc site
6. Back up `/config` before major version jumps.

## Gotchas

- **Flat-file = filesystem performance matters.** Grav caches heavily, but initial page render without cache hits reads many small files. NFS-mounted `/config` is noticeably slower than local disk.
- **Admin plugin is a separate install.** The bare Grav skeleton has NO web UI — just content files. Install `admin`, `form`, `login`, and `email` plugins for a functional authoring experience.
- **Password hashes live in flat files** (`user/accounts/*.yaml`). Anyone with filesystem read access can see the hashes. Use bcrypt (default) and protect the volume.
- **No database means no built-in search at scale.** Grav's default search iterates files. For sites >200 pages, install the `tntsearch` plugin (SQLite-backed index).
- **`user/data/` accumulates plugin data.** Form submissions, comment entries, etc. land in flat files. Busy sites can end up with tens of thousands of small files — plan filesystem + backup strategy.
- **GPM fetches from `getgrav.org` over HTTPS.** Air-gapped deploys need to host a local GPM mirror or `composer create-project` each plugin offline.
- **The LSIO image mounts the ENTIRE install at `/config`.** Unlike WordPress-style setups where only `wp-content/` is mounted, Grav's per-volume layout means an upgrade is `docker compose pull` + the image runs its own self-update. `/config` persists everything.
- **First-boot setup race.** The LSIO image extracts the default skeleton only if `/config` is empty. If you bind-mount a pre-populated directory, ensure the expected structure exists or the container fails to serve.
- **`chmod` matters.** PHP needs read-write access to `/config/www/user/` for admin-UI content editing. Wrong PUID/PGID silently disables the admin's "save" button.
- **HTTPS in admin URL is required for secure cookies.** Behind a reverse proxy, set `Absolute URL` in `user/config/system.yaml` to your public `https://` URL or admin login flows break.
- **Twig template errors surface as 500s** with details in `/config/www/logs/grav.log`. Debug mode (`system.twig.debug: true`) shows errors in the browser.
- **PHP version matters.** Grav 1.7+ requires PHP 7.3.6+; newer cores want PHP 8.x. Check `learn.getgrav.org/basics/requirements` before upgrading.
- **Skeletons are starting points, not themes.** Once you download a skeleton, it's *your* site — not tracked for updates. Theme-only upgrades happen via `bin/gpm update`.
- **Content is Markdown + YAML frontmatter.** Plain-text, git-friendly. Many users version-control the entire `user/` directory. Admin UI writes compatible Markdown, so hand-editing + admin editing both work.
- **File upload limits** depend on PHP-FPM config (`upload_max_filesize`, `post_max_size`) — adjust in `/config/php/php-local.ini` or similar, then restart the container.
- **Unlike WordPress, Grav has a much smaller ecosystem.** ~300 plugins vs WordPress's 60k+. If a feature isn't in Grav's plugin index, you're likely writing PHP.
- **Grav 2.x is in development** (check the repo's `2.0` branch). Expect significant changes to the plugin API when it ships.

## Links

- Repo: <https://github.com/getgrav/grav>
- Website: <https://getgrav.org/>
- Docs: <https://learn.getgrav.org/>
- Installation: <https://learn.getgrav.org/basics/installation>
- Downloads (skeletons / plugins / themes): <https://getgrav.org/downloads>
- GPM guide: <https://learn.getgrav.org/advanced/grav-gpm>
- Admin plugin: <https://github.com/getgrav/grav-plugin-admin>
- LSIO Docker repo: <https://github.com/linuxserver/docker-grav>
- Releases: <https://github.com/getgrav/grav/releases>
- Community (Discord): <https://chat.getgrav.org/>
