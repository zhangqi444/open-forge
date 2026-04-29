
## 2026-04-29 00:40–01:30 UTC — batch 2

**Processed (5):** Supabase, Immich, Storybook, Home Assistant, Uptime-Kuma.

**Upstream sources consulted:**
- Supabase: `docker/README.md`, `docker/.env.example`, `docker/docker-compose.yml` on `master`
- Immich: `README.md` on `main`; `docker/docker-compose.yml`, `docker/example.env` on `main`
- Storybook: `README.md` on `main`
- Home Assistant: `home-assistant.io/source/_includes/installation/container/cli.md` + `compose.md` (install docs); `home-assistant/docker/README.md`; install-types index
- Uptime-Kuma: `README.md`, `compose.yaml` on `master`

**Notes:**
- Supabase recipe covers the 13-service stack (Studio, Kong, Auth, PostgREST, Realtime, Storage, imgproxy, postgres-meta, Postgres, Edge Runtime, Logflare, Vector, Supavisor) and the critical pre-prod secret rotation step (`utils/generate-keys.sh` + 20+ env-var replacements).
- Immich recipe emphasizes upstream's "use the release-tag compose file, not `main`" convention and notes the custom Postgres image (vectorchord / pgvecto.rs).
- Storybook recipe frames it as "not a self-hosted app in the usual sense — it's a static site you build and serve." Covers the multiple static-host options (CF Pages / Vercel / Netlify / S3+CDN / own-VPS / GH Pages / Chromatic).
- Home Assistant recipe flags the cloud-VPS mismatch (HA is LAN-oriented; cloud HA loses most integrations). Covers the Container install (the open-forge-compatible path) and mentions HAOS / Supervised / Core as out-of-scope.
- Uptime-Kuma recipe documents the NFS-unsupported constraint, WebSocket reverse-proxy requirement, and UI-only first-run bootstrap.

**Cumulative progress:** 11 / 1274 done (0.9%). 1263 pending.

## 2026-04-28 23:56–00:13 UTC — batch 1

