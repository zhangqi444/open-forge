---
name: RetroAssembly
description: "Self-hosted retro game collection cabinet in your browser. Docker. React + Node.js. arianrhodsandlot/retroassembly. Play NES/SNES/Genesis/GameBoy/Arcade/30+ consoles via web browser, auto box art, save states, gamepad support, spatial navigation, retro shaders. MIT."
---

# RetroAssembly

**Your personal retro game collection cabinet — in the browser.** Self-hosted web app for playing retro games from NES, SNES, Genesis, GameBoy, Arcade, and 30+ other consoles. Auto-detects and displays beautiful box art for your collection. Save states, gamepad support, spatial navigation, retro-style shaders, and on-screen virtual controller for mobile. Powered by Nostalgist.js (libretro cores).

Built + maintained by **arianrhodsandlot**. Also available as a hosted service at [retroassembly.com](https://retroassembly.com). MIT license.

- Upstream repo: <https://github.com/arianrhodsandlot/retroassembly>
- Docker Hub: `arianrhodsandlot/retroassembly`
- Website: <https://retroassembly.com>
- Discord: <https://discord.gg/gwaKRAYG6t>

## Architecture in one minute

- **React + Node.js** web app
- Port **80** (Docker default)
- ROMs served from a mounted volume
- Emulation runs **in-browser** via Nostalgist.js (WebAssembly libretro cores) — the server just serves files
- Resource: **very low server-side** — static file serving; emulation is all client-side WASM

## Compatible install methods

| Infra      | Runtime                                  | Notes                                           |
| ---------- | ---------------------------------------- | ----------------------------------------------- |
| **Docker** | `arianrhodsandlot/retroassembly`         | **Primary** — single container                  |
| Hosted     | [retroassembly.com](https://retroassembly.com) | Managed option; connect your own storage   |

## Install via Docker

```yaml
services:
  retroassembly:
    image: arianrhodsandlot/retroassembly:latest
    container_name: retroassembly
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - /path/to/your/roms:/app/roms
```

> For the full quick-start and advanced configuration, see the [Docker Hub page](https://hub.docker.com/r/arianrhodsandlot/retroassembly).

```bash
docker compose up -d
```

Visit `http://localhost` → your game collection is displayed with box art.

## ROM organisation

RetroAssembly detects games by console folder structure. Organise your ROMs by system:

```
/path/to/roms/
├── nes/
├── snes/
├── genesis/
├── gb/
├── gba/
├── arcade/
└── ...
```

## Supported platforms (30+)

| Console family | Available emulators |
|----------------|---------------------|
| Arcade | `fbneo`, `mame2003_plus` |
| NES | `fceumm`, `nestopia` |
| SNES | `snes9x` |
| Sega Genesis / Mega Drive | `genesis_plus_gx` |
| Game Boy / GBC | `gambatte`, `mgba` |
| Game Boy Advance | `mgba` |
| Atari 2600 | `stella2014` |
| Atari 5200/7800 | `a5200`, `prosystem` |
| Atari Lynx | `mednafen_lynx` |
| Nintendo DS | `desmume`, `melonds` |
| Nintendo 64 | `mupen64plus_next` |
| PlayStation | `mednafen_psx`, `pcsx_rearmed` |
| PlayStation Portable | `ppsspp` |
| Sega Master System | `genesis_plus_gx` |
| Sega Game Gear | `genesis_plus_gx` |
| Sega Saturn | `mednafen_saturn` |
| Neo Geo | `fbneo` |
| PC Engine / TurboGrafx | `mednafen_pce` |
| MSX | `fmsx`, `bluemsx` |
| …and more | See upstream README for full list |

## Features overview

| Feature | Details |
|---------|---------|
| 30+ consoles | NES, SNES, Genesis, GBA, N64, PS1, PSP, Arcade, and more |
| Auto box art | Automatically detects and displays cover art |
| Save states | Save and resume gameplay at any point |
| Rewind | Some emulators support rewinding gameplay |
| Spatial navigation | Keyboard/gamepad navigation through library (no mouse needed) |
| Retro shaders | Visual effects for authentic retro look (CRT, scanlines, etc.) |
| Virtual controller | On-screen gamepad for mobile/touchscreen play |
| Physical gamepad | Full gamepad support |
| Client-side emulation | Emulation runs in-browser via WASM — server just serves files |
| Mobile-friendly | Responsive UI with touch support |

## Gotchas

- **You must provide your own ROMs.** RetroAssembly does not include or download ROMs. You need to legally obtain ROM files for your games and mount them.
- **Emulation is client-side.** The server does very little — it serves static files. All emulation happens in the user's browser via WebAssembly libretro cores. Server resources are minimal, but the client needs a capable browser.
- **ROMs mount path matters.** The volume must be mounted at the path the app expects. Check the Docker Hub quick-start for the current expected mount point.
- **MIT license.** Free to use, modify, redistribute.

## Backup

```sh
# ROMs are your primary asset — back up your ROM directory
# Save states are in browser localStorage (client-side) — not server-side
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active React/Node.js development, MIT license, hosted + self-hosted options.

## Retro-emulation-family comparison

- **RetroAssembly** — React/Node.js, web-based collection cabinet, 30+ consoles, box art, WASM emulation; MIT
- **EmulatorJS** — Pure web-based emulation, no server required, embed anywhere; MIT
- **RetroPie** — Raspberry Pi focused, EmulationStation frontend, many emulators; GPL-2.0
- **Batocera** — Linux distro, full game console OS, local HDMI output focused

**Choose RetroAssembly if:** you want a beautiful self-hosted web cabinet for your retro ROM collection with automatic box art, save states, and gamepad support — accessible from any browser on your network.

## Links

- Repo: <https://github.com/arianrhodsandlot/retroassembly>
- Docker Hub: <https://hub.docker.com/r/arianrhodsandlot/retroassembly>
- Website: <https://retroassembly.com>
- Discord: <https://discord.gg/gwaKRAYG6t>
