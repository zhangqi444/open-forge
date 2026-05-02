# HabitSync

**What it is:** Powerful self-hostable habit tracking platform with social features. Track daily, weekly, monthly, or custom-interval habits (including negative habits to reduce). Supports shared habits with friends, monthly community challenges with leaderboards, achievement medals, push/email notifications via Apprise, and a mobile PWA + Android app. Authentication is OIDC/SSO (PKCE flow) — no built-in username/password UI except optional basic auth via bcrypt hashes.

**Official URL:** https://github.com/jofoerster/habitsync  
**Demo:** https://demo.habitsync.de

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended for production |
| Any Linux host | Docker run | Single container |

---

## Inputs to Collect

| Phase | Input | Notes |
|-------|-------|-------|
| Deploy | `BASE_URL` | Full public URL (e.g. `https://habits.example.com`) — required for OIDC redirect |
| Deploy | OIDC provider URL + client ID | Required for SSO login (Authelia, Google, any OIDC-compatible IdP) |
| Deploy | `JWT_SECRET` | SHA-512 hash of a secret key; generate with `openssl rand -base64 64`; needed to keep sessions across restarts |
| Deploy | Data directory | Mounted at `/data`; contains H2 database files |
| Deploy | Host port | Default `6842` |
| Optional | Basic auth users | `APP_SECURITY_BASIC-AUTH-USERS_<username>=<bcrypt-hash>` for username/password login |
| Optional | Apprise API URL | `APPRISE_API_URL` — for push/email/webhook notifications |
| Optional | Mail settings | `SPRING_MAIL_HOST`, `SPRING_MAIL_USERNAME`, `SPRING_MAIL_PASSWORD`, etc. |
| Optional | PostgreSQL | Swap H2 default DB for PostgreSQL for production workloads |
| Optional | `PUID` / `PGID` | Run-as user/group IDs (defaults `6842`/`6842`) |

---

## Software-Layer Concerns

### Docker image
```
ghcr.io/jofoerster/habitsync:latest
```

### docker-compose.yml
```yaml
services:
  web:
    image: ghcr.io/jofoerster/habitsync:latest
    environment:
      - BASE_URL=https://your-domain.com
      # OIDC issuer (PKCE flow); configure a public client on your IdP
      # Redirect URI: https://your-domain.com/auth-callback
      # Mobile redirect: habitsync://auth-callback
      - APP_SECURITY_ISSUERS_MYIDP_URL=https://auth.example.com
      - APP_SECURITY_ISSUERS_MYIDP_CLIENT-ID=habitsync-client
      - APP_SECURITY_ISSUERS_MYIDP_NEEDS-CONFIRMATION=true
      # Optional: basic auth user (bcrypt hash)
      # Generate: htpasswd -bnBC 10 "" yourpassword | tr -d ':\n' | sed 's/\$/\$\$/g'
      # - APP_SECURITY_BASIC-AUTH-USERS_admin=<bcrypt-hash>
      # Session persistence
      - JWT_SECRET=<sha512-hash-of-secret>
      # Mail (optional)
      - SPRING_MAIL_ENABLED=false
      # Apprise notifications (optional)
      # - APPRISE_API_URL=http://apprise-api:8000
      # Run-as user (optional)
      - PUID=1000
      - PGID=1000
    volumes:
      - ./data:/data
    ports:
      - "6842:6842"
    restart: unless-stopped
```

### Authentication
HabitSync uses OIDC with public clients (PKCE flow). Supported out of the box:
- **Any OIDC-compatible IdP** (Authelia, Authentik, Keycloak, etc.) — use public client with PKCE
- **Google** — requires `CLIENT-SECRET` workaround (it's sent to clients, so it's not truly secret)
- **Basic auth** — create bcrypt hashes with `htpasswd -bnBC 10 "" password | tr -d ':\n' | sed 's/\$/\$\$/g'`

**OIDC scopes required:** `openid`, `profile`, `email`

### Database
- **Default: H2** (embedded file-based, stored in `/data`) — fine for small personal use
- **PostgreSQL**: set `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD` for production deployments

### Notifications (Apprise)
Set `APPRISE_API_URL` to an [Apprise API](https://github.com/caronc/apprise-api) instance for push notifications. A `docker-compose-apprise.yml` example is available in the repo's `examples/` directory.

---

## Upgrade Procedure

> ⚠️ **v0.19.0 breaking change:** The mobile OIDC redirect URI changed from `habitsync:///auth-callback` to `habitsync://auth-callback` (triple slash → double slash). Update your IdP's allowed redirect URIs when upgrading to v0.19.0+.

```bash
docker compose pull
docker compose up -d
```

H2 data persists in the mounted volume. For PostgreSQL, check release notes for schema migrations.

---

## Gotchas

- **OIDC is the primary auth method** — there is no built-in email/password account creation UI; you must configure at least one OIDC issuer or basic auth user before anyone can log in
- **`NEEDS-CONFIRMATION=true` by default** — new users must be approved by an existing user before accessing the app; set to `false` for open registration
- **`JWT_SECRET` is required for session persistence** — without it, all sessions are invalidated on container restart
- **Google requires `CLIENT-SECRET`** — Google's OIDC flow is not fully PKCE-compatible for public clients; the client secret is sent to the browser (not a true secret) as a workaround
- **Mobile app** — Android APK is available in GitHub Releases; requires `BASE_URL` to be publicly reachable

---

## Links

- GitHub: https://github.com/jofoerster/habitsync
- Demo: https://demo.habitsync.de
- Apprise API: https://github.com/caronc/apprise-api
