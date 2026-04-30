---
name: MicroBin
description: "Tiny self-hosted pastebin + file-share + URL-shortener written in Rust. Single-binary, E2E encryption (server + client side), QR codes, animal-name IDs, SQLite or JSON storage. BSD-3-Clause."
---

# MicroBin

MicroBin is **"the minimalist pastebin that also does files + redirects"** — a tiny, single-binary self-hosted paste service written in Rust. It's small (a few MB RAM + disk), easy to deploy (one binary + env file), and packs more features than you'd expect at its size: **text pastes + file uploads + URL redirects + server-side + client-side E2E encryption + QR codes + animal-name IDs (pig-dog-cat instead of opaque hashes) + expiring + editable pastes + SQLite + JSON storage backends + admin UI**.

Built + maintained by **Daniel Szabo (szabodanika)**, Hungary-based. Open-source BSD-3-Clause; hosted service at **my.microbin.eu** for people who want to pay for managed hosting.

Use cases: (a) sharing code/logs/configs between machines (b) sending large files to friends (c) URL shortener for your domain (d) "postbox" for accepting uploads from others (e) simple quick notes (f) serving test configs + raw content.

Features:

- **Single binary** — Cargo install or Docker
- **Server-side + client-side E2E encryption** — paste encrypted before upload in browser
- **File uploads** — no artificial size limits
- **Raw text serving** — `/raw/...` for scripts + curl-pipe patterns
- **QR code generation** for mobile sharing
- **URL shortening + redirection**
- **Animal-name IDs** — memorable, typeable (64-word pool)
- **Multiple attachments**
- **SQLite OR JSON** storage
- **Private / public** uploads
- **Editable / uneditable** uploads
- **Automatic expiring + never-expiring**
- **Dark mode + light mode auto**
- **Vanilla JS + minimal CSS** — fast + auditable frontend
- **water.css** styling

- Upstream repo: <https://github.com/szabodanika/microbin>
- Homepage + docs: <https://microbin.eu>
- Docs: <https://microbin.eu/docs/intro>
- Public test instance: <https://pub.microbin.eu>
- Paid hosted: <https://my.microbin.eu>
- Docker Hub: <https://hub.docker.com/r/danielszabo99/microbin>
- crates.io: <https://crates.io/crates/microbin>
- Roadmap: <https://microbin.eu/roadmap>

## Architecture in one minute

- **Rust** + **Actix-Web** server
- **SQLite** or **JSON flat-file** storage
- **Tiny** — few-MB RAM, tens-of-MB disk
- **Single binary** — no runtime deps beyond the OS
- **Config via env vars** — full list on microbin.eu/docs

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | `danielszabo99/microbin`                                   | **Upstream-primary**                                                               |
| Cargo              | `cargo install microbin`                                                   | Rust-native                                                                                |
| Raspberry Pi       | ARM images available                                                                | Perfect for tiny SBCs                                                                                  |
| Bare-metal         | Download binary + systemd unit                                                                      | Minimal                                                                                                |

## Inputs to collect

| Input                    | Example                                                   | Phase        | Notes                                                                    |
| ------------------------ | --------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain                   | `paste.example.com`                                            | URL          | TLS via reverse proxy                                                                                        |
| `MICROBIN_PORT`          | `8080`                                                                 | Network      | Behind reverse proxy                                                                                    |
| `MICROBIN_AUTH_BASIC_USERNAME` + `_PASSWORD` | optional BasicAuth gate                                   | Access       | Protects whole instance                                                                                             |
| `MICROBIN_ADMIN_USERNAME` + `_PASSWORD`                        | admin panel creds                                                                | Bootstrap    | Set BEFORE exposing                                                                                                              |
| `MICROBIN_DATA_DIR`      | `/data`                                                                                               | Storage      | Volume-mount for persistence                                                                                                                |
| Storage choice           | SQLite (default) OR `MICROBIN_JSON_DB=true`                                                                                       | Storage      | JSON = simpler migrations; SQLite = better for many pastes                                                                                                                |
| `MICROBIN_HASH_IDS=true` | opaque IDs vs animal names                                                                                       | UX           | Trade memorability for obscurity                                                                                                                               |
| Disable features         | `MICROBIN_PURE_HTML=true`, `MICROBIN_NO_ENCRYPTION=true`, etc.                                                                                | Feature flags | Harden attack surface if unused                                                                                                                                |

## Install via Docker

```yaml
services:
  microbin:
    image: danielszabo99/microbin:2                  # pin version
    restart: always
    ports: ["8080:8080"]
    volumes:
      - ./microbin-data:/data
    environment:
      MICROBIN_ADMIN_USERNAME: admin
      MICROBIN_ADMIN_PASSWORD: ${ADMIN_PASSWORD}
      MICROBIN_PUBLIC_PATH: https://paste.example.com
      MICROBIN_DATA_DIR: /data
```

Or via the upstream one-liner:
```sh
bash <(curl -s https://microbin.eu/docker.sh)
```

## First boot

1. Deploy with admin credentials set
2. Browse + login to admin
3. Create a test paste → verify `/p/pig-dog-cat` works
4. Try `/raw/pig-dog-cat` for raw text endpoint
5. Try upload → verify file persists
6. Put behind TLS + decide whether to enable basic auth (private instance)
7. Back up `/data` directory
8. Review feature env vars — disable unused features to shrink attack surface (`MICROBIN_NO_FILE_UPLOAD=true`, etc.)

