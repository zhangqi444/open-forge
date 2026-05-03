---
name: managebot-project
description: Discord bot for managing Docker containers via slash commands. Start/stop/restart/pause/delete containers, list images, and prune. Upstream: https://github.com/xdFNLeaks/managebot
---

# managebot

Discord bot that lets you view and manage Docker containers via Discord slash commands. Execute Docker actions (start, stop, restart, pause, unpause, delete), list containers sorted by online/offline status, manage images, and prune unused images. Upstream: <https://github.com/xdFNLeaks/managebot>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | [GitHub README](https://github.com/xdFNLeaks/managebot#docker-composeyaml) | ✅ | Recommended |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Create a Discord bot at https://discord.com/developers/applications" | info | All |
| config | Discord bot token | string | All |
| config | Discord server (guild) ID | string | All |
| config | Admin Discord user ID | string | All |
| config | Timezone offset (e.g. 0 for UTC, 11 for UTC+11) | number | All |
| config | Path for config directory | path | All |

## Setup

1. Create a Discord application at <https://discord.com/developers/applications>.
2. Under OAuth2 → URL Generator: select `bot` and `applications.commands` scopes; set permissions to **Administrator**.
3. Invite the bot to your server using the generated URL.
4. Create `config/config.json`:

```json
{
  "token": "YOUR_DISCORD_BOT_TOKEN",
  "timezone_offset": 0,
  "guild_ids": [YOUR_GUILD_ID],
  "allowed_user_ids": [YOUR_ADMIN_USER_ID],
  "status": {
    "type": "playing",
    "message": "with docker-compose.yaml files"
  }
}
```

## Docker Compose install

Source: <https://github.com/xdFNLeaks/managebot>

```yaml
version: "3.3"
services:
  managebot:
    container_name: managebot
    privileged: true
    restart: unless-stopped
    image: "ghcr.io/xdfnleaks/managebot:latest"
    volumes:
      - /your/path/to/managebot/config:/usr/src/app/config
      - /var/run/docker.sock:/var/run/docker.sock
```

## Commands

| Command | Description |
|---|---|
| `/docker execute` | Execute start/stop/restart/pause/unpause/delete on a container |
| `/list` | List all containers, sorted into Online & Offline |
| `/docker images` | Manage Docker images |
| `/docker prune` | Prune unused Docker images |
| `/uptime` | Show container uptime |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- Container runs `privileged: true` and mounts `/var/run/docker.sock` — this gives it full Docker control on the host. Only run on trusted hosts.
- `allowed_user_ids` limits which Discord users can run commands — set this correctly.
- Status types: `playing`, `watching`, `listening`.
- `guild_ids` must be an array (e.g. `[123456789012345678]`).

## References

- GitHub: <https://github.com/xdFNLeaks/managebot>
- Discord Developer Portal: <https://discord.com/developers/applications>
