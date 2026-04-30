---
name: LinuxGSM
description: "CLI tool to install + manage 100+ Linux dedicated game servers — Minecraft, CS2, ARK, Valheim, Rust, Palworld, Factorio, etc. Bash scripts wrapping SteamCMD. Install, monitor, alert, update, backup, console. MIT."
---

# LinuxGSM

LinuxGSM is **the Bash-based standard for running Linux dedicated game servers** — one command installer + monitor + updater + backup for 100+ game servers. Started 2012; still the first thing experienced server admins reach for. Built + led by **Daniel Gibbs (dgibbs64)**; thriving community + long track record.

Use case: **"I want to host a Palworld/Minecraft/Valheim/Rust/CS2/ARK server for my friends and not become a sysadmin."**

Features (per upstream):

- **100+ games supported** — full list on <https://linuxgsm.com>
- **Installer** — one command sets up game + dependencies + SteamCMD
- **Monitor** — auto-restart crashed servers
- **Alerts** — Discord, Email, Pushbullet, etc. on events
- **Updater** — detect + install game updates via SteamCMD
- **Server Details** — connection info, ports, versions
- **Backup** — tar/compress game data
- **Console** — reattach to running game server

Compatibility (per upstream):

- Ubuntu, Debian, CentOS officially supported
- Other distros "likely to work" but untested

- Upstream repo: <https://github.com/GameServerManagers/LinuxGSM>
- Homepage: <https://linuxgsm.com>
- Docs: <https://docs.linuxgsm.com>
- Discord: <https://linuxgsm.com/discord>
- Sponsor: <https://github.com/sponsors/dgibbs64>
- Docker variants (community): <https://github.com/GameServerManagers/docker-gameserver>

## Architecture in one minute

- **Bash scripts** — the whole thing
- **SteamCMD** under the hood for Steam-distributed games (CS2, ARK, Valheim, Palworld, Rust, ...)
- **Non-Steam games** (Minecraft, Factorio) use their own installers wrapped in LinuxGSM
- **No daemon** — cron + tmux is the runtime. Monitor script checks server every N minutes.
- **Per-game user** — LinuxGSM convention: one OS user per game server (`csserver`, `mcserver`, etc.)
- **Resource**: depends entirely on game. Minecraft = 1-4 GB RAM; ARK = 8-12 GB; Palworld = 16+ GB for dedicated.

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Bash install on Ubuntu/Debian/CentOS**                           | **Upstream-primary**                                                               |
| VPS                | Same as above                                                              | Popular: Hetzner, OVH, Linode, Vultr                                                       |
| Docker             | **Community `GameServerManagers/docker-gameserver`**                                  | Separate repo; not primary                                                                                 |
| Kubernetes         | DIY                                                                                   | Unusual — game servers = stateful + port-sensitive                                                                                 |
| Dedicated hardware | Home server / colo                                                                                   | LAN/friends-group use                                                                                                                   |

## Inputs to collect

| Input                | Example                                                | Phase        | Notes                                                                    |
| -------------------- | ------------------------------------------------------ | ------------ | ------------------------------------------------------------------------ |
| Game server          | `csgoserver`, `pzserver`, `palserver`, `mcserver`, ...        | Install      | See full list at <https://linuxgsm.com/servers/>                                 |
| Host distro          | Ubuntu 22.04 recommended                                         | OS           | Debian + CentOS also officially supported                                                    |
| OS user              | one per server (`gameserver` convention)                           | User         | **Never run as root** — LinuxGSM explicitly refuses                                                     |
| Ports                | Game-specific; UDP + TCP                                                 | Network      | Open in firewall; consider DDoS protection                                                                  |
| RAM / CPU            | Game-specific                                                                | Hardware     | See per-game docs on <https://docs.linuxgsm.com>                                                                      |
| Alerts (opt)         | Discord webhook, email, etc.                                                           | Monitoring   | Configured in `_default.cfg` or per-instance                                                                                              |

## Install

Upstream's canonical install flow (example: Counter-Strike 2 server):

```sh
# As a dedicated non-root user:
sudo useradd -m csgoserver
sudo -u csgoserver -i bash
# inside csgoserver's shell:
wget -O linuxgsm.sh https://linuxgsm.sh && chmod +x linuxgsm.sh && bash linuxgsm.sh csgoserver
./csgoserver install
./csgoserver start
./csgoserver monitor             # set this in cron
./csgoserver details             # show connection info
```

Each game has a distinct `<game>server` script. Example scripts: `mcserver` (Minecraft), `valheimserver`, `palserver`, `rustserver`, `factorioserver`.

## First boot

