---
name: iSponsorBlockTV
description: "Self-hosted app that connects to your YouTube TV app on smart TVs / consoles / streamers and auto-skips sponsor segments + mutes ads — uses SponsorBlock community database. Works with Apple TV, Samsung, LG, Android TV, Chromecast, Roku, Fire TV, Switch, Xbox, PlayStation. Python. GPL-3.0."
---

# iSponsorBlockTV

iSponsorBlockTV is **self-hosted YouTube ad/sponsor-skipping for your TV** — bridges the gap between SponsorBlock (widely deployed as a browser extension on desktop) and TV-based YouTube apps where there's no extension model. Runs on any always-on machine in your network (Pi, NAS, homelab VM, Docker on laptop); pairs with your smart-TV / console YouTube app via YouTube's TV-remote-control protocol (used by the iOS/Android YouTube apps to act as remotes); uses the community-maintained **SponsorBlock API** to auto-skip sponsor + intro segments; auto-mutes ads and auto-clicks "Skip Ad" when available.

Created + maintained by **dmunozv04 (Daniel Muñoz)**. Mature + stable; Python-based.

> **⚠️ Upstream warning (active):**
>
> *"YouTube appears to have changed the screen ID code format and is in the process of revoking all existing codes. This means that you'll have to pair your device again."*
>
> This is the recurring pattern for iSponsorBlockTV: YouTube periodically changes pairing protocols, forcing re-pair. When you adopt this tool, subscribe to the repo to catch breakage announcements.

Features:

