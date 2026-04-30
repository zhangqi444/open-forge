---
name: OliveTin
description: "Safe, simple web UI for running predefined shell commands. YAML-configured command buttons + argument forms. Go backend + static frontend. Explicitly markets \"AI Autonomy Level 1 of 5 (assistance-only)\" — transparent AI-involvement signal. AGPL-3.0. Production-maturity badge."
---

# OliveTin

OliveTin is **"sudo-for-your-family-via-web-page"** — a web UI that exposes **predefined shell commands** you specifically configure, as click-to-run buttons. Less-technical users get a mobile-friendly dashboard; they can't arbitrary-exec, they can only invoke exactly the commands you pre-configured. Perfect for: give your family a "restart Plex" button, give junior admins a dropdown-driven backup script, expose `wake-on-lan` for a touch-tablet, let yourself SSH from your phone via a form. YAML config (cloud-native 😉).

Built + maintained by **James Read** (OliveTin org). **License: AGPL-3.0**. Active + production-maturity (upstream claims). Tracks AI Autonomy via a visible badge — currently **"Level 1 of 5 (assistance-only)"** per `ai-levels-of-autonomy-in-software-engineering/` — upstream's transparent signal that AI assists but doesn't write code autonomously. Rare + admirable upstream-values signal.

Use cases: (a) **family-friendly "restart the Plex server" buttons** — your non-technical partner taps a button, no SSH required (b) **junior-admin web-form for pre-approved scripts** — dropdowns + text inputs + preset args (c) **IoT / touch-tablet buttons** on walls at home (d) **phone-friendly remote-server quick-actions** (e) **container orchestration lite** — "spin up + tear down my dev environment" buttons (f) **homelab dashboard action tiles** — pairs well with Homarr / Homepage.

Features (from upstream README):

- **Responsive touch-friendly UI** — tablets, phones, desktops
- **YAML config** — define commands + forms declaratively
- **Dark mode**
- **Accessibility** — passes Firefox accessibility checks; issues taken seriously
- **Container image** — quick testing + homelab deploy
- **Run any Linux command** — full shell capability (fundamental power + footgun)
- **Argument templating** — `{{ variable }}` substitution from form inputs
- **Dropdown arguments** — restrict user choices to safe options
- **Command variables** — pass env vars to commands
- **Webhooks / schedules** — trigger commands on events or timers
- **Execution logs** — what ran, when, exit code, stdout/stderr
- **Multi-user + permissions** (with recent versions)
- **OpenID Connect** SSO integration
- **Go binary** — single-binary deploy option
- **Docker image** — container-friendly
- **OpenTelemetry-compatible metrics**

- Upstream repo: <https://github.com/OliveTin/OliveTin>
- Homepage: <https://www.olivetin.app>
- Docs: <https://docs.olivetin.app>
- Upgrade guide (2k→3k): <https://docs.olivetin.app/upgrade/2k3k.html>
- Discord: <https://discord.gg/jhYWWpNJ3v>
- YouTube demo: <https://www.youtube.com/watch?v=UBgOfNrzId4>
- Awesome-selfhosted entry: <https://github.com/awesome-selfhosted/awesome-selfhosted#automation>
- CII Best Practices badge: <https://bestpractices.coreinfrastructure.org/projects/5050>

## Architecture in one minute

- **Go backend** — single binary; serves web UI + executes shell commands
- **Static frontend** — HTML/JS/CSS bundled into binary
- **Config**: YAML file
- **No DB** — stateless except for logs
- **Resource**: tiny — tens of MB RAM; depends on command-execution load
- **Port 1337** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`jamesread/olivetin:latest`** (multi-arch)                    | **Easiest**                                                                        |
| Static binary      | Download from releases                                                    | Just run it                                                                                   |
| Debian/Ubuntu .deb | Package releases available                                                        | systemd-friendly                                                                                         |
| Kubernetes         | Works as a container                                                                                  | Minimal pattern                                                                                            |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain / IP          | `olivetin.example.com` or LAN IP                            | URL          | TLS strongly recommended (see gotchas)                                                                         |
| `config.yaml`        | Command definitions + UI layout                             | **CRITICAL** | The whole security model is IN this config                                                                                    |
| Authentication       | Basic auth / reverse-proxy auth / OIDC                                | **CRITICAL** | **NEVER expose without auth**                                                                                    |
| Command-execution user | Container running-as user                                                                                     | Security     | LIMIT privileges!                                                                                                            |
| Mounted volumes      | Which host paths the container needs access to                                                                            | Security     | Minimize                                                                                                                           |

