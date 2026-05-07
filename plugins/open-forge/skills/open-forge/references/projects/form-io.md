---
name: form-io
description: form.io recipe for open-forge. Combined drag-and-drop form builder and REST API platform. Build data-driven apps with embeddable forms. MIT, Node.js + MongoDB. Source: https://github.com/formio/formio
---

# form.io

A combined drag-and-drop form builder and REST API platform for building data-driven applications. Define forms visually; form.io automatically generates REST API endpoints for submissions, authentication, and role-based access control. Forms embed in React/Angular/Vue apps via the `<formio>` component or plain JS. MIT licensed (community edition), written in Node.js with MongoDB backend. Source: <https://github.com/formio/formio>. Demo: <https://portal.form.io>

## Compatible Combos

| Infra | Runtime | Database | Notes |
|---|---|---|---|
| Any Linux | Docker Compose | MongoDB | Recommended — official compose provided |
| Any Linux | Node.js (manual) | MongoDB | For custom environments |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. forms.example.com |
| "Admin email?" | email | First admin account |
| "Admin password?" | string | Change from default `CHANGEME` |
| "JWT secret?" | string | Random string for signing auth tokens |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "MongoDB URI?" | Connection string | If using external MongoDB instead of bundled |
| "Reverse proxy for HTTPS?" | Yes / No | Recommended for production |

## Software-Layer Concerns

- **MongoDB required**: form.io stores all form definitions and submission data in MongoDB — no SQL support.
- **Default credentials**: Docker Compose default admin is `admin@example.com` / `CHANGEME` — change immediately after first login.
- **JWT secret**: Set `JWT_SECRET` env var to a strong random string — used for signing auth tokens; default is insecure.
- **Community vs Enterprise**: The open-source `formio/formio` repo is the community edition. Enterprise features (advanced workflows, PDF forms, offline forms) require a commercial license.
- **Form embedding**: Forms are embedded in frontend apps using the `@formio/js` JavaScript library — works with any framework or plain HTML.
- **Submission storage**: All form submissions are stored in MongoDB via the auto-generated REST API.
- **CORS**: Configure allowed origins for the API if embedding forms on different domains.

## Deployment

### Docker Compose (recommended)

```bash
git clone https://github.com/formio/formio.git
cd formio
docker compose up -d
# Access at http://localhost:3001
# Default login: admin@example.com / CHANGEME
```

The included `docker-compose.yml` starts form.io + MongoDB together.

### Docker Compose with custom env

```yaml
services:
  formio:
    image: formio/formio:latest
    restart: unless-stopped
    ports:
      - "3001:3001"
    environment:
      - MONGO=mongodb://mongo:27017/formio
      - JWT_SECRET=your-very-long-random-secret
      - ADMIN_EMAIL=admin@yourdomain.com
      - ADMIN_PASS=strongpassword
    depends_on:
      - mongo

  mongo:
    image: mongo:6
    restart: unless-stopped
    volumes:
      - mongo-data:/data/db

volumes:
  mongo-data:
```

### NGINX reverse proxy

```nginx
server {
    listen 443 ssl;
    server_name forms.example.com;

    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Embed a form in a web page

```html
<script src="https://cdn.form.io/formiojs/formio.full.min.js"></script>
<link rel="stylesheet" href="https://cdn.form.io/formiojs/formio.full.min.css">
<div id="formio"></div>
<script>
  Formio.createForm(document.getElementById('formio'),
    'https://forms.example.com/yourproject/yourform');
</script>
```

## Upgrade Procedure

1. `docker compose pull && docker compose up -d`.
2. MongoDB data persists in the volume across upgrades.
3. Check https://github.com/formio/formio/releases for breaking changes before major version upgrades.

## Gotchas

- **Change default password immediately**: The Docker Compose default `CHANGEME` password is in the README — change it before exposing the server.
- **Set JWT_SECRET**: Without a fixed secret, all auth tokens are invalidated on container restart.
- **Community edition limits**: Advanced features shown in the cloud portal may not be available in the self-hosted community edition.
- **MongoDB only**: No PostgreSQL or SQLite support — MongoDB is a hard requirement.
- **API-first**: form.io is primarily an API platform — the admin UI is for form building; actual form rendering happens in your frontend using the `@formio/js` library.
- **CORS configuration**: Set `PORTAL_SECRET` and `CORS` env vars if embedding forms from different origins.

## Links

- Source: https://github.com/formio/formio
- Documentation: https://help.form.io/
- JavaScript library: https://github.com/formio/formio.js
- Demo builder: https://formio.github.io/formio.js/app/builder.html
- Releases: https://github.com/formio/formio/releases