- **Auto-skip segments** — sponsors, intros, outros, self-promotion, filler tangents, interaction reminders (configurable per category)
- **Auto-mute ads** — during unskippable pre-roll/mid-roll
- **Auto-click "Skip Ad"** — when the button becomes available
- **Wide device compatibility** — Apple TV, Samsung Tizen, LG WebOS, Android TV, Chromecast, Google TV, Roku, Fire TV, Nintendo Switch, Xbox One/Series, PlayStation 4/5
- **Auto-discovery** (SSDP) — find TV devices on same network during setup
- **Manual pairing** — via YouTube TV code (shown in TV's YouTube settings) — doesn't require same network after pairing
- **Docker + native Python** deployment
- **Textual-based TUI configurator** — modern terminal UI for settings

- Upstream repo: <https://github.com/dmunozv04/iSponsorBlockTV>
- Installation Wiki: <https://github.com/dmunozv04/iSponsorBlockTV/wiki/Installation>
- Docker images: <https://ghcr.io/dmunozv04/isponsorblocktv>
- Docker Hub: <https://hub.docker.com/r/dmunozv04/isponsorblocktv>
- SponsorBlock project: <https://sponsor.ajay.app>

## Architecture in one minute

- **Python 3.x** app
- **Connects TO your TV** using YouTube's Lounge API (same protocol that YouTube mobile apps use to "cast" control)
- **Queries SponsorBlock API** for known segments on currently-playing video
- **Issues skip/mute commands** via Lounge API
- **No DB** — just config + device credentials
- **Resource**: tiny — ~50 MB RAM; near-zero CPU idle

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                         |
| ------------------ | -------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Raspberry Pi       | **Docker** — ideal always-on tiny box                              | **Most common deployment**                                                        |
| Single VM          | Docker                                                                     | Works                                                                                     |
| NAS                | Docker package                                                                         | Popular                                                                                                 |
| Bare Python        | `pip install` — works too                                                                            | For users avoiding Docker                                                                                                       |
| Home Assistant add-on | Community add-on available                                                                                       | Nice fit if on HA OS                                                                                                                        |
| Raspberry Pi Zero 2 W | Plenty powerful; perfect                                                                                                      | Low-power always-on                                                                                                                                     |

## Inputs to collect

| Input                   | Example                                   | Phase        | Notes                                                                     |
| ----------------------- | ----------------------------------------- | ------------ | ------------------------------------------------------------------------- |
| TV YouTube app          | YouTube app open on TV                            | Setup        | Needed for pairing                                                                |
| Device pairing code     | From TV YouTube → Settings → "Link with TV code"              | Setup        | OR auto-discover on same LAN                                                               |
| SponsorBlock categories | sponsor / intro / outro / selfpromo / ...                        | Policy       | Enable categories you want skipped                                                                                    |
| Network                 | during pairing: same LAN recommended                                             | Network      | After pairing, no longer required                                                                                                     |
| Container / Python runtime | Docker or `pip install iSponsorBlockTV`                                                     | Runtime      | Either                                                                                                                                   |

## Install via Docker

```yaml
services:
  isponsorblocktv:
    image: ghcr.io/dmunozv04/isponsorblocktv:latest       # pin in prod
    container_name: isponsorblocktv
    restart: unless-stopped
    network_mode: host                                        # recommended for SSDP discovery
    volumes:
      - ./config:/app/config
```

First-run config is interactive — the **Textual TUI** walks you through pairing:

```sh
docker run --rm -it --network=host -v ./config:/app/config \
  ghcr.io/dmunozv04/isponsorblocktv:latest add-device
```

Or edit `config.json` manually if you prefer.

## First boot

1. Open YouTube app on TV → `Settings → "Link with TV code"` → note the TV code (shown as `XXX XXX XXX`)
2. Run `add-device` CLI → enter code OR select auto-discovered device
3. Choose segment categories to skip (sponsor, intro, outro, selfpromo, music_offtopic, interaction, filler)
4. Choose ad-skip options (auto-mute, auto-skip)
5. Save config → start container with default command
6. Play a YouTube video on TV → observe auto-skips in logs
7. (Optional) Enable auto-start on device boot

## Data & config layout

- `/app/config/config.json` — all settings incl. device auth tokens
- **Tokens allow iSBTV to control your TV's YouTube app** — treat config as sensitive

## Backup

```sh
sudo tar czf isbtv-$(date +%F).tgz config/
```

Small; easy. If lost, re-pair device (trivial but requires TV-side action).

## Upgrade

1. Releases: <https://github.com/dmunozv04/iSponsorBlockTV/releases>. Active.
2. Docker: bump tag → restart.
3. **Pay attention to YouTube-API-change warnings** — occasional forced re-pair when YouTube changes protocols (see upstream warning above).
4. Watch repo + releases for breaking-protocol announcements.

## Gotchas

- **YouTube keeps changing the protocol.** This isn't iSBTV's fault — YouTube periodically breaks third-party control. **Subscribe to repo releases** to catch re-pair notices. Current warning (as of README snapshot) is about screen-ID code format change.
- **Pairing takes TV-side action each time** — not a once-and-done. Cross-reference <https://github.com/dmunozv04/iSponsorBlockTV/wiki> for current pairing instructions.
- **After pairing, same LAN isn't required** — iSBTV can live anywhere on the internet; it talks to youtube.com via YouTube's Lounge API. But during pairing setup with auto-discovery, same LAN makes it easier.
- **Host networking recommended** for SSDP auto-discovery (Docker bridge breaks mDNS/SSDP — same pattern as UpSnap/Scrypted from batches 70-71).
- **Multiple TVs**: one iSBTV instance can control many TVs. Add each via `add-device`.
- **Ad-skip legality**: YouTube's Terms of Service prohibit circumventing ads. iSBTV is widely used but officially against ToS. **Your account could theoretically be flagged** — rare in practice but understand the risk.
- **YouTube Premium solves ads** — if you'd rather pay YouTube and get the official no-ad experience (including on TV), that's the upstream-endorsed path. iSBTV is for users who want self-hosted ad/sponsor skipping without subscribing.
- **SponsorBlock is community-moderated** — segment quality depends on crowdsourced submissions. Occasional false positives (skip real content) or misses (don't skip sponsors). Configurable: "skip" vs "prompt" per category.
- **Shorts limitation**: documented in README — Shorts playback has quirks; workaround via long-press menu.
- **AirPlay audio**: Apple TV ad-mute doesn't work when audio is AirPlayed elsewhere. Documented limitation.
- **PlayStation / Xbox consoles**: fully supported, somewhat surprising given their closed ecosystems — uses the same TV Lounge protocol.
- **Privacy**: iSBTV reads what you're watching (video ID) to query SponsorBlock. Video IDs go to SponsorBlock API. SponsorBlock's privacy policy applies. Self-hosted iSBTV doesn't phone home otherwise.
- **Textual TUI**: the modern configurator is a nice touch — better than command-line flags for non-dev users.
- **Home Assistant integration**: community add-on available; fits well with HA's "hub for everything" model.
- **License**: **GPL-3.0**.
- **Not a replacement for**:
  - Ad-blocking DNS (Pi-hole / AdGuard Home) — works at DNS layer, can't skip already-loaded YouTube ads
  - Browser SponsorBlock extension — for desktop browser; iSBTV is for TV apps
  - YouTube Premium — official ad-free + offline + background playback
- **Alternatives worth knowing:**
  - **SponsorBlock browser extension** — desktop only
  - **ReVanced / YouTube Vanced (deprecated)** — modded Android YouTube app; Android devices only
  - **PipeTube / NewPipe / LibreTube / FreeTube** — alternative YouTube clients on their own devices
  - **Pi-hole + adblock lists** — blocks at DNS layer; YouTube ads often uncatchable this way
  - **YouTube Premium** — official paid no-ads
  - **Choose iSBTV if:** you want TV/console YouTube app ad+sponsor skipping + self-hosted + one-time-pair convenience.

## Links

- Repo: <https://github.com/dmunozv04/iSponsorBlockTV>
- Installation Wiki: <https://github.com/dmunozv04/iSponsorBlockTV/wiki/Installation>
- Docker (GHCR): <https://ghcr.io/dmunozv04/isponsorblocktv>
- Docker Hub: <https://hub.docker.com/r/dmunozv04/isponsorblocktv>
- Releases: <https://github.com/dmunozv04/iSponsorBlockTV/releases>
- SponsorBlock: <https://sponsor.ajay.app>
- YouTube Lounge API (background): <https://github.com/FabioGNR/pyytlounge>
- SponsorBlock browser extension: <https://sponsor.ajay.app/>
- Home Assistant add-on: search community add-ons
