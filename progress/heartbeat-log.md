
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