## Install via Docker

```yaml
services:
  olivetin:
    image: jamesread/olivetin:latest     # **pin version** in prod
    restart: unless-stopped
    volumes:
      - ./olivetin-config.yaml:/config/config.yaml:ro
      # Add any host paths the commands need access to (carefully)
      # - /var/run/docker.sock:/var/run/docker.sock   # only if needed
    ports: ["1337:1337"]
```

Example `olivetin-config.yaml`:

```yaml
actions:
  - title: Restart Plex
    icon: plex
    shell: docker restart plex

  - title: Wake Server
    icon: power
    shell: wake-on-lan {{ mac }}
    arguments:
      - name: mac
        title: Target Server
        type: choice
        choices:
          - value: "aa:bb:cc:11:22:33"
            title: "Gaming Rig"
```

## First boot

1. Write your `config.yaml` with carefully-scoped commands
2. Start OliveTin → browse `http://host:1337`
3. Test each button → verify commands run correctly
4. Put behind TLS + auth reverse proxy (SWAG / Caddy / Traefik / Authelia / Authentik)
5. Don't expose to internet without authentication

## Data & config layout

- `config.yaml` — command definitions + UI layout + auth config
- Log files — execution history + output
- NO DB

## Backup

```sh
cp config.yaml config-$(date +%F).yaml
```

The whole security model is config-file-based. Back it up + version-control it (carefully, if it contains sensitive details).

## Upgrade

1. Releases: <https://github.com/OliveTin/OliveTin/releases>. Active.
2. Docker: pull + restart.
3. Config format is stable with deprecation warnings; read release notes.
4. 2000-series → 3000-series upgrade had breaking changes documented at <https://docs.olivetin.app/upgrade/2k3k.html>.

## Gotchas

- **OLIVETIN = WEB-EXPOSED SHELL-EXEC GATEWAY**: this is the fundamental security reality. Anything you can run in OliveTin, someone with OliveTin access can run. **Defense is ENTIRELY in:**
  - **Authentication in front** (NEVER expose without auth)
  - **TLS** mandatory
  - **Command scoping in config** (use dropdowns + restrict args)
  - **Run OliveTin as a LIMITED user** — not root
  - **Container isolation** — mount only needed volumes
  - **Audit command execution logs**
- **"SAFE" is CONFIG-DEPENDENT**: upstream README uses the word **safe** — this refers to PRE-DEFINED commands (not arbitrary exec), not that OliveTin is itself secure against every attack. A misconfigured OliveTin (e.g., `shell: {{ user_input }}` with no validation) = command injection. **`shell:` lines must sanitize user input + use argument dropdowns rather than free-text where possible.**
- **COMMAND INJECTION in argument templating**: `shell: wake-on-lan {{ mac }}` with `mac` as free-text input = attacker types `; rm -rf /` → game over. **Always prefer `type: choice` (dropdowns) over free-text** for args. Or quote + escape carefully.
- **DOCKER SOCKET = ROOT-EQUIVALENT** (same warning as pad-ws, xyops, Homarr batch 89): if you mount `/var/run/docker.sock` to OliveTin, OliveTin commands can do anything to your Docker. Only do this if the whole point is Docker management (e.g., container restart buttons) + understand the implications.
- **PRIVILEGE HIERARCHY**: run OliveTin as a non-root user. Use Linux capabilities / sudoers rules for specific elevated commands OliveTin needs (pass through sudo with NOPASSWD for EXACT commands). Example: `olivetin` user → `sudo systemctl restart plex` with sudoers entry allowing ONLY that exact command.
- **LOG RETENTION**: OliveTin logs every command execution (who, what, when, output). Operationally valuable for audit. Rotate + retain per your policy. Logs contain full command output — **may include secrets** if commands print them.
- **SECRETS IN CONFIG**: if your commands need API keys / passwords, they end up in config.yaml or env vars. Treat config.yaml as secret; file perms 600; encrypt backups.
- **MULTI-USER PERMISSIONS**: recent versions support multiple users with scoped permissions. For team use: one admin + limited non-admin users with curated button sets. Verify current implementation for your version.
- **OIDC SSO**: supported. Strongly recommended for team / family use (no password management hassle; centralized revocation).
- **AI-AUTONOMY BADGE** ("Level 1 of 5 — assistance-only"): upstream's explicit + transparent signal about AI-involvement in development. **New pattern**: **"AI-autonomy-transparency signal"** — upstream publicly declares their AI-tool policy via a standardized badge (link to ai-levels-of-autonomy-in-software-engineering/). **1st tool in AI-autonomy-transparency family** — worth watching for future tools adopting this or similar badges.
  - Complements AzuraCast's "100% human-coded" contributor-policy (batch 87) but in a different scope: AzuraCast = NO AI in their code; OliveTin = AI assists but doesn't write autonomously. Both are transparent + consistent.
