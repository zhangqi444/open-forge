# Wishlist

**What it is:** Self-hosted shareable wishlist app for friends and family. Users add items to their wishlist; others can claim items to avoid gift duplication. Supports multiple groups, Registry Mode (single public list, no account required for claimers), item suggestions with approval workflows, auto-fetch of product data from URLs, OAuth, SMTP invites, and PWA.

**GitHub:** https://github.com/cmintey/wishlist  
**Docker image:** `ghcr.io/cmintey/wishlist:latest`  
**Helm chart:** https://github.com/mddeff/wishlist-charts (community)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; single container + SQLite |
| Kubernetes | Helm | Community Helm chart available |

---

## Inputs to Collect

### Phase: Deploy

| Variable | Description |
|----------|-------------|
| `ORIGIN` | Public URL users connect to — e.g. `https://wishlist.example.com` or `http://192.168.1.x:3280`. **Required.** If using an IP address, include the port. |
| `TOKEN_TIME` | Hours until signup/password reset tokens expire (default `72`) |

### Phase: Optional

| Variable | Description |
|----------|-------------|
| `DEFAULT_CURRENCY` | Global default currency ISO code (e.g. `USD`, `EUR`) |
| `MAX_IMAGE_SIZE` | Max image upload size in bytes (default `5000000` = 5 MB) |
| SMTP config | Required for email invites — configure in app admin panel |
| OAuth config | For OAuth-based authentication |

---

## Software-Layer Concerns

- **SQLite database** at `./data` — mount `./data:/usr/src/app/data` for persistence
- **Image uploads** at `./uploads` — mount `./uploads:/usr/src/app/uploads`
- **`ORIGIN` must be set correctly** — wrong value causes CSRF/auth errors; include port if using IP
- **Does not support running at a subpath** — must be at root (e.g. `https://wishlist.domain.com`, not `https://domain.com/wishlist`)
- **Nginx reverse proxy note:** Add buffer settings to avoid known issues:
  ```
  proxy_buffer_size   128k;
  proxy_buffers       4 256k;
  proxy_busy_buffers_size   256k;
  ```

### Feature summary

| Feature | Notes |
|---------|-------|
| Multiple groups | Separate wishlists per group (family, friends, etc.) |
| Registry Mode | Single public list; claimers don't need an account |
| Item suggestions | Three modes: Approval Required, Auto Approval, Surprise Me |
| URL auto-fetch | Paste a product URL to auto-fill item details |
| SMTP invites | Send invite links via email (SMTP config required) |
| OAuth | Supported for user authentication |
| PWA | Installable on desktop and mobile |

---

## Example Docker Compose

```yaml
services:
  wishlist:
    container_name: wishlist
    image: ghcr.io/cmintey/wishlist:latest
    ports:
      - "3280:3280"
    volumes:
      - ./uploads:/usr/src/app/uploads
      - ./data:/usr/src/app/data
    environment:
      ORIGIN: https://wishlist.example.com
      TOKEN_TIME: "72"
    restart: unless-stopped
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. SQLite and uploads persist in mounted volumes

---

## Gotchas

- **`ORIGIN` is required** — leaving it as an IP without the port, or setting it incorrectly, causes login and CSRF failures
- **No subpath support** — must be hosted at the domain/IP root
- **Nginx users** — must set buffer size config to avoid proxy issues (see above)
- **Registry Mode public links** — anyone with the link can claim items without logging in; share carefully
- First admin account is created via registration; public signup can be disabled afterward in the admin panel

---

## Links

- GitHub: https://github.com/cmintey/wishlist
- Docker image: https://github.com/cmintey/wishlist/pkgs/container/wishlist
- Helm chart: https://github.com/mddeff/wishlist-charts
