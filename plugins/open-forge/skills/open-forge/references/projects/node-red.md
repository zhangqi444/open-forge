---
name: Node-RED
description: Low-code visual programming editor for wiring together hardware, APIs, and online services via a browser-based flow editor. Built on Node.js with a rich ecosystem of community "nodes".
---

# Node-RED

Node-RED is a Node.js runtime plus a browser-based flow editor that lets you wire together input nodes (MQTT, HTTP, webhooks, GPIO, serial, Modbus…), function nodes (JS code, template, switch, change), and output nodes into event-driven flows. It's especially popular in home automation, IoT, and light ETL work.

- Upstream repo: <https://github.com/node-red/node-red>
- **Docker repo:** <https://github.com/node-red/node-red-docker>
- Image: `nodered/node-red` on Docker Hub
- Docs: <https://nodered.org/docs/>

## Compatible install methods

| Infra                | Runtime                         | Notes                                                             |
| -------------------- | ------------------------------- | ----------------------------------------------------------------- |
| Single host / Pi     | Docker (`nodered/node-red`)     | Recommended self-host path; multi-arch images                     |
| Bare metal           | npm global (`npm i -g node-red`) | Official install for Pi/Linux; see <https://nodered.org/docs/getting-started/local> |
| Kubernetes           | Helm chart (community)          | Several exist; not upstream-official                              |
| Desktop              | Electron wrapper (community)    | Not upstream                                                      |

## Inputs to collect

| Input            | Example                         | Phase   | Notes                                                                            |
| ---------------- | ------------------------------- | ------- | -------------------------------------------------------------------------------- |
| Listen port      | `1880`                          | Runtime | Default editor + HTTP endpoints                                                   |
| Data dir         | `/data` inside container        | Runtime | Flows, credentials, `settings.js`, installed nodes                                |
| `TZ`             | `Europe/London`                 | Runtime | Needed for correct cron / scheduled flows                                         |
| Admin auth       | username + bcrypt hash          | Runtime | Edit `settings.js` → `adminAuth` block; see docs link below                       |
| Credential secret | random string                  | Runtime | Set `credentialSecret` in `settings.js` before storing secrets in flows           |

## Install via Docker

Upstream's canonical one-liner (from <https://github.com/node-red/node-red-docker#run>):

```sh
docker run -d --name mynodered \
  -p 1880:1880 \
  -v node_red_data:/data \
  --restart unless-stopped \
  nodered/node-red:4.1.8
```

Tag policy — pin a real version from <https://hub.docker.com/r/nodered/node-red/tags> (at time of writing `4.1.8`, with node-20 by default). Alternative tags:

- `:4.1.8-minimal` — smaller image, fewer built-in nodes (dashboard, etc. must be installed)
- `:4.1.8-20` / `:4.1.8-22` — pin Node.js major alongside Node-RED
- `:latest` — tracks newest stable; fine for tinkering, bad for reproducibility

### Compose variant

```yaml
services:
  node-red:
    image: nodered/node-red:4.1.8
    container_name: node-red
    restart: unless-stopped
    environment:
      - TZ=Europe/London
    ports:
      - 1880:1880
    volumes:
      - ./node-red-data:/data
```

Bind-mounting `./node-red-data:/data` from the host is fine, but **on first run** the container will be uid 1000 inside; if the host dir is owned by a different user you'll see permission errors. Either `chown -R 1000:1000 ./node-red-data` or run the container as your host user (`user: "$(id -u):$(id -g)"`).

## Authentication (do this before exposing publicly)

Node-RED ships with **no authentication** by default. Edit `/data/settings.js` inside the volume:

```js
adminAuth: {
  type: "credentials",
  users: [
    {
      username: "admin",
      password: "$2b$08$...bcrypt-hash...",  // node-red admin hash-pw
      permissions: "*"
    }
  ]
},
credentialSecret: "some-long-random-string",
```

Generate the hash with:

```sh
docker exec -it mynodered node-red admin hash-pw
```

Full auth options: <https://nodered.org/docs/user-guide/runtime/securing-node-red>. Use an auth-aware reverse proxy on top if you want SSO.

## Data & config layout

All state lives under `/data/`:

- `/data/flows.json` — your flows
- `/data/flows_cred.json` — encrypted credentials (useless without `credentialSecret`)
- `/data/settings.js` — runtime config (auth, HTTP admin root, logger, etc.)
- `/data/node_modules/` — nodes installed via the Palette Manager / `npm install`
- `/data/package.json` — pinned set of installed nodes

Back up the entire `/data/` volume, plus record your `credentialSecret` separately.

## Upgrade

1. Review release notes: <https://github.com/node-red/node-red/releases>. Major versions occasionally deprecate core nodes.
2. Bump the image tag in your compose/run command.
3. `docker compose pull && docker compose up -d` (or `docker pull && docker rm -f mynodered && docker run ...`).
4. On first start post-upgrade, Node-RED will npm-install any missing palette nodes from `/data/package.json`. Watch `docker logs` for errors and bump any incompatible nodes via Palette Manager.

## Gotchas

- **No auth by default.** Do not expose `1880` to the internet without configuring `adminAuth` + TLS (or putting an auth-aware reverse proxy in front).
- **`credentialSecret` must be set before storing secrets.** If you add flows with credentials and then set (or change) `credentialSecret`, existing credentials become undecryptable. Pick one on day 1.
- **Palette-installed nodes live in `/data/node_modules`** — don't try to install nodes by `docker exec npm install` in `/usr/src/node-red`; they won't survive restart.
- **Host `:latest` upgrades break flows occasionally.** Pin the tag and upgrade deliberately.
- **`/data` permission surprises:** bind-mounted host dirs must be writable by uid 1000 inside the container.
- **Multi-arch tags fib.** A few rare Node-RED tags are not published for arm/v6 (original Pi). Check <https://hub.docker.com/r/nodered/node-red/tags> before deploying to very old hardware.
- **Projects feature (git-backed flows) is optional** but recommended; enable in `settings.js` under `editorTheme.projects`.
- **Function node runs in the main loop.** Long-running or blocking code in a function node will stall all flows. Use a separate service or `exec`/queue nodes for heavy work.
- **Serial/GPIO hardware** requires `--device=` + the right host group membership; the container runs rootless in default setups.

## Links

- Docs hub: <https://nodered.org/docs/>
- Getting started (Docker): <https://nodered.org/docs/getting-started/docker>
- Docker repo README: <https://github.com/node-red/node-red-docker>
- Securing Node-RED: <https://nodered.org/docs/user-guide/runtime/securing-node-red>
- Releases: <https://github.com/node-red/node-red/releases>
- Docker Hub: <https://hub.docker.com/r/nodered/node-red>
- Library: <https://flows.nodered.org/>