1. Install per-game: `./gameserver install`
2. Review config in `lgsm/config-lgsm/<gameserver>/_default.cfg` (DO NOT EDIT — copy to `<gameserver>.cfg` + edit there)
3. Start: `./gameserver start`
4. Attach console: `./gameserver console` (detach: `Ctrl+A` then `D` — it's tmux)
5. Install cron monitor:
   ```
   */5 * * * * /home/csgoserver/csgoserver monitor > /dev/null 2>&1
   0 * * * * /home/csgoserver/csgoserver update > /dev/null 2>&1
   30 5 * * * /home/csgoserver/csgoserver update-lgsm > /dev/null 2>&1
   0 0 * * 0 /home/csgoserver/csgoserver backup > /dev/null 2>&1
   ```
6. Configure alerts: Discord webhook / email in config
7. Open firewall ports (game-specific)
8. Test from friend's machine

## Data & config layout (per game server)

- `~/<gameserver>` — main CLI script
- `~/lgsm/` — LinuxGSM internals (config, modules, logs, functions)
- `~/lgsm/config-lgsm/<gameserver>/_default.cfg` — upstream defaults (don't edit)
- `~/lgsm/config-lgsm/<gameserver>/<gameserver>.cfg` — YOUR overrides
- `~/lgsm/config-lgsm/<gameserver>/common.cfg` — shared across instances on same user
- `~/serverfiles/` — game files (via SteamCMD)
- `~/log/` — logs
- `~/backups/` — generated by `<gameserver> backup`

## Backup

```sh
# LinuxGSM's built-in:
./gameserver backup                       # creates tar in ~/backups/
# Restore: extract the tar over ~/serverfiles/ (game-specific procedure)
```

Or rsync `~/serverfiles/` + `~/lgsm/config-lgsm/` to external storage.

## Upgrade

### Game updates
```sh
./gameserver update            # SteamCMD checks + installs new game version
```
Schedule hourly in cron.

### LinuxGSM itself
```sh
./gameserver update-lgsm       # updates the LGSM scripts
```
Schedule weekly.

### OS updates
Standard: `unattended-upgrades` on Ubuntu/Debian. Reboot window off-peak.

## Gotchas

- **Don't run LinuxGSM as root.** Scripts refuse. Convention = one dedicated user per game. Treat gameservers as compromise-vulnerable (large C++ codebases, network-exposed, plugin ecosystems).
- **Game servers are HIGH-vulnerability surface.** Minecraft (Log4Shell), CS2 RCE history, ARK has had RCEs. Mitigations:
  - Run as non-root in isolated user (LinuxGSM enforces)
  - Restrict user filesystem + capabilities (systemd unit with `ProtectSystem=strict`)
  - Keep game + LGSM updated (cron)
  - Firewall to only needed ports
  - DDoS protection in front (Cloudflare Spectrum / OVH GAME / specialized game DDoS)
- **DDoS is real.** Game servers get DDoSed routinely. Home IP = especially bad idea. VPS with DDoS protection minimum; dedicated game-host providers ideal.
- **Port UDP vs TCP game-specific.** Don't open all — one UDP port for game + one TCP for query/RCON typical. Close admin ports to internet (RCON password-bruteforced in seconds).
- **Steam guard / Steam credentials**: some games require a Steam account with access. Anonymous SteamCMD works for many (CS2, ARK). Others (Palworld, DayZ) may need auth. LinuxGSM supports both.
- **Mods = untrusted code**. Running modded Minecraft / Garry's Mod / etc. = running arbitrary Java/Lua on YOUR server. Audit mod sources.
- **`_default.cfg` vs `<gameserver>.cfg`**: edit the SECOND ONE. Upstream overwrites `_default.cfg` on LGSM updates.
- **tmux not screen**: LinuxGSM uses tmux; `./gameserver console` then `Ctrl+A D` to detach (like screen). Don't `Ctrl+C` or you'll kill the server.
- **Backups before major updates**: some game patches break save compatibility. Minecraft world-format changes can nuke multiplayer worlds. Always `./gameserver backup` before `./gameserver update` on production/community servers.
- **Server lifecycle**: game servers = people's social connective tissue. Communicate maintenance windows. Unexpected downtime = community churn.
- **Monetization rules**: most game EULAs forbid monetizing servers without license (Mojang commercial server rules are infamous). Donation-only typically OK; paywalls/P2W usually not. You take the EULA risk.
- **Licensing**: LinuxGSM is **MIT**. Individual games have their own EULAs (almost always non-commercial for self-hosting).
- **Project health**: Daniel Gibbs has run this since 2012; large contributor base; sustained cadence. Not bus-factor-1.
- **Docker variants exist** (separate repo `docker-gameserver`) but upstream primary mode = bare Linux install. Docker convenient for dev/test; bare install often preferred in production for performance.
- **Alternatives worth knowing:**
  - **Pterodactyl Panel** — full web UI for managing multiple game servers (heavier, feature-rich)
  - **AMP (Application Management Panel)** — commercial panel (CubeCoders); polished
  - **Docker game-server images** (community) — simpler Dockerized game servers
  - **Crafty Controller** — Minecraft-specific web UI
  - **Choose LinuxGSM if:** CLI-first, minimal infrastructure, standard VPS/VM, SSH admin.
  - **Choose Pterodactyl if:** multi-user / multi-game hosting biz; rich web UI.
  - **Choose Crafty Controller if:** Minecraft-only and want a web dashboard.

## Links

- Repo: <https://github.com/GameServerManagers/LinuxGSM>
- Homepage (install commands per game): <https://linuxgsm.com>
- Docs: <https://docs.linuxgsm.com>
- Game servers list: <https://linuxgsm.com/servers/>
- Discord: <https://linuxgsm.com/discord>
- Sponsor: <https://github.com/sponsors/dgibbs64>
- Docker variants: <https://github.com/GameServerManagers/docker-gameserver>
- Pterodactyl (alt, web panel): <https://pterodactyl.io>
- Crafty Controller (alt, Minecraft): <https://craftycontrol.com>
- AMP (alt, commercial): <https://cubecoders.com/AMP>
