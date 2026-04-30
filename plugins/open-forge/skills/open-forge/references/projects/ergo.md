---
name: Ergo
description: "Modern IRC server in Go (formerly Oragono). Integrated services (NickServ/ChanServ/HostServ) + bouncer (history + multi-client) + bleeding-edge IRCv3. Single binary + YAML config + rehashable. MIT. Active + mature. Fork of Ergonomadic."
---

# Ergo

Ergo is **"the IRCd you run when you want IRC-plus-bouncer-plus-services in ONE piece of software"** — a modern IRC server written in Go, formerly known as Oragono. Combines what traditionally required **3 separate daemons** (an IRCd, a services framework, and a bouncer) into one cohesive server. Bleeding-edge **IRCv3** support (used as reference implementation). Runtime-reloadable YAML config. **Built for simplicity + IRCv3 + modern security**. Fork of the Ergonomadic IRC daemon (2016 ancestor).

Built + maintained by **ergochat org** (primarily slingamn + community). **License: MIT** (ancestral Ergonomadic is also permissive). Active for 8+ years. Testnet at testnet.ergo.chat.

Use cases: (a) **small-community IRC server** — Discord / Slack alternative for a technical / nerd community (b) **bouncer alternative** — Ergo's built-in history + multi-client support replaces ZNC/SoJu bouncers (c) **IRCv3 reference implementation** — develop clients against Ergo's latest IRCv3 features (d) **Tor hidden-service IRC** — Ergo supports running as Tor .onion (e) **LDAP-integrated IRC** — enterprise-lite IRC with LDAP auth (f) **self-hosted chat for technical team** — who prefer IRC's simplicity over Slack/Discord (g) **IRCv3 protocol research** — bleeding-edge protocol experimentation.

Features (from upstream README):

- **Integrated services**: NickServ (accounts), ChanServ (channel registration), HostServ (vanity hosts)
- **Bouncer features**: history storage, multi-client same-nickname
- **Native TLS/SSL** including client certs
- **IRCv3 reference support**
- **YAML config**; **rehashable** (reload at runtime)
- **SASL authentication**
- **LDAP support** (via ergo-ldap)
- **40+ languages** via Crowdin
- **UTF-8 nick + channel names** (RFC 8265 / PRECIS)
- **Tor hidden service** support
- **Extensible IRC operator** privilege system
- **bcrypt password hashing**
- **`UBAN`** unified-ban (IPs, networks, masks, accounts) + KLINE + DLINE
- **Specs-first development** — see ergo.chat/specs.html

- Upstream repo: <https://github.com/ergochat/ergo>
- Homepage: <https://ergo.chat>
- Specs: <https://ergo.chat/specs.html>
- User guide: <https://github.com/ergochat/ergo/blob/stable/docs/USERGUIDE.md>
- Manual: <https://github.com/ergochat/ergo/blob/stable/docs/MANUAL.md>
- Productionizing: <https://github.com/ergochat/ergo/blob/stable/docs/MANUAL.md#productionizing-with-systemd>
- Docker: <https://ghcr.io/ergochat/ergo>
- Docker distrib dir: <https://github.com/ergochat/ergo/tree/master/distrib/docker>
- Testnet: <https://testnet.ergo.chat>
- Translations: <https://crowdin.com/project/ergochat>
- LDAP: <https://github.com/ergochat/ergo-ldap>
- AUR: <https://aur.archlinux.org/packages/ergochat/>
- Gentoo: <https://packages.gentoo.org/packages/net-irc/ergo>

## Architecture in one minute

- **Go binary** — single static executable
- **Integrated storage**: default BuntDB (embedded); no separate DB required
- **Optional**: LDAP for auth
- **Resource**: tiny — 30-100MB RAM
- **Ports**: 6667 (plaintext) + 6697 (TLS) + 6697 STARTTLS + optional custom

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Binary release** | **Download + systemd**                                          | **Upstream-recommended**                                                           |
| **Docker compose** | **`ghcr.io/ergochat/ergo` + `distrib/docker` example**          | **Common self-host**                                                               |
| Build-from-source  | `git clone` + `make`                                                     | For custom builds                                                                                   |
| AUR / Gentoo       | Distro packages                                                                                    | If available                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `irc.example.com`                                           | URL          | For TLS certs + advertised server name                                                                                    |
| TLS cert             | Real cert from Let's Encrypt + IRC port-forward             | **CRITICAL** | **`./ergo mkcerts` generates self-signed for local dev**                                                                                    |
| `ircd.yaml`          | Full config                                                                                 | **CRITICAL** | **All behavior in one file**                                                                                    |
| Network name         | `MyIRCNet`                                                                                   | Config       | Advertised in MOTD + WHO                                                                                                            |
| Admin operator       | Name + bcrypt-hashed password                                                                                                        | Bootstrap    | IRC operator-level auth                                                                                                                            |
| LDAP config          | (optional) URL + bind DN                                                                                                                       | SSO          | For enterprise use                                                                                                                                            |