**Bootstrap + 2 recipes:** Set up `progress/selfhst-progress.json` (1274 apps sorted by stars, fetched from `cdn.jsdelivr.net/gh/selfhst/cdn@main/directory/software.json`). Marked the 11 existing recipes as `done` (only 4 of those slugs appear in selfh.st's directory). Wrote **n8n** and **Excalidraw** recipes.

**Skipped nothing.** Earlier skepticism about Storybook/Docusaurus/Unsloth being "non-self-hostable" was wrong — they're static-site-generators / local-model-training tools, all self-hostable, and will be processed in their star order.


## 2026-04-29 01:40–02:30 UTC — batch 3

**Processed (5):** Syncthing, LocalSend, Netdata, Stirling-PDF, code-server.

**Upstream sources consulted:**
- Syncthing: `README.md` + `README-Docker.md` on `main`; `Dockerfile` on `main`
- LocalSend: `README.md` on `main`
- Netdata: `README.md` + `packaging/docker/README.md` on `master`
- Stirling-PDF: `README.md` on `main`; `exampleYmlFiles/docker-compose-latest.yml` on `master`
- code-server: `docs/install.md` + `docs/guide.md` + `ci/release-image/Dockerfile` on `main`

**Notes:**
- Syncthing recipe emphasizes upstream's explicit guidance that `--network=host` is non-negotiable on Linux (LAN discovery breaks otherwise), and documents the UID/GID model shared with the linuxserver.io image.
- LocalSend is (like Storybook) not a traditional self-hosted server — it's a P2P desktop/mobile app. Recipe frames it honestly, covers the per-platform install matrix, and notes the edge case of running the AppImage under Xvfb on a headless Linux host (not officially supported; Syncthing is a better fit for that role).
- Netdata recipe covers the parent-child streaming architecture (first-party alternative to Netdata Cloud), the dense Docker mount list (each mount enables specific collectors), and the security implications of exposing `:19999` publicly.
- Stirling-PDF recipe covers the SYSTEM_ / SECURITY_ / UI_ env-var namespace and flags `SECURITY_ENABLELOGIN=false` as the default (fine for private use, dangerous on public URLs).
- code-server recipe covers 5 install paths (install.sh, Docker, npm, apt/rpm, Helm), the Open VSX vs Microsoft-marketplace caveat, and the permissions pitfalls of running the container as root.

**Cumulative progress:** 16 / 1274 done (1.3%). 1258 pending.



## 2026-04-29 02:30–02:55 UTC — batch 4

**Progress-file reconciliation:** caught that `caddy.md`, `apache-superset.md`, and `grafana.md` recipes already existed on disk but were still marked `"pending"` in `progress/selfhst-progress.json`. Flipped them to `done`.

**Processed (3):** AFFiNE, AppFlowy, Docusaurus.

**Upstream sources consulted:**
- AFFiNE: `.docker/selfhost/compose.yml` + `.env.example` + `config.example.json` on `canary`. Upstream self-host docs site at `docs.affine.pro/docs/self-host-affine` cited but not scraped.
- AppFlowy: Client README on `main` (just confirms this is the Flutter client, directs to AppFlowy-Cloud for server). AppFlowy-Cloud `README.md` + `docker-compose.yml` + `deploy.env` on `main`. Step-by-step guide at `appflowy.com/docs/Step-by-step-Self-Hosting-Guide...` cited.
- Docusaurus: `README.md` on `main`. No docker-compose (it's a static-site generator, not a server). Deployment targets derived from the README's links to `docusaurus.io/docs/deployment`.

**Notes:**
- **AFFiNE** compose is tight: one-shot migration container (`service_completed_successfully` dep) + pgvector/pg16 (mandatory — AI features use the extension) + redis. `POSTGRES_HOST_AUTH_METHOD: trust` is the default; recipe flags it as fine on private Docker network but recommends setting `DB_PASSWORD` anyway.
- **AppFlowy** was the most time-consuming — two repos (client `AppFlowy-IO/AppFlowy` vs server `AppFlowy-IO/AppFlowy-Cloud`), open-core caveat (free self-host = ONE user seat only; multi-user requires commercial fork), ~10-container stack. Recipe documents the full service list and the open-core warning prominently.
- **Docusaurus** reframed as a BUILD tool, not a server — the "self-host" question becomes "which static file host?" (nginx / Caddy / GH Pages / Vercel / Netlify / Cloudflare Pages / S3+CloudFront). No database, no orchestrator. Recipe's "Compatible install methods" table lists all upstream-documented deploy targets.

**Cumulative progress:** 22 / 1274 done (1.7%). 1252 pending.


## 2026-04-29 03:10–03:40 UTC — batch 5

**Processed (3):** NocoDB, Prometheus, Traefik.

**Upstream sources consulted:**
- NocoDB: `README.md` on `develop` (install commands). `docker-compose/2_pg/docker-compose.yml` + `docker-compose/3_traefik/docker-compose.yml` on `develop`. `install.nocodb.com/noco.sh` Auto-Upstall script cited (not scraped — too long).
- Prometheus: `README.md` on `main`. `documentation/examples/prometheus.yml` starter config on `main`.
- Traefik: `README.md` on `master`. Doc links deferred to `doc.traefik.io/traefik/`.

**Notes:**
- **NocoDB** license caveat flagged prominently — Sustainable Use License 1.0 is source-available with commercial-use restrictions, NOT OSI open-source. Recipe documents all 5 install paths (Docker one-liner w/ SQLite, Docker w/ external Postgres, Auto-Upstall, compose w/ Postgres only, compose w/ Traefik+LE+Watchtower) and the counterintuitive "SMTP + storage configured in-app, not env" footgun. Auto-Upstall flagged as production-recommended but writes to /root/ by default (non-standard).
- **Prometheus** recipe emphasizes the pull-only model (Pushgateway is the escape hatch), the cardinality footgun, and that Prometheus has NO built-in auth — basic-auth at the reverse proxy is the common pattern. Documented the three-component deployment shape (Prometheus + Alertmanager + node_exporter) but scoped this recipe to Prometheus only. Binary install with systemd unit is upstream-recommended; Docker variant also documented. Flagged `--web.enable-lifecycle` and `--web.enable-admin-api` as opt-in features.
- **Traefik** recipe leads with the static-vs-dynamic config distinction (biggest day-one trip-up). Documented the Docker self-host pattern (the most common shape on selfh.st stacks), binary+systemd, and Helm chart for K8s. Emphasized: acme.json MUST be 0600; Let's Encrypt rate limits (50 certs/week — always test with staging CA first); DNS-01 is required for wildcards; dashboard MUST have auth in production.

**Cumulative progress:** 25 / 1274 done (2.0%). 1249 pending.

**Deferred:** Ansible (68k stars) and Unsloth Studio (63k stars) — both are awkward fits for open-forge's "self-host a service" model. Ansible is a CLI/config-management tool (AWX is the web UI that could be self-hosted but is a different project). Unsloth is a Python package for fine-tuning LLMs, not a server. Next batch will tackle them honestly — likely as "skipped" with a brief justification, or as thin recipes pointing to AWX / the Unsloth pip install flow.


## 2026-04-29 04:10–04:35 UTC — batch 6

**Progress-file reconciliation:** caught 4 recipes (`ansible.md`, `memos.md`, `unsloth-studio.md`, `vaultwarden.md`) that existed on disk but were still marked `"pending"` in `progress/selfhst-progress.json`. Flipped to `done`.

**Processed (5):** PocketBase, Pi-hole, Meilisearch, Rclone, Appwrite.

**Upstream sources consulted:**
- PocketBase: `README.md` on `master`. No official Docker image — documented the community `ghcr.io/muchobien/pocketbase` as ⚠️ third-party.
- Pi-hole: `pi-hole/docker-pi-hole` `README.md` on `master` (inline docker-compose example). `docs.pi-hole.net` referenced but not scraped. v6 focus (env-var renames from v5).
- Meilisearch: `README.md` on `main`; `Dockerfile` on `main` (Rust 1.89 + Alpine 3.22); `docs/learn/self_hosted/install_meilisearch_locally` fetched as `.md`.
- Rclone: `README.md` on `master` (provider list). `rclone.org/install/` referenced but not scraped; canonical systemd-mount pattern from `rclone.org/commands/rclone_mount/` common knowledge.
- Appwrite: `README.md` on `main` (self-host section has the canonical `docker run ... --entrypoint="install"` invocation verbatim).

**Notes:**
- **PocketBase** recipe emphasizes pre-v1.0 breaking-changes warning from upstream's own README. Highlighted the no-official-Docker-image fact (community images only) and the SSE-realtime requirement that breaks under default nginx proxy_buffering.
- **Pi-hole** recipe frames it honestly as a LAN tool, not a cloud service. Flagged the v5→v6 env-var renames (`FTLCONF_*`) that silently break old compose files, the port-53 host-conflict with systemd-resolved, the NO `--privileged` upstream guidance on 2022.04+ images, and the DHCP-role considerations (NET_ADMIN cap + turn off router DHCP).
- **Meilisearch** recipe covers all 5 upstream install paths. Hammers on master-key requirement (+ MEILI_ENV=production disabling the public dashboard). Distinguished dumps vs snapshots for backups.
- **Rclone** was the most conceptually-unusual — reframed as "CLI, not daemon" up front (like Ansible/Storybook/LocalSend in prior batches). Documented the 3 long-running shapes (mount / serve / scheduled-sync) with systemd unit examples for each. Flagged `--vfs-cache-mode`, `--bwlimit`, `sync` vs `copy` semantic-destruction gotcha.
- **Appwrite** stack is 20+ microservices. Recipe covers the canonical `docker run … --entrypoint="install"` + `--entrypoint="upgrade"` model, `_APP_CONSOLE_WHITELIST_EMAILS` bootstrapping, S3 vs local storage, and the `_APP_ENV=development` footgun that exposes MariaDB + Redis on host ports.

**Cumulative progress:** 34 / 1274 done (2.7%). 1240 pending.



## 2026-04-29 04:53–05:15 UTC — batch 7

**Processed (5):** Gitea, Joplin, Coolify, World Monitor, Jellyfin.

**Upstream sources consulted:**
- Gitea: `README.md` on `main`; `docs.gitea.com/installation/` index cited. Compose example derived from `docs.gitea.com/installation/install-with-docker`. Systemd unit sourced from `contrib/systemd/gitea.service`.
- Joplin: `README.md` on `master` (very long client-install matrix); `docker-compose.server.yml` on `dev` (the canonical Joplin Server compose shape). `joplinapp.org/help/install/server_docker` cited.
- Coolify: `README.md` on `main`; `scripts/install.sh` on `main` (inspected env-var interface directly — `ROOT_USERNAME`, `ROOT_USER_EMAIL`, `AUTOUPDATE`, `REGISTRY_URL`, `DOCKER_ADDRESS_POOL_BASE/SIZE`).
- World Monitor: `README.md` on `main`; `worldmonitor.app/docs/getting-started` referenced but not scraped.
- Jellyfin: `README.md` on `master`; `jellyfin.org/docs/general/installation/` index; `jellyfin.org/docs/general/administration/hardware-acceleration/` for HW-accel matrix.

**Notes:**
- **Gitea** recipe covers the 7 install paths, emphasizing the two dominant shapes (Docker Compose with Postgres, binary+systemd). Documented the GITEA__section__KEY env-var convention that overrides `app.ini`. Flagged Gitea Actions needing a separate `act_runner` and the two SSH patterns (built-in SSH server vs host-OpenSSH-shim).
- **Joplin** required honest reframing — clients are desktop/mobile-native, and "self-host" specifically means Joplin Server. Recipe starts with "two different self-host framings" table distinguishing Joplin Server vs just pointing clients at existing Nextcloud/Dropbox. Compose derived from upstream's `docker-compose.server.yml` with the `profiles: [full, server]` layering. Flagged the `admin@localhost/admin` default-credential footgun prominently.
- **Coolify** recipe emphasizes the "only install.sh is supported" upstream stance. Documented env-var pre-seeding (ROOT_USERNAME/PASSWORD/EMAIL, AUTOUPDATE=false, REGISTRY_URL, DOCKER_ADDRESS_POOL_*). Server-addition SSH model (Coolify manages remote servers via its own generated SSH key) called out. Warned about the single-point-of-failure footgun of orchestrating production apps from the same Coolify host.
- **World Monitor** was the most atypical — AGPL-3.0 Next.js/Tauri hybrid with 5 variant builds, optional Ollama or OpenAI integration, and a downloadable native desktop app. Reframed as "not a traditional server" up front (similar to Storybook / Docusaurus / LocalSend in prior batches). Documented the 5-variant build-scripts (`npm run build:tech` etc.), the Tauri native binaries, and the fact that "self-host" typically means running Next.js in production mode.
- **Jellyfin** is the first proper "media server" recipe. Covered the full install matrix (APT/DNF repos, upstream Docker image, LinuxServer.io community image, portable tarballs, Windows/macOS installers). Hammered on hardware transcoding (QSV/VAAPI/NVENC/VideoToolbox/AMF), the bundled `jellyfin-ffmpeg` fork vs stock ffmpeg, `JELLYFIN_PublishedServerUrl`, and the three remote-access patterns (LAN-only / Tailscale / public-with-reverse-proxy). Flagged DLNA/discovery needing `network_mode: host` or UDP ports 1900/7359, no built-in rate limiting on login, HEVC/AV1 → H.264 CPU cost without HW accel.

**Cumulative progress:** 39 / 1274 done (3.1%). 1235 pending.



## 2026-04-29 05:25–05:55 UTC — batch 8

**Processed (5):** Odoo, Mastodon, Alist, Huginn, OpenCut.

**Upstream sources consulted:**
- Odoo: `README.md` on `master` (thin — points at docs site); `docker-library/docs/odoo/content.md` on `master` (canonical Docker image README with compose example + env-var docs); `odoo.com/documentation/master/administration/install/` referenced for APT repo structure.
- Mastodon: `README.md` on `main`; `docker-compose.yml` on `main` (the canonical production compose shape — Postgres 14, Redis 7, optional Elasticsearch 7.17, web+streaming+sidekiq split).
- Alist: `README.md` on `main`; `docker-compose.yml` on `main`; `Dockerfile` on `main` (surfaced `INSTALL_FFMPEG` / `INSTALL_ARIA2` build args and the PUID/PGID/UMASK env-var model).
- Huginn: `README.md` on `master`; `doc/docker/install.md` on `master`. Didn't scrape `.env.example` but referenced it.
- OpenCut: `README.md` on `main` (explicit self-host-with-Docker section at port 3100; dev-mode Bun flow at 3000). `docker-compose.yaml` at the 14-byte path turned out to be a 404 — real compose file is at the repo root but not fetchable via the `/main/` path tested; recipe cites it generically.

**Notes:**
- **Odoo** recipe scoped to Community edition; Enterprise mentioned but flagged as paid-subscription-only. Documented the 6 upstream install paths (Docker, APT, RPM, source, nightly tarball, Odoo.sh as out-of-scope). Hammered on the `admin_passwd` footgun (without a strong value set, `/web/database/manager` is publicly destructive), the reverse-proxy `proxy_mode=True` + longpolling `/websocket` routing requirements, and the explicit reality that major-version upgrades (17→18→19) are NOT one-command operations — use OpenUpgrade or Odoo's paid service.
- **Mastodon** is the canonical federated-social-network deploy. Covered Docker Compose + bare-metal Ubuntu paths. Emphasized the IMMUTABLE `LOCAL_DOMAIN` (changing breaks all federation), the optional-but-painful Elasticsearch config (single-node ES needs specific JVM + mlock config), Sidekiq queue-splitting for scaling, and the S3/R2 object storage upgrade for anything with actual users. Included the full `tootctl` admin CLI reference.
- **Alist** required geographic context (project originated `Xhofe/alist`, now `AlistGo/alist`; user base heavily Chinese; many China-market drive backends). Framed it correctly as a READ-aggregator + WebDAV server, NOT a sync tool (per upstream's disclaimer about 302-redirect behavior). Flagged the 2FA-before-exposure rule (Alist connects to full-access cloud tokens), the random-admin-password-printed-once on first boot, and the OpenList fork as a possible alternative.
- **Huginn** recipe distinguishes the three Docker shapes (all-in-one bundled-MySQL, multi-process `huginn-single-process` for scaling, bare-metal). Hammered on default `admin`/`password` creds (inexcusable on any exposed deploy), `ENABLE_INSECURE_AGENTS=true` meaning arbitrary code execution via Shell/Ruby Agents, and the project's maintenance-mode status (newer automation tools like n8n get more active dev).
- **OpenCut** is another "not quite a traditional server" case (like Storybook, LocalSend, Docusaurus, World Monitor in prior batches). Reframed as "web app is the self-host target; desktop is a user-installed artifact; WASM core is a dev dep." Covered the monorepo structure (Next.js web + GPUI desktop + Rust WASM), production Docker on port 3100 vs dev mode on 3000, and the privacy-first "video data stays in the browser" model (server stores metadata not frames — body-size limits are defensive). Warned about the active-refactor state (export/rendering being rewritten with a new binary approach).

**Cumulative progress:** 44 / 1274 done (3.5%). 1230 pending.



## 2026-04-29 06:23–06:55 UTC — batch 9

**Processed (5):** Plane, Gogs, Metabase, Discourse, Penpot.

**Upstream sources consulted:**
- Plane: `README.md` on `preview` (repo default branch); `developers.plane.so/self-hosting/methods/docker-compose.md` (fetched via `.md` suffix — the docs site serves raw MDX). `setup.sh` on `master` inspected for release-latest selfhost helper signature. Repo-root `docker-compose.yml` found but confirmed as DEV compose (builds from local Dockerfiles).
- Gogs: `README.md` on `main`. `gogs.io/docs/installation` referenced but not scraped. Canonical `app.ini` structure from <https://gogs.io/docs/advanced/configuration_cheat_sheet> (well-known from prior deploys).
- Metabase: `README.md` on `master`; `docs/installation-and-operation/running-metabase-on-docker.md` on `master` (full docker compose example + MB_DB_* env-var docs inline).
- Discourse: `README.md` on `main`; `docs/INSTALL-cloud.md` on `main` (canonical "Quick Start" with `install-discourse` one-liner, hardware requirements table, supported cloud providers). `discourse_docker/README.md` on `main` for `launcher` command reference.
- Penpot: `README.md` on `develop` (the repo default branch); `docker/images/docker-compose.yaml` on `develop` (full canonical compose with the `x-flags` / `x-uri` / `x-secret-key` YAML anchors pattern + inline comments for S3 + Traefik).

**Notes:**
- **Plane** recipe untangles the Commercial-vs-Community edition distinction (commercial one-liner at `prime.plane.so/install` vs the Community `setup.sh` action-menu). Hammered on the `WEB_URL` ⇄ `CORS_ALLOWED_ORIGINS` exact-match rule, the 4GB-RAM floor (migrator OOMs below), and the DEV-only repo-root compose gotcha. Included all 12 compose services in architecture section.
- **Gogs** recipe includes honest framing up front: *"Gitea is probably a better choice today."* Project development is slow compared to Gitea; Gogs remains MIT-licensed and lean but loses on feature velocity. Covered binary install with systemd unit, Docker Compose with Postgres, and the `INSTALL_LOCK`/`DISABLE_REGISTRATION` `app.ini` tightening required after first-run wizard.
- **Metabase** recipe hammered on the **H2 → Postgres appdb rule** (the single biggest production footgun). Documented the OSS-vs-Enterprise image distinction (`metabase/metabase` vs `metabase/metabase-enterprise`), the `load-from-h2` migration command, and the JVM heap sizing (`-Xmx2g` min for production). Included the upstream-canonical `/dev/urandom:/dev/random:ro` bind-mount workaround.
- **Discourse** was the most opinionated. Upstream is emphatic that `discourse_docker` is the ONLY supported install — no K8s, no bare-metal, no community Docker images. Recipe includes the hardware-requirements table from INSTALL-cloud.md, the launcher command reference, the `rebuild` vs `restart` distinction (most common operational question), and the SMTP-is-mandatory-even-for-first-admin constraint. Covered multi-container web+data split for large installs and the `docker_manager`-plugin upgrade flow via `/admin/upgrade`.
- **Penpot** recipe navigates the `PENPOT_FLAGS` feature-flag model carefully — upstream's default compose ships with `disable-email-verification` + `disable-secure-session-cookies`, which are dev defaults that bite hard on public deploys. Flagged the literal `change-this-insecure-key` default `PENPOT_SECRET_KEY` (must be rotated pre-boot). No instance-admin UI — promotion requires `./run.sh manage` CLI inside the backend container. Covered the Valkey-renamed-from-Redis situation, the Chromium-heavy exporter, and the `PENPOT_HTTP_SERVER_MAX_BODY_SIZE` setting for Figma-import file sizes.

**Cumulative progress:** 49 / 1274 done (3.8%). 1225 pending.



## 2026-04-29 06:53–07:25 UTC — batch 10

**Processed (5):** LocalAI, Twenty CRM, Rocket.Chat, Copyparty, Sentry.

**Upstream sources consulted:**
- LocalAI: `README.md` on `master` (full quickstart with CPU/NVIDIA-CUDA-12/CUDA-13/Jetson/ROCm/Intel-oneAPI/Vulkan tags); `models.localai.io` gallery referenced.
- Twenty: `README.md` on `main` (points to docs.twenty.com for self-host); `packages/twenty-docker/docker-compose.yml` on `main` (canonical compose with server + worker + db + redis); `packages/twenty-docker/.env.example` on `main`.
- Rocket.Chat: `README.md` on `develop` (mostly marketing/deployment-provider links); `RocketChat/Docker.Official.Image/compose.yml` on `main` (⚠️ has `DEPRECATED_COMPOSE` env check — upstream is migrating people OFF it); `RocketChat/rocketchat-compose/compose.yml` + `README.md` on `main` (current blessed stack). Deprecation context: Bitnami MongoDB images retired.
- Copyparty: `README.md` on `hovudstraum` (the 3386-line fever-dream README); `scripts/docker/README.md` on `hovudstraum` for the `min/im/ac/iv/dj` editions table; `contrib/systemd/copyparty.service` on `hovudstraum` for the reference systemd unit.
- Sentry: `README.md` on `master` (5 lines — just points at dev docs); `install.sh` on `master` for the full install entrypoint sequence; `install/check-minimum-requirements.sh` and `install/_min-requirements.sh` for the 4-CPU/14-GB-RAM (or 2-CPU/7-GB errors-only) floor, Docker/Compose versions, and SSE 4.2 requirement; `docker-compose.yml` on `master` (857 lines, 50+ services) scanned for service inventory.

**Notes:**
- **LocalAI** recipe focused on the 7 GPU variants (CPU / CUDA-12 / CUDA-13 / Jetson / ROCm / Intel / Vulkan) because that's where most self-hosting decisions happen. Covered the 5 model-loading sources (gallery / huggingface:// / ollama:// / yaml-config / oci://) verbatim from the quickstart. Flagged the mandatory `API_KEY` for anything beyond localhost (default is unauth, anyone can burn your GPU), the VRAM-overflow silent-CPU-fallback footgun, and the macOS DMG-not-signed `xattr` workaround upstream calls out in issue #6268.
- **Twenty** is a straightforward compose deploy but has the familiar pre-v1 + AGPLv3 combo. Emphasized the `SERVER_URL` exact-match rule (protocol + host + port), the literal `replace_me_with_a_random_string` default for `APP_SECRET`, and the "OAuth env vars are commented-out in the compose block by default" trap that breaks Gmail/Outlook sync setup for new admins. Documented Workspace ≠ superadmin — there's no instance-wide admin over multiple workspaces.
- **Rocket.Chat** recipe was the most tangled. Upstream is in the middle of a compose-file migration (`Docker.Official.Image` → `rocketchat-compose`), the old compose fails unless `DEPRECATED_COMPOSE_ACK=1` is set, and Bitnami MongoDB images retired in 2025 — recipe surfaces all three and points at the migration forum post. Documented MongoDB replica-set requirement (Meteor change streams), the Oplog URL subtle-performance bug, and the GridFS-in-Mongo default that blows up DB size.
- **Copyparty** is the maximalist of the batch. Framed it honestly — it speaks HTTP/HTTPS/WebDAV/FTP/FTPS/SFTP/SMB/TFTP/mDNS/SSDP/DLNA from ONE Python file. Covered all the upstream install paths (sfx, pypi, exe, zipapp, Docker editions, OS packages, Termux, bootable flashdrive for recovery). Documented the Docker editions table (`min`/`im`/`ac`/`iv`/`dj`), the accounts+volumes permission string syntax, the "default is open to everyone" footgun, the FTP-passive-port firewall requirement, and the `--xff-hdr cf-connecting-ip` rule for Cloudflare tunnels.
- **Sentry** recipe leads with upstream's own "low-volume deployments and proofs-of-concept" qualifier because users routinely miss it and then complain Sentry self-hosted doesn't scale. Covered the FSL-1.1-Apache-2.0 licensing (not OSI-open), hardware minimums (4 CPU/14 GB RAM, or 2/7 for errors-only), the ~50-service container inventory, ClickHouse's SSE 4.2 requirement (and the KVM-cpuinfo-masking escape hatch), install.sh's phases, upgrade discipline (always `./install.sh`, never `docker compose pull`), and the Helm-charts-are-NOT-official warning.

**Cumulative progress:** 54 / 1274 done (4.2%). 1220 pending.



## 2026-04-29 07:23–07:50 UTC — batch 11

**Processed (5):** RSSHub, SiYuan, Logseq, Cal.com, Payload.

**Upstream sources consulted:**
- RSSHub: `README.md` + `docker-compose.yml` on `master`. Documented the 3-service stack (rsshub + redis + browserless) and the `chromium-bundled` single-container variant.
- SiYuan: `README.md` on `master` (Docker Hosting section has the canonical `docker run` + docker-compose example inline). No separate `docker-compose.yml` in repo.
- Logseq: `README.md` on `master`. Reframed honestly as "desktop app, not server" (like Ansible/Storybook/LocalSend/Rclone in prior batches). Documented 3 deployment shapes: desktop app, community Docker web build (experimental), and publish-spa static-site action.
- Cal.com: `README.md` + `docker-compose.yml` on `main`. Documented the env-var-heavy setup including the `CALENDSO_ENCRYPTION_KEY` critical-secret footgun (loss = every integration dead) and the EE/AGPL boundary for Organizations/SAML/Workflow SMS.
- Payload: `README.md` on `main`. Reframed as "npm package in your Next.js app, NOT a standalone server" — Payload's v3 architecture is unique among the CMSes processed so far. Documented 4 deploy paths: BYO Docker, Vercel+Neon+Blob, Cloudflare Workers+D1+R2, existing Next.js integration.

**Notes:**
- **RSSHub** access-control hammered in the gotchas section — without `ACCESS_KEY`/WHITELIST, public deploys become open scraping proxies and will be used for abuse. Flagged Browserless's 500MB+ RAM cost on small VPS.
- **SiYuan** recipe covers the paid-tier / free-tier boundary prominently (sync/AI/official backup are paid; local + S3-sync + BYO AI keys are free). Documented PUID/PGID + access auth code + dejavu snapshot repo (key-loss = permanent data loss) as the 3 setup pillars.
- **Logseq** recipe spends significant time explaining why there's no traditional self-host story — the DB-graph vs file-graph transition, sync options (Syncthing/iCloud/git), publish-spa for read-only static sites. Useful for setting realistic expectations before a user attempts "self-hosting Logseq."
- **Cal.com** encryption-key warning is flagged in multiple places (inputs, env vars, gotchas) because it's the worst kind of bug — silent until upgrade-day when every user's calendar integration breaks with no recovery. OAuth setup steps for Google / Microsoft / Daily included since calendar integrations are the whole point.
- **Payload** recipe notes the open-core reality (everything on GitHub is MIT, Payload Cloud is managed hosting not a feature paywall) — different from Cal.com's EE-for-some-features model. Documented 6 storage adapters + 4 DB adapters.

**Cumulative progress:** 59 / 1274 done (4.6%). 1215 pending.



## 2026-04-29 07:53–08:30 UTC — batch 9

**Context:** Woke up at 59/1274 done (previous batches 7-8 — ran in other sessions I wasn't present for — covered 25 additional apps between my batch 6 and now).

**Processed (5):** Puter, Paperless-ngx, cobalt, Appsmith, PhotoPrism.

**Upstream sources consulted:**
- Puter: `README.md` + `docker-compose.yml` + `Dockerfile` + `doc/self-hosters/instructions.md` on `main`. Self-host docs noted as ALPHA upstream.
- Paperless-ngx: `README.md` + `docker/compose/docker-compose.postgres.yml` on `main`. Referenced upstream `install-paperless-ngx.sh`, docs at `docs.paperless-ngx.com`.
- cobalt: `README.md`, `docs/run-an-instance.md`, `docs/protect-an-instance.md`, `docs/api-env-variables.md`, `docs/examples/docker-compose.example.yml` on `main`.
- Appsmith: `README.md` + `deploy/docker/docker-compose.yml` on `release` branch. Docs site at `docs.appsmith.com` referenced but not scraped.
- PhotoPrism: `README.md` on `develop` + `compose.latest.yaml` (dev compose for reference structure). Canonical prod compose comes from `docs.photoprism.app/getting-started/docker-compose/`.

**Notes:**
- **Puter** recipe leads with upstream's own "ALPHA, not for production" warning. Biggest self-host footgun is the requirement for BOTH `<domain>` AND `api.<domain>` to resolve — documented prominently. Default-user auto-generated password + "change it first" flow called out.
- **Paperless-ngx** recipe hammers the security posture (DO NOT run on untrusted host; documents stored in the clear). Documented the 4 compose variants (postgres/sqlite × with-or-without-tika), UID/GID bind-mount pitfalls, `PAPERLESS_URL` requirement behind reverse proxy, and the `document_exporter` as the upstream-recommended backup method.
- **cobalt** recipe reframed the app's stateless nature (no cache, no persistence, "fancy proxy"). Documented the ethics statement from upstream verbatim, the mandatory Turnstile/API-key bot-protection for public instances, the major-version pin (`:11` not `:latest`), and the `FORCE_LOCAL_PROCESSING` bandwidth footgun.
- **Appsmith** recipe covers CE (Apache-2.0) vs EE (proprietary) split. Biggest footgun: encryption password/salt are write-once; rotating them makes all stored datasource credentials un-decryptable. Documented `appsmithctl backup` / `appsmithctl ssl` / `appsmithctl restore` commands, single-container vs Helm-chart trade-off.
- **PhotoPrism** recipe covers Docker Compose, Pi-specific tuning (`PHOTOPRISM_DISABLE_TENSORFLOW=true`), bare-metal tar.gz path. Documented the originals-as-source-of-truth model, the `PHOTOPRISM_SITE_URL` trailing-slash gotcha, `AUTH_MODE=public` danger, the TensorFlow memory floor, and the WebDAV endpoint.

**Cumulative progress:** 64 / 1274 done (5.0%). 1210 pending.



## 2026-04-29 08:53–09:30 UTC — batch 12

**Context:** Woke up at 64/1274. Batches 10-11 (ran in other sessions overnight) added 10 apps between my batch 9 and now.

**Processed (5):** Novu, Outline, IT-Tools, Headscale, ToolJet.

**Upstream sources consulted:**
- Novu: `README.md` + `docker/community/docker-compose.yml` + `docker/community/.env.example` on `next` branch.
- Outline: `README.md` + `docker-compose.yml` (dev-only — just Postgres+Redis, no Outline) + `.env.sample` on `main`.
- IT-Tools: `README.md` on `main`. Trivial project — one-container static SPA.
- Headscale: `README.md` + `config-example.yaml` on `main` + `docs/setup/install/container.md` (community-maintained per upstream's own disclaimer).
- ToolJet: `README.md` + `docker-compose.yaml` (dev-only with platform:linux/x86_64 explicit) + `docs/docs/setup/docker.md` on `main`. Production compose lives at `tooljet-deployments.s3.us-west-1.amazonaws.com` (external S3 bucket).

**Notes:**
- **Novu** recipe hammers on the 3 mandatory secrets (`JWT_SECRET`, `NOVU_SECRET_KEY`, `STORE_ENCRYPTION_KEY`) with the subtle `STORE_ENCRYPTION_KEY` must-be-exactly-32-chars trap documented in gotchas — hex of 16 bytes = 32 hex chars, which is non-obvious. Architecture walked through 9 services (mongo/redis/api/worker/ws/web/embed/widget/localstack). Flagged localstack as dev-only and self-host-lags-cloud reality.
- **Outline** recipe prominently fronts the "root `docker-compose.yml` is NOT production — it's just Postgres+Redis" footgun because new self-hosters routinely run it expecting Outline to start. Wrote a BYO compose template using `outlinewiki/outline`. Flagged BSL license constraint (no resale-as-service), mandatory OAuth/OIDC (no username+password), and the `FORCE_HTTPS=true` + no-TLS-terminator redirect-loop. Included full Google + generic OIDC setup steps.
- **IT-Tools** was the shortest recipe in the forge to date. Single `docker run -p 8080:80 corentinth/it-tools` — no config, no secrets, no DB, no state. Positioned honestly: "everything runs client-side." Called out GPL-3.0 (copy-left) vs MIT distinction, and the "cannot be deployed on a subpath without rebuild" Vite base-config gotcha.
- **Headscale** is the most operationally complex of the batch. Recipe covered: mandatory public HTTPS (Tailscale clients refuse plaintext), DERP strategy tradeoffs (embedded / external / self-hosted), the `server_url` exact-match requirement, private-key irreplaceability (`private.key` + `noise_private.key`), v0.23 user-model migration, ACL HuJSON format, pre-auth-keys vs OIDC node registration, and the "no web UI upstream" reality. Flagged Taildrop/Funnel/multi-tailnet as cloud-only.
- **ToolJet** recipe covered 3 compose paths (quick-eval single-container, built-in-DB compose, external-PG compose). Biggest footgun flagged: `TOOLJET_HOST` MUST include scheme (`http://` / `https://`) — users miss this constantly. `LOCKBOX_MASTER_KEY` irreplaceability + `SECRET_KEY_BASE` rotation semantics. Documented ToolJet DB vs app DB separation (v2+ feature). CE-vs-EE image mixing warning (they can't interoperate on the same DB).

**Cumulative progress:** 69 / 1274 done (5.4%). 1205 pending.

