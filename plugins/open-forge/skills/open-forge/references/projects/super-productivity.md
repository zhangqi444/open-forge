# Super Productivity

Advanced to-do list and time-tracking app with timeboxing, integrated Jira/GitHub/GitLab/OpenProject issue tracking, calendar sync, and WebDAV sync. Designed for productivity workflows: it never collects data and has no mandatory user accounts. Data stays wherever you choose — local, WebDAV, or cloud sync providers. Upstream: <https://github.com/super-productivity/super-productivity>. Docs: <https://github.com/super-productivity/super-productivity/wiki>.

Super Productivity runs as a static Angular web app. Self-hosting means serving the compiled frontend — there is **no backend process**. The app's data layer is entirely client-side; sync happens via WebDAV (Nextcloud, etc.), Dropbox, or a custom sync server.

Listening port: depends on your web server (commonly `8080` or `80`).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (linuxserver/super-productivity) | <https://hub.docker.com/r/linuxserver/super-productivity> | Community (LSIO) | Quick self-hosted web app. |
| Docker (super-productivity/super-productivity) | <https://github.com/super-productivity/super-productivity/wiki/2.13-Run-with-Docker> | ✅ | Official Docker image. |
| Static file serving (nginx/Caddy) | <https://github.com/super-productivity/super-productivity/releases> | ✅ | Download release archive, serve with any web server. |
| Desktop app (Electron) | <https://github.com/super-productivity/super-productivity/wiki/2.01-Downloads-and-Install> | ✅ | Windows/macOS/Linux desktop. No self-hosting needed. |
| Web app (hosted) | <https://app.super-productivity.com> | ✅ | Use without self-hosting; data stays in browser. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| port | "Port to serve Super Productivity on?" | Number (default 8080) | Docker/static |
| sync | "Sync method?" | `AskUserQuestion`: `WebDAV (Nextcloud, etc.)` / `Dropbox` / `Local only` | All |
| auth | "Add basic auth in front of the app?" | Yes/No | Reverse proxy setups |

## Software-layer concerns

### Docker Compose (official image)

```yaml
services:
  super-productivity:
    image: johannesjo/super-productivity:latest
    ports:
      - "8080:80"
    restart: unless-stopped
```

Access at `http://localhost:8080`. The container serves the pre-built static files via nginx.

### Docker Compose (linuxserver/super-productivity)

```yaml
services:
  super-productivity:
    image: lscr.io/linuxserver/super-productivity:latest
    container_name: super-productivity
    environment:
      PUID: 1000
      PGID: 1000
      TZ: America/New_York
    ports:
      - "8080:80"
    restart: unless-stopped
```

### Static serve (no Docker)

1. Download the latest web release from <https://github.com/super-productivity/super-productivity/releases> (look for `super-productivity-web-*.zip` or similar).
2. Extract and serve with any static web server:
   ```bash
   # With Python (quick test)
   python3 -m http.server 8080 --directory ./dist
   
   # With Caddy
   caddy file-server --listen :8080 --root ./dist
   ```

### Data and sync

Super Productivity stores all data in the **browser's LocalStorage/IndexedDB** by default. There is no server-side storage. To sync between devices:

| Sync method | Setup |
|---|---|
| **WebDAV** | Settings → Sync → WebDAV. Point to Nextcloud, ownCloud, or any WebDAV server. Stores a single JSON file. |
| **Dropbox** | Settings → Sync → Dropbox. OAuth flow required. |
| **Local file** | Export/import JSON backup from Settings. |

For WebDAV, you need a WebDAV server (e.g. Nextcloud). Super Productivity creates a file like `super-productivity-backup.json` in the WebDAV root.

### No persistent Docker volume needed

Because data lives in the browser, the Docker container itself has no state. No volume mounts are required unless you're serving custom config files.

## Upgrade procedure

Docker:
1. `docker compose pull`
2. `docker compose up -d`

Static: download the new release archive, replace the old files, done.

## Gotchas

- **No backend / no server-side storage.** The self-hosted version is just a static web app. If you clear browser data, you lose local data — use sync to prevent this.
- **HTTPS required for some sync features.** Dropbox OAuth and some browser APIs (like clipboard access) require HTTPS. Put a reverse proxy with TLS in front for production use.
- **Data is per-browser.** Without sync enabled, each browser/device has independent data. Enable WebDAV or Dropbox sync to share across devices.
- **Jira/GitHub integrations require network access.** The app calls external APIs directly from the browser, so the self-hosted server doesn't need special outbound access — the user's browser does.
- **No user accounts or multi-user support.** Super Productivity is a single-user app. Multiple users on the same instance each get their own browser storage — there's no separation at the server level.

## Links

- Upstream: <https://github.com/super-productivity/super-productivity>
- Docker guide: <https://github.com/super-productivity/super-productivity/wiki/2.13-Run-with-Docker>
- Downloads: <https://github.com/super-productivity/super-productivity/wiki/2.01-Downloads-and-Install>
- Sync docs: <https://github.com/super-productivity/super-productivity/wiki/3.08-Sync-Integration-Comparison>
- Web app vs desktop comparison: <https://github.com/super-productivity/super-productivity/wiki/3.05-Web-App-vs-Desktop>