## Install via Docker (distrib example)

```yaml
services:
  ergo:
    image: ghcr.io/ergochat/ergo:stable    # **pin specific version**
    container_name: ergo
    restart: unless-stopped
    ports:
      - "6667:6667"
      - "6697:6697"
    volumes:
      - ./ergo-config:/ircd
    command: ["run", "--conf", "/ircd/ircd.yaml"]
```

See <https://github.com/ergochat/ergo/tree/master/distrib/docker> for full example.

## First boot

1. Copy `default.yaml` → `ircd.yaml`; edit network + server name + listeners
2. Generate TLS: `./ergo mkcerts` (dev) or install real certs
3. Register an admin operator (bcrypt hash password with `./ergo genpasswd`)
4. Start: `./ergo run` (or docker)
5. Connect with IRC client (Hexchat, WeeChat, Irssi, The Lounge, Kiwi IRC)
6. `/oper <name> <password>` → become IRC operator
7. `/nickserv register <email>` → test NickServ registration
8. `/join #test` → test channel creation
9. Configure MOTD + rules
10. Put behind proper TLS + DNS
11. Open ports 6667 + 6697 in firewall
12. Back up `ircd.yaml` + BuntDB

## Data & config layout

- `ircd.yaml` — THE config file
- `ircd.db` (or similar) — BuntDB: accounts, channels, bans, history
- TLS certs: where `ircd.yaml` points them
- Logs — as configured

## Backup

```sh
sudo tar czf ergo-$(date +%F).tgz ergo-config/
# Consider stopping ergo first for DB consistency; or use --at-most-once semantics
```

## Upgrade

1. Releases: <https://github.com/ergochat/ergo/releases>. Semver; active.
2. Binary: replace binary + restart.
3. Docker: pull + restart.
4. **REHASHABLE CONFIG** = most changes don't need restart — send SIGUSR1 or `/rehash`. Rare feature.
5. Check release notes for DB-migration requirements on major versions.

## Gotchas

- **"IS IRC STILL RELEVANT?"** — yes, for specific communities:
  - **OSS project chats** (freenode → Libera.Chat moved in 2021; many projects stayed IRC)
  - **Technical / hacker / retro communities**
  - **Low-bandwidth, low-friction access** — works on legacy hardware, text terminals
  - **Low-lock-in simplicity** — decades-stable protocol
  - **Much-simpler-than-Matrix** alternative
  - Not: mass market, media-rich, mobile-first — use Matrix/Signal/Discord there
- **IRC CULTURE + OPERATIONS**: IRC has distinct operational culture. If running a public server, understand:
  - Netiquette expectations
  - Channel ops ethics
  - Spam + abuse handling (K-line/D-line procedures)
  - Ban-evasion tactics (proxies, Tor)
- **HISTORY STORAGE = DIFFERENT FROM TRADITIONAL IRC**: traditional IRC was ephemeral. Ergo stores history (configurable). Users should know: **messages persist server-side**. Privacy implications:
  - DMs stored for replay to offline clients
  - Channel history stored (configurable per-channel)
  - Server admin can read all (same as any chat server)
  - **Consent + disclosure** — tell users when history is stored
- **BOUNCER-INTEGRATED = NO SEPARATE ZNC**: if you've run ZNC/SoJu bouncers, Ergo's built-in bouncer replaces them. Users connect directly with one nickname from multiple clients.
- **IRCv3 FEATURE DEPENDENCY** on CLIENT: Ergo implements bleeding-edge IRCv3. But **feature works only if client supports it too**. Old clients (mIRC, pidgin, some Hexchat versions) may miss chathistory / labeled-response / message-tags etc. Modern clients (Hexchat recent, WeeChat, Gamja, The Lounge) support more.
- **TOR HIDDEN-SERVICE OPERATION** — strong privacy feature; sign of modern-IRC-server design. Affects anti-abuse strategy (Tor exit nodes often blocked elsewhere).
- **SASL = REQUIRED FOR ACCOUNT LOGIN IN MODERN CLIENTS**. Ergo supports SASL PLAIN + EXTERNAL (client cert) + SCRAM. Configure per client.
- **CLIENT CERTIFICATES = STRONG AUTH**: Ergo supports SASL EXTERNAL via client TLS cert. More secure than passwords. Power-user feature.
- **HUB-OF-CREDENTIALS TIER 2**: Ergo stores:
  - User account passwords (bcrypt-hashed — good!)
  - Channel registrations + ops
  - Private messages (if history stored)
  - Ban lists
  - LDAP creds (if integrated)
  - **48th tool in hub-of-credentials family — Tier 2.**
