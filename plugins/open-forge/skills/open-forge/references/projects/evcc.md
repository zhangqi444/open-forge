---
name: evcc
description: "Extensible EV charge controller and energy management system — optimizes home EV charging around solar production, grid tariffs, battery state. Talks to 200+ wallboxes, inverters, meters, vehicles. Prioritizes self-generated PV + cheap-grid-hour charging. Active German OSS. MIT."
---

# evcc

**evcc** (Electric Vehicle Charge Controller) is **the definitive self-hosted home EV charge management system**. If you have solar panels + a home battery + an EV wallbox, evcc orchestrates them: charge the car primarily from your PV surplus, fall back to cheap grid hours, respect your home battery's needs, and give you a beautiful dashboard + mobile-friendly UI.

Extremely popular in **Germany / DACH** solar homes — active development by the same community that drives SMA/Fronius/Kostal/etc. solar ecosystems.

Features:

- **PV-optimized charging** — charge from solar surplus first (excess after house load + battery)
- **Time-of-use tariffs** — cheap-hour charging against dynamic electricity prices (Tibber, aWATTar, Octopus Agile, Nordpool, EPEX Spot)
- **Min/max charging** — e.g., "always ≥50% SoC by 07:00" combined with PV optimization
- **Battery care** — respect home battery state (don't steal from battery when grid is cheaper)
- **Planning** — schedule charging for specific times (grid peak shaving)
- **Multi-vehicle / multi-charger** — supports fleets
- **200+ devices** — wallboxes (KEBA, go-e, ABL, Wallbe, easee, openWB, Alfen, Mennekes, Zaptec, etc.), inverters (SMA, Fronius, Kostal, SolarEdge, Huawei, Solax, Growatt, etc.), meters (Tibber Pulse, Shelly, Modbus/SDM), vehicles (Tesla, VW/Audi/Skoda/SEAT via Cupra API, BMW, Mercedes, Polestar, Volvo, Renault, Peugeot, Hyundai/Kia, Nissan, Ford, Porsche, Fiat, Smart, Dacia, etc.)
- **REST API** + MQTT + WebSocket
- **Home Assistant integration** (MQTT-based, native)
- **Mobile-friendly UI** (no app yet, but PWA)
- **Smart meter + grid-feed-in visualization**
- **Sponsor model** — some cloud-based features (vehicle APIs, some tariffs) require sponsor token (free for personal; donate to upstream)

- Upstream repo: <https://github.com/evcc-io/evcc>
- Website / docs: <https://evcc.io>
- Documentation (EN/DE): <https://docs.evcc.io>
- Discussions / support: <https://github.com/evcc-io/evcc/discussions>
- Templates: <https://github.com/evcc-io/evcc/tree/master/templates>
- Sponsor: <https://github.com/sponsors/andig>

## Architecture in one minute

- **Single Go binary**; very low resource (Raspberry Pi 3+ works)
- **Config**: single YAML file (`evcc.yaml`)
- **Internal DB**: SQLite (session history, settings)
- **Talks to devices** via Modbus TCP/RTU, HTTP REST, MQTT, OCPP, vendor-specific APIs
- **Web UI** served by binary (port 7070 default)

## Compatible install methods

| Infra              | Runtime                                            | Notes                                                                       |
| ------------------ | -------------------------------------------------- | --------------------------------------------------------------------------- |
| Single device      | **Native binary / distro package** (`.deb` for Debian/Ubuntu/RPi) | **Upstream-recommended** — most support threads assume this                     |
| Single device      | **Docker (`evcc/evcc`)**                                        | Works; some use cases (Modbus RTU on serial port) simpler native             |
| Raspberry Pi       | **arm64 .deb**                                                          | Extremely common deployment — Pi in the basement next to the inverter                   |
| Home Assistant OS  | HACS add-on (community)                                                        | Option if HA is already central                                                                  |
| Kubernetes         | Possible but atypical                                                                            | Not the target use case                                                                                     |

## Inputs to collect

| Input                  | Example                             | Phase     | Notes                                                                        |
| ---------------------- | ----------------------------------- | --------- | ---------------------------------------------------------------------------- |
| Grid meter             | Modbus address / Shelly URL / Tibber Pulse          | Energy    | **Required** — evcc needs to know current house + grid draw                      |
| PV inverter            | SMA/Fronius/etc.                                         | Energy    | For PV-surplus charging                                                                    |
| Home battery (opt)     | BYD/LG/PowerWall/etc.                                             | Energy    | Optional; battery-aware priority                                                                      |
| Wallbox                | KEBA/go-e/etc.                                                              | Charger   | Must support modulation / OCPP / vendor API                                                                     |
| Vehicle API (opt)      | Tesla, VW-ID, BMW                                                                | Vehicle   | SoC / departure / target; some require sponsor token                                                                         |
| Tariff provider (opt)  | Tibber / Awattar / Octopus                                                                | Pricing   | For dynamic pricing modes                                                                                                     |
| Port / host            | `0.0.0.0:7070`                                                                                        | Network   | Expose on LAN                                                                                                                      |
| Auth                   | admin password                                                                                                 | Security  | Required on recent versions                                                                                                                 |
| Home Assistant MQTT    | broker creds                                                                                                            | Integration  | Optional                                                                                                                                         |

## Install on Debian/Ubuntu/RPi

```sh
# Official apt repo
curl -fsS https://dl.evcc.io/public/evcc-io/gpg.0744755C.key | sudo apt-key add -
sudo apt-add-repository "deb https://dl.evcc.io/public/evcc-stable/deb/debian $(lsb_release -cs) main"
sudo apt update
sudo apt install -y evcc

# Interactive setup
sudo evcc configure
# → guided wizard probing devices, writing /etc/evcc.yaml

sudo systemctl start evcc
sudo systemctl enable evcc
```

Browse `http://<host>:7070`.

## Install via Docker

```yaml
services:
  evcc:
    image: evcc/evcc:latest                       # pin in prod
    container_name: evcc
    restart: unless-stopped
    ports:
      - "7070:7070"
    volumes:
      - ./evcc.yaml:/etc/evcc.yaml:ro
      - ./data:/root/.evcc                         # SQLite history
    # For Modbus RTU on USB/serial:
    # devices:
    #   - /dev/ttyUSB0:/dev/ttyUSB0
    network_mode: host                             # simplest for mDNS device discovery
```

## First boot

1. Run `evcc configure` (or edit YAML from templates) → detect your wallbox + inverter + meter
2. Browse UI → set a loadpoint per car (vehicle + charger) → choose default mode (**PV**, **Min+PV**, **Now**, **Off**)
3. Plug in car → evcc modulates charging current to match PV surplus
4. Check dashboard: house load / grid / PV / battery / car arrows animate
5. Try "Plan" — schedule "80% by 07:00"
6. Configure MQTT to surface to Home Assistant

## Data & config layout

- `/etc/evcc.yaml` — main config (site + meters + chargers + vehicles + loadpoints)
- `/var/lib/evcc/` or `~/.evcc/` — SQLite (charging session history)
- Logs: systemd journal

## Backup

```sh
sudo tar czf evcc-$(date +%F).tgz /etc/evcc.yaml /var/lib/evcc/
```

## Upgrade

1. Releases: <https://github.com/evcc-io/evcc/releases>. **Very active** — weekly-ish releases.
2. `apt upgrade evcc` → `systemctl restart evcc` (zero-downtime not guaranteed; seconds-scale blip)
3. Read CHANGELOG — YAML schema changes happen during 0.x → 0.x+1 minor jumps.
4. Docker: bump tag; `docker compose up -d`.

## Gotchas

- **evcc requires a grid meter reading.** If you can't read your house/grid load, evcc can't do PV-surplus charging properly. Shelly 3EM, Tibber Pulse, Modbus SDM, or smart meter via P1 cable are common paths.
- **Device support is broad but not universal.** Check the compatibility list (<https://github.com/evcc-io/evcc/wiki/Hardware>) before buying a wallbox. Some "smart" wallboxes don't expose modulation → unsupported.
- **Wallbox must support current modulation** — fixed 16A wallboxes can't do PV-surplus charging. Look for "dynamic current adjustment" or "Modbus/OCPP/REST control."
- **3-phase switching** — some wallboxes support auto-switch 1↔3 phase (useful for low-PV scenarios). evcc supports it if the wallbox does.
- **Vehicle SoC** — not strictly required, but dramatically improves planning. Vehicle APIs vary in reliability; Tesla is best; some require sponsor token for commercial cloud integrations.
- **Sponsor token**: some features (especially vehicle APIs that proxy manufacturer clouds) are behind a sponsor token. Free for personal use; support upstream.
- **Home battery arbitration**: order-of-operations matters. Configure `batteryBoost` / `batteryGridChargeLimit` carefully, or the car + battery will fight over surplus.
- **Dynamic tariffs** — Tibber/Awattar API keys required; evcc pulls hourly prices; planning mode uses them.
- **Modbus RTU on USB serial** — requires Docker `--device` pass-through or native install; permissions must allow user `evcc` to access `/dev/ttyUSB0`.
- **mDNS device discovery** — native install finds devices automatically; Docker needs `network_mode: host` or configured hostnames.
- **Live UI lag**: some telemetry comes via polling; expect 1-5s update latency — not milliseconds.
- **Community is German-first**. UI fully localized (DE/EN/FR/ES/IT/NL/etc.) but discussion/support often DE. Forums welcoming; English works.
- **Safety**: evcc commands physical high-current charging. Test in low-current modes first. Always have the wallbox's own safety (RCD + contactor) intact.
- **OCPP (Open Charge Point Protocol)** — evcc is an OCPP 1.6 client; can talk to OCPP-compliant wallboxes + can serve as OCPP server for CSMS integration.
- **Home Assistant**: MQTT integration is clean; evcc publishes status → HA picks up sensors automatically.
- **Mobile app**: no native app; PWA works well; iOS "Add to Home Screen" gives fullscreen.
- **License**: **MIT**. 
- **Commercial option**: no SaaS; sponsor-based funding.
- **Alternatives worth knowing:**
  - **openWB** — another German EV charger OSS (Python); for openWB hardware specifically
  - **EMS (Energy Management Systems)** — commercial turnkey from wallbox vendors (KEBA EMS, go-eCharger app)
  - **Home Assistant energy dashboard + custom automations** — DIY route
  - **Tesla app + scheduled charging** — vendor-specific
  - **SolarEdge EV charger** + SolarEdge's own app
  - **Loxone / KNX-based systems** — professional home automation
  - **Wallbox Pulsar Plus app** — vendor-specific
  - **Choose evcc if:** you have solar + EV + any non-trivial wallbox/inverter combo and want sophisticated PV-optimized charging with dynamic tariffs.
  - **Choose vendor apps if:** single-vendor ecosystem and you don't care about optimization depth.
  - **Choose Home Assistant DIY if:** you want to build everything yourself.

## Links

- Repo: <https://github.com/evcc-io/evcc>
- Website: <https://evcc.io>
- Docs (EN): <https://docs.evcc.io/en/docs/quickstart>
- Docs (DE): <https://docs.evcc.io/docs/quickstart>
- Compatibility list: <https://github.com/evcc-io/evcc/wiki/Hardware>
- Templates: <https://github.com/evcc-io/evcc/tree/master/templates>
- Discussions: <https://github.com/evcc-io/evcc/discussions>
- Releases: <https://github.com/evcc-io/evcc/releases>
- Docker Hub: <https://hub.docker.com/r/evcc/evcc>
- Home Assistant integration: <https://docs.evcc.io/docs/integrations/home-assistant>
- Sponsor: <https://github.com/sponsors/andig>
- Discord: <https://discord.gg/6MrvYeHPb8>
- openWB (alt): <https://github.com/snaptec/openWB>
- Tibber (tariff provider): <https://tibber.com>
- Awattar (tariff provider): <https://www.awattar.de>
- Home Assistant: <https://www.home-assistant.io>
