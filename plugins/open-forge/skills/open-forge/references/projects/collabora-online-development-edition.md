---
name: collabora-online-development-edition
description: Collabora Online Development Edition (CODE) recipe for open-forge. LibreOffice-based online office suite for self-hosted document editing. Integrates with Nextcloud, Seafile, and others. MPL-2.0. Source: https://github.com/CollaboraOnline/online
---

# Collabora Online Development Edition (CODE)

The community edition of Collabora Online — a powerful LibreOffice-based online office suite for self-hosted collaborative document editing. Supports .docx, .xlsx, .pptx, .odt, and all major document formats. Real-time collaborative editing with track changes, comments, and macros. Integrates with Nextcloud, Seafile, ownCloud, and other platforms via WOPI protocol. MPL-2.0 licensed. Upstream: <https://github.com/CollaboraOnline/online>. Website: <https://www.collaboraoffice.com/code>

## Compatible Combos

| Infra | Runtime | Integration | Notes |
|---|---|---|---|
| Any Linux VPS | Docker | Nextcloud | Most common setup — see Nextcloud app docs |
| Any Linux VPS | Docker | Seafile | Via WOPI connector |
| Any Linux VPS | Docker | Standalone WOPI | Any WOPI-compatible file host |
| Debian/Ubuntu | APT package | Any WOPI host | Collabora provides apt.collaboraoffice.com repo |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for CODE?" | FQDN | e.g. office.example.com — must be HTTPS |
| "Integration target?" | Nextcloud / Seafile / other | Drives WOPI host config |
| "Allowed WOPI host domain?" | FQDN or regex | The domain of your Nextcloud/Seafile instance |
| "Admin username and password?" | credentials | For the CODE admin panel |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Number of simultaneous documents?" | Number | Free CODE tier allows up to 20 connections |
| "Font requirements?" | Font list | Custom fonts can be injected into the container |

## Software-Layer Concerns

- **WOPI protocol**: CODE communicates with file hosts (Nextcloud, Seafile) via WOPI. The file host must run a WOPI connector plugin/app.
- **HTTPS required**: CODE must be served over HTTPS — browsers will refuse mixed-content WebSocket connections.
- **20-connection free limit**: The community CODE edition supports up to 20 simultaneous document connections. Collabora Online (commercial) has no limit.
- **Reverse proxy required**: CODE runs on port 9980 internally — put NGINX or Caddy in front for HTTPS termination.
- **aliasgroup / server_name**: The `aliasgroup1` env var or config option must list the WOPI host domain — CODE refuses connections from unlisted hosts.
- **Docker image from packages**: Official image at `collabora/code` on Docker Hub, built from Debian packages. Updated with each release.
- **Admin panel**: Available at `https://office.example.com/browser/dist/admin/admin.html`

## Deployment

### Docker Compose (with NGINX reverse proxy)

```yaml
services:
  code:
    image: collabora/code:latest
    ports:
      - "127.0.0.1:9980:9980"
    environment:
      aliasgroup1: "https://nextcloud.example.com:443"
      username: admin
      password: changeme
      extra_params: "--o:ssl.enable=false --o:ssl.termination=true"
    cap_add:
      - MKNOD
    restart: unless-stopped
```

NGINX config:
```nginx
server {
    listen 443 ssl;
    server_name office.example.com;

    # Static files
    location ^~ /browser {
        proxy_pass http://127.0.0.1:9980;
        proxy_set_header Host $host;
    }

    # WOPI discovery
    location ^~ /hosting/discovery {
        proxy_pass http://127.0.0.1:9980;
        proxy_set_header Host $host;
    }

    # Capabilities
    location ^~ /hosting/capabilities {
        proxy_pass http://127.0.0.1:9980;
        proxy_set_header Host $host;
    }

    # WebSocket (cool)
    location ~ ^/cool/(.*)/ws$ {
        proxy_pass http://127.0.0.1:9980;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 36000s;
    }

    location / {
        proxy_pass http://127.0.0.1:9980;
        proxy_set_header Host $host;
    }
}
```

### Nextcloud integration

1. In Nextcloud, install the **Nextcloud Office** (formerly Collabora Online) app.
2. Go to Nextcloud Admin → Office → set CODE URL to `https://office.example.com`.
3. Optionally enable "Use your own server" and disable "Allow users to edit locally installed office".

## Upgrade Procedure

1. `docker compose pull && docker compose up -d`
2. Check release notes at https://www.collaboraonline.com/release-notes/ — especially for WOPI or API changes.

## Gotchas

- **20-connection limit**: CODE is the free community edition — 20 simultaneous open documents. For more, consider Collabora Online (commercial) or Nextcloud Hub.
- **HTTPS only**: Without HTTPS, browsers block the WebSocket connections CODE needs. Use Let's Encrypt via Caddy or Certbot.
- **`cap_add: MKNOD`**: Required for CODE's internal document rendering process.
- **aliasgroup must match WOPI host exactly**: Domain mismatch = CODE refuses to open documents. Include the protocol and port if non-standard.
- **ssl.termination=true**: When running behind a TLS-terminating reverse proxy, set this flag so CODE doesn't try to handle its own TLS.
- **Memory**: CODE is essentially LibreOffice running headless — plan for ~512MB–1GB RAM depending on load.

## Links

- Source: https://github.com/CollaboraOnline/online
- Website: https://www.collaboraoffice.com/code
- SDK / integration docs: https://sdk.collaboraonline.com/
- Docker Hub: https://hub.docker.com/r/collabora/code
- Nextcloud integration guide: https://nextcloud.com/collaboraonline/
