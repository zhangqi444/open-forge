---
name: Friendica
description: "Open federated social network. PHP/MySQL or Docker. friendica/friendica. Fediverse: ActivityPub + Diaspora + OStatus. Connects to Mastodon, Lemmy, Peertube, Pixelfed, Pleroma, etc."
---

# Friendica

**Platform for decentralised social communication — your open and free social network.** Part of the Fediverse: via multiple protocols, Friendica connects to Mastodon, Lemmy, Diaspora, Misskey, Peertube, Pixelfed, Pleroma, and more. Receives content from Tumblr, WordPress, and RSS too. Import/mirror via IFTTT and Buffer add-ons. Granular per-post privacy scope.

Long-running project, **Fediverse veteran**. On the [Awesome Humane Tech](https://codeberg.org/teaserbot-labs/delightful-humane-design#fediverse) list.

- Upstream repo: <https://github.com/friendica/friendica>
- Project site: <https://friendi.ca>
- Docker repo: <https://github.com/friendica/docker>
- Public server directory: <https://dir.friendica.social/servers>
- Install docs: <https://github.com/friendica/friendica/blob/stable/doc/en/admin/install.md>
- Addons: <https://github.com/friendica/friendica-addons>

## Architecture in one minute

- **PHP 7.4+** + **MySQL/MariaDB** (InnoDB + Barracuda row format required)
- **Apache** with `mod_rewrite` + `AllowOverride All` (upstream-blessed); Nginx works via wiki config
- Long-running **worker daemon** (cron or systemd) for background message delivery — Friendica is more like an email server than a typical blog
- Resource: **medium** — PHP app + DB + queued deliveries
- Must be at a TLD or subdomain (no path component); **required** for Diaspora federation

## Compatible install methods

| Infra              | Runtime                                  | Notes                                                                              |
| ------------------ | ---------------------------------------- | ---------------------------------------------------------------------------------- |
| **Bare-metal LAMP** | Apache + PHP + MySQL                    | **Upstream-primary**. See `doc/en/admin/install.md`.                               |
| **Docker**         | `friendica/server` (hub.docker.com)      | Community-maintained at <https://github.com/friendica/docker>                      |
| **YunoHost**       | `friendica_ynh`                          | <https://github.com/YunoHost-Apps/friendica_ynh>                                   |
| **Unraid**         | Community template                       | <https://www.jenovarain.com/2023/03/setting-up-friendica-on-unraid/>                |

## Inputs to collect

| Input                 | Example                    | Phase     | Notes                                                                            |
| --------------------- | -------------------------- | --------- | -------------------------------------------------------------------------------- |
| Domain                | `social.example.com`       | URL       | **Must be TLD or subdomain; no path.** Required for Diaspora federation.         |
| TLS                   | Let's Encrypt email        | TLS       | Fediverse-wide federation requires HTTPS                                         |
| MySQL/MariaDB         | host + DB + user + pw      | Storage   | InnoDB + Barracuda row format                                                     |
| Admin email           | you@example.com            | Auth      | First-user / admin during install wizard                                         |
| SMTP                  | provider + API key         | Notify    | Required for notifications / password reset / confirmation emails                |
| Cron / worker daemon  | every minute               | Runtime   | Background delivery; systemd service is upstream-recommended                     |
| Image library (opt.)  | ImageMagick                | Media     | For animated GIF / WebP support                                                   |

## Install via bare-metal (upstream-recommended)

Follow upstream: <https://github.com/friendica/friendica/blob/stable/doc/en/admin/install.md>.

Summary:

1. Provision **Ubuntu/Debian/RHEL** host with PHP 7.4+, Apache (with `mod_rewrite`), MySQL/MariaDB. Ensure POSIX module is enabled (RHEL/CentOS disable it by default).
2. Create a MySQL DB with UTF8MB4 + InnoDB + Barracuda row format.
3. Clone Friendica from GitHub into your web root; clone the addons repo into `addon/`.
4. Enable `AllowOverride All` on the vhost so Friendica's `.htaccess` works.
5. Set up HTTPS (Let's Encrypt via Certbot).
6. Visit `https://<domain>/` — the install wizard prompts for DB creds + admin email + timezone.
7. Set up **cron** (every minute) or the systemd daemon service for the worker.
8. Configure SMTP in Admin settings.

## Install via Docker

Follow <https://github.com/friendica/docker>. Typical compose:

```yaml
services:
  app:
    image: friendica/server:stable
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - friendica-data:/var/www/html
    environment:
      FRIENDICA_URL: https://social.example.com
      FRIENDICA_ADMIN_MAIL: admin@example.com
      MYSQL_HOST: db
      MYSQL_DATABASE: friendica
      MYSQL_USER: friendica
      MYSQL_PASSWORD: changeme
    depends_on:
      - db

  db:
    image: mariadb:10
    restart: unless-stopped
    command: --innodb-file-format=Barracuda --innodb-file-per-table=1
    volumes:
      - db-data:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: changeme
      MYSQL_DATABASE: friendica
      MYSQL_USER: friendica
      MYSQL_PASSWORD: changeme

  cron:
    image: friendica/server:stable-cron
    restart: unless-stopped
    volumes:
      - friendica-data:/var/www/html
    depends_on:
      - app

volumes:
  friendica-data:
  db-data:
```

Check upstream's docker repo for current env vars + image tags — the Docker stack also ships a separate `*-cron` image for the worker daemon.

## First boot

1. Deploy.
2. Visit your domain → run install wizard (DB creds, admin email, timezone, language).
3. Set up **cron** or systemd worker — without it, outgoing posts never leave the queue.
4. Register your admin account → access the Admin panel at `/admin`.
5. Configure **SMTP** so confirmations + password resets + notifications work.
6. Enable **addons** as needed (e.g. phpmailer for SMTP, twitter, mastodon-bridge).
7. Test federation: follow a Mastodon account from the search bar. Should resolve + deliver.
8. Back up DB + `config/local.config.php` + `storage/` (if local).

## Data & config layout

- `<web root>/config/local.config.php` — main config (DB creds, site name, etc.)
- `<web root>/storage/` — media uploads (if local-file storage backend is chosen)
- MySQL DB `friendica` — all posts, relationships, messages, timelines
- `<web root>/addon/` — addon source tree

## Backup

```sh
mysqldump friendica > friendica-$(date +%F).sql
sudo tar czf friendica-files-$(date +%F).tgz /var/www/friendica/config/ /var/www/friendica/storage/
```

Contents: **full social graph + DMs + photos + contact list** — social data is high-sensitivity (who knows whom, what they said). Encrypt at rest; restrict access.

## Upgrade

1. Tags: <https://github.com/friendica/friendica/releases>
2. Bare-metal: `git pull` on `stable` branch, `composer install`, run DB migrations via the admin console.
3. Docker: `docker compose pull && docker compose up -d`; run migrations per upstream release notes.
4. Always back up DB before upgrade.

## Gotchas

- **Email-server mindset, not blog mindset.** Friendica queues deliveries to remote Fediverse servers. Without a reliable cron/worker, posts pile up and are delivered late (or not at all). The worker is not optional.
- **URL layout is strict.** Must be TLD or subdomain — no `/friendica/` path component. **Required** for Diaspora federation; Diaspora silently rejects path-mounted servers.
- **POSIX module on RHEL/CentOS.** Disabled by default on Red Hat family distros; Friendica fails cryptically without it. Either install on Debian/Ubuntu (easier) or explicitly enable POSIX per the Friendica docs.
- **MySQL needs InnoDB + Barracuda.** Modern MariaDB defaults ship with this, but older MySQL setups may need `innodb-file-format=Barracuda` + `innodb-file-per-table=1`.
- **PHP command-line must have `register_argc_argv = On`.** Needed for cron scripts. Separate setting from web-mode PHP; commonly missed.
- **Apache `mod_rewrite` + `AllowOverride All` required.** Nginx works but needs a hand-crafted config from the wiki — less hand-holding than Apache.
- **Federation-protocol soup.** Friendica speaks ActivityPub, Diaspora, OStatus, DFRN. If a remote server refuses to federate, it's usually a protocol-compatibility quirk — logs + the remote admin are your friends.
- **Addons enable real federation bridges.** Twitter, Mastodon, Buffer, IFTTT bridges are addons — not core. Install `friendica-addons` alongside core and enable what you need.
- **Hosting-provider-compatibility warning (upstream).** Many cheap PHP hosts won't work because they don't allow cron or don't have full `php-cli`. Upstream's README warns about this specifically.
- **Moderation is the social-server admin burden.** Fediverse instance operators are moderators — expect spam accounts, federation-abuse reports, and defederation decisions. Not a "set and forget" deploy.
- **Fediverse-instance-responsibility.** You're running a node in a federated network that hosts other people's social data. Budget for backups, abuse handling, and GDPR/DSA-style responsibilities if you have EU users.
- **Legacy PHP code base (~2010 origins).** It works, it federates widely, but the code shows its age compared to newer Fediverse projects (Mastodon, Misskey). Trade-off: best Fediverse-protocol breadth vs cleanest codebase.

## Project health

Active (long-running project from the Fediverse's earliest days), humane-tech-listed, multiple install methods (bare-metal + Docker + YunoHost + Unraid), active issue tracker, Fediverse helper/developer forums.

## Fediverse-server-family comparison

- **Friendica** — widest protocol breadth (ActivityPub + Diaspora + OStatus + DFRN), PHP/MySQL, veteran project
- **Mastodon** — ActivityPub-only, Ruby/Rails, largest user base, tweet-style UX
- **Misskey** — ActivityPub, Node/TypeScript, feature-rich, quote-posts
- **Pleroma / Akkoma** — ActivityPub, Elixir, lightweight, customizable
- **Hubzilla** — sibling project (same lineage as Friendica), "nomadic identity" focus
- **GoToSocial** — Go, lightweight, single-user focus

**Choose Friendica if:** you want maximum Fediverse-protocol coverage (Diaspora is a big one — Mastodon doesn't speak it) and don't mind a veteran PHP codebase.

## Links

- Repo: <https://github.com/friendica/friendica>
- Docs: <https://github.com/friendica/friendica/tree/stable/doc/en>
- Addons: <https://github.com/friendica/friendica-addons>
- Docker: <https://github.com/friendica/docker>
- Mastodon (alt): <https://github.com/mastodon/mastodon>
- Hubzilla (sibling): <https://hubzilla.org>