- **CII BEST PRACTICES BADGE**: upstream achieved CII/OpenSSF Best Practices badge → security + dev-process institutional signal. **Positive stewardship indicator.** Similar to the Coverity / Snyk / OpenSSF Scorecard signals — third-party validation of practices.
- **PRODUCTION MATURITY BADGE**: upstream's "maturity Production" badge per README. Community accepts this claim; my read aligns — stable + long-running + clear upgrade guides.
- **HUB-OF-CREDENTIALS (TRANSITIVE)**: OliveTin's config.yaml often references tool credentials (Docker socket, API keys, SSH keys). While OliveTin itself stores minimal secrets, its TRANSITIVE access to other systems makes it a **transitive crown-jewel**. **27th tool in hub-of-credentials family (transitive)**.
- **SOLE-MAINTAINER with community**: James Read (jamesread) + contributors. **Bus-factor concern mitigated by: AGPL + CII badge + Discord + active-release cadence + Go-simple-codebase.** Pattern similar to wanderer batch 91, Memories batch 88.
- **COMMERCIAL-TIER**: no commercial SaaS; donation/sponsor funding. **"pure-donation"** tier (matching SWAG 90, LinkStack 91, wanderer 91).
- **AGPL-3.0**: source disclosure if you modify + offer as network-accessible service.
- **ALTERNATIVES WORTH KNOWING:**
  - **n8n** — general workflow automation (much broader scope)
  - **Node-RED** — flow-based programming (IoT + home automation adjacent)
  - **Automatisch** — open-source Zapier alternative
  - **Huginn** — Ruby automation agents
  - **Shiori / Buttons** (NixOS-style) — similar command-button tools
  - **Rundeck / Rundeck Community** — enterprise job scheduler; complex
  - **Choose OliveTin if:** you want SIMPLE + predefined-commands + YAML-config + lightweight + safe-for-non-technical-users.
  - **Choose n8n if:** you want general workflow automation with integrations ecosystem.
  - **Choose Rundeck if:** you need enterprise-class job scheduling + audit + teams.
- **Project health**: active + production-labeled + CII-badge + cached Discord + clear upgrade docs + Go-simple-codebase. Strong signals.

## Links

- Repo: <https://github.com/OliveTin/OliveTin>
- Homepage: <https://www.olivetin.app>
- Docs: <https://docs.olivetin.app>
- Discord: <https://discord.gg/jhYWWpNJ3v>
- 2k→3k upgrade: <https://docs.olivetin.app/upgrade/2k3k.html>
- YouTube demo: <https://www.youtube.com/watch?v=UBgOfNrzId4>
- AI autonomy levels ref: <https://blog.jread.com/posts/ai-levels-of-autonomy-in-software-engineering/>
- CII Best Practices: <https://bestpractices.coreinfrastructure.org/projects/5050>
- n8n (alt, workflow): <https://n8n.io>
- Node-RED (alt, flow): <https://nodered.org>
- Rundeck (alt, enterprise): <https://www.rundeck.com>