## Data & config layout

- `/data/` — SQLite DB OR JSON file + uploaded files
- Env vars — all config
- Logs to stdout

## Backup

```sh
sudo tar czf microbin-$(date +%F).tgz microbin-data/
```

## Upgrade

1. Releases: <https://github.com/szabodanika/microbin/releases>. Active.
2. Docker: bump tag; restart.
3. **SQLite migrations**: run automatically; always back up first.
4. Read changelog for env-var renames (some happen during 1.x→2.x).

## Gotchas

- **Public instances = abuse magnets.** Open pastebins are used for: malware hosting, phishing lure pages, stolen-credential dumps, CSAM, warez. If you run a public instance expect abuse reports + law-enforcement requests. **Default stance: private instance + basic-auth OR `MICROBIN_READONLY=true`**. If going public, read microbin.eu on moderation + implement `MICROBIN_LIST_SERVER` + report workflow.
- **URL shortener = phishing vector.** Any URL-shortener hosted on your domain can be used in phishing emails ("paste.example.com/xyz" looks legit). Default stance: disable URL redirect feature unless needed (`MICROBIN_NO_URL_REDIRECTION=true`).
- **File upload = unbounded disk growth.** MicroBin doesn't artificially limit file sizes by default. Large uploads + forgotten expiries = disk full. Set `MICROBIN_DEFAULT_EXPIRY=24hour` + `MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB=10` + `MICROBIN_MAX_FILE_SIZE_ENCRYPTED_MB=10` explicitly. Monitor disk.
- **E2E encryption caveat**: client-side encryption means the server literally cannot read the paste. Also means: **if user loses the key, content is gone forever.** Feature + footgun. Document this for users.
- **Admin credentials in env vars** → visible in `docker inspect` to anyone on the host. Standard container-secrets concern. Use Docker secrets or mount a file for truly sensitive deployments.
- **SQLite on slow storage** (SD card) — writes can be slow. For Pi SBC use, prefer SSD/USB-SSD.
- **Hash IDs vs animal names tradeoff**: animal names are memorable + shareable verbally ("it's pig-dog-cat") but are also guessable (64³ = 262K permutations → brute-forceable for PUBLIC pastes). For private data, use `MICROBIN_HASH_IDS=true` to get opaque IDs + rate-limit.
- **`MICROBIN_PURE_HTML`** disables JavaScript → pastes editable without JS. Use this for max-paranoia audiences + to demonstrate the minimal frontend.
- **No built-in HTTPS** — put behind Caddy/Traefik/nginx for TLS. Common self-host pattern.
- **Rate limiting** is NOT built-in — do it at the reverse proxy layer if you expose publicly. Otherwise a single script can DoS with a flood of pastes.
- **Data export**: JSON backend = human-readable dump; SQLite = standard tools. Low lock-in.
- **`MICROBIN_QR=true`** generates QR codes for each paste URL — fantastic UX for "this is the wifi password" kiosk setups.
- **"Postbox mode"** (`MICROBIN_READONLY=false, MICROBIN_PUBLIC_PATH=https://post.example.com, MICROBIN_HIDE_LOGO=true`) — let people upload but not see others' uploads. Clever pattern for "send me your secret document" workflows.
- **License**: **BSD-3-Clause** (permissive) — maximally liberal.
- **Project health**: Daniel Szabo solo + hosted-service revenue + donations. Bus-factor-1, but: (a) single-binary Rust = trivially runnable indefinitely from last release (b) tiny codebase = forkable (c) permissive license.
- **Ethical purchase**: my.microbin.eu managed hosting = fund upstream. Same pattern as Papra, MiroTalk, Write.as, rallly.co, etc.
- **Alternatives worth knowing:**
  - **PrivateBin** — PHP; mature; E2E encryption first-class; larger community
  - **Hastebin** — JS/Node; tiny; classic
  - **Opengist** — gist-like snippets; Go
  - **Linx** / **Linx-server** — file-sharing focused; Go
  - **Wastebin** — Rust; very small; modern
  - **Pastee** / **Rentry** / **Termbin** — SaaS alternatives
  - **Choose MicroBin if:** Rust single-binary + file upload + URL shortener + admin UI + animal names.
  - **Choose PrivateBin if:** E2E encryption priority + PHP stack fine + larger community.
  - **Choose Wastebin if:** even-simpler minimalism in Rust.

## Links

- Repo: <https://github.com/szabodanika/microbin>
- Homepage + docs: <https://microbin.eu>
- Docs: <https://microbin.eu/docs/intro>
- Screenshots: <https://microbin.eu/screenshots/>
- Roadmap: <https://microbin.eu/roadmap>
- Public test: <https://pub.microbin.eu>
- Hosted: <https://my.microbin.eu>
- Docker Hub: <https://hub.docker.com/r/danielszabo99/microbin>
- crates.io: <https://crates.io/crates/microbin>
- Releases: <https://github.com/szabodanika/microbin/releases>
- PrivateBin (alt): <https://privatebin.info>
- Opengist (alt): <https://github.com/thomiceli/opengist>
- Wastebin (alt): <https://github.com/matze/wastebin>
- Hastebin (alt): <https://github.com/toptal/haste-server>
