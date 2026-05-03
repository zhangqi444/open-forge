# OpenUEM

> Unified endpoint and IT asset manager with a web-based console. Provides VNC remote assistance, file browsing on remote disks, Winget-based package deployment, profile automation (software, registry, local users/groups), Wake-on-LAN/power controls, and component health dashboards. Apache 2.0.

**Official URL:** https://openuem.eu  
**Docs:** https://openuem.eu/docs/Console/intro  
**GitHub:** https://github.com/open-uem/openuem-console

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker / Docker Compose | Recommended for the console; agents installed on managed endpoints |
| Windows Server | Native binary | Agents are Windows-first (Winget-based deployment) |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| Domain / IP | Where the console will be reachable | `uem.example.com` |
| Admin credentials | Initial admin user for the console | username + password |
| Agent Worker URL | Address agents will use to connect back to the server | `https://uem.example.com` |

---

## Software-Layer Concerns

### Architecture
OpenUEM is multi-component:
- **Console** — web UI (this recipe) where admins log in to view/manage endpoints
- **Agent Workers** — server-side workers that receive and dispatch commands
- **Agents** — lightweight clients installed on each managed endpoint (Windows-first; Winget required for package deployment)

Follow the full deployment guide at https://openuem.eu/docs/ for agent-worker setup. The console is the entry point but useless without at least one worker + one admitted agent.

### Quick Start (Console via Docker)
```bash
# Pull and run the console image (check hub.docker.com/r/openuem for latest tag)
docker run -d \
  --name openuem-console \
  -p 8080:8080 \
  --restart unless-stopped \
  openuem/openuem-console:latest
```

For a full stack (console + workers + DB), refer to the docker-compose example in the upstream docs.

### Admitting an Agent
1. Install the OpenUEM agent on an endpoint (see https://openuem.eu/docs/Agents/intro)
2. In the console: **Agents → Pending** → click **Admit**
3. Admitted agents appear under **Endpoints** and expose inventory, VNC, file browser, and Winget controls

### Key Features
| Feature | Location in console |
|---------|-------------------|
| Endpoint inventory | Endpoints → select endpoint |
| VNC remote assistance | Endpoints → endpoint → Remote Assistance |
| File browser | Endpoints → endpoint → Files |
| Package deploy (Winget) | Endpoints → endpoint → Software |
| Profile automation | Profiles → New Profile |
| Wake on LAN / reboot | Endpoints → endpoint → Power |
| Component health | Dashboard |

### Ports
- Default console port: `8080` — reverse-proxy with Nginx/Caddy for TLS

---

## Upgrade Procedure

1. Pull the new image: `docker pull openuem/openuem-console:latest`
2. Stop and remove the old container: `docker stop openuem-console && docker rm openuem-console`
3. Re-run with the same flags as the initial deploy
4. Also update agent-worker components and agents per the upstream release notes

---

## Gotchas

- **Agents required** — the console alone shows nothing; at least one admitted agent is needed before the UI becomes meaningful
- **Winget is Windows-only** — package deployment via Winget only works on managed Windows endpoints; cross-platform package management is not currently supported
- **Agent admission is manual by default** — agents that contact a worker appear as "Pending" in the console and must be explicitly admitted before they are managed; this is a security gate, not a bug
- **VNC requires network path** — the console proxies VNC through the worker; the worker must be able to reach the endpoint on the VNC port for remote assistance to work

---

## Links
- Docs: https://openuem.eu/docs/Console/intro
- GitHub (console): https://github.com/open-uem/openuem-console
- GitHub (org): https://github.com/open-uem
