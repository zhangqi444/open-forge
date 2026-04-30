---
name: Sandstorm
description: "Self-hosted web productivity suite: security-hardened app 'package manager' that sandboxes each grain (document/wiki/etc.) in its own container. Install apps from the Sandstorm market with one click. x86-64 Linux. Apache-2.0."
---

# Sandstorm

Sandstorm is **an opinionated self-hosted platform for running web apps** — not a single app, but a **security-hardened runtime** that packages each app (and each *instance* of data — e.g., a document, a wiki, a blog) in its own sandbox ("grain"). Click an app in the in-app market, create a new grain, share the link — and the grain runs in its own ephemeral container with no network access by default.

Philosophy: apps should be as easy to install as on a phone, as isolated as VMs, and share data only via explicit Powerbox requests. A 2014-era vision of "personal cloud" that pioneered capability-based security for webapps.

> **Project status (read carefully):**
> - **Sandstorm was largely unmaintained 2017-2020** after Sandstorm.io (the company) pivoted.
> - **Community revival is ongoing** — the `sandstorm-io/sandstorm` repo sees sporadic maintenance. Check latest commits + releases before deploying.
> - **App ecosystem (apps.sandstorm.io)** is **frozen in time** — many apps are old versions (e.g., an older Etherpad, older WordPress). Upstream projects have moved on; Sandstorm packages typically haven't.
> - **Oasis** (Sandstorm's hosted SaaS at `oasis.sandstorm.io`) **was shut down** — self-host only.
> - For new deployments, most self-hosters choose **YunoHost** (similar app-store vision) or **NixOS modules** for multi-app hosting; Sandstorm is primarily of historical + research interest now.
> - That said: **the security model is still excellent** and unique. If its philosophy matches your use case, it's still usable.

- Upstream repo: <https://github.com/sandstorm-io/sandstorm>
- Website: <https://sandstorm.io>
- Docs: <https://docs.sandstorm.io>
- Demo: <https://demo.sandstorm.io>
- App market: <https://apps.sandstorm.io>
- Community: <https://sandstorm.io/community>
- Dev group: <https://groups.google.com/group/sandstorm-dev>

## Architecture in one minute

- **One Sandstorm install** → a server runs the Sandstorm shell (Meteor app + Mongo)
- **Grains** — each "instance" of an app (e.g., one Etherpad doc, one WordPress blog) runs in its own chroot + namespaces + seccomp sandbox with **no network** by default
- **Powerbox** — capability-based UI for cross-grain sharing (e.g., "let this blog embed this Etherpad")
- **SPK packages** — apps distributed as signed `.spk` bundles; installed offline or from the market
- **Cap'n Proto** — the IPC layer
- **Wildcard DNS required** — each grain gets a random subdomain

## Compatible install methods

| Infra      | Runtime                                         | Notes                                                         |
| ---------- | ----------------------------------------------- | ------------------------------------------------------------- |
| Single VM  | **Official install script (`install.sh`)** on x86-64 Linux | **The only well-supported way**                                   |
| Docker     | Possible but nontrivial (needs privileged + namespaces) | Not upstream-recommended                                              |
| Kubernetes | Not supported upstream                                             |                                                                              |
| ARM        | Not supported (x86-64 only)                                                    | No Pi install                                                                        |
| Managed    | Oasis (shut down); no current SaaS alternative                                              |                                                                                              |

## Inputs to collect

| Input              | Example                                      | Phase     | Notes                                                            |
| ------------------ | -------------------------------------------- | --------- | ---------------------------------------------------------------- |
| Base domain        | `sandstorm.example.com`                         | DNS       | Shell / admin UI hostname                                              |
| Wildcard           | `*.sandstorm.example.com`                          | DNS       | **Mandatory** — each grain = subdomain                                                  |
| Wildcard TLS       | Let's Encrypt DNS-01                                    | Security  | HTTP-01 won't do wildcard                                                                    |
| Server type        | single-tenant / multi-user / invite-only                      | Config    | Controls sign-up mode                                                                                    |
| Admin login token  | generated during install                                                  | Bootstrap | First-user token printed on install                                                                                      |
| SMTP (opt)         | for invites + notifications                                                         | Email     | Recommended                                                                                                                              |

## Install (standard)

```sh
curl https://install.sandstorm.io | bash
# Answers a few questions (port, username, data dir, etc.)
# Prints admin URL + token for first login
```

After install:
- Visit `https://sandstorm.example.com/` → enter admin token → become first admin
- Configure base URL + wildcard + SMTP via admin UI
- Open the app market tab → install apps (they register subdomains on the fly)

## Wildcard TLS

Obtain a wildcard cert via DNS-01 (Cloudflare/Route53/etc.):
```sh
certbot certonly --dns-cloudflare -d sandstorm.example.com -d *.sandstorm.example.com
```
Place cert where Sandstorm expects (see docs); Sandstorm can also use sandcats.io free DNS + TLS if you let it.

## Sandcats.io

Upstream offers **sandcats.io** — free DNS + TLS for Sandstorm hosts (`yourname.sandcats.io`). The `install.sh` offers to set this up. It's the path of least resistance if you don't want to manage wildcard DNS + certs yourself.

## First boot

1. Log in as admin (first token)
2. Admin settings → set base URL + SMTP + sign-up mode
3. Apps tab → browse market → install e.g. Etherpad, Wekan, Rocket.Chat, WordPress, Gitlab-like
4. "Create new grain" → launch a document/board/etc.
5. Share button → generate link (with or without edit access)
6. Powerbox: when an app wants to embed or fetch from another grain, you're prompted to grant capability

## Data & config layout

- `/opt/sandstorm/` (default) — install root
  - `var/mongo/` — user / grain metadata
  - `var/sandstorm/grains/<id>/` — each grain's storage
  - `var/sandstorm/apps/` — installed app packages
  - `var/log/` — logs
  - `sandstorm.conf` — main config

## Backup

```sh
sudo sandstorm stop
tar czf sandstorm-$(date +%F).tgz -C /opt sandstorm/
sudo sandstorm start
```

Also: **per-grain export** — each grain has a "Download backup" option (`.zip`) via the shell UI. Users can self-serve their data.

## Upgrade

1. Releases: <https://github.com/sandstorm-io/sandstorm/releases>. Sporadic.
2. `sudo sandstorm update` (built-in) — checks for new channel release + updates in place.
3. Back up `/opt/sandstorm` first.
4. Grain data format rarely changes; app packages update independently via the market.

## Gotchas

- **Maintenance status** — check the repo activity before committing to a new Sandstorm deployment. For years it had little upstream activity. A community fork or revitalization may emerge; or not. Plan accordingly.
- **App catalog is stale** — many packaged apps are years out of date. Don't expect the latest Etherpad/WordPress in the market; package versions are frozen at whoever last pushed an `.spk`.
- **Single-user vs multi-user** — great for personal "Google Docs replacement"; multi-tenant orgs possible but rare.
- **Grain isolation is real** — each grain has no network access by default (egress prohibited). Great for security; means apps that need to call external APIs (e.g., IMAP, webhooks) are awkward. Powerbox provides HTTP egress caps if granted.
- **Wildcard DNS is mandatory** — each grain gets its own random subdomain for origin isolation. You must control `*.your-sandstorm.tld`.
- **x86-64 Linux only** — no ARM, no macOS, no BSD.
- **Apps are not Docker images** — Sandstorm has its own package format (SPK) with runtime contract. Packaging a new app means writing a "vagrant-spk" build — nontrivial.
- **Grain state** — when you delete a grain, its data is gone. There's no multi-grain backup/restore UI beyond individual export.
- **No native mobile apps** — everything is web; some apps have phone-friendly UIs.
- **Share-by-link model** — grain URLs contain crypto tokens; anyone with the URL has whatever permissions were granted. Rotating/revoking requires re-sharing.
- **Migration out** — each grain's data is exportable; but importing to a fresh non-Sandstorm service depends on app-specific formats.
- **Security model** is the real story. If you want "capabilities + sandbox + data-per-grain," nothing else matches. If you just want "easy self-host apps," simpler stacks work.
- **License**: Apache-2.0 for the platform; apps have their own licenses.
- **Alternatives worth knowing:**
  - **YunoHost** — similar "app store" vision; broader + more maintained app catalog; lighter security guarantees (separate recipe)
  - **Cloudron** — commercial app-store platform (SaaS-like experience on your server) (separate recipe)
  - **Cosmos Cloud** — modern self-host management dashboard + store
  - **CasaOS / Umbrel** — homelab-friendly app dashboards
  - **Docker Compose + individual apps** — more ops but more flexibility + currency
  - **Choose Sandstorm if:** you want its capability-based security model + grain-per-document architecture and can accept stale apps.
  - **Choose YunoHost if:** you want similar spirit with a healthier ecosystem.
  - **Choose Cloudron if:** you'll pay for polished multi-app hosting.

## Links

- Repo: <https://github.com/sandstorm-io/sandstorm>
- Website: <https://sandstorm.io>
- Docs: <https://docs.sandstorm.io>
- Install docs: <https://docs.sandstorm.io/en/latest/install/>
- App market: <https://apps.sandstorm.io>
- How it works: <https://sandstorm.io/how-it-works>
- Security practices: <https://docs.sandstorm.io/en/latest/using/security-practices/>
- Developer hub: <https://docs.sandstorm.io/en/latest/developing/>
- Sandcats DNS: <https://sandcats.io>
- Community: <https://sandstorm.io/community>
- Dev group: <https://groups.google.com/group/sandstorm-dev>
- Cap'n Proto (IPC layer): <https://capnproto.org>
- YunoHost alternative: <https://yunohost.org>
- Cloudron alternative: <https://cloudron.io>
