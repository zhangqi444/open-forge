---
name: exercise-diary-project
description: ExerciseDiary recipe for open-forge. Minimalist workout diary with GitHub-style year heatmap visualization. Single Go binary in Docker; SQLite storage; bcrypt auth; Bootswatch themes. Upstream: https://github.com/aceberg/ExerciseDiary
---

# ExerciseDiary

A minimalist workout diary with a GitHub-style year heatmap visualization. Log exercises day by day and see your activity at a glance on an annual heatmap. Single Go binary; SQLite storage; Bootswatch themes; optional session-cookie auth.

Upstream: <https://github.com/aceberg/ExerciseDiary>

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host (AMD64/ARM64) | Single container; data in bind-mount |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Default: `8851` |
| preflight | "Timezone?" | `TZ` env var — required for correct day-boundary tracking |
| config | "Enable authentication?" | `AUTH=true`; requires `AUTH_USER` and bcrypt `AUTH_PASSWORD` |
| config (auth) | "Username?" | `AUTH_USER` |
| config (auth) | "Password (bcrypt hash)?" | Generate with `htpasswd -bnBC 10 "" password | tr -d ":\n"` |
| config | "Theme?" | Any Bootswatch theme name in lowercase; default `grass` |

## Software-layer concerns

### Image

```
aceberg/exercisediary
```

Docker Hub: <https://hub.docker.com/r/aceberg/exercisediary>

### Compose

```yaml
services:
  exdiary:
    image: aceberg/exercisediary
    restart: unless-stopped
    ports:
      - "8851:8851"
    volumes:
      - ./data:/data/ExerciseDiary
    environment:
      TZ: America/New_York      # required
      HOST: "0.0.0.0"
      PORT: "8851"
      THEME: "grass"
      COLOR: "light"            # light or dark
      # AUTH: "true"
      # AUTH_USER: "myuser"
      # AUTH_PASSWORD: "<bcrypt hash>"
      # AUTH_EXPIRE: "7d"
```

> Source: upstream docker-compose.yml — <https://github.com/aceberg/ExerciseDiary>

### Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `TZ` | `""` | Timezone — set this for correct day boundaries |
| `HOST` | `0.0.0.0` | Listen address |
| `PORT` | `8851` | Web UI port |
| `THEME` | `grass` | Bootswatch theme (lowercase); also `emerald`, `ocean`, `sand`, `wood`, `grayscale` |
| `COLOR` | `light` | `light` or `dark` background |
| `HEATCOLOR` | `#03a70c` | Heatmap color hex |
| `PAGESTEP` | `10` | Items per page |
| `AUTH` | `false` | `true` to enable session-cookie auth |
| `AUTH_USER` | `""` | Username (required when auth enabled) |
| `AUTH_PASSWORD` | `""` | Bcrypt-hashed password |
| `AUTH_EXPIRE` | `7d` | Session lifetime — number + `m`/`h`/`d`/`M` |

### Generating a bcrypt password hash

```bash
htpasswd -bnBC 10 "" yourpassword | tr -d ":\n"
# Or without local install:
docker run --rm httpd:alpine htpasswd -bnBC 10 "" yourpassword | tr -d ":\n"
```

See upstream [BCRYPT.md](https://github.com/aceberg/ExerciseDiary/blob/main/docs/BCRYPT.md) for alternatives.

## Upgrade procedure

```bash
docker compose pull && docker compose up -d
```

## Gotchas

- **`TZ` is required** — without it, day boundaries fall at UTC midnight, logging entries on the wrong day.
- **Auth password must be bcrypt-hashed** — plain-text passwords are rejected.
- **No user management UI** — single-user; change credentials via env vars + restart.
- **Intended for local network use** — enable auth and front with a TLS reverse proxy if exposing externally.
- **`THEME` must be lowercase** — `Flatly` fails; `flatly` works.

## Links

- Upstream README: <https://github.com/aceberg/ExerciseDiary>
- Bcrypt guide: <https://github.com/aceberg/ExerciseDiary/blob/main/docs/BCRYPT.md>
- Bootswatch themes: <https://bootswatch.com>
