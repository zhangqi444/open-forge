# Atheos

**Self-hosted web-based IDE — a maintained fork of Codiad with built-in Git integration, multi-user permissions, modern JS (no jQuery), and a minimal server footprint.**
Official site: https://atheos.io
GitHub: https://github.com/Atheos/Atheos
Docker Hub: https://hub.docker.com/r/hlsiira/atheos

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker | Image on Docker Hub |
| Any Linux (LAMP) | Manual PHP install | PHP + web server required |

---

## Inputs to Collect

### Required
- Workspace directory (where code projects live)
- Web server with PHP support (manual install) or Docker

---

## Software-Layer Concerns

### Docker
```bash
docker run -d \
  -p 8080:80 \
  -v /path/to/workspace:/var/www/html/workspace \
  hlsiira/atheos
```

Or with Docker Compose:
```yaml
services:
  atheos:
    image: hlsiira/atheos
    ports:
      - "8080:80"
    volumes:
      - ./workspace:/var/www/html/workspace
      - ./data:/var/www/html/data
      - ./plugins:/var/www/html/plugins
      - ./themes:/var/www/html/themes
    restart: unless-stopped
```

### Manual install
1. Place Atheos files in a web-accessible directory
2. Ensure write access on: `/config.php`, `/data`, `/workspace`, `/plugins`, `/themes`
3. Navigate to the install URL in your browser

### Key features
- Web-based code editor with syntax highlighting
- Built-in Git integration
- Multi-user with permission system
- Plugin support
- Custom themes
- Zero jQuery — modern vanilla JS

---

## Upgrade Procedure

Atheos has a built-in update check but no auto-updater. To upgrade:
1. Back up: `/config.php`, `/data`, `/workspace`, `/plugins`, `/themes`
2. Delete everything else (including `/themes/default`)
3. Extract new release over the root directory
4. Restore backed-up folders/files
5. Ensure write permissions are intact

---

## Gotchas

- Primarily developed on Debian LAMP — other stacks may need adjustments
- Auto-updater is being rewritten; manual file copy is currently required to upgrade
- Write permissions on `/config.php`, `/data`, `/workspace`, `/plugins`, `/themes` are required for the app to function

---

## References
- Official site: https://atheos.io
- GitHub: https://github.com/Atheos/Atheos#readme
