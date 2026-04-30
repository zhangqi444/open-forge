
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



## 2026-04-29 09:23–09:45 UTC — batch 13

**Processed (5):** Portainer, qBittorrent, Sunshine, Reactive Resume, Mattermost.

**Upstream sources consulted:**
- Portainer: `develop` README (for feature framing + CE-vs-BE context). Deploy details from `docs.portainer.io/start/install-ce` canonical install docs (well-known patterns).
- qBittorrent: `master` README (pointer-only — real install docs live in `INSTALL` + wiki). LinuxServer.io image shape from their published docs.
- Sunshine: `master` README (rich — gamepad + encoder compat matrix, install-method table). Docs on `docs.lizardbyte.dev`.
- Reactive Resume: `main` README + `compose.yml` on `main` — full 4-service stack (postgres + browserless + seaweedfs + reactive_resume + init job). Docs on `docs.rxresu.me`.
- Mattermost: `master` README (server repo) + `mattermost/docker` repo's `docker-compose.yml` + `README.md`. Canonical install lives in the `mattermost/docker` repo, not the server repo.

**Notes on framing:**
- **Portainer** — Flagged the 5-minute admin-bootstrap timeout (the #1 Portainer support question) and the CE-vs-Business license split. Added `--admin-password-file` seeding as the automated path.
- **qBittorrent** — Framed honestly around `qbittorrent-nox` (not the GUI) and the fact that **upstream ships no official Docker image** — LinuxServer.io is community, not upstream. Added the Gluetun VPN-sidecar pattern since that's the dominant self-host shape for public trackers. Documented the default `admin/adminadmin` credentials footgun and the recent random-password behavior.
- **Sunshine** — Wrote up as what it is (game stream host, NOT remote desktop), documented the many install paths, and put the "headless Linux = no display = no streaming" gotcha front-and-center because it's the #1 confusion for "stream from my basement server" setups. Also HDR combo requirements (Windows + RTX + HDR10 display + client).
- **Reactive Resume** — Recipe leads with the 4-service architecture since that confuses new users. Documented the `APP_URL` vs `PRINTER_APP_URL` trap (the #1 cause of "blank PDF output") and the chromedp/headless-shell alternative printer. Noted `BROWSERLESS_TOKEN: change-me` default as a must-override.
- **Mattermost** — Covered Docker (upstream-recommended via `mattermost/docker`), Ubuntu .deb (bare metal), and the TE vs EE license split. Flagged the bind-mount UID 2000 requirement, the "first user becomes SysAdmin" bootstrap, and that Calls require dedicated UDP ports that reverse proxies don't handle. Included `mmctl` section for CLI-based admin.

**Cumulative progress:** 74 / 1274 (5.8%). 1200 pending.



## 2026-04-29 09:53–10:30 UTC — batch 14

**Context:** Woke up at 74/1274 (other sessions added batches 7-13 between my batch 6 at 04:35 and now).

**Processed (5):** Umami, Trilium Notes, 1Panel, Directus, Nextcloud.

**Upstream sources consulted:**
- Umami: `README.md` + `docker-compose.yml` on `master`. Docs point at <https://umami.is/docs>.
- Trilium Notes: `README.md` + `docker-compose.yml` on `main` of `TriliumNext/Trilium` (the active fork; zadam/trilium archived early 2024). Docs at <https://docs.triliumnotes.org>.
- 1Panel: `README.md` on `master` of `1Panel-dev/1Panel` (dev branch has no top-level README; default branch detection via probe). Install script at `resource.1panel.pro/v2/quick_start.sh`.
- Directus: `directus/readme.md` (README moved to package subfolder on main; no top-level README). `docker-compose.yml` on `main` is explicitly dev-only debug harness — production compose lives at <https://docs.directus.io/self-hosted/docker-guide>.
- Nextcloud: `nextcloud/server` README + `nextcloud/docker` README + `nextcloud/all-in-one` readme. Three distinct first-party install paths — made all three explicit in the recipe.

**Notes:**
- **Umami** recipe hammers the `APP_SECRET=replace-me-with-a-random-string` default (upstream ships it in compose.yml) and the `admin`/`umami` default credentials. Documented ad-blocker evasion via `TRACKER_SCRIPT_NAME` + `COLLECT_API_ENDPOINT`. Included v1→v2 migration gotcha.
- **Trilium Notes** recipe leads with the zadam/trilium → TriliumNext fork transition since that's the #1 confusion now. Covered server+desktop-client sync topology (most users miss that sync is client-pulls-from-server over HTTPS with cert validation — self-signed fails without a client toggle). Protected-notes client-side encryption irrecoverability flagged.
- **1Panel** recipe is unusual — it's a host-level control plane, not a containerized app. I framed it honestly: "pick one meta control plane per server" with explicit conflict list (CasaOS, cPanel, aaPanel, YunoHost, Coolify, Dokploy, CapRover). Also noted that 1Panel's marketplace prominently features **OpenClaw** as an AI agent runtime and Ollama for local LLMs — that's us in the wild, nice to see. Flagged the "random port + security path is defense-in-depth, not security" reality.
- **Directus** recipe front-loads the license-revision-in-progress warning (community thread at <https://community.directus.io/t/directus-license-revision-community-feedback-requested/2125>). Critical footgun flagged: the root-of-repo `docker-compose.yml` is a multi-DB dev harness (PG+MySQL+MariaDB+MSSQL+Oracle+MinIO+MailDev+Cockroach+Keycloak all at once), NOT production. Many self-hosters use it and wonder why their VPS is ruined.
- **Nextcloud** recipe is the longest so far (328 lines) because there are THREE legitimate install paths — AIO (Nextcloud GmbH's recommendation), `nextcloud/docker` (community, expert-only per upstream's own warning), and Helm. Wrote all three explicitly because the "which path?" question dominates self-host Nextcloud support. Also the trusted_domains + OCC + trusted_proxies + overwriteprotocol trio — #1 source of broken reverse-proxy deploys — got its own section.

**Cumulative progress:** 79 / 1274 done (6.2%). 1195 pending.



## 2026-04-29 10:53–11:45 UTC — batch 15

**Processed (5):** CyberChef, File Browser, PostHog, Keycloak, Glance.

**Upstream sources consulted:**
- CyberChef: `README.md` on `master` of `gchq/CyberChef`. Simple static SPA — README has all the install info needed (prebuilt image + build-yourself + release zip).
- File Browser: `README.md` on `master` of `filebrowser/filebrowser` (short — points at filebrowser.org). Docker compose files at root are 14-byte 404s. Critical find: the README's "Project Status" section documents **maintenance-only mode** as of early 2026 per hacdias' blog post. Active fork `gtsteffaniak/filebrowser` noted for users wanting ongoing features.
- PostHog: `README.md` on `master` (marketing-heavy but has the deploy-hobby one-liner). Actually fetched and inspected `bin/deploy-hobby` — revealed the "**⚠️ You REALLY need 8GB or more of memory**" warning that contradicts the README's "4GB recommended." Also saw `POSTHOG_SECRET` + `ENCRYPTION_SALT_KEYS` auto-generation.
- Keycloak: `README.md` on `main` (short — CNCF project, points at keycloak.org/documentation). Pulled the Quarkus Dockerfile for version context.
- Glance: `README.md` on `main` — rich, 446 lines. Has inline compose snippets, full config examples, and "Common issues" + "FAQ" sections that I mined for gotchas.

**Notes:**
- **CyberChef** is the simplest recipe to date (187 lines) — no state, no secrets, no DB, no auth. 100% client-side. Emphasized the "no config" nature, flagged the upstream's own "crypto operations should not be relied upon for security" disclaimer, and the localStorage history leak.
- **File Browser** recipe leads with the maintenance-only upstream reality because that's the #1 consideration for new deploys in 2026. Recommended the `gtsteffaniak` fork as the active alternative while still documenting both paths. Flagged the default-password footgun (older images) vs. the random-password-in-logs footgun (newer images), the `user:` / ownership trap for bind-mounts, the share-links-are-unauth design decision, and the "Execute Command" RCE feature.
- **PostHog** recipe front-loaded the 8GB RAM / 100k-events-per-month reality. Upstream is explicit that self-host is a "hobby deploy" and Cloud is the recommended path above small scale — I documented this honestly. Covered the 10+ service stack (Postgres + ClickHouse + Kafka + ZK + Redis + MinIO + Nginx + Certbot + Temporal + plugin-server + workers) so users understand the ops burden. Distinguished MIT-licensed core vs. `ee/` proprietary directory; pointed at `posthog-foss` mirror for pure FOSS users.
- **Keycloak** recipe (328 lines — tied with Nextcloud for longest) covered the serious-tier auth platform cleanly. Distinguished the post-v17 Quarkus vs. pre-v17 WildFly builds (old guides mentioning `standalone.xml` are wrong now). `start` vs `start-dev` distinction prominent. Reverse-proxy headers are Keycloak's #1 support issue — dedicated the largest gotcha section to `KC_PROXY_HEADERS=xforwarded` + matching proxy-side config. Covered bootstrap-admin → delete-after-claiming pattern, realm design (don't use `master` for your users), OIDC vs SAML client modeling, Infinispan caching in HA, and the native-image tradeoffs.
- **Glance** recipe covered the 3 install paths (upstream docker-compose-template, manual compose, binary + systemd) and the 4 custom-widget mechanisms (iframe / html / extension / custom-api). Upstream README's own "Common issues" section gave me 3 excellent gotchas (Pi-hole rate limits, Dark Reader layout breakage, nested pages YAML trap) verbatim from maintainer docs. Docker socket mount security implications for the `docker-containers` widget explicitly flagged.

**Cumulative progress:** 84 / 1274 done (6.6%). 1190 pending.



## 2026-04-29 11:24–12:05 UTC — batch 16

**Processed (5):** AdGuard Home, Dokploy, restic, Frappe/ERPNext, Web-Check.

**Upstream sources consulted:**
- AdGuard Home: `README.md` on `master`, and `scripts/install.sh` (verified what the one-liner actually does — systemd unit, `/opt/AdGuardHome/` layout, port 53 preflight).
- Dokploy: `README.md` on `canary`, plus the actual `dokploy.com/install.sh` (inspected in full — revealed that the one-liner does `docker swarm leave --force`, reinits Swarm, creates `/etc/dokploy` with `chmod 777`, launches Postgres/Redis/Dokploy as Swarm services + Traefik as a `docker run`. Pins `docker 28.5.0` and `traefik:v3.6.7`).
- restic: `README.md` on `master`. Fairly thin — restic's real docs are at <https://restic.readthedocs.io>. Pulled command patterns + backend list from README.
- Frappe/ERPNext: ERPNext app `README.md` (marketing-heavy), the `frappe_docker` repo's `README.md`, AND `compose.yaml` (to enumerate the actual 10+ services: configurator, backend, frontend, websocket, queue-short, queue-long, scheduler + db/Redis via overrides + create-site job).
- Web-Check: Default branch is `master`, but `README.md` lives at `.github/README.md` (resolved via GitHub's `/readme` API). Root `docker-compose.yml` is a tiny stub. README is long and rich (1333 lines); mined the Deployment + Configuring sections for the full env-var list + 1-click deploy URLs.

**Notes:**
- **AdGuard Home** (285 lines) — gave full weight to the port 53 conflict problem (the #1 install failure, per every support forum for AG Home + Pi-hole), documented the `network_mode: host` vs `bridge` tradeoff (bridge breaks per-client rules), and the DHCP coexistence footgun. Included a side-by-side comparison table with Pi-hole since users usually ask "which one?" Covered encrypted DNS (DoH/DoT/DoQ) both for upstream (AG calling resolvers) and downstream (AG serving phones) use cases — AG's best differentiator.
- **Dokploy** (200 lines) — recipe led with "install.sh is destructive of existing Docker state" because that's the #1 thing users don't realize. It `docker swarm leave --force`s and reinits Swarm, capturing ports 80/443/3000. Documented the exact Swarm service layout from the install script. Emphasized `/etc/dokploy` being `chmod 777` as a deliberate upstream choice. Called out that the Docker socket mount on both `dokploy` and `dokploy-traefik` means two containers with root-on-host. Not-well-known tip: `DOCKER_SWARM_INIT_ARGS` for AWS VPC CIDR collisions.
- **restic** (317 lines) — the longest so far. Treated this as the "foundational backup tool" recipe because the forge will want to reference it from many other recipes (every app needs backups). Covered binary install, all backends, REST server as a self-host pattern, systemd timer template, excludes template, cron alternative. Heavy emphasis on "lose the password = lose data forever" — printed in bold, mentioned 3 times because users still lose their password. Pre-0.15 prune slowness, `--pack-size` for huge repos, `bench backup` pattern for live databases, exit code 3 = partial-success quirk.
- **Frappe/ERPNext** (264 lines) — front-loaded the "this is heavyweight" reality (10+ containers, 8GB RAM comfort). Documented the overrides-based compose approach which is non-obvious (base `compose.yaml` alone won't boot — needs at least a DB override + Redis override). `pwd.yml` demo-only warning prominent. `bench` CLI examples, multi-site, backup-via-`bench`, custom-apps-require-rebuilding-image gotcha, version-skipping prohibition. ERPNext and Frappe are a deeply integrated pair — recipe treated them as one thing (which they are in practice).
- **Web-Check** (205 lines) — simple stateless container, but the recipe spent real space on ethical / legal gotchas: running port scans + traceroute against targets you don't own can trip IDS/WAF, and your IP is on the hook. Also flagged that `REACT_APP_*` API keys are client-visible (in browser bundle) → use read-only scoped keys. Netlify/Vercel timeout-vs-Docker trade-off. No-auth-by-default public-exposure footgun.

**Cumulative progress:** 89 / 1274 done (7.0%). 1185 pending.



## 2026-04-29 12:24–13:00 UTC — batch 17

**Processed (5):** Medusa, Nginx Proxy Manager, Glances, Dokku, SeaweedFS.

**Upstream sources consulted:**
- Medusa: `README.md` on `develop` (thin — it's mostly marketing + "go see the docs"), plus the actual install pages from the docs repo (`www/apps/book/app/learn/installation/page.mdx` and `docker/page.mdx`). The README alone is unsuitable for writing an install recipe; needed the docs mdx files.
- Nginx Proxy Manager: `README.md` on `master` (good self-contained install section with compose snippet). Root `docker-compose.yml` at the path I tried was empty — turns out upstream keeps the reference compose inline in the README + at <https://nginxproxymanager.com/setup/>. Used the README's snippet as canonical.
- Glances: `README.rst` on `master` (RST, 688 lines). Extracted install methods, pip extras matrix, Docker tags (`latest-full`, `latest`, `ubuntu-latest-full`, `dev`), and the canonical Docker run commands for console/web modes.
- Dokku: `README.md` on `master` (116 lines — short, points at dokku.com/docs). Key extract: the exact `bootstrap.sh` install command with a pinned version (`v0.37.10`) and the prereq list (Ubuntu 22.04/24.04 or Debian 11+).
- SeaweedFS: `README.md` on `master` (657 lines, rich). Plus `docker/seaweedfs-compose.yml` (59 lines) — used as the reference production topology.

**Notes:**
- **Medusa** (233 lines) — front-loaded architecture explanation because "Medusa" isn't obvious (headless commerce with a modules-based backend + Admin SPA + optional Next.js storefront). Documented both `create-medusa-app` CLI (Node-native) and `dtc-starter` Docker paths. Flagged that upstream's README is intentionally minimal (points at docs + Cloud) so the real install reference is the docs site, not GitHub. `workerMode` + CORS gotchas + Next.js Starter Storefront Node v25 incompatibility called out.
- **Nginx Proxy Manager** (243 lines) — the classic "reverse proxy with a GUI" recipe. Heavy emphasis on the default `admin@example.com` / `changeme` credentials footgun, the armv7-dropped-in-2.14+ gotcha (must pin `:2.13.7` for old Pis), Let's Encrypt HTTP-01 requiring port 80 open, and shared Docker networks for container-to-container proxying. Compared vs. Traefik/Caddy/HAProxy at the top.
- **Glances** (277 lines) — long but mostly because of breadth. Covered all 7 modes (console / web / RPC / central browser / exporter / MCP / pip), the full pip extras matrix (18 options), Docker image tag variants, and 30+ exporter destinations. MCP server for AI assistants is new-ish (introduced as a pip extra) — included. Main gotchas: `pip install glances` without `[web]` extra silently lacks web UI; `--password` prompts interactively; `pid: host` + Docker socket = root on host.
- **Dokku** (241 lines) — SSH/CLI-first PaaS contrast with Dokploy/CapRover/K8s at top. Documented `bootstrap.sh` with pinned version, post-install checklist (global domain, SSH keys, postgres plugin, letsencrypt), `git push dokku main` deploy pattern, Procfile + buildpacks + Dockerfile + compose deploy modes, scaling, env vars. Gotchas: single-host no-HA, dokku-postgres isn't production-grade, buildpack cache fills disk, LE rate limits.
- **SeaweedFS** (309 lines) — the heaviest recipe in the batch because SeaweedFS has a lot of moving parts (master + volume + filer + S3 + WebDAV + mount, each a separate process optionally). Architecture-in-one-minute section up front. Covered replication placement encoding (`000`/`001`/`110`/etc.), erasure coding, tiered storage to cloud, filer metadata store options (leveldb / Postgres / Cassandra / TiKV), and the production topology (3 masters for Raft, 3+ volume servers, 1-2 filers with external DB). Gotchas include no-auth defaults, single-master SPOF, async erasure coding, and memory footprint scaling with volume count.

**Cumulative progress:** 94 / 1274 done (7.4%). 1180 pending.



## 2026-04-29 12:54–13:40 UTC — batch 18

**Processed (5):** Frigate, InfluxDB, changedetection.io, Czkawka, ntfy.

**Upstream sources consulted:**
- Frigate: `README.md` on `dev` branch (83 lines — mostly screenshots + marketing; points at docs.frigate.video). Plus `docker-compose.yml` (44 lines — it's the DEV container compose, not production; still useful for device passthrough / group_add patterns). Relied on general Frigate knowledge + upstream-confirmed detector/hardware matrix.
- InfluxDB: README on BOTH `main` (v3 Core) AND `main-2.x` (v2) branches — upstream documents the three-version situation in the README itself. Got the version-compatibility matrix + storage engine differences from there.
- changedetection.io: `README.md` on `master` (357 lines — rich) + `docker-compose.yml` (148 lines with extensive inline env-var comments). README explicitly documents the Docker + Docker Compose install path, notification URL examples, filter types, and the new LLM-powered rules feature.
- Czkawka: `README.md` on `master` (208 lines). Covers all 4 frontends (Krokiet, Czkawka GTK, Czkawka CLI, Cedinia Android) + the comparison table with FSlint/DupeGuru/Bleachbit. Upstream makes clear Krokiet is the new-GUI successor with Czkawka GTK in bugfix-only mode.
- ntfy: `README.md` on `main` (277 lines but 95% is the sponsor list — actual content ~50 lines pointing at ntfy.sh/docs/install/). Used general ntfy knowledge + documented the canonical install/config patterns.

**Notes:**
- **Frigate** (244 lines) — front-loaded the "hardware requirements are non-trivial" reality. Without an AI accelerator, CPU-only inference doesn't scale. Google Coral supply-constraint flagged (notoriously hard to find in stock). Intel iGPU via OpenVINO is the practical alternative. Distinguished FFmpeg hw decode vs AI accelerator (two separate hardware paths). `shm_size` sizing formula documented. 0.14+ auth-mandatory change called out with port 8971 vs 5000 distinction. Home Assistant integration via MQTT emphasized.
- **InfluxDB** (338 lines, longest in batch) — **three active versions** make this the trickiest recipe so far. Wrote a proper version-decision-tree early. Flux removal in v3 is the biggest breaking change for existing users with Flux-heavy Grafana dashboards. Covered install paths for all three versions + per-version data layouts + backup commands + upgrade paths (v1→v2 via `influxd upgrade` CLI, v2→v3 via line-protocol compatibility + data export). Cardinality-explosion TSM trap + "Port 8086 is universal but overloaded" gotcha + "Flux doesn't work in v3" front-and-center.
- **changedetection.io** (279 lines) — covered the standalone Docker run + the docker-compose-with-sockpuppetbrowser pattern needed for JS-rendered pages. Apprise notification URL examples for 12+ services. Filter types: CSS / XPath / JSONPath / jq / regex. New-as-of-2026 LLM-powered rules section (per-site "notify only when X" intent, powered by LiteLLM supporting OpenAI/Gemini/Anthropic/Ollama). Key gotchas: no default password, `USE_X_SETTINGS=1` required behind reverse proxies, sites actively blocking scrapers (Cloudflare/PerimeterX).
- **Czkawka** (270 lines) — not a server app (it's a desktop utility), so recipe structure differed: four frontends (Krokiet / Czkawka GTK / CLI / Cedinia Android) each with install paths. CLI section got the most detail because that's the only automation-relevant frontend. Delete-method modes (`aen`/`aeo`/`hl`/`hlo`) documented with the safety advice to ALWAYS dry-run with `--delete-method none` first. Czkawka GTK noted as bugfix-only per upstream, Krokiet recommended for new users.
- **ntfy** (292 lines) — HTTP-based pub-sub notification service. Covered public `ntfy.sh` tier vs self-host tradeoffs. Example curl publish + subscribe patterns. User + ACL setup via CLI. The honest Firebase FCM story (without FCM Android's WebSocket can be killed by aggressive battery optimizers; FCM requires rebuilding the Android app). The iOS-requires-Apple-APNs-relay-via-ntfy.sh reality (self-host doesn't fully escape ntfy.sh dependency for iOS users). Inbound SMTP server for email-triggered notifications. Web Push requires HTTPS + `behind-proxy: true` sanity check.

**Cumulative progress:** 99 / 1274 done (7.8%). 1175 pending. One more batch takes us past 100 done.



## 2026-04-29 13:23–14:00 UTC — batch 19 🎉 crossed 100

**Processed (5):** Homepage (gethomepage), Postiz, SearXNG, Jitsi Meet, Chatwoot.

**Upstream sources consulted:**
- Homepage: README on `main` (178 lines but mostly banner/feature-list) + `docs/installation/docker.md` (58 lines — the canonical install doc). README-root `docker-compose.yaml` returned 404; docs file has the real compose example.
- Postiz: README on `main` (145 lines — mostly sponsor banners) + `docker-compose.yaml` (hefty, ~200 lines, all env vars inline) + fetched `gitroomhq/postiz-docs` repo for quickstart.mdx + installation/docker-compose.mdx (362 lines, matches main repo's compose with RUN_CRON addition) + configuration/reference.mdx. Temporal stack with ElasticSearch adds the bulk.
- SearXNG: main repo's `README.md` was 404 (weird); `searxng-docker` repo has been DEPRECATED per its own README — points to main repo's `container/` dir ("compose-instancing"). Fetched `docs/admin/installation-docker.rst` (206 lines, canonical) + `container/docker-compose.yml` (28 lines, minimal) + `container/.env.example` (15 lines).
- Jitsi Meet: `jitsi-meet` README is 87 lines (mostly marketing, points to handbook). `docker-jitsi-meet` README (39 lines) + its `docker-compose.yml` (521 lines!) + `env.example` (242 lines) provided the real install details. Handbook URL: jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker.
- Chatwoot: `develop` branch README (139 lines — good feature list) + `docker-compose.production.yaml` (62 lines — canonical prod compose, minimal structure with base YAML anchor) + `docker-compose.yaml` (dev, irrelevant). Official docs at chatwoot.com/docs/self-hosted.

**Notes on each recipe:**
- **Homepage** (245 lines) — the standout gotcha: `HOMEPAGE_ALLOWED_HOSTS` is MANDATORY since v1.0 — without it, app returns 403. This is the #1 "why doesn't my upgrade work?" support question. Covered Docker auto-discovery via labels, `HOMEPAGE_VAR_*` / `HOMEPAGE_FILE_*` env var substitution, dashboard-icons integration, and no-built-in-auth reality (needs reverse-proxy auth layer).
- **Postiz** (321 lines, longest in batch) — multi-service stack with Temporal + ElasticSearch adds complexity. 4 databases total (Postiz PG + Temporal PG + ES + Redis). OAuth redirect-URL setup is the primary onboarding pain. Migration warning for v2.11.2 → v2.12.0 Temporal change. Acknowledged AGPL copyleft for SaaS resellers. Twitter/X API paid-tier reality called out.
- **SearXNG** (303 lines) — the DEPRECATED `searxng-docker` repo trap is addressed front-and-center; new installs MUST use `container/` compose-instancing from the main repo. Added migration section for users of the deprecated repo. `secret_key` mandatory, `image_proxy: true` for privacy, Valkey (Redis fork) as default KV store. Public-vs-private-instance table distinguishing operational requirements.
- **Jitsi Meet** (273 lines) — front-loaded the "UDP 10000 + NAT" reality with an ASCII port table; this is the #1 cause of "joined the meeting but can't hear/see anyone." `JVB_ADVERTISE_IPS` required for NAT setups. Cloud firewall rules for UDP are the common blocker on AWS/GCP/Azure. Jibri (recording) + Jigasi (SIP) called out as separate resource-heavy components. E2EE limited to ≤4 participants in production.
- **Chatwoot** (318 lines) — pgvector-based Postgres is the important detail (plain `postgres:16` fails migration if Captain AI is on). `REDIS_PASSWORD` URL-encoding footgun. Inbound email routing is the hardest part of any Chatwoot deploy. Multi-tenant signup (`ENABLE_ACCOUNT_SIGNUP`) must be disabled for single-tenant internal deploys. Helm chart available for k8s.

**Milestone: 100+ done.** 104 / 1274 (8.2%). 1170 pending. Consistent batch-of-5 cadence holding up; 100 crossed in ~19 batches over the past ~3 weeks (per backlog on earlier sessions).



## 2026-04-29 13:53–14:35 UTC — batch 20

**Processed (5):** NanoClaw, Wiki.js, Grafana Loki, Budibase, Authelia.

**Upstream sources consulted:**
- NanoClaw: README on `main` (194 lines — fully substantive, not a placeholder). Real upstream project by `qwibitai/nanoclaw`, positioned explicitly as a minimalist MIT-licensed alternative to OpenClaw. No docker-compose at root (not its distribution model; it's a workstation-install-via-`nanoclaw.sh` tool). No fabrication — recipe strictly follows README content.
- Wiki.js: root README (527 lines — mostly sponsor/donation banners + changelog) has minimal install info; real canonical install doc is in separate `requarks/wiki-docs` repo at `master` branch, `install/docker.md` (196 lines). Got full Docker Compose + Docker run + env-var + LE examples from there. Upstream explicitly warns against `:latest` tag. v2 vs "v3 Next" reality documented.
- Loki: README on `main` (140 lines — good pointer-to-docs content). Noted the March 2026 Helm chart fork to `grafana-community/helm-charts` for OSS users (from the README). Fetched `production/docker-compose.yaml` (64 lines) — the canonical single-binary dev compose. Grafana docs at grafana.com/docs/loki/latest/ as the actual documentation home.
- Budibase: README on `master` (197 lines — hybrid product positioning as "AI operations platform" w/ `@budibase/cli`). Fetched `hosting/docker-compose.yaml` — 7-container stack (app-service + worker-service + proxy-service + minio + couchdb + redis + litellm-service). `hosting.properties` (env file) also fetched for full env-var list. GPL-3.0 license.
- Authelia: README on `master` (483 lines — lots of badges, actual substance ~50 lines). Fetched `examples/compose/lite/compose.yml` (109 lines — canonical Traefik + Authelia lite example). Rich upstream docs at authelia.com; OIDC Provider support noted (beta-stable in 2026).

**Notes on each recipe:**
- **NanoClaw** (219 lines) — Interesting case: it's an explicit minimalist competitor/alternative to OpenClaw by user `qwibitai`. MIT-licensed. Treated honestly per upstream positioning ("small enough to understand, secure by isolation"). Not a server — installs on user workstation via `nanoclaw.sh` bootstrap. Architecture is Node host process + per-session Docker containers running Bun + Claude Agent SDK, SQLite inbound/outbound databases for message passing. Config-file-less design (customization = Claude Code editing source). Channels installed via `/add-<channel>` skills from `channels` branch; providers via `providers` branch. Docker Sandboxes micro-VM option documented. Gotchas: not server-deployable, fork-drift risk, no multi-user, depends on OneCLI Agent Vault + Claude Code tooling.
- **Wiki.js** (302 lines) — v2-vs-v3 reality front-and-center ("v3 has been in development for years; v2 is current stable — use v2"). `:latest` explicitly warned against per upstream docs. 10+ install methods documented. Database backend matrix (Postgres recommended). Docker + Docker Compose + env-var + config.yml + Let's Encrypt built-in paths all covered. Git sync feature noted. AGPLv3 license.
- **Loki** (327 lines, longest in batch) — Explained the key design tradeoff upfront ("no full-text indexing on content, only labels → 10-100x cheaper than ELK, but queries without label filter are slow"). Three deploy modes (monolithic / simple-scalable / microservices). High-cardinality labels = #1 footgun documented. March 2026 Helm chart fork to `grafana-community/helm-charts` for OSS users called out (per upstream README). Compactor + retention nuances. Alloy (current) vs Promtail (feature-complete).
- **Budibase** (249 lines) — 7-container stack (app + worker + proxy + minio + couchdb + redis + litellm). LiteLLM integration for AI agents (new 2026 positioning — "AI Agents that run your operations"). 5+ mandatory secrets (JWT_SECRET, MINIO_ACCESS_KEY/SECRET_KEY, INTERNAL_API_KEY, API_ENCRYPTION_KEY) all stable-one-way. CouchDB as app-metadata store (unusual choice). GPL-3.0.
- **Authelia** (374 lines, longest-ever in forge) — Front-loaded the ForwardAuth concept with "how it works in 30 seconds." Covered the Traefik lite example verbatim from upstream. Full `configuration.yml` sample with access_control rules + session + storage + notifier sections. OIDC Provider mode covered for apps that speak OIDC (Grafana/Nextcloud/Gitea/etc.). Parent-domain cookie SSO mechanic called out as the primary architectural constraint. 20+ gotchas including the storage.encryption_key rotation danger and the Redis-for-HA requirement.

**Cumulative progress:** 109 / 1274 done (8.6%). 1165 pending.



## 2026-04-29 14:25–14:55 UTC — batch 21

**Processed (5):** Cloudreve, ArchiveBox, KeePassXC, Kestra, SigNoz.

**Upstream sources consulted:**
- Cloudreve: root README (76 lines — mostly a features bullet + pointers to docs); no compose in main repo. Real deploy docs live in separate `cloudreve/docs` repo (`en/overview/deploy/docker-compose.md`, 92 lines) and the canonical compose in separate `cloudreve/docker-compose` repo (46 lines + 6-line `.env.example`). Community + Pro editions explained upstream.
- ArchiveBox: README (1607 lines — massive) + `docker-compose.yml` at repo root (195 lines, well-commented with optional overlays for noVNC / Pi-hole / WireGuard / ChangeDetection / PYWB). Sonic full-text search now in-container (no longer separate sidecar); orchestrator/scheduler also in-container.
- KeePassXC: README (69 lines); NOT a server app — desktop app only. Honest recipe pivots to self-hosting-the-KDBX-file patterns (Nextcloud/Syncthing/WebDAV sync).
- Kestra: README (250 lines) + `docker-compose.yml` (65 lines, Postgres + Kestra server-standalone). Strict basic-auth password policy (email format + ≥8 chars + uppercase + number) documented verbatim in compose.
- SigNoz: README (244 lines) + `deploy/docker/docker-compose.yaml` (185 lines, 6 services) + `.env` (1 line). ClickHouse 25.5 + Zookeeper + SigNoz app + OTel Collector + migrator + init-clickhouse (UDF fetcher). Default `SIGNOZ_TOKENIZER_JWT_SECRET=secret` is a real INSECURE default present in upstream — front-loaded as critical gotcha.

**Notes on each recipe:**
- **Cloudreve** (271 lines) — Multi-cloud storage abstraction explained upfront (10+ providers). Pro-vs-Community edition distinction. Called out `POSTGRES_HOST_AUTH_METHOD=trust` as insecure default. Noted the Dockerfile bundles libreoffice + ffmpeg + vips + libraw (~1.5 GB image). Aria2 BT ports 6888 TCP/UDP + NAT. `TZ=Asia/Shanghai` hardcoded in Dockerfile — override required.
- **ArchiveBox** (265 lines) — Explained what outputs per snapshot (HTML/PDF/screenshot/DOM/WARC/yt-dlp media/plaintext). `ALLOWED_HOSTS=*` + `CSRF_TRUSTED_ORIGINS` gotchas front-loaded. Disk growth reality ("10K snapshots = 100-1000 GB"). Chromium profile via noVNC for authenticated-site archiving. Full env var table. Optional overlays (Pi-hole/WireGuard/PYWB/ChangeDetection) documented from upstream compose.
- **KeePassXC** (247 lines) — Honest treatment: this is a desktop app, NOT a server. The "self-hosting" angle = syncing the `.kdbx` file. Recipe covers all install methods (native binaries + flatpak + homebrew + winget), master-key strategies (password / +keyfile / +YubiKey / paranoid-triple), syncing strategies (Nextcloud/Syncthing/rclone/git), mobile clients (KeePassDX/KeePassium/Strongbox), browser integration. Clear warning "if you want web-based multi-user, use Bitwarden/Vaultwarden instead."
- **Kestra** (322 lines) — Three deploy modes (server local / server standalone / distributed). Docker socket mount security warning front-loaded (anyone who can submit a flow = root on host). Strict basic-auth password policy called out. Enterprise-vs-OSS feature matrix (OIDC/SAML/RBAC = paid). Git integration via `SyncFlows` task. Task runners matrix (process/docker/kubernetes/serverless).
- **SigNoz** (241 lines) — 6-container stack explained. `SIGNOZ_TOKENIZER_JWT_SECRET=secret` default is genuinely insecure — critical gotcha. ClickHouse memory/disk sizing guide. Retention = cost. Init container fetches `histogram-quantile` UDF from GitHub releases — air-gapped gotcha. OTel-native (nothing SigNoz-specific in SDKs). Vendor-lock-in honesty (no easy data export). vs Datadog/NewRelic positioning.

**Cumulative progress:** 114 / 1274 done (8.9%). 1160 pending.



## 2026-04-29 15:23–15:40 UTC — batch 22

**Processed (5):** RustFS, Infisical, Ente Auth, Ente Photos, Actual Budget.

**Upstream sources consulted:**
- RustFS: README (16 KB — detailed positioning vs MinIO, full feature status table, 6 install methods) + `docker-compose.yml` (271 lines, w/ 3 profile groups: default/observability/proxy/dev).
- Infisical: README (13 KB) + `docker-compose.prod.yml` (49 lines, flagged `# PIN THIS TO A SPECIFIC TAG`) + `.env.example` (142 lines — rich env-var reference incl. OAuth providers).
- Ente (both Photos + Auth): monorepo `ente-io/ente`. README (137 lines) + `server/compose.yaml` (110 lines, explicitly labeled "not meant for production use") + `docs/docs/self-hosting/installation/` (quickstart.md 46 lines + compose-doc.md 83 lines + env-var.md 60 lines + requirements.md 41 lines). Auth and Photos share the same Museum backend — documented as such in both recipes.
- Actual Budget: README (pointer-to-docs) + `actual-server` README (flags Feb 2025 repo merger into `actualbudget/actual` `packages/sync-server`) + `docker-compose.yml` (tiny, 23 lines — env vars all commented out by default).

**Notes on each recipe:**
- **RustFS** (248 lines) — Upfront comparison table vs MinIO reflecting upstream's own positioning language. Hedged honestly ("these are RustFS's own claims; MinIO is mature at scale"). Distributed mode's 🚧 status called out as key trade-off vs MinIO. Container UID 10001 chown gotcha front-loaded. Default `rustfsadmin`/`rustfsadmin` credentials flagged as critical vulnerability. 3 compose profiles (observability / proxy / dev) documented.
- **Infisical** (314 lines) — Free vs Enterprise feature matrix split clearly (SSO/SAML/SCIM/RBAC/IP-allowlist = paid). `ENCRYPTION_KEY` + `AUTH_SECRET` sample values from `.env.example` flagged as genuinely PUBLIC — many self-hosters leave them default. CLI-vs-SDK injection trade-off explained. vs Vault vs Doppler framing.
- **Ente Photos** (285 lines) — 3-container stack (Museum + Postgres + MinIO + socat workaround for presigned URL resolution). `quickstart.sh` vs compose-from-source paths. 3 hardcoded bucket names (`b2-eu-cen` / `wasabi-eu-central-2-v3` / `scw-eu-fr-v3`) called out — don't rename without editing museum.yaml. Compose file's "not meant for production use" disclaimer respected. E2EE means recovery is impossible by design.
- **Ente Auth** (184 lines) — Cross-referenced shared architecture with Photos. Made clear: hosted Auth is FREE forever (no reason to self-host Auth alone); if self-hosting, same stack as Photos; or use offline-only mobile apps. 3 install paths explicit. Port :3003 for web UI. Custom-server-URL "long-press sign in" gotcha documented (easy to miss).
- **Actual Budget** (263 lines) — Local-first architecture explained upfront vs Firefly III's client-server model. Electron desktop apps are a valid no-server option. Feb 2025 repo consolidation (`actual-server` → `actual/packages/sync-server`) called out. Bank sync via GoCardless (EU/UK) or SimpleFIN (US/Canada). E2EE is per-budget opt-in. PikaPods + Fly.io managed alternatives at $1.40-1.50/month mentioned.

**Cumulative progress:** 119 / 1274 done (9.3%). 1155 pending.



## 2026-04-29 15:53–16:10 UTC — batch 23

**Processed (5):** Valkey, WireGuard Easy (wg-easy), Zulip, Project N.O.M.A.D., Karakeep.

**Upstream sources consulted:**
- Valkey: README (394 lines — heavy on build-from-source; covers TLS/RDMA/systemd/libbacktrace/Lua build flags + testing). Docker Hub tag list (`8.2.x` / `8.1.x` / `8.0.x` / `7.2.x` + -alpine/-bookworm/-trixie variants). Positioning vs Redis OSS 7.2.4 was explicit.
- wg-easy: README (126 lines — points at docs site for real install guidance). `docker-compose.yml` (44 lines — v15 with IPv6, cap_add NET_ADMIN + SYS_MODULE, sysctls for IP forwarding, IPv4/v6 dual-stack network). Upstream docs site at wg-easy.github.io for specifics.
- Zulip: repo README (80 lines — terse, points at readthedocs). docker-zulip repo README (62 lines) + docs/how-to/compose-*.md (compose-getting-started 68 lines, manual/docker-compose 65 lines, compose-settings 159 lines, compose-ssl 176 lines, compose-secrets 143 lines). Note: `docker-compose.yml` is NOT at the repo root — `ci/base.yaml` + overlay files per use case. Image MOVED from docker.io/zulip/docker-zulip (legacy, 11.x only) to ghcr.io/zulip/zulip-server:12.0-0.
- Project N.O.M.A.D.: README (158 lines — feature table, hardware tiers, no-auth security philosophy verbatim). `install/management_compose.yaml` (121 lines — 4 services: admin/dozzle/mysql/redis, explicit "replaceme" placeholders required). Inspected for docker socket mount (admin container has full host access).
- Karakeep: README (125 lines) + `docker/docker-compose.yml` (44 lines — 3 services: web/chrome/meilisearch). `docs/docs/02-installation/01-docker.md` (89 lines — canonical install walkthrough with .env file contents).

**Notes on each recipe:**
- **Valkey** (290 lines) — Positioned as drop-in Redis 7.2.4 fork (BSD 3-clause vs Redis's SSPL post-2024). Feature-parity table. Migration path (stop Redis → copy dump.rdb → start Valkey). Explicit note that Redis modules (RediSearch/RedisJSON/etc.) are NOT in Valkey — there are separate projects (valkey-search, valkey-json). Managed offerings (AWS ElastiCache, GCP Memorystore) called out as Valkey-compatible now. Cluster + Sentinel mode protocol identical.
- **wg-easy** (245 lines) — v14 → v15 rewrite front-loaded as breaking. Verbatim docker-compose.yml with cap_add NET_ADMIN + SYS_MODULE explained (`SYS_MODULE` is unusual). IP forwarding sysctls required on host. UDP port-forwarding caveat for NAT hosts. "All client private keys stored on server" threat model explicit — UX trade-off. Podman NET_RAW note. 2FA + OIDC + one-time links + client expiration + per-client firewall v15 features. Caddy/Traefik reverse proxy (only for TCP :51821; UDP :51820 is raw WG).
- **Zulip** (251 lines) — Two install paths (standard installer recommended; Docker Compose "moderately increases effort" per upstream). Image migration (docker.io/zulip/docker-zulip → ghcr.io/zulip/zulip-server:12.0-0). Channels + topics model front-loaded as differentiator. Heavy stack (Postgres + RabbitMQ + Redis + memcached + Nginx). Realm = org concept. Zulip Push Notification Service caveat for self-hosted mobile push. Standard installer + certbot one-liner.
- **Project N.O.M.A.D.** (249 lines) — HONEST security caveat front-loaded: NO AUTH BY DESIGN + upstream explicitly says "not for public internet." Docker socket mount in admin container = full host access. Debian/Ubuntu-only constraint. Hardware tiers (min 4 GB RAM; optimal 32 GB + RTX 3060+). Bundled apps list explicit (Kiwix/Kolibri/Ollama/Qdrant/ProtoMaps/CyberChef/FlatNotes/Dozzle). `replaceme` placeholders in compose explicitly enumerated. Install script + uninstall script + helper scripts. Compared to IIAB/Endless/RACHEL/LibreMesh. Roadmap auth request link included for users who need auth.
- **Karakeep** (281 lines) — 2024 rename from Hoarder flagged prominently (old image deprecated). Verbatim compose (3-service: web/chrome/meilisearch). AI providers: OpenAI vs Ollama vs LM Studio vs none. `release` tag vs pinned version for upgrades — pin in prod. Browser extension + native mobile apps. Full-page archival storage (~1-5 MB per bookmark) disk-usage warning. Comparison vs Linkwarden/Readeck/Wallabag/Shiori. Meilisearch version-compat caveat on upgrades. vs Pocket (shut down 2024) + Omnivore (shut down 2024) positioning.

**Cumulative progress:** 124 / 1274 done (9.7%). 1150 pending.


## 2026-04-29 — Batch 24 (5 recipes + 1 skipped)

- **dashy** (24850★) — single-container Node/Vue dashboard. Pinned `lissy93/dashy:3.1.1`; flagged no-server-auth + config hot-reload quirks.
- **netbird** (24822★) — WireGuard mesh with Signal/Management/Relay/coturn + bundled Zitadel IdP. Recommended upstream installer over hand-rolled compose; documented UDP NAT-traversal realities.
- **plausible** (24690★) — Community Edition repo (`plausible/community-edition`), NOT the main `plausible/analytics` repo (flagged the 2024 rename). Postgres 16 + ClickHouse 24.12, four required ClickHouse overlay XMLs, TOTP_VAULT_KEY permanence warned.
- **monica** (24568★) — Laravel 10 personal CRM. Apache variant recommended; documented `APP_KEY` permanence, required `php artisan setup:production` post-deploy, DB password double-set trap.
- **firefly-iii** (23085★) — personal finance manager. 3-service compose (core + mariadb + cron sidecar); flagged `STATIC_CRON_TOKEN` exactly-32-char requirement, `APP_KEY` permanence, MariaDB vs Postgres swap path.
- **dub** (23454★) — **SKIPPED**: upstream `docker-compose.yml` is explicitly local-dev-only ("Do not use this in production"); no production self-hosting guide published. Would require fabrication to write a recipe.

Running totals: 129 done / 1 skipped / 1144 pending (1274 total).

## 2026-04-29 — Batch 27 (5 recipes)

- **node-red** (23065★) — Node.js low-code flow editor. `nodered/node-red` Docker image; recommended `:4.1.8` pin. Flagged no-auth-default + `credentialSecret` must be set before storing secrets. `/data` volume uid/gid 1000 perm warning.
- **dockge** (23016★) — compose-native stack manager (Uptime Kuma author). Canonical `/opt/stacks` left-path-equals-right-path trap explained in depth. Docker socket = root-equivalent warning front-loaded. 1-admin-only / no RBAC noted.
- **nocobase** (22221★) — no-code plugin platform on Postgres/MySQL/MariaDB/SQLite. Use `docker/app-postgres/docker-compose.yml`, NOT repo-root compose (dev-only with verdaccio/kingbase/adminer). APP_KEY + ENCRYPTION_FIELD_KEY permanence warned. Bumped upstream's `postgres:10` to `postgres:16`.
- **chartdb** (22069★) — static SPA diagram editor. No backend, no DB; localStorage only. Flagged build-time-vs-runtime `VITE_` env trap for self-hosted LLMs; analytics-on-default; AGPL. Export warning because localStorage evaporates easily.
- **activepieces** (21950★) — MIT workflow automation, app + worker + pg + redis. Pinned mixed-version-tags gotcha (upstream ships app:0.80.1 + worker:0.79.0 — harmonize). AP_ENCRYPTION_KEY permanence. pgvector image required for AI-memory pieces. `AP_EXECUTION_MODE=UNSANDBOXED` single-tenant caveat.

Running totals: 134 done / 1 skipped / 1139 pending (1274 total, 10.6%).

## 2026-04-29 17:53 UTC — Batch 25 (5 recipes)

- **mkdocs** (22025★) — honest pivot: framed as a **static site generator**, not a self-hosted service. Four paths documented: pip + nginx (recommended), `squidfunk/mkdocs-material` Docker build-tool, `gh-deploy`, CI build. Flagged `mkdocs serve` = dev only, don't expose. `site_url` subpath trap, Material theme vs Insiders licensing, plugin version-skew warning.
- **vector** (21727★) — Rust observability pipeline from Datadog. Agent vs aggregator roles explained up front. 4 install paths: deb/rpm, binary, Docker (`timberio/vector`), official Helm. `data_dir` mandatory + `buffer.type:disk` for durability warned front. VRL is its own language. API port 8686 unauthenticated — firewall. Docker-logs source socket mount = root-equivalent.
- **matomo** (21459★) — Apache variant compose from `matomo-org/docker/.examples/apache`. MariaDB auto-upgrade + skip-upgrade-backup documented. **Trusted Hosts** footgun flagged. Browser-archiving-doesn't-scale → CLI cron example. GeoLite2 license-key requirement post-MaxMind 2019 change. `:Z`/`:z` SELinux label note for non-RHEL hosts.
- **beszel** (21417★) — PocketBase-based monitoring hub. Architecture diagram: hub pulls from agents over SSH ed25519. Compose variants: hub-only, agent-only, same-system. GPU variants (`-nvidia`/`-intel`). Hub SSH key = trust root (backup warning). Agent socket mount hardening note with `docker-socket-proxy`. Pre-1.0 version-pinning emphasized. Upstream Helm chart at `supplemental/kubernetes/beszel-hub`.
- **authentik** (21232★) — IdP/SSO. 3-service compose (postgresql/server/worker) — documented the Redis-service removal migration for pre-2024.4 users. Year-based versioning (`2026.2.2` current). Secret-key permanence, outpost-needs-Docker-socket, double-underscore env-var convention, initial-setup flow world-accessible footgun, blueprints startup-reconcile GitOps note.

Running totals: **139 done / 1 skipped / 1134 pending** (1274 total, 10.9%).

## 2026-04-29 — Batch 27 (5 recipes)

- **teable** (21177★) — no-code DB on real PostgreSQL. Standalone compose (app + pg 15.4 + prisma-migrate sidecar). Flagged demo-creds-in-upstream-`.env`, exposed host port 42345 default, app+migrate-image-lockstep requirement, telemetry opt-out.
- **safeline** (21094★, chaitin/SafeLine) — multi-service WAF (Postgres + mgt + detector + Tengine + Luigi + FVM + Chaos). Upstream one-liner installer preferred; Tengine uses `network_mode: host` (owns 80/443); `SUBNET_PREFIX=169.254.0` link-local caveat; `resetadmin` runbook note; China-region image prefix path.
- **wordpress** (21070★) — Docker Library image (upstream GitHub repo is SVN mirror, not source of truth). Reference compose w/ MySQL 8. Auto-generated salts → pin via 8 env vars; `WORDPRESS_DB_NAME` must pre-exist; `X-Forwarded-Proto` requirement; permissions UID 33 Debian vs 82 Alpine CLI.
- **wekan** (20911★) — Meteor/Mongo kanban. Single-node MongoDB **replica set required** (change-streams); 190+ env vars in upstream compose; first-user-is-admin; `ROOT_URL` exact-match; FerretDB alternative noted; upgrade = `rm wekan-app` only, never the DB container.
- **navidrome** (20743★) — Go music server, Subsonic API. Minimal 1-container compose; read-only root FS + UID mapping; transcoding needs ffmpeg (in image, not binary); SQLite on local disk only (not NFS); first-user-admin; Caddy + Traefik overlay composes noted.

Running totals: 144 done / 1 skipped / 1129 pending (1274 total, 11.3%).

## 2026-04-29 — Batch 25 (5 recipes)

- **neko** (20705★) — WebRTC virtual browser / shared desktop. Flagged WebRTC UDP reality (52000-52100/udp), mandatory `NEKO_NAT1TO1` for VPS NAT, `shm_size: 2gb` requirement, v2→v3 env-key rename (`NEKO_PASSWORD` → `NEKO_MEMBER_MULTIUSER_*`), ICE-Lite vs TURN tradeoff, GPU acceleration via `.nvidia` variants + nvidia-runtime.
- **pangolin** (20451★) — Fossorial identity-aware reverse proxy + WireGuard. 3-service stack (pangolin/traefik/gerbil). Installer-binary preferred over hand-edited compose. CE (AGPL) vs EE (Fossorial Commercial License, free under $100K rev) positioning. NET_ADMIN + SYS_MODULE on Gerbil trust boundary. Wildcard DNS mandatory. Newt clients at remote sites.
- **netbox** (20375★) — IPAM/DCIM source-of-truth. Use `netbox-docker` repo **release branch**, NOT main. Pointed out password-double-set trap across 4 env files, `ALLOWED_HOSTS` default `*`, `API_TOKEN_PEPPER_1` rotation cost (re-issue all tokens), two-redis-not-one design (queue + cache), plugin build-at-image-time requirement. Postgres 18 default — noted downgrade path to 16.
- **teleport** (20194★) — **No upstream docker-compose for the cluster.** Recipe pivots to package+systemd (recommended) and Helm for K8s/HA; Docker is documented but for demos only. One-major-version-at-a-time upgrade rule. CA keys + cluster-name permanence. SQLite vs HA backend reality check. AGPL Community vs Enterprise feature split called out (SSO to major IdPs is EE-only).
- **docmost** (19945★) — Notion-style collab wiki. 3-service compose (Node + Postgres 18 + Redis 8). Flagged `APP_SECRET` permanence (JWT signing), Postgres-password-double-set trap, **Redis `maxmemory-policy=noeviction` mandatory** for Y.js collab integrity, WebSocket passthrough requirement for real-time editing, S3 storage switch doesn't migrate existing files, telemetry on by default.

Running totals: 149 done / 1 skipped / 1124 pending (1274 total, 11.8%).

## 2026-04-29 — Batch 28 (5 recipes)

- **nginx-proxy** (19820★) — docker-gen + nginx combo. Flagged `:latest`/`:alpine` as production-hostile (per upstream), acme-companion pairing, socket-mount risk, multi-container variant, and real-IP-header footgun.
- **listmonk** (19803★) — Go newsletter manager with Postgres. Two-underscore env naming pattern, `--config ''` flag, bounce-processing gap, Postgres password locked at init, AGPL.
- **snapdrop** (19713★) — acquired by LimeWire 2023; front-loaded the maintenance status + **PairDrop** as the active fork. Dev compose regenerates self-signed certs daily; `X-Forwarded-For` critical to prevent cross-tenant peer-visibility bug.
- **cadvisor** (19091★) — Google's container advisor. Covered privileged-mode need, `/dev/kmsg` mapping, cardinality trim flags, gcr.io→ghcr.io image move in v0.53.0, K8s double-count risk, cgroup v2 since v0.46.0.
- **invidious** (18953★) — YouTube front-end. Documented companion pairing (now ~required), Quay-not-Docker-Hub image location, `:latest` rolling-tag justification given YouTube churn, AGPL, official hosted instances shut down 2024 after Google C&D.

Running totals: 154 done / 1 skipped / 1119 pending (1274 total).

## 2026-04-29 — Batch 29 (5 recipes)

- **ebook2audiobook** (18758★) — ebook→audiobook TTS pipeline. Multi-accelerator image matrix (cpu/cu118-128/rocm/xpu/jetson); upstream compose uses `profiles: [cpu/gpu]`. Flagged: GPU flavor must match CUDA major version; MPS not exposed in Docker; first run downloads multi-GB models; Gradio UI has no auth; legal scope (DRM-free only) front-loaded.
- **bookstack** (18718★) — Laravel wiki with book/chapter/page hierarchy. Upstream does NOT ship an image; recipe uses community-standard `lscr.io/linuxserver/bookstack` + MariaDB. Flagged: default admin creds `admin@admin.com/password`, `APP_URL` exact-match requirement, APP_KEY permanence, SSO requires editing `.env` not env vars.
- **bitwarden** (18501★) — Official self-hosted server via `bitwarden.sh` installer. ~10-container stack (nginx/web/api/identity/admin/events/icons/notifications/attachments/mssql). Flagged: amd64-only (SQL Server), 4GB+ RAM, `bitwarden.sh update` regenerates compose (customize via `./bwdata/env/*.override.env`), installation ID+Key required (free), license gated for Organizations, Vaultwarden positioned as lightweight ARM-friendly alternative.
- **etherpad** (18278★) — Real-time collaborative text editor. Node.js + Postgres 15 upstream compose. Flagged: default admin password `admin/admin` in upstream compose (must override), `DEFAULT_PAD_TEXT` cannot be empty (upstream bug), WebSocket passthrough required, `TRUST_PROXY=true` behind proxies, no built-in auth (pad URLs are the security boundary), `etherpad-lite` → `etherpad` rename, plugin quality varies.
- **linkwarden** (18109★) — Bookmark manager with full-page archiving + AI tagging. 3-service compose (linkwarden/postgres 16/meilisearch 1.12.8). Flagged: **upstream compose missing `MEILI_MASTER_KEY`** (Meilisearch runs with random key each boot, breaking reconnect), `NEXTAUTH_URL` must include `/api/v1/auth`, first user = admin race, 1-5 MB per archived link (20-50 GB/10k links), SSRF-safe private network block by default. Positioning vs Pocket/Omnivore (both shut down 2024).

**Cumulative progress:** 159 / 1274 done (12.5%) + 1 skipped. 1114 pending.

## 2026-04-29 — batch 30 (5 recipes)

- **fail2ban** (17636★) — host-level IPS; upstream ships no Docker image. Recipe covers distro-package + systemd as primary path, crazymax/fail2ban container as Docker-host alternative. Front-loads `ignoreip`-lockout risk, `DOCKER-USER` vs `INPUT` chain confusion, `network_mode: host` + `NET_ADMIN/NET_RAW` requirements, and the botnet-immunity limitation (pair with CrowdSec for distributed attacks).
- **overleaf** (17615★) — LaTeX collaborative editor. Honest recipe: "do not hand-roll compose, use `overleaf/toolkit`". Architecture-in-one-minute explains toolkit's modular compose fragments. Captures Server-Pro-vs-CE line, Docker-socket trust boundary (sibling containers run as host root equivalent), Mongo 8.0 pin, 8–10 GB image size.
- **asciinema** (17225★) — terminal-recording host. Apache-2.0. Upstream docs-site is Docker-Compose-first with HTTPS (Caddy) and HTTP-only variants. Flags email-link-only login (log access == admin access if SMTP down), `SECRET_KEY_BASE` rotation = session invalidation, full-text search leaks terminal contents.
- **koel** (17117★) — Laravel music streamer. Two compose templates (MariaDB / Postgres). Security front-loads the public-default admin `admin@koel.dev` / `KoelIsCool` and the `APP_KEY` loss = data loss trap. Covers `docker exec php artisan koel:scan` for rescans, streaming methods (PHP/x-sendfile/x-accel), Plus-paid-features.
- **calibre-web** (17023★) — Flask ebook UI. Upstream explicitly points to `lscr.io/linuxserver/calibre-web` for Docker; pip install for bare metal. Security front-loads default `admin`/`admin123`, `DOCKER_MODS=universal-calibre` is x86_64-only, SQLite-on-NFS "database is locked" trap, OPDS unauth leak, PUID/PGID mismatches on shared libraries.

**State:** 164 done / 1 skipped / 1109 pending (12.9%). Past 17k stars. Next slice: post-17k-star apps (17000 → 16k band).

## 2026-04-29 — batch 31 (5 recipes)

- **victoriametrics** (16884★) — TSDB/monitoring. Architecture-in-one-minute covers the 8+ components (`victoria-metrics`, `vmagent`, `vmalert`, `vmauth`, `vmbackup`/`vmrestore`, `vmctl`, plus `vminsert`/`vmstorage`/`vmselect` for cluster). Upstream ships `compose-vm-single.yml` (full stack w/ Grafana+Alertmanager+vmalert) and `compose-vm-cluster.yml`. Front-loads: no built-in auth on :8428 (delete-series API is an open gun), retention is global (enterprise-only per-metric), PromQL ≠ MetricsQL (VM has extensions), enterprise features (downsampling, retention filters).
- **convertx** (16636★) — File-converter web UI wrapping 20+ CLIs (FFmpeg/ImageMagick/Calibre/LibreOffice/Pandoc/Inkscape/Vips…). Single-container deployment. Front-loads: first-visitor-to-`/register` becomes admin (bootstrap race), `JWT_SECRET` must be set (else UUID regen every boot invalidates sessions), `HTTP_ALLOWED=true` disables HTTPS-only cookies, 2GB+ image due to toolchain bundling, AGPL-3.0.
- **postal** (16477★) — Outbound mail delivery platform (Sendgrid alternative). Architecture covers `web`/`smtp`/`worker`/`runner` containers + external MariaDB + RabbitMQ. Uses `postal` CLI wrapping docker-compose. Front-loads: port-25 ISP blocks, PTR/SPF/DKIM/DMARC necessity, DKIM `signing.key` backup criticality, v2→v3 one-way migration, outbound-only scope (not a Mailcow replacement).
- **docs-collaboration** (16450★) — La Suite Docs (French gov). Architecture: Django backend (`lasuite/impress-backend`) + Next.js frontend + y-provider (Yjs CRDT WebSocket) + Postgres + Redis + S3 + mandatory OIDC. Upstream's own caveat: "we only run Kubernetes in production; Compose is experimental". Front-loads: OIDC mandatory (no local login), S3 mandatory (no local-disk mode), `PUBLISH_AS_MIT=true` strips GPL PDF export, `frontend` UID 101 volume permissions, y-provider stateful WS needs sticky sessions. Codename `impress` appears throughout image names.
- **apprise** (16443★) — Notification gateway. Two-project split clarified: `apprise` (library+CLI, `pip install`) vs `apprise-api` (self-host Flask+Gunicorn wrapper, `caronc/apprise` image on DH). Three `APPRISE_STATEFUL_MODE` choices (`simple`/`hash`/`disabled`). Front-loads: no built-in auth (never expose direct), token leakage via DEBUG logs, UID/permission trap, service-specific quirks (Matrix `matrixs://` vs `matrix://`, Signal needs external signal-cli-rest-api sidecar).

**State:** 169 done / 1 skipped / 1104 pending (13.3%). Into 16k-star band. Next slice continues descending.

## 2026-04-29 — batch 32 (5 recipes)

- **windmill** (16344★) — Internal-tools/workflow platform (Retool + Airflow + Temporal alt). 8-component architecture documented: `server`/`worker`/`worker_native`/`indexer` (EE)/`extra` (LSP/multiplayer/DAP)/`dind` sidecar/`caddy-l4`/Postgres 16. Front-loads: first signup = admin, default Postgres `changeme`, `:main` tag moves daily, `privileged: true` workers for PID isolation, `WINDMILL_KEY` loss = all secrets unreadable, dind-vs-host-socket trade-off, EE-only features (multiplayer, indexer, dedicated workers).
- **flarum** (16255★) — Forum software; upstream ships no Docker image. Recipe uses `mondedie/flarum` as de-facto community path + documents Composer path for bare metal. Flarum 2.x branch rewrite flagged; extensions API breaking changes between 1.x/2.x. `FLARUM_ADMIN_*` envs trigger installer on every start until DB exists — removal instructions included.
- **maxun** (15532★) — No-code web scraper (Playwright-based). 6-service architecture: Postgres/MinIO/Redis/backend/frontend/browser (isolated Chromium with `SYS_ADMIN`+`seccomp=unconfined`+2GB shm). Front-loads: four-way URL var sync (`BACKEND_URL`/`PUBLIC_URL`/`VITE_BACKEND_URL`/`VITE_PUBLIC_URL`), `ENCRYPTION_KEY` backup criticality (OAuth tokens), default port binding 0.0.0.0 leaks Postgres/MinIO, bot-detection caveat, legal-gray scraping disclaimer, AGPL.
- **apache-answer** (15485★) — Q&A platform (Stack Overflow clone). Single-binary Go; upstream compose is 12 lines, single service. SQLite default, MySQL/Postgres for scale. Front-loads: web-wizard install (no env-driven bootstrap = tricky for IaC), can't migrate DBs post-install, reputation-privilege thresholds need tuning for small communities, spam immediately without CAPTCHA. Recently graduated to Apache TLP (2024).
- **grav** (15466★) — Flat-file PHP CMS (no database). Upstream ships no Docker image; recipe uses `lscr.io/linuxserver/grav`. Admin plugin is separate install; password hashes live in YAML files (not DB). Front-loads: NFS perf hit on flat-file reads, `/config` volume contains entire Grav tree (unlike WP partial mounts), 300-plugin ecosystem vs WP's 60k, Grav 2.x in development with breaking plugin API, content is Markdown+YAML (git-friendly).

**State:** 174 done / 1 skipped / 1099 pending (13.7%). Still in 15k-star band. Next slice continues descending.

## 2026-04-29 — batch 33 (5 recipes)

- **mail-in-a-box** (15280★) — Ubuntu 22.04 bash-script mail appliance (postfix/Dovecot/Nextcloud/Roundcube/nsd/spamassassin/fail2ban/duplicity/nginx/munin). Honest pivot: NOT a Docker app, upstream explicitly rejects Docker. Recipe covers the fresh-Ubuntu-only install path, port-25 ISP reality, PTR requirement, DNSSEC glue records, `secret_key.txt` backup criticality, and deliberately-not-customizable design. Linked iRedMail/Mailu/Mailcow/Modoboa as alternatives.
- **jackett** (15261★) — *arr-stack indexer proxy (500+ torrent/usenet trackers). No upstream Docker image; recipe uses `lscr.io/linuxserver/jackett`. Front-loads: no default admin password (set immediately!), private-tracker cookies can get your account banned, USB 3.0 RF interference trap, Prowlarr as modern alternative. `DataProtection-Keys` backup criticality documented.
- **zigbee2mqtt** (15069★) — Zigbee↔MQTT bridge. Architecture section clarifies: Z2M does NOT ship an MQTT broker, you bring your own. Front-loads: always use `/dev/serial/by-id/` not `/dev/ttyACM0`, `coordinator_backup.json` is your insurance against dead radio, network key must be stable (regenerating = all devices fall off), USB 3.0 2.4GHz interference, permit-join is an attack window, HA add-on vs Docker trade-off.
- **nodebb** (15053★) — Node.js forum (phpBB/Flarum alternative). Architecture walks through MongoDB 7 (default) / Postgres 18 / Redis-as-primary via Compose profiles. Front-loads: default creds `nodebb/nodebb` in upstream compose, WebSocket reverse-proxy config, `config.json` `secret` stability for sessions, Mongo 7→8 `setFeatureCompatibilityVersion` trap, GPL-3.0.
- **cachet** (15017★) — Status-page system mid-transition between 2.x (stable, Docker-supported) and 3.x (rewrite on Laravel 11, no Docker yet). Recipe documents both paths honestly: 2.x compose for the deployable-today route, 3.x manual install for new deploys. Front-loads: `:latest`/`main` warnings from upstream, default `APP_KEY=${APP_KEY:-null}` session-invalidation trap, PHP 7.x EOL on 2.x, scheduler cron + queue worker requirements. Linked migration guide.

**State:** 179 done / 1 skipped / 1094 pending (14.1%). Entering the 14k-star band next.

## 2026-04-30 — batch 34 (5 recipes)

- **caprover** (14993★) — self-hosted PaaS (Heroku alternative) on Docker Swarm. Architecture section: caprover/caprover is itself a container managing Swarm via mounted docker.sock. Front-loads: default password `captain42`, snap-Docker unsupported, port mappings are hardcoded (80/443/3000), Cloudflare proxy-mode breaks LE, Swarm is in maintenance mode = long-term risk. `/captain/` as single point of state.
- **openproject** (14946★) — Rails PM suite, 9-container compose. Uses `opf/openproject-docker-compose` (stable/17 branch) NOT the dev compose at the root of opf/openproject. Hocuspocus service for collab editing (new in 17.x). Front-loads: upstream default `p4ssw0rd`, `SECRET_KEY_BASE` stability, Postgres default is still 13 (new installs should bump to 17 BEFORE first boot), 4GB RAM minimum.
- **gotify** (14916★) — minimal push-notifications server (Go). SQLite default, App tokens for send / Client tokens for receive. Front-loads: default admin pw `admin` if `GOTIFY_DEFAULTUSER_PASS` not set, WebSocket reverse-proxy headers, single-instance no HA, message history unbounded. Linked ntfy/Apprise/Pushover as alternatives.
- **onedev** (14896★) — Java git+CI+kanban+packages+AI-MCP all-in-one. Upstream develops at code.onedev.io (GitHub is mirror). 2-container compose (onedev + postgres:14). Front-loads: default password `changeit` in TWO places, docker.sock mount = host pwn risk, SSH on non-standard 6611, license changed to MIT in 2022. Alternatives: Gitea+Woodpecker, Forgejo, GitLab CE.
- **freshrss** (14876★) — PHP RSS aggregator. Tiny (runs on Pi 1). Supports SQLite/Postgres/MySQL/MariaDB. Front-loads: `/data/` must NOT be web-exposed (Docker image handles this; manual installs must block), `CRON_MIN` empty = no polling, XPath scrapers are brittle, Fever/GReader/Nextcloud-News APIs for mobile apps. Linked Miniflux/TTRSS/Commafeed as alternatives.

**State:** 184 done / 1 skipped / 1089 pending (14.4%). Crossed into the 14k-star band. Next: `vert` (14692★), `peertube` (14656★), `seafile` (14629★), then below 14500.

## 2026-04-30 — batch 35 (5 recipes)

- **vert** (14692★) — privacy-first browser-side file converter (SvelteKit + WebAssembly) + optional `vertd` daemon (Rust + FFmpeg) for video. Architecture section: two separate repos/containers, `PUB_*` build args are BAKED at build time (not runtime). Front-loads: prebuilt image has localhost:5173 hardcoded; Docker Desktop Win/macOS = no GPU; COOP/COEP headers needed for WASM threads; AGPL-3.0.
- **peertube** (14656★) — federated video platform (ActivityPub + WebTorrent). 6-container compose (peertube + postgres:17-alpine + redis:8-alpine + webserver + certbot + postfix). Front-loads: **`PEERTUBE_WEBSERVER_HOSTNAME` is PERMANENT** (baked into every federated ID), static 172.18.0.42 IP is deliberate, DKIM record must be published from `docker-volume/opendkim/keys/*/*.txt`, AGPL-3.0 copyleft.
- **seafile** (14629★) — high-perf file sync/share with client-side encryption libraries, SeaDoc, optional AI face recognition. CE covered (AGPL-3.0); PE mentioned as commercial. 3 required + several optional containers via `COMPOSE_FILE` chain. Front-loads: default admin pw `asecret`, encrypted libraries have NO admin reset, S3 is PE-only, no CalDAV, file locking is PE-only.
- **librespeed** (14591★) — HTML5 speedtest.net alternative. 3 modes (standalone / backend / frontend for multi-POP). Telemetry off by default. Front-loads: stats page has no auth without `PASSWORD`, GDPR_EMAIL is regulatory not cosmetics, measurement capped by server bandwidth, `OBFUSCATION_SALT` auto-changes on restart = broken old URLs.
- **duplicati** (14500★) — incremental+encrypted+deduplicated backup client (not a storage server). 4 release channels (latest/beta/experimental/canary). Front-loads: **lose passphrase = lose backup forever**, distinct `SETTINGS_ENCRYPTION_KEY` vs per-backup passphrase, historical 2.0.5/2.0.6 data-loss bugs → test restores monthly, default runs as root. Alternatives: Restic, BorgBackup, Kopia.

**State:** 189 done / 1 skipped / 1084 pending (14.8%). Average recipe lengths in batch: vert 195, peertube 179, seafile 194, librespeed 211, duplicati 194.

## 2026-04-30 — batch 36 (5 recipes)

- **lemmy** (14357★) — federated Reddit alternative (ActivityPub). 5-service stack (lemmy + lemmy-ui + pict-rs + postgres pgautoupgrade + postfix + nginx). Recommends the `LemmyNet/lemmy-ansible` playbook over hand-rolled compose. Front-loads: **domain is PERMANENT**, default dev-compose pw `password`, default pict-rs key `my-pictrs-key`, first-user-admin race, CSAM risk + pictrs-safety sidecar, AGPL-3.0. Threadiverse context (Mbin/Piefed).
- **oauth2-proxy** (14270★) — OAuth2/OIDC reverse-proxy / forward-auth middleware. Two deploy patterns documented (reverse-proxy vs forward-auth for nginx/Traefik/K8s). Provider quickstarts (Google/Entra/GitHub/GitLab/Keycloak/Dex/generic OIDC). Front-loads: `cookie_secret` must be 16/24/32 bytes exact, `whitelist_domains` prevents open-redirect, `--provider=azure` deprecated → `entra-id`, distroless base since v7.6. Alternatives: Authelia/Authentik/Pomerium.
- **libretranslate** (14250★) — self-hosted translate API (Argos Translate / OpenNMT under the hood). Two images: `:latest` (CPU) and `:latest-cuda` (NVIDIA GPU). Front-loads: **no rate limit/API key by default** = instant bot flood, loading all languages = OOM (use `LT_LOAD_ONLY`), CUDA image skips healthcheck, CORS allow-all default. Alternatives: DeepL, NLLB-200 + vLLM, Argos CLI.
- **filestash** (14112★) — storage-agnostic file manager (FTP/SFTP/S3/SMB/WebDAV/IPFS/~20 backends). Plugin-driven. Optional Collabora office. Front-loads: first-visitor-to-`/admin/setup` race, Collabora license for >20 users, share links never expire by default, plugin `.so` ABI not stable across versions. Alternatives: Nextcloud, ownCloud Infinite Scale, FileBrowser, Seafile.
- **xpipe** (14044★) — honest pivot: NOT a self-hostable server. Upstream README explicit: desktop app only, runs on your workstation. Documented per-platform installers (Windows MSI/winget/choco, macOS pkg/brew, Linux deb/rpm/AUR). Front-loads: proprietary freemium with open-core, no Docker, needs display, linked alternatives for the actual web-SSH-gateway use case (Guacamole, Teleport, Sshwifty).

**State:** 194 done / 1 skipped / 1079 pending (15.2%). Batch 36 lengths: lemmy 221, oauth2-proxy 239, libretranslate 202, filestash 175, xpipe 175.

## 2026-04-30 — batch 37 (5 recipes)

- **cloudflared** (13999★) — Cloudflare Tunnel client. No-port-forwarding outbound tunnel to Cloudflare edge; remote-managed (dashboard) vs locally-managed (`config.yml`) modes both documented. Front-loads: version-lifecycle policy (supported only within 1y of release), `--no-autoupdate` essential in Docker, TUNNEL_TOKEN = account secret, Cloudflare dependency (domain must be on Cloudflare). Alternatives: Tailscale Funnel, Pangolin, frp, ngrok, Zrok.
- **habitica** (13853★) — gamified habit-tracker RPG. **Honest "self-hosting unsupported" warning front-loaded**: upstream compose is dev-only (Dockerfile-Dev), no release tags, mobile apps hard-coded to habitica.com, content updates don't flow automatically. MongoDB 7 replica set mandatory. Admin promotion is manual via mongosh. Community self-hosting wiki linked.
- **automatisch** (13807★) — open-source Zapier alternative. 4-service stack (main + worker + postgres 14 + redis 7). Same image runs as main or worker via `WORKER=true` env — noted as Windmill-like pattern. Front-loads: pre-1.0 instability, `ENCRYPTION_KEY` loss = OAuth token data loss, `HOST`+`PROTOCOL` baked into OAuth callbacks, first-user-admin race, CE-vs-EE gating, AGPL-3.0. Alternatives: n8n, Activepieces, Huginn, Node-RED, Windmill.
- **sonarr** (13724★) — TV-show PVR in the "arr" stack. **No official Docker image** — LinuxServer.io is de-facto; Hotio alt documented. v4 stable / v5 in `develop` branch. Dedicated "Path mapping" section (the #1 arr-stack gotcha) — Sonarr + download client must see downloads at same path for hardlinks + atomic moves. Front-loads: auth off by default, API key in config.xml = password-grade, v4→v5 DB migration one-way. Alternatives: Radarr/Lidarr/Readarr/Whisparr, Bazarr, Prowlarr, Overseerr.
- **snipe-it** (13712★) — open-source IT asset management. **Repo-rename precedent**: `snipe/snipe-it` → `grokability/snipe-it` (Docker image name unchanged). Laravel + MariaDB 11.4. Front-loads: `APP_KEY` loss = sealed-field data loss, `/setup` must not run twice, email required for password reset, Laravel queue worker not in default compose (needed for bulk ops). Alternatives: GLPI, Ralph NG, iTop.

**State:** 199 done / 1 skipped / 1074 pending (15.6%). Batch 37 lengths: cloudflared 220, habitica 215, automatisch 208, sonarr 170, snipe-it 194.

## 2026-04-30 — batch 38 (5 recipes)

- **flaresolverr** (13672★) — anti-Cloudflare proxy helper for arr stack. Uses real headless Chromium to bypass Cloudflare's "checking your browser". Front-loads: effectiveness is a moving target (Cloudflare Turnstile defeats it often now), `shm_size: 1gb` REQUIRED or Chromium crashes, no auth → never expose publicly. Wiring into Prowlarr + Jackett documented.
- **zitadel** (13646★) — cloud-native IDP (OIDC/SAML/OAuth/passkeys/SCIM). Go + Postgres 17 event-sourced. Front-loads: `ZITADEL_MASTERKEY` must be exactly 32 chars + loss = unrecoverable (encrypts all stored secrets), external domain baked into OIDC issuer URLs, event-sourced DB grows steadily, gRPC requires h2c reverse proxy. Alternatives: Keycloak, Authentik, Authelia, Ory, Casdoor.
- **openvpn** (13617★) — the C source repo. **Honest framing**: not a "run this image" project. Documented distribution paths: Angristan's openvpn-install script, kylemanna/docker-openvpn (aging), Pritunl (management UI), OpenVPN Access Server (commercial). Front-loaded "consider WireGuard first" advisory. Alternatives: WireGuard, Tailscale, Headscale, Netbird, SoftEther, Pritunl.
- **semaphore-ui** (13545★) — modern Ansible/Terraform/Bash/PowerShell task runner. **Name confusion**: NOT the same as semaphoreci.com (SaaS CI). Front-loads: default admin pw `p455w0rd` in upstream compose, default `SEMAPHORE_ACCESS_KEY_ENCRYPTION` in upstream compose is well-known NOT secret (encrypts SSH Key Store), SQLite → Postgres above ~5 concurrent tasks. Server/Runner split pattern documented. Alternatives: AWX, Rundeck, StackStorm.
- **radarr** (13532★) — movie PVR, sibling of Sonarr. Same no-official-Docker norm (LinuxServer.io / Hotio). Dedicated path-mapping section (arr-stack #1 gotcha). Front-loads: v4→v5 auto-migrate, Custom Formats replace release profiles, TMDB metadata source, Minimum Availability setting, v4 stable + v5 on develop. Referenced Trash Guides. Alternatives: Sonarr/Lidarr/Readarr/Whisparr, Watcher3, CouchPotato (dead).

**State:** 204 done / 1 skipped / 1069 pending (16.0%). Batch 38 lengths: flaresolverr 167, zitadel 230, openvpn 204, semaphore-ui 224, radarr 169.

## 2026-04-30 — batch 39 (5 recipes)

- **casdoor** (13497★) — IAM with 50+ prebuilt IdP integrations (Google/Entra/Apple/WeChat/Alipay/Feishu/etc.). Strong in Chinese-market integrations. Front-loads: default admin `admin`/`123` must change, STANDARD vs AIO edition (AIO bundles MySQL in-container; NOT for prod), `origin` setting baked into OIDC callbacks, Casbin engine for authz, fast-moving pre-1.0-style versioning. Alternatives: Zitadel, Keycloak, Authentik, Authelia, Ory, LogTo.
- **metube** (13358★) — yt-dlp web UI. Documented: subscriptions polling, cookies.txt for members-only, `OUTPUT_TEMPLATE`, playlist cap via `DEFAULT_OPTION_PLAYLIST_ITEM_LIMIT`. Front-loads: **no built-in auth** (never expose publicly), YouTube-breakage cadence = stale images 403 quickly, disk exhaustion from uncapped playlists, legal context note. Alternatives: Tube Archivist, Tubesync, Pinchflat.
- **borg** (13248★) — dedup encrypting backup tool. 1.x vs 2.x incompatibility front-loaded. Repo-password = irrecoverable loss. Documented: `repokey-blake2` vs `keyfile-blake2`, `borg compact` required to reclaim space post-prune, append-only mode for ransomware resistance, `borg transfer` for 1→2 migration, borgmatic wrapper. Alternatives: restic, Kopia (same batch), Duplicacy, rsnapshot.
- **crowdsec** (13198★) — crowd-sourced IDS. Agent (log parser, detects) + Bouncers (block, enforce) architecture explained. 6 bouncer types documented (firewall iptables/nftables, nginx, Cloudflare, Traefik, custom). Front-loads: **detects but doesn't block until bouncer installed**, LAPI port 8080 = never public, whitelist yourself to avoid self-ban, reputation gate on new agents. Alternatives: fail2ban, Cloudflare WAF, Wazuh, ModSecurity.
- **kopia** (13099★) — modern Borg/restic sibling. Three modes: CLI, KopiaUI desktop, headless server with web UI. First-class S3/B2/Azure/GCS/SFTP/WebDAV/Rclone backends. Front-loads: repo password unrecoverable, Docker `privileged: true` + `user: 0:0` trade-off for FUSE + read-any-file, TLS cert mandatory for server UI login, maintenance run required to reclaim space, scheduler only runs when process alive. Alternatives: Borg, restic, Duplicacy, rsync.net.

**State:** 209 done / 1 skipped / 1064 pending (16.4%). Batch 39 lengths: casdoor 204, metube 195, borg 239, crowdsec 210, kopia 255.

## 2026-04-30 — batch 40 (5 recipes)

- **coder** (13034★) — self-hosted Codespaces. Server + external provisioners + Terraform templates + agents. Workspaces on Docker/K8s/EC2/Proxmox/etc. Front-loads: **wildcard DNS required** for port-forwarding features, Postgres required for prod, agent token rotates per workspace restart, AGPL core + commercial "Premium" split (prebuilds, SSO groups, HA, audit export). Alternatives: Codespaces, Gitpod, DevPod, Okteto.
- **bentopdf** (12958★) — client-side WASM PDF toolkit. 50+ tools in-browser. Contrasted with Stirling-PDF (server-side). Two image variants (default vs `-simple`). Front-loads: WASM loads from jsDelivr by default (air-gap needs config), dual-licensed AGPL-3.0/$79 commercial, digital-sig CORS proxy is the ONE server-side piece, browser memory cap. AGPL WASM components loaded via CDN not bundled. Alternatives: Stirling-PDF, pdf.js, Documenso.
- **documenso** (12728★) — OSS DocuSign alternative. Dedicated "signing certificate is required, non-negotiable" section (PKCS#12 on disk with UID 1001 ownership). Dev self-signed vs prod AATL-cert path documented. Google Cloud HSM integration mentioned. Front-loads: encryption keys ≥32 chars + unrecoverable if lost, Next.js→Remix migration in progress (env var churn), UID-1001 file ownership, AATL-cert or PDFs show untrusted warning. Alternatives: DocuSeal, OpenSign.
- **wallabag** (12654★) — OSS Pocket. Browser ext + mobile + Kobo + API. Four storage backends documented. Default admin `wallabag`/`wallabag`. SingleFile extension pairing for JS-heavy sites. Front-loads: default creds, public signup ON by default, Graby parser limits with SPA sites, OAuth domain baked into app pairings. Alternatives: Linkwarden, Karakeep, Hoarder, Shiori, Shaarli.
- **mailcow** (12633★) — 15-container mail suite. Dedicated "Hard requirements" section front-loaded (PTR, clean IP, port 25 unblocked, 6 GB RAM, dedicated VPS only). Full DNS checklist with MX/SPF/DKIM/DMARC/PTR/MTA-STS/TLSRPT. `./update.sh` + `./helper-scripts/backup_and_restore.sh` = canonical ops tools. Front-loads: mail hosting is hard, Port 25 blocked on AWS/GCP/Azure, IP-reputation baseline, don't use on Kubernetes. Alternatives: Mailu, Mail-in-a-Box, Poste.io, Stalwart, hosted (Migadu/Fastmail).

**State:** 214 done / 1 skipped / 1059 pending (16.8%). Batch 40 lengths: coder 275, bentopdf 171, documenso 237, wallabag 213, mailcow 234.

## 2026-04-30 04:10 UTC — issues sweep + batch 41 (5 recipes)

### Step 0 (sync)
- `git pull --rebase --autostash` — already up to date (an intervening branch `claude/go-setup-RLDJL` on origin, not merged).

### Step 1 (GitHub issues) — ce8accf
- **#24** (Windows/WSL2 setup): duplicate of #25 (byte-identical body). Marked duplicate in `progress/issues-log.json`; left open — the PAT lacks `issues:write`, can't comment/close via API (got `403 Resource not accessible`). Needs manual close by human.
- **#25** (Windows/WSL2 setup): added `docs/windows-setup.md` (172 lines) — WSL2 + Docker Desktop Option A/B, verification, version requirements, troubleshooting. Linked from README.md. Commit message uses `closes #25`.
- **#26** (marketplace description says "Ghost, more coming"): rewrote `.claude-plugin/marketplace.json` description to reflect current scope. `closes #26`.
- **#27** (stale Git proxy on Windows): covered in `docs/windows-setup.md` troubleshooting — `git config --get http.proxy` detection + bypass (`git -c http.proxy=`) + unset. `closes #27`.
- **PAT limitation recorded**: PAT has `metadata=read` + `contents=write` but not `issues=write`. `closes #N` magic in commit messages did NOT auto-close on push to default branch (only PRs trigger that). All 4 issues remain open on GitHub despite the fix being merged; human or a PAT with `issues:write` needs to close them. Documented in `progress/issues-log.json`.

### Step 2 (selfh.st batch 41) — pending commit
- **audiobookshelf** (12586★) — audiobook + podcast server, Node.js + SQLite. Emphasized the WebSocket reverse-proxy gotcha (biggest support issue), fixed `/audiobookshelf` subpath, Audible AAX decryption caveat, native mobile app beta status. Alternatives: Booksonic, Plex, Kavita, Jellyfin+Finamp.
- **stalwart** (12540★) — modern Rust all-in-one mail (JMAP/IMAP/SMTP/CalDAV/CardDAV/WebDAV). Front-loaded "version is 0.x, expect breakage" + "no webmail included" + "Console logger for Docker (not File)" + "Use `STALWART_RECOVERY_ADMIN` env var to skip log-extracted temp password". Pluggable storage section (RocksDB/Postgres/S3/FDB). Compared to mailcow: ~150 MB RAM vs 6 GB, modern JMAP. Shared mail-hosting prerequisites (PTR, port 25, clean IP). Alternatives: mailcow, Mailu, Mail-in-a-Box, DIY Postfix+Dovecot+Rspamd, DMS.
- **dozzle** (12485★) — Docker log viewer. Agent mode + Swarm mode. File-auth / OIDC / forward-proxy auth matrix. Guarded: mount socket read-only, don't enable actions unless auth is strong, logs aren't persisted (Docker's log driver is). Alternatives: Portainer, Yacht, LazyDocker, ctop, Grafana+Loki.
- **termix** (12394★) — browser SSH + RDP/VNC/Telnet (via guacd 1.6.0) + tunnel mgr + file mgr + Docker mgmt. Front-loaded: centralized SSH access = high-value target (mandate 2FA + VPN/Tailscale + IP allow-list), keep guacd private, WebSocket required. Compared to Guacamole (heavier), Teleport (enterprise), Warpgate (pairs nicely). Native iOS + Android + desktop apps documented.
- **stash** (12248★) — adult content organizer ("Jellyfin for adult"). Included NSFW/legal-notice line. Full `STASH_*` env + 6-volume breakdown (data/metadata/config/cache/blobs/generated). Front-loaded: v0.27 dropped Win7/8/Server 2008/2012, DLNA = host-network mode, scrapers drift, generated/ can be enormous, auth OFF by default (set a password!). Alternatives: Whisparr, MediaCMS.

**Batch 41 lengths:** audiobookshelf 221, stalwart 240, dozzle 243, termix 214, stash 198.
**State:** 219 done / 1 skipped / 1054 pending (17.2%).

## 2026-04-30 04:50 UTC — batch 42 (5 recipes)

### Step 0 (sync)
- `git pull --rebase --autostash` — already up to date (unrelated branch `claude/go-setup-RLDJL` seen on origin but not touching main).

### Step 1 (issues)
- No new issues since last heartbeat. #24, #25, #26, #27 still open on GitHub; all **addressed in code via commit `ce8accf`** (previous heartbeat). Cannot close via API (PAT lacks `issues:write`). Awaiting human manual close.

### Step 2 (selfh.st batch 42)
- **formbricks** (12143★) — OSS Typeform/survey platform. Next.js + Postgres, encryption key ≥32 bytes (unrecoverable if lost), first-user-is-admin + SIGNUP_DISABLED flag. `WEBAPP_URL` permanent. Compared to Tally/Typeform/LimeSurvey/OhMyForm.
- **mealie** (12070★) — recipe manager + meal planner. Default branch `mealie-next`. Both SQLite (1-20 users) and Postgres compose documented from upstream install docs. Front-loaded: **SQLite+NAS=corruption risk** (use Postgres), pin `vX.Y.Z` tag (upstream explicitly recommends), repo rename `hay-kot/mealie` → `mealie-recipes/mealie`. Alternatives: Tandoor, Nextcloud Cookbook, Grocy, Paprika, Cooklang.
- **rybbit** (12025★) — privacy-first analytics (GA4/PostHog/Plausible competitor). Heavy stack: Caddy + Next.js client + Node.js backend + ClickHouse + Postgres. Bundled Caddy profile `with-webserver` vs BYO-proxy. Session replay opt-in + capacity warning. Mapbox token optional for geo. `DISABLE_SIGNUP` + `DISABLE_TELEMETRY` flagged. v0.x churn warning. Alternatives: Plausible, Umami, PostHog, Matomo, GoatCounter.
- **yourls** (11996★) — PHP link shortener since 2009. Official Docker image. Spam + domain-blacklist risk front-loaded; `YOURLS_PRIVATE=true` strongly recommended; 128-char cookie key; Cloudflare Turnstile plugin for public-facing. `YOURLS_SITE` domain = permanent (short URLs are absolute). Compared to Shlink/Kutt/Dub/Polr.
- **sftpgo** (11972★) — SFTP/SCP/FTPS/HTTP/WebDAV server in Go. Detailed Community-vs-Enterprise comparison table (dual-edition model). Pluggable storage (local/S3/GCS/Azure/SFTP/HTTP/Crypt), per-user home on cloud bucket. Front-loaded: preserve host keys across upgrades (else clients see "host key changed" warning), port 2022 vs 22 decision, UID 1000, 3 image variants (full/alpine/distroless), Enterprise for ISO-27001 / high-perf cloud / compliance. Alternatives: openssh-sftp, ProFTPd, MinIO, Nextcloud, rclone serve.

**Batch 42 lengths:** formbricks 202, mealie 219, rybbit 211, yourls 202, sftpgo 216.
**State:** 224 done / 1 skipped / 1049 pending (17.6%).

## 2026-04-30 05:05 UTC — batch 43 (5 recipes)

### Step 0 / Step 1
- Synced (up to date). #24/#25/#26/#27 unchanged (still open; PAT can't close; code already fixed).

### Step 2 (selfh.st batch 43)
- **logto** (11951★) — OSS Auth0/Okta/Clerk alternative. Two-port split (3001 user-facing OIDC, 3002 admin console). Upstream compose is flagged "demo only" — documented prod-style. ENDPOINT is permanent (OIDC `iss` claim). MPL-2.0 license (weaker than AGPL; file-level copyleft). Alternatives: Authelia, Keycloak, Zitadel, Authentik, Casdoor, Ory.
- **planka** (11906★) — Trello clone in Node.js+Postgres. 1337 internal port. `DEFAULT_ADMIN_EMAIL` locks that user from deletion (intentional safety feature). 100+ notification providers via Apprise. Pro tier for fine-grained permissions. Alternatives: Wekan, Kanboard, Vikunja, Nextcloud Deck.
- **docuseal** (11781★) — document signing. Simpler start than Documenso (auto-generates signing cert on first run; SQLite default). Bundled Caddy sidecar compose. Front-loaded: auto-generated cert is self-signed (Adobe shows untrusted); losing `certs/` = unverifiable signatures. Compared DocuSeal-vs-Documenso trade-offs (DocuSeal=easier start, Documenso=more production-minded).
- **adnanh-webhook** (11774★) — Go binary that runs shell commands on HTTP webhooks. Mature maintenance-mode project. NO OFFICIAL DOCKER IMAGE — documented 4 community images per README. Front-loaded: no-auth-if-no-trigger-rule is an RCE, HMAC signature type per provider (GitHub X-Hub-Signature-256, GitLab X-Gitlab-Token), shell-injection hygiene, Docker-socket access = root. Alternatives: n8n, Caddy exec plugin, smee.io, systemd socket activation.
- **amnezia** (11616★) — **unusual**: the "repo" is the CLIENT app, server is deployed BY the client via SSH to your VPS. Purpose-built for censored regions (Iran/China/Russia/Myanmar). Protocol selection guide table (WireGuard vs AmneziaWG vs OpenVPN+Cloak vs XRay+Reality vs Shadowsocks) mapped to threat model. Russian-origin threat-model note. Keenetic router native AmneziaWG support noted. Alternatives: Outline, AlgoVPN, Streisand (dead), PiVPN, wg-easy, Marzban.

**Batch 43 lengths:** logto 197, planka 203, docuseal 219, adnanh-webhook 256, amnezia 165.
**State:** 229 done / 1 skipped / 1044 pending (18.0%).

## 2026-04-30 05:20 UTC — batch 44 (5 recipes)

### Step 0 / Step 1
- Synced. Issues #24-#27 still open — unchanged (PAT lacks issues:write; code fixes already in ce8accf).

### Step 2 (selfh.st batch 44)
- **whoogle** (11491★) — Google search proxy. Upstream compose is hardened (cap_drop ALL, non-root, tmpfs-only). Positioned vs SearXNG (aggregator, heavier) and Kagi/DDG (SaaS). Flagged: Google breaks scrapers regularly, 429 rate limits, basic auth ≠ TLS. Farside integration note for `WHOOGLE_ALT_*` link rewriting.
- **shiori** (11440★) — bookmark manager. Front-loaded: default credentials `shiori`/`gopher` (CHANGE IMMEDIATELY — well-known). SQLite default + optional Postgres/MySQL. Dev compose vs prod image distinction noted. Alternatives: Wallabag, Hoarder/Karakeep, LinkWarden, LinkDing, Readeck.
- **homer** (11300★) — static dashboard. Key security gotcha front-loaded: API keys in config.yml are served to browsers = don't expose without auth. Smart cards poll from browser (CORS on target required). Positioned vs Homepage/Dashy (server-side widgets = no exposure), Heimdall/Organizr/Homarr/Flame.
- **owncast** (11188★) — single-user Twitch-alike. Default creds `admin`/`abc123` front-loaded. RTMP cleartext warning. HLS 10-30s latency NOT low-latency. Bandwidth budget math (bitrate × viewers). Single-user only = deliberate design; each broadcaster = own install. Alternatives: PeerTube, Ant Media, nginx-rtmp, Mirotalk.
- **misskey** (11133★) — feature-rich ActivityPub server. Front-loaded: `url` is PERMANENT federation identity. WebSocket required. First-user-is-admin. Don't run `develop` branch in prod. Object storage strongly recommended. Forks list (Sharkey, Firefish, Iceshrimp, CherryPick, Foundkey). Alternatives: Mastodon, Pleroma/Akkoma, GoToSocial, Pixelfed, Bluesky.

**Batch 44 lengths:** whoogle 178, shiori 200, homer 185, owncast 182, misskey 189.
**State:** 234 done / 1 skipped / 1039 pending (18.4%).

## 2026-04-30 05:35 UTC — batch 45 (5 recipes)

### Step 0 / Step 1
- Synced. Issues #24-#27 unchanged.

### Step 2 (selfh.st batch 45)
- **quickwit** (11114★) — Rust search engine for logs/traces/events. Stateless compute + S3 storage model; Elasticsearch-compat API; Jaeger/OTEL native. Front-loaded: v0.x API unstable, append-only (no UPDATE), HA needs Kafka, metastore Postgres is SPOF. Alternatives: Elasticsearch, Loki, VictoriaLogs, ClickHouse, Signoz, Jaeger.
- **nginx-ui** (11095★) — nginx admin panel. Two deploy modes (bundled-with-nginx Docker image vs native-alongside-existing-nginx). Positioned vs Nginx Proxy Manager (NPM hides nginx.conf, Nginx UI exposes it). Front-loaded: Docker socket = root on host, git-init /etc/nginx for rollback (UI has no rollback), AI features send configs to third-party LLMs. Alternatives: NPM, Zoraxy, Caddy, Traefik.
- **umbrelos** (11078★) — **full OS** (not a container); Debian-based home-server distro. License pivot in 1.0: **PolyForm Noncommercial** (not OSI-OSS) — free for personal use, paid for commercial. Hardware tiers: Umbrel Pro/Home (full support) vs Pi 5/x86 (best-effort). Tailscale-first remote access. Alternatives: CasaOS, Unraid, TrueNAS SCALE, Yunohost, HexOS, Runtipi, Proxmox.
- **seerr** (11049★) — media request manager. **Successor to Jellyseerr** (which forked Overseerr). Lineage front-loaded. Jellyfin/Plex/Emby + Sonarr/Radarr integration. Per-user quotas, 4K separate permission. Migration from Jellyseerr/Overseerr noted. Alternatives: Ombi, Petio, Requestrr, Doplarr.
- **komodo** (11024★) — Docker fleet manager (former "Monitor"). Core + Periphery architecture. GPL-3.0 + (optionally) FerretDB instead of Mongo for SSPL-free stack. Front-loaded: Docker-socket = root, KOMODO_HOST permanence for OAuth, first-user-is-admin, git-sync GitOps pattern, `komodo.skip` label to protect infra containers. Vs Portainer: Komodo wins on git-sync/builds, "no business edition" explicit. Alternatives: Portainer, Dockge, Yacht, Swarm, k8s+Lens, Nomad, CapRover, Rancher.

**Batch 45 lengths:** quickwit 212, nginx-ui 205, umbrelos 170, seerr 199, komodo 196.
**State:** 239 done / 1 skipped / 1034 pending (18.8%).

## 2026-04-30 05:50 UTC — batch 46 (5 recipes)

### Step 0 / Step 1
- Synced. Issues #24-#27 unchanged.

### Step 2 (selfh.st batch 46)
- **datasette** (11008★) — Simon Willison's SQLite-to-website publisher. Framing: "GitHub Pages for datasets." One-liner cloud deploys via `datasette publish <target>`. Plugin ecosystem (~100 plugins). Read-only by default; positioned as publish-tool not edit-tool. Alternatives: Grist (editable), Superset/Metabase (BI), CKAN (gov open-data), NocoDB/Baserow.
- **grist** (11001★) — Airtable alternative with real Python in formulas. Community Edition = full-featured OSS core; commercial extras (audit streaming, SCIM, enterprise admin) clearly enumerated. Front-loaded: **Python formulas = unsandboxed code execution by default** — `GRIST_SANDBOX_FLAVOR=gvisor` required for untrusted users. Positioned vs Datasette (publish vs edit). Alternatives: NocoDB, Baserow, Rowy, Airtable.
- **esphome** (10986★) — YAML → ESP32/8266 firmware, Home Assistant companion. Two-part architecture (dashboard server + device firmware). Split install methods (HA add-on vs Docker vs pip). Open Home Foundation membership noted. Voice Preview Edition + BLE proxying + mmWave radar callouts. Alternatives: Tasmota, WLED, ESPEasy, Arduino/PlatformIO raw, MicroPython.
- **simplex-chat** (10959★) — identifier-less messenger. Recipe focuses on **self-hosting SMP + XFTP servers** (simplex-chat/simplexmq) rather than the clients. Architecture: no user IDs at all, unidirectional disposable queues, clients hold all state. Front-loaded: `server_identity.key` = CRITICAL (losing breaks all users), SMP is short-lived not archive, no server-side message backup. Detailed vs-Signal/Matrix/Session comparison. AGPL-3.0.
- **mosquitto** (10843★) — THE canonical MQTT broker. Eclipse Mosquitto. Backbone of HA + Zigbee2MQTT + ESPHome + industrial. Front-loaded: **2.x changed default from `allow_anonymous true` to `false`** (1.x → 2.x breaking change), port 1883 cleartext, retained-messages persist forever. Minimal mosquitto.conf + ACL examples. Alternatives: EMQX, HiveMQ, VerneMQ, NanoMQ. "Mosquitto is right for 99% of self-hosted installs" — explicit scale advice.

**Batch 46 lengths:** datasette 235, grist 226, esphome 248, simplex-chat 223, mosquitto 259.
**State:** 244 done / 1 skipped / 1029 pending (19.2%).

## 2026-04-30 06:05 UTC — batch 47 (5 recipes)

### Step 0 / Step 1
- Synced. Issues #24-#27 unchanged.

### Step 2 (selfh.st batch 47)
- **gatus** (10784★) — dev-oriented health dashboard; YAML config-as-code. Rich condition DSL (STATUS/RESPONSE_TIME/BODY/CERTIFICATE_EXPIRATION/DNS_RCODE). Breadth: HTTP/ICMP/TCP/DNS/SSH/WS/STARTTLS + 40+ alert providers. Positioned vs Uptime Kuma (Kuma wins on web-UI editing; Gatus on config-as-code + condition DSL). Alternatives: Uptime Kuma, Statping, Upptime (GitHub Actions), Prometheus+Blackbox, Healthchecks.
- **kutt** (10724★) — URL shortener. Front-loaded spam/blacklist prevention: `DISALLOW_ANONYMOUS_LINKS=true`, `DISALLOW_REGISTRATION=true`, CAPTCHA. Noted `kutt.it` TLD suspension (Italian registrar) and `kutt.to` as the working domain. Alternatives: YOURLS, Shlink (strongest analytics), Polr, Dub. Choose-matrix.
- **obsidian-livesync** (10557★) — community Obsidian plugin; recipe focuses on the **backend** (CouchDB / S3 / WebRTC P2P). CORS config is critical (without specific origins = mobile can't connect). CouchDB MUST be TLS for mobile. E2E passphrase loss = data loss. Fly.io is no longer free (noted). livesync-serverpeer/webpeer pseudo-peers for P2P. Alternatives: Obsidian Sync (paid), Syncthing, Remotely Save, git+mobile.
- **linkding** (10522★) — minimal bookmark manager. Auto-archive via single-file-cli (local HTML) OR Wayback Machine. Positioned as "less bloat than Wallabag, more functional than Shiori." Archive feature uses headless Chromium (~500MB spike). Alternatives: Shiori, Hoarder/Karakeep, LinkWarden, Wallabag, Readeck.
- **sonarqube** (10481★) — static code analysis platform. Requires host kernel tuning (`vm.max_map_count=524288`, `fs.file-max=131072`) — front-loaded as #1 gotcha. Default `admin`/`admin` → forced password change on first login. Postgres MANDATORY since 7.9 (SQLite/MySQL/Oracle/MSSQL removed). Editions comparison (CE vs Developer/Enterprise/Data Center — C/C++/Swift only in paid tiers; branch analysis + PR decoration paid-only). Alternatives: Semgrep, Qodana, DeepSource, CodeQL, Snyk Code.

**Batch 47 lengths:** gatus 268, kutt 217, obsidian-livesync 244, linkding 197, sonarqube 225.
**State:** 249 done / 1 skipped / 1024 pending (19.5%).

## 2026-04-30 06:20 UTC — batch 48 (5 recipes)

### Step 0 / Step 1
- Synced. Issues #24-#27 still open (PAT lacks issues:write).

### Step 2 (selfh.st batch 48)
- **kavita** (10416★) — reading server for manga/comics/books. Pre-1.0 warning front-loaded (upstream explicitly says "You may lose data"). SQLite-only (no Postgres). Kavita+ paid tier transparency (external metadata, scrobbling). Alternatives: Komga (Postgres-capable), Calibre-Web, Stump (Rust), Audiobookshelf. Mihon/Tachiyomi integration noted.
- **bunkerweb** (10367★) — nginx+ModSec+OWASP CRS WAF turnkey. Multi-container architecture documented (BunkerWeb + Scheduler + DB + UI). Scheduler-is-the-brain warning; DB is source of truth for settings after first boot. 1.5→1.6 setting renames front-loaded. ModSec false-positive tuning warning. Alternatives: manual nginx+ModSec, Traefik+CrowdSec, Cloudflare WAF.
- **aureus** (10348★) — Laravel 11 + Filament 5 ERP. "Young project" warning front-loaded. PHP 8.3+ mandatory, MySQL 8+/SQLite only (no MariaDB/Postgres listed). Plugin-uninstall drops tables warning from upstream. Alternatives: Odoo CE, ERPNext, Dolibarr, Axelor, Akaunting.
- **woocommerce** (10272★) — WordPress e-commerce plugin. Recipe distinguishes: **monorepo is for contributors**, operators install via wp plugin install. TLS mandatory for payments, PCI-DSS scope warning, HPOS migration guide linked. Extensive payment-gateway ecosystem. Email-deliverability warning (`mail()` spams-bin, use SMTP plugin). Alternatives: Shopify, Medusa, Saleor, PrestaShop.
- **pairdrop** (10181★) — AirDrop clone in browser. HTTPS-is-mandatory (WebRTC blocks plain HTTP). TURN server required for internet transfers (20-30% of combos need it); coturn docker snippet provided. Stateless server. Alternatives: LocalSend (native apps), Snapdrop (parent, dormant), OnionShare, Croc, KDE Connect.

**Batch 48 lengths:** kavita 198, bunkerweb 273, aureus 269, woocommerce 256, pairdrop 218.
**State:** 254 done / 1 skipped / 1019 pending (19.9%).

## 2026-04-30 06:35 UTC — batch 49 (5 recipes)

### Step 0 / Step 1
- Synced. Issues #24-#27 still open (PAT lacks issues:write; already addressed in code).

### Step 2 (selfh.st batch 49)
- **blinko** (10141★) — AI-powered card notes. pgvector MANDATORY warning front-loaded. AI-cost transparency (OpenAI pricing + Ollama local alternative). First-user-is-admin race. macOS "damaged" unquarantine fix from upstream FAQ. Alternatives: Obsidian+livesync, Logseq, Memos, AppFlowy, Joplin, TriliumNext.
- **evershop** (10041★) — TS/Node+GraphQL+React ecommerce. Positioned in the Node.js commerce landscape (vs Medusa headless-only, vs Vendure TS mature). Postgres-only noted. `/install` endpoint first-run-only + first-user race. Smaller ecosystem than WooCommerce.
- **filepizza** (10019★) — P2P file transfer via WebRTC link-based model (vs PairDrop's pairing). v2 architecture (Redis-backed channels, Service Worker streaming, direct WebRTC without WebTorrent). HTTPS-mandatory, uploader-tab-must-stay-open, TURN for NAT.
- **healthchecks** (9992★) — cron monitoring / dead-man's-switch. **`sendalerts` must be running** warning front-loaded (most critical gotcha for self-hosters). Separate-container pattern shown. `SITE_ROOT` bake-in warning. Pair-with-Gatus advice for complete coverage. Alternatives: Cronitor, DMS, Cronicle.
- **piped** (9932★) — privacy YT frontend. Multi-service architecture (backend + frontend + proxy + nginx + postgres) documented. YouTube-breaks-periodically warning front-loaded. Bandwidth math (viewers × bitrate via your server). Legal-gray-area disclaimer for public instances. Mobile clients (LibreTube/Yattee/Pipeline) noted.

**Batch 49 lengths:** blinko 216, evershop 236, filepizza 193, healthchecks 255, piped 229.
**State:** 259 done / 1 skipped / 1014 pending (20.3%) — **crossed 20%!**

## 2026-04-30 06:50 UTC — batch 50 (5 recipes) — 🎉 50th batch

### Step 0 / Step 1
- Synced. Issues #24-#27 still open (PAT lacks issues:write).

### Step 2 (selfh.st batch 50)
- **typebot** (9886★) — visual chatbot builder. **License caveat front-loaded: Fair Source License (FSL), NOT OSS.** Two-subdomain architecture required (builder + viewer). ENCRYPTION_SECRET shared between builder+viewer. NEXT_PUBLIC_* build-time bake-in warning. Alternatives: Botpress (pure OSS), Rasa, Chatwoot, Formbricks (if just forms).
- **akaunting** (9766★) — Laravel accounting for SMBs. **License caveat front-loaded: BSL (Business Source License), NOT OSS.** Many App Store apps are paid (Double Entry, Bank Feeds, Multi-currency)—transparency. Accounting-data-backup-is-critical warning. Alternatives: Firefly III (personal), Invoice Ninja, Dolibarr, Odoo CE.
- **checkmate** (9707★) — BlueWave uptime + infra monitor. MongoDB-backbone (not Postgres). Capture agent is optional for hardware metrics. Pairs-with-Healthchecks advice. Alternatives: Uptime Kuma, Gatus, Zabbix, Netdata.
- **invoice-ninja** (9702★) — v5 Laravel + Flutter billing platform. **License caveat front-loaded: Elastic License 2.0, NOT OSS.** APP_KEY loss = data loss (upstream explicit). Pin tags, not v5-develop. Queue+cron mandatory. 40+ payment gateways. White-label $40/year. Alternatives: Akaunting, Crater (MIT), Dolibarr.
- **leantime** (9590★) — ADHD/dyslexia/autism-aware PM tool. Unique neurodivergent-design angle documented. Kanban+Gantt+goals+canvases+wikis+timesheets all in free OSS core. MySQL/MariaDB only (no Postgres). AGPL-3.0. Alternatives: OpenProject, Taiga, Plane, Kanboard, Wekan.

**Batch 50 lengths:** typebot 243, akaunting 255, checkmate 212, invoice-ninja 291, leantime 232.
**State:** 264 done / 1 skipped / 1009 pending (20.7%). **50 batches complete 🎉**

## 2026-04-30 07:05 UTC — batch 51 (5 recipes)

### Step 0 / Step 1
- Synced. Issues #24-#27 still open (PAT lacks issues:write).

### Step 2 (selfh.st batch 51)
- **kanboard** (9565★) — **MAINTENANCE MODE warning front-loaded** (from upstream README). Default admin/admin warning. Plugin-trust caveat. Alternatives-to-more-active-tools guidance (Leantime, Plane, Wekan).
- **mautic** (9513★) — OSS marketing automation. Email-reputation-is-everything front-loaded (SPF/DKIM/DMARC/warm-up). Dedicated tracking subdomain advice. Cron #1 operational issue warning. MySQL only. GDPR tooling documented. DPG verification noted.
- **omnitools** (9394★) — client-side-only utility tool hub. ~28MB Docker. Pure SPA; zero server state. Positioned vs it-tools (dev-focused) and CyberChef (forensics-grade). WebAssembly big-first-load warning. Static hosting on Pages/Netlify covered.
- **runtipi** (9366★) — personal homeserver app store. **"No guarantee of support/security" warning front-loaded** (from upstream). Host-install (not container) noted as deliberate. Port conflict warning for existing-nginx hosts. Compared to CasaOS, Umbrel, YunoHost positioning.
- **heimdall** (9139★) — LinuxServer.io application dashboard. Mature-but-slow-development noted. Enhanced-Apps Docker-networking gotcha (use service names). Custom-background upload-max-filesize gotcha. Fallback fetched from readme.md (lowercase) since master has no README.md. Alternatives: Homepage (most active), Homer (YAML), Dashy.

**Batch 51 lengths:** kanboard 201, mautic 257, omnitools 171, runtipi 193, heimdall 209.
**State:** 269 done / 1 skipped / 1004 pending (21.1%).

### New README-case-variant found
- **Heimdall**: upstream uses `readme.md` (lowercase) on master, no `README.md`. Added to the Komodo-style case-variant fallback pattern. Updated in-memory playbook.

## 2026-04-30 07:20 UTC — batch 52 (5 recipes)

### Step 0 / Step 1
- Synced. Issues #24-#27 still open (PAT lacks issues:write).

### Step 2 (selfh.st batch 52)
- **miniflux** (9133★) — single-Go-binary RSS reader, Postgres-only. Reeder + Fever/Google Reader API integration highlighted. `hstore` extension gotcha. `BASE_URL` importance front-loaded.
- **bigbluebutton** (9096★) — OSS virtual classroom. **Ubuntu-only + bbb-install.sh** front-loaded (major constraint). Public IP + reverse DNS + UDP 16384-32768 required. Scaling via Scalelite documented. Classroom-vs-Jitsi positioning.
- **prestashop** (9047★) — PHP e-commerce. **Post-install hardening checklist** front-loaded (delete install/, rename admin/, perms). **Paid-module economy warning** (breaking changes between majors break paid modules). OSL-3.0 core + AFL-3.0 modules license-transparency. EU VAT MOSS/OSS nuance. Positioned vs WooCommerce/Shopware.
- **grocy** (8991★) — "ERP for your household." Default admin/admin warning. Data-entry reality-check front-loaded. Barcode Buddy companion documented. Tandoor/Mealie positioning (recipes only). OpenFoodFacts coverage caveat.
- **octoprint** (8972★) — 3D printer web UI. OctoPi image as recommended install path. **"Do NOT port-forward publicly"** security front-loaded. Klipper+Mainsail positioning (pick the right tool). One-printer-per-instance constraint. Pi Zero W OOM gotcha. AGPL-3.0 + Patreon support note.

**Batch 52 lengths:** miniflux 194, bigbluebutton 204, prestashop 228, grocy 200, octoprint 198.
**State:** 274 done / 1 skipped / 999 pending (21.5%).

## 2026-04-30 07:35 UTC — batch 53 (5 recipes)

### Step 0 / Step 1
- Synced. Issues #24-#27 still open (PAT lacks issues:write).

### Step 2 (selfh.st batch 53)
- **rss-bridge** (8906★) — feed generator for sites that don't have one. 500+ bridges. **Don't run publicly without auth** front-loaded. Legal-gray-zone disclaimer. Bridge-breakage frequency warning. Pin by date tag.
- **dawarich** (8868★) — Google Timeline replacement. **Pre-1.0 + "do not update automatically"** warnings front-loaded (direct from upstream). Photon geocoding 80GB gotcha. Don't-delete-original-data precedent. Mobile-battery-drain caveat.
- **pterodactyl** (8833★) — game server mgmt panel (Panel PHP + Wings Go). Pelican Panel successor/fork front-loaded for new deployments. Container-escape=host-root multi-tenant warning. Production: multi-node architecture. BisectHosting/Shockbyte industry note.
- **owncloud** (8765★) — file sync/share. **Dual-product disambiguation front-loaded**: Core 10.x (this recipe) vs oCIS (Go rewrite) vs Nextcloud fork. "Don't pick Core 10.x for new deploys" guidance. Data-dir-outside-webroot security requirement. AGPL-3.0.
- **romm** (8698★) — ROM manager + browser player (EmulatorJS). **Legal caveat front-loaded** (copyrighted ROMs). BIOS files same caveat. Platform-slug-matters gotcha. ScreenScraper registration recommendation for obscure consoles. Young-project warning.

**Batch 53 lengths:** rss-bridge 209, dawarich 243, pterodactyl 229, owncloud 240, romm 248.
**State:** 279 done / 1 skipped / 994 pending (21.9%).

### New precedents
- **Dual-product brand disambiguation**: ownCloud Core 10.x vs oCIS vs Nextcloud fork — pattern applies to similarly-complex brands.
- **Fork-supersedes-parent advice**: Pterodactyl → Pelican Panel; pattern for "recommend successor but document original."
- **Legal-caveat for copyrighted-content tools**: RomM (ROMs) extends the precedent set by Piped (alt-YouTube), Invidious, etc.

## 2026-04-30 07:50 UTC — batch 54 (5 recipes)

### Step 0 / Step 1
- Synced. Issues #24-#27 still open (PAT lacks issues:write).

### Step 2 (selfh.st batch 54)
- **heyform** (8695★) — open-source form builder (Typeform-style). MongoDB not Postgres. GDPR/PII warning. Spam/CAPTCHA front-loaded. "Duo" founder-note preserved from README.
- **tiddlywiki** (8589★) — **unique single-HTML-file wiki** architecture front-loaded. 20-year project. Dual-mode (single-file vs Node.js) explained. Save-in-browser-gotcha for Chrome/Safari. BSD-3-Clause. TiddlyWiki's README was HTML-encoded markup (TW auto-generated); fetched + parsed conceptually.
- **solidtime** (8504★) — modern OSS time tracker. "AI-slop PRs banned" maintainer policy front-loaded. Postgres preferred over MySQL. No-invoicing-built-in caveat. Comparison to Kimai/Clockify/Toggl. AGPL-3.0.
- **step-ca** (8444★) — private CA-as-a-Go-binary. "Back up ROOT + INTERMEDIATE keys" imperative front-loaded. ACMEv2/SSH CA/OIDC explained. Short-lived-cert philosophy. Homelab HTTPS use case. Vault + cert-manager positioning.
- **fluxer** (8389★) — Discord-alternative chat. **"DON'T SELF-HOST YET"** warning front-loaded (direct from upstream). Recipe catalogs + pivots to Revolt/Matrix/Rocket.Chat/Mattermost alternatives today. Written as "come back when refactor ships." Respects upstream's explicit request.

**Batch 54 lengths:** heyform 205, tiddlywiki 225, solidtime 224, step-ca 240, fluxer 157.
**State:** 284 done / 1 skipped / 989 pending (22.3%).

### New precedents
- **"Don't self-host yet" project pattern**: Fluxer — honestly catalog but redirect to ready alternatives. Pattern for future pre-self-hosting projects.
- **Unique-architecture front-loading**: TiddlyWiki's single-HTML-file model deserves its own upfront explainer, not buried.
- **Maintainer-policy quotes preserved verbatim**: Solidtime's AI-slop-PR ban, Fluxer's self-host-wait message — both from upstream README, treated as authoritative.

## 2026-04-30 08:05 UTC — batch 55 (5 recipes)

### Step 0 / Step 1
- Synced. Issues #24-#27 still open (PAT lacks issues:write).

### Step 2 (selfh.st batch 55)
- **ghostfolio** (8283★) — OSS wealth/portfolio tracker. **"Not investment advice/tax software"** front-loaded. Yahoo rate-limits gotcha. TWR vs IRR distinction. AGPL-3.0. Alternatives: Portfolio Performance (desktop), Sharesight (tax), Actual/Firefly III (budgeting).
- **tandoor-recipes** (8277★) — recipe manager + meal planner. URL import + OCR + aisle-based shopping. Ingredient-duplicate hygiene gotcha. Positioned vs Mealie (simpler) + Grocy (ERP). AGPL-3.0.
- **privatebin** (8236★) — zero-knowledge pastebin. **URL fragment = decryption key** architecture front-loaded. "Lost URL = lost paste" design note. Burn-after-reading-vs-crawlers gotcha. Tor hidden service common pattern. Zlib/libpng license (unusual).
- **papermark** (8197★) — OSS DocSend alternative. **External-SaaS-heavy warning** (Resend + Tinybird + Stripe dependency front-loaded). Fundraising-deck DNA contextualized. Analytics accuracy caveat. AGPL-3.0.
- **technitium** (8166★) — full-featured self-hosted DNS (authoritative + recursive + DoT/DoH/DoQ). systemd-resolved :53 conflict gotcha. Open-resolver DDoS warning. Positioned vs Pi-hole/AdGuard Home/Unbound/BIND. GPL-3.0. .NET 8.

**Batch 55 lengths:** ghostfolio 212, tandoor-recipes 217, privatebin 234, papermark 201, technitium 215.
**State:** 289 done / 1 skipped / 984 pending (22.7%).

### New precedents
- **External-SaaS-dependency transparency**: Papermark (Resend/Tinybird/Stripe) — some OSS projects lean heavily on commercial cloud services; document honestly so self-hosters know what they're signing up for.
- **Zero-knowledge architecture front-loading**: PrivateBin's URL-fragment-key model deserves upfront explanation, not buried.
- **"Not tax/investment advice" disclaimers** for finance tools (Ghostfolio) — extends safety-critical front-loading to legal/compliance territory.

## 2026-04-30 08:20 UTC — batch 56 (5 recipes)

### Step 0 / Step 1
- Synced. Issues #24-#27 still open (PAT lacks issues:write).

### Step 2 (selfh.st batch 56)
- **graylog** (8022★) — log-management platform. **SSPL license** front-loaded (not OSI-approved). 3-part architecture (Graylog+MongoDB+OpenSearch) front-loaded. OpenSearch vs ES compatibility matrix called out. Enterprise-features-locked called out. Positioned vs Loki/OpenSearch-direct/Wazuh/Splunk.
- **librephotos** (7982★) — Google Photos alt with face + object ML. **Initial-scan-is-slow-on-CPU** front-loaded. Evolved-from-Ownphotos noted (original README is stale). Positioned vs Immich (wins on mobile sync) + PhotoPrism (wins on simplicity). MIT.
- **mumble** (7956★) — low-latency voice chat. **"Certificate = identity, back up the cert"** imperative front-loaded. UDP-preferred, TCP-fallback-is-lag caveat. Positioned vs Discord (quality + privacy) / TeamSpeak / Jitsi / Element. BSD-3.
- **teslamate** (7923★) — Tesla data logger. **Upstream security warning about deceptive forks/fake apps** front-loaded verbatim. Tesla Fleet API onboarding change (post-2023) flagged. **"No built-in auth — MUST reverse-proxy with auth"** front-loaded. AGPL-3.0.
- **sure-finance** (7900★) — personal finance app. **Community fork of abandoned Maybe Finance** history front-loaded. Trademark-compliance note preserved. "Early project state" warning. Plaid-access-friction gotcha. Positioned vs Firefly III/Actual/GnuCash/Ghostfolio. AGPL-3.0.

**Batch 56 lengths:** graylog 217, librephotos 220, mumble 218, teslamate 209, sure-finance 217.
**State:** 294 done / 1 skipped / 979 pending (23.1%).

### New precedents
- **Security-warning-verbatim-from-upstream**: TeslaMate's README ships a CAUTION block about malicious forks + fake App Store apps stealing Tesla creds; preserved verbatim. Extends earlier "maintainer-policy quotes" pattern to security advisories.
- **Architectural-history front-loading**: LibrePhotos (Ownphotos origin, stale README). Sure (Maybe Finance fork). Helps self-hosters understand why the docs may not match the code.
- **SSPL-license transparency**: Graylog — extends BSL/Elastic-2.0/PolyForm pattern to another non-OSI license; flagged for re-hosters.
- **"No built-in auth — reverse-proxy is mandatory"**: TeslaMate, extends earlier pattern (HTTPS-mandatory for WebRTC).
- **Trademark-preservation-in-forks**: Sure's README reminds forkers not to use Maybe's name/logo; preserved for downstream.
