---
name: magicpack-project
description: Web-based Wake-on-LAN tool for teams. Each user gets an individual link to power on their assigned computer. Upstream: https://github.com/alex-swki/magicpack
---

# MagicPack

Web-based Wake-on-LAN (WoL) tool designed for teams and companies. Deploy once; give each employee their own unique link to power on their assigned workstation remotely (e.g. via VPN before RDP). No login required per user — each computer gets a dedicated URL path. Upstream: <https://github.com/alex-swki/magicpack>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | [GitHub README](https://github.com/alex-swki/magicpack#deploy-magicpack-using-docker) | ✅ | Recommended |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| config | Public URL users will access MagicPack with | URL | All |
| config | Colour theme (LIGHT or DARK) | options | All |
| config | Company logo path and width | path + number | Optional |
| config | Custom page title and descriptions | string | Optional |

## Requirements

- Linux host (Docker `network_mode: host` is required to send magic packets on the LAN)
- Docker installed

## Docker Compose install

Source: <https://github.com/alex-swki/magicpack>

```yaml
version: "3.3"
services:
  magicpack:
    image: alexswki/magicpack
    network_mode: host
    restart: always
    container_name: magicpack
    volumes:
      - ./computers.json:/magicpack/computers.json
      - ./.env:/magicpack/.env.local
```

1. Clone the repository and `cd` into it.
2. Edit `.env` with your settings.
3. Edit `computers.json` with your computers list.
4. Run `docker compose up -d`.

## Configuration

### .env

| Variable | Description |
|---|---|
| `NEXT_PUBLIC_URL` | URL users visit (e.g. `http://localhost:3000`) |
| `NEXT_PUBLIC_COLOR_THEME` | `LIGHT` or `DARK` |
| `NEXT_PUBLIC_COMPANY_LOGO_PATH` | Path to logo inside `/magicpack-app/public/` |
| `NEXT_PUBLIC_COMPANY_LOGO_WIDTH` | Logo width in CSS pixels |
| `NEXT_PUBLIC_PAGE_TITLE` | Title text |
| `NEXT_PUBLIC_PAGE_DESC1` | First paragraph |
| `NEXT_PUBLIC_PAGE_DESC2` | Second paragraph |

### computers.json

```json
{
  "john-doe": {
    "name": "John Doe",
    "computer": {
      "location": "Main Office",
      "name": "XY-PC001",
      "mac": "A1:B2:C3:4D:5E:6F",
      "dns": "xy-pc001.example.com"
    }
  }
}
```

Each key (e.g. `john-doe`) becomes the URL path: `http://yourhost:3000/john-doe`.

`computers.json` can be edited live — no container restart needed.

## Upgrade procedure

```bash
docker compose pull
docker compose restart
```

After editing `.env`, use `docker compose restart` to apply changes.

## Gotchas

- **Requires `network_mode: host`** — magic packets must be sent from the Docker host's network. Does not work with bridge networking.
- MAC address format must be `A1:B2:C3:4D:5E:6F` (colon-separated).
- The DNS field is used for ping status checks, not for routing the WoL packet.
- Not suitable for sending WoL across subnets without additional broadcast forwarding.

## References

- GitHub: <https://github.com/alex-swki/magicpack>
