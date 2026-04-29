
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