- **BCRYPT HASHING** — sound cryptographic choice. Positive signal; contrasts with legacy IRCds that used MD5/plaintext. **"Modern-cryptography-hygiene" signal** — positive transparent-maintenance feature.
- **REHASHABLE CONFIG** (SIGUSR1 / IRC `/rehash`) — rare + powerful + operationally friendly. **Zero-downtime-config-change** — recipe convention: when a tool supports this, highlight it. Applicable to: Ergo, nginx, haproxy, some other mature-server tools.
- **UBAN UNIFIED-BAN SYSTEM** — Ergo-specific innovation. Simpler than the patchwork K-line/G-line/D-line that traditional IRCds accumulate.
- **FORK LINEAGE**: Ergo forked from Ergonomadic (2016) + renamed from Oragono (circa 2021). **3rd tool with rebrand-preservation** pattern (Lunar 92 GetCandy→Lunar, Kometa 95 PMM→Kometa, Ergo 96 Oragono→Ergo).
- **MULTI-LAYER HERITAGE**: Ergonomadic → Oragono → Ergo (2 renames). Each layer brought new maintainer + scope. Recipe convention: complex fork-lineage deserves a history note.
- **TRANSPARENT-MAINTENANCE**: MIT + 8+ years + semver + specs-driven + Crowdin translations + active + test-net + testnet.ergo.chat live. **30th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: ergochat org + long-term contributor community. **25th tool in institutional-stewardship family — transitional-from-sole-maintainer-to-team sub-tier** (reinforces Kometa 95, Dispatcharr 96).
- **SOLE-MAINTAINER-with-community: 15 tools** (slingamn primary + community).
- **MIT LICENSE**: permissive.
- **IRC vs MATRIX — THE FEDERATION DEBATE**:
  - **IRC**: server-local communities + bouncer-integrated clients + old-but-battle-tested
  - **Matrix**: federated + E2E-encrypted + modern + higher-overhead
  - **Both have niches**: IRC for "lightweight technical community", Matrix for "E2E-federated modern chat"
- **MANY DISTRO PACKAGES** (AUR, Gentoo) — signal of mature project + community care.
- **ALTERNATIVES WORTH KNOWING:**
  - **Traditional IRCds**: InspIRCd, UnrealIRCd, Charybdis, Solanum, Plexus, Hybrid — mature + older + typically need separate services (Atheme, Anope) + separate bouncers (ZNC, SoJu)
  - **Matrix servers**: Synapse, Dendrite, Conduit — different protocol + federated + modern
  - **XMPP servers**: Prosody, ejabberd, Openfire (pair with Converse 96)
  - **Discord / Slack / Rocket.Chat / Mattermost** — centralized commercial or commercial-OSS team chat
  - **Zulip** — threaded topic-based chat
  - **Choose Ergo if:** you want simple + modern + integrated (IRCd+services+bouncer) + IRCv3 + MIT + Go.
  - **Choose traditional IRCd + Atheme + ZNC if:** you want the legacy power-stack.
  - **Choose Matrix if:** you want federation + E2E + modern.
  - **Choose XMPP if:** you want federation + XEPs + OMEMO.
- **PROJECT HEALTH**: mature + MIT + active + testnet + specs-driven + translations + LDAP + distro packages. Strong healthy signals.

## Links

- Repo: <https://github.com/ergochat/ergo>
- Homepage: <https://ergo.chat>
- User guide: <https://github.com/ergochat/ergo/blob/stable/docs/USERGUIDE.md>
- Manual: <https://github.com/ergochat/ergo/blob/stable/docs/MANUAL.md>
- Specs: <https://ergo.chat/specs.html>
- Docker: <https://ghcr.io/ergochat/ergo>
- Testnet: <https://testnet.ergo.chat>
- LDAP: <https://github.com/ergochat/ergo-ldap>
- Crowdin: <https://crowdin.com/project/ergochat>
- Ergonomadic (ancestor): <https://github.com/jlatt/ergonomadic>
- Atheme (services, if paired with traditional IRCd): <https://github.com/atheme/atheme>
- Solanum (modern IRCd alt): <https://github.com/solanum-ircd/solanum>
- InspIRCd (traditional): <https://www.inspircd.org>
- Libera.Chat (largest IRC network, uses Solanum): <https://libera.chat>
- Matrix (alt protocol): <https://matrix.org>
