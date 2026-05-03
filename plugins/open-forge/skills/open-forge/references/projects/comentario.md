# Comentario

> Open-source web comment engine — embed a discussion section into any website. Privacy-first (no tracking pixels or ads), role-based moderation, social login, spam extensions (Akismet, Perspective), live updates, and import from Disqus/WordPress/Commento. Successor to the discontinued Commento.

**Official URL:** https://comentario.app  
**Docs:** https://docs.comentario.app  
**Demo:** https://demo.comentario.app  
**Source:** https://gitlab.com/comentario/comentario

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; PostgreSQL required |
| Cloudron | Cloudron package | One-click via Cloudron store |
| Railway | Template | Unofficial Railway template available |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `POSTGRES_*` | PostgreSQL connection details | host, port, user, password, db |
| `SECRET_KEY` | App secret key for session signing | random 64+ char string |
| `BASE_URL` | Public URL of this Comentario instance | `https://comments.example.com` |
| `SMTP_*` | SMTP settings for email notifications | host, port, user, password |

### Phase: Optional Social Login
| Input | Description |
|-------|-------------|
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google OAuth2 |
| `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` | GitHub OAuth2 |
| `TWITTER_CLIENT_ID` / `TWITTER_CLIENT_SECRET` | Twitter/X OAuth2 |
| `GITLAB_CLIENT_ID` / `GITLAB_CLIENT_SECRET` | GitLab OAuth2 |
| OIDC provider config | Generic OIDC (LinkedIn, Authentik, Keycloak, etc.) |

### Phase: Optional Spam Extensions
| Input | Description |
|-------|-------------|
| Akismet API key | Spam detection |
| APILayer / Perspective API key | Offensive language / toxicity detection |

---

## Software-Layer Concerns

### Deployment
Full deployment guide at: https://docs.comentario.app/en/getting-started/

The quick path is Docker Compose with PostgreSQL. A compose file is provided in the repository.

### Embedding on Your Site
Add the Comentario script tag to any HTML page:
```html
<script defer src="https://comments.example.com/js/comentario.js"></script>
<comentario-comments></comentario-comments>
```

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| PostgreSQL volume | All comments, users, domains, stats |

### Ports
- Default: `8080` — proxy with Nginx/Caddy for TLS (HTTPS required for OAuth/SSO)

### Import from Disqus / WordPress / Commento
Built-in import tool in the admin UI accepts Disqus XML export, WordPress XML export, or Commento JSON export.

---

## Upgrade Procedure

1. Pull latest image: `docker compose pull`
2. Stop: `docker compose down`
3. Start: `docker compose up -d`
4. Database migrations run automatically on startup

---

## Gotchas

- **PostgreSQL required** — no SQLite option; you need a PostgreSQL instance
- **HTTPS for OAuth** — social login providers require a public HTTPS callback URL; HTTP-only deployments cannot use social login
- **BASE_URL must match** — the public URL must be exact; OAuth redirects and embed script URLs depend on it
- **Multiple domains, one instance** — a single Comentario instance can serve comment widgets for multiple websites; manage all from the admin UI
- **Commento fork** — originally forked from Commento; since v3.0 it's a fully rewritten product with no legacy code; Commento++ imports are supported
- **Statistics collection** — Comentario collects depersonalised stats (country, browser, language) per visitor; no personal data, no tracking pixels

---

## Links
- Homepage: https://comentario.app
- Docs: https://docs.comentario.app
- GitLab source: https://gitlab.com/comentario/comentario
- Demo: https://demo.comentario.app
- Cloudron: https://www.cloudron.io/store/app.comentario.cloudronapp.html
