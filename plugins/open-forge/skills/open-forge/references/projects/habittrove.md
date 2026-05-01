# HabitTrove

**Gamified habit tracker — earn coins for completing habits and redeem them for custom rewards. Daily streaks, heatmap, freehand drawings, PWA support, and automatic daily backups.**
Demo: https://demo.habittrove.com
GitHub: https://github.com/dohsimpson/HabitTrove

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |

---

## Inputs to Collect

### Required
- `AUTH_SECRET` — random secret for authentication (`openssl rand -base64 32`)

---

## Software-Layer Concerns

### Setup
```bash
mkdir -p data backups
chown -R 1001:1001 data backups   # required — app runs as UID 1001
export AUTH_SECRET=$(openssl rand -base64 32)
```

### Docker Compose
```yaml
services:
  habittrove:
    image: dohsimpson/habittrove:latest
    ports:
      - "3000:3000"
    volumes:
      - ./data:/app/data
      - ./backups:/app/backups
    environment:
      - AUTH_SECRET=your_generated_secret
    restart: unless-stopped
```

### Docker run
```bash
docker run -d \
  -p 3000:3000 \
  -v ./data:/app/data \
  -v ./backups:/app/backups \
  -e AUTH_SECRET=$AUTH_SECRET \
  dohsimpson/habittrove
```

### Ports
- `3000` — web UI

### Image tags
- `latest` — stable release (recommended)
- `vX.Y.Z` — version-pinned for reproducible deployments
- `dev` — latest development build (unstable)

### Storage
- `/app/data` — user data
- `/app/backups` — automatic daily backups with rotation

### Key features
- Coin rewards for completing habits
- Custom reward wishlist (redeem with coins)
- Habit streaks and statistics
- Calendar heatmap visualization
- Freehand drawings on habits/rewards
- Multi-language (English, Spanish, French, German, Chinese, Korean, Japanese, Russian, Catalan)
- Dark mode
- Progressive Web App (PWA)
- Automatic daily backups with rotation

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- **Must** `chown -R 1001:1001 data backups` before first run — app runs as UID 1001 inside container
- `AUTH_SECRET` must be set and kept stable — changing it invalidates existing sessions
- Pull requests not accepted — submit feature requests/bugs as issues

---

## References
- GitHub: https://github.com/dohsimpson/HabitTrove#readme
