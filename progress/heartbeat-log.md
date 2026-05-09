
## 2026-05-04 04:34 UTC

**Step 0 — sync:** `git pull` completed (rebased over remote changes including merged PR #50 release workflow).

**Step 1 — GitHub issues:** No new issues since last check. PR #50 (auto-release workflow) confirmed merged upstream.

**Step 2 — catalog freshness:** Not due (last checked recently, within 7-day window).

**Step 3 — catalog growth:**
- Source: awesome-selfhosted-data (now In progress, Source #2)
- Batch 1: 5 recipes authored and committed
  - `apache-airflow.md` — 45k★, CeleryExecutor + Redis + Postgres
  - `anubis.md` — 19k★, reverse-proxy bot protection sidecar
  - `docker-mailserver.md` — 18k★, full-stack containerized mail server
  - `activitywatch.md` — 17k★, local time tracker (desktop app, noted Docker limitations)
  - `bytebase.md` — 14k★, database schema change management
- Commit: `42d0b70` (recipes) + `ef7a8a5` (tracking) → pushed as `455ab1e`
- Tracking: `selfhst-progress.json` marked complete, `sources.md` updated, `awesome-selfhosted-progress.json` created
- Remaining net-new candidates: ~812 (817 - 5 done)

## 2026-05-04T05:34:00Z
- Step 0: repo up to date (455ab1e)
- Step 1: no open issues
- Step 2: catalog-check skipped (not 7 days since last check)
- Step 3: batch 2 processed — affine-community-edition, filebrowser, changedetection.io, ente, actual-budget
  - Wrote 4 new recipe files (changedetection.io.md, ente.md new; affine-community-edition.md, filebrowser.md were untracked from prior session)
  - Updated actual-budget.md with cleaner structure from official docker-compose
  - Built dist, committed 031465a, pushed to main
  - Updated awesome-selfhosted-progress.json: 10 processed, 807 remaining, batches_completed=2

## 2026-05-04T05:49:00Z
- Step 0: repo up to date (031465a)
- Step 1: no open issues
- Step 2: catalog-check skipped (not 7 days since last check)
- Step 3: batch 3 processed — dify.ai (139k★), hoppscotch-community-edition (79k★), kong (43k★), cal.diy (42k★), casaos (33k★)
  - Scanned ~300 slugs to identify top by star count
  - Excluded lobehub (Proprietary) and elasticsearch (SSPL-1.0) in favor of OSS alternatives
  - Built dist, committed f9d7455, pushed to main
  - Updated awesome-selfhosted-progress.json: 15 processed, ~797 remaining, batches_completed=3

## 2026-05-04T06:10:00Z
- Step 0: repo up to date (f9d7455)
- Step 1: no open issues
- Step 2: catalog-check skipped (not 7 days since last check)
- Step 3: batch 4 processed — rocket.chat (45k★), khoj (34k★), medusajs (32k★), infisical-community-edition (26k★), navidrome-music-server (20k★)
  - Scanned slugs 301-601 for star counts; excluded reveal.js (no server component), lobehub (Proprietary), elasticsearch (SSPL-1.0)
  - Built dist, committed e0691a1, pushed to main
  - Updated awesome-selfhosted-progress.json: 20 processed, ~792 remaining, batches_completed=4

## 2026-05-04 07:44 UTC

**Batch 6 completed** (continuation from prior split turn):
- Wrote 5 new recipes: minio, maybe-finance, vault, hasura, harbor
- Built dist, committed & pushed: `606427b`
- Updated `progress/awesome-selfhosted-progress.json`: batches_completed=6, apps_processed=30

**GitHub issues:** 0 open issues — nothing to action.

**Catalog freshness check:** Last run ~7h ago (last_checked_at: 2026-05-03T20:49:00Z, all checked, pending=[]) — within 7-day window, skipped.


## 2026-05-04 08:29 UTC

**Batch 7 completed:**
- Wrote 5 new recipes: calibre, super-productivity, awx, centrifugo, btcpayserver
- Built dist, committed & pushed: `6e4af3b`
- Updated progress tracker: batches_completed=7, apps_processed=35

**GitHub issues:** 0 open issues.

**Catalog now at ~1,297 recipes.**


## 2026-05-04 08:44 UTC

**Batch 8 completed:**
- Wrote 5 new recipes: bruno, unleash, opensearch, element-web, trigger-dev
- Built dist, committed & pushed: `c411158`
- Updated progress tracker: batches_completed=8, apps_processed=40

**GitHub issues:** 0 open — nothing to action.

**Catalog now at ~1,302 recipes.**


## 2026-05-04T10:29:00Z — Batch 9

**Step 0:** git pull — already up to date.
**Step 1:** GitHub issues — 0 open issues, nothing to action.
**Step 2:** Catalog freshness — last checked 2026-05-04T08:44:00Z, within 7-day window, skipped.
**Step 3:** Catalog growth — wrote 5 new recipes:
- `gitbutler.md` — GitButler desktop Git client (Tauri/Rust, virtual branches, MCP integration)
- `devpod.md` — DevPod client-only dev environment tool (devcontainer.json, multi-provider)
- `grist-core.md` — Grist relational spreadsheet (SQLite docs, Python formulas, Apache 2.0)
- `growthbook.md` — GrowthBook feature flags + A/B testing (MongoDB, port 3000+3100, MIT core)
- `invoiceninja.md` — Invoice Ninja invoicing platform (Laravel/Flutter, MySQL, Chrome PDF, EL 2.0)

Built dist ✓ — commit `381339d` pushed to main.
Progress JSON updated: batches_completed=9, apps_processed=45.

## 2026-05-04T10:44:00Z — Batch 10

**Step 0:** git pull — already up to date.
**Step 1:** GitHub issues — 0 open issues, nothing to action.
**Step 2:** Catalog freshness — last checked today, within 7-day window, skipped.
**Step 3:** Catalog growth — wrote 5 new recipes:
- `lobe-chat.md` — LobeChat AI chat platform (76K★, multi-LLM, MCP, stateless+server modes)
- `flowise.md` — Flowise LLM flow builder (52K★, drag-and-drop AI agents, SQLite/Postgres)
- `erpnext.md` — ERPNext open-source ERP (33K★, frappe_docker, MariaDB, multi-service)
- `answer.md` — Apache Answer Q&A platform (15K★, Go+React, single container, SQLite)
- `lago.md` — Lago billing infrastructure (9.6K★, usage-based billing, Rails, AGPL)

Built dist ✓ — commit `cf9c5cd` pushed to main.
Progress JSON updated: batches_completed=10, apps_processed=50.

## 2026-05-04T11:29:00Z
- Batch 11 committed: flagsmith, openreplay, typesense, wagtail, soketi
- Catalog: 1,331 recipes (+5 from batch 11)
- Commit: a88f143
- GitHub issues: 0 open
- Catalog freshness: within 7-day window, no check needed

## 2026-05-04T11:44:00Z — Batch 12
- GitHub issues: 0 open
- Catalog freshness: last checked 2026-05-04T08:44:00Z, within 7-day window — skipped
- Batch 12 written and committed: temporal (12K★), prefect (16K★), home-assistant (74K★), openobserve (14K★), highlight (8K★)
- Commit: bc1ffd6
- Catalog now at 1,322 recipes (dist/generic bundle: 1331 lines)
- Progress: batches_completed=12, apps_processed=60

## 2026-05-04T12:29Z
- Step 0: git pull — already up to date
- Step 1: 0 open GitHub issues — nothing to address
- Step 2: catalog-check.json last_checked_at 2026-05-03T20:49Z — within 7 days, skipped
- Step 3: committed batch 13 (6ba0c67) — saleor, hyperswitch, screego, languagetool, jupyterlab; 65 apps processed total across 13 batches

## 2026-05-04T13:22Z
- Step 0: git pull — already up to date
- Step 1: 0 open GitHub issues — nothing to address
- Step 2: catalog-check.json last_checked_at 2026-05-03T20:49Z — within 7 days, skipped
- Step 3: committed batch 14 (0a40312) — gitpod, livekit, twenty, illa-builder, hatchet; 70 apps processed total across 14 batches

## 2026-05-04T13:50Z
- Step 0: git pull — already up to date
- Step 1: 0 open GitHub issues — nothing to address
- Step 2: catalog-check.json within 7 days, skipped
- Step 3: committed batch 15 (71bff78) — stalwart-mail, conduwuit, dendrite, webstudio, zincsearch; 75 apps processed total across 15 batches

## 2026-05-04T14:29Z — Batch 16
- Completed 5 recipes: gotenberg, rustdesk, undb, apitable, gickup
- Rebuilt dist, committed d9c21fd, pushed to origin/main
- Total: 80 apps processed across 16 batches

---
**2026-05-04T15:14Z — Batch 17**
- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open issues
- Step 2: Catalog freshness — catalog-check.json was missing; ran first 20 recipes (13ft-ladder through akaunting) — all OK, no updates needed. Created catalog-check.json.
- Step 3: Catalog growth — batch 17 committed (d6ff1e3):
  - tubearchivist (YouTube archive, yt-dlp + ES + Redis)
  - fonoster (Twilio alternative, telephony/voice API)
  - jenkins (CI/CD automation server)
  - element-call (Matrix-powered group video calls)
  - gitness (Harness Open Source — Drone CI successor, code hosting + CI/CD)
- Total processed: 85 apps across 17 batches

---
**2026-05-04T16:14Z — Batch 18**
- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open issues
- Step 2: Catalog freshness — last_checked_at 1h ago, within 7-day window. Skipped.
- Step 3: Catalog growth — batch 18 committed (99dee7c):
  - gitlab-ce (full DevOps platform — Git, CI/CD, registry, issues)
  - seafile-ce (file sync/share with client-side encryption)
  - opentelemetry-collector (vendor-agnostic telemetry pipeline)
  - jaeger (distributed tracing — CNCF graduated, v2 built on OTEL Collector)
  - telegraf (plugin-driven metrics agent, 300+ plugins, TIG stack)
- Total processed: 90 apps across 18 batches

---
**2026-05-04T16:44Z — Batch 19**
- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open issues
- Step 2: Catalog freshness — last_checked_at 90 min ago. Skipped.
- Step 3: Catalog growth — batch 19 committed (25c7174):
  - ory-kratos (API-first identity/user management — login, registration, MFA, recovery)
  - ory-hydra (OpenID Certified OAuth2 + OIDC server, high-throughput token issuance)
  - gitea-runner (Gitea Actions CI runner / act_runner — GitHub Actions compatible)
  - prometheus-alertmanager (alert dedup/grouping/routing for Prometheus — email, Slack, PagerDuty)
  - renovate (automated dependency update bot — 90+ package managers, 10+ platforms)
- Total processed: 95 apps across 19 batches

---
**2026-05-04T16:59Z — Batch 20**
- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open issues
- Step 2: Catalog freshness — within 7-day window. Skipped.
- Step 3: Catalog growth — batch 20 committed (78be74a):
  - cozy-stack (personal cloud platform — files, contacts, calendar, web app store; now Twake Workplace)
  - nextcloud-aio (official all-in-one Nextcloud: NC + Office + Talk + Backup + Redis + PG in one setup UI)
  - overseerr (media request management for Plex+Sonarr+Radarr; note: superseded by Seerr)
  - podgrab (podcast downloader/archiver; low-maintenance since 2023)
  - drawio (self-hosted diagrams.net / draw.io diagramming app)
- Total processed: 100 apps across 20 batches

---
**2026-05-04T17:14Z — Batch 21**
- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open issues
- Step 2: Catalog freshness — within 7-day window. Skipped.
- Step 3: Catalog growth — batch 21 committed (170a098):
  - k3s (lightweight Kubernetes in a single binary — edge, IoT, ARM, CI)
  - nats (CNCF messaging system — pub/sub + JetStream persistence)
  - manticore-search (fast SQL-first search database, Elasticsearch alternative)
  - mermaid-live-editor (self-hosted Mermaid diagram editor)
  - whats-up-docker (WUD — container update notifier)
- Skipped: jellyseerr (merged into seerr, already in catalog), focalboard (unmaintained)
- Total processed: 105 apps across 21 batches

---
**2026-05-04T17:29Z — Batch 22**
- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open issues
- Step 2: Catalog freshness — within 7-day window. Skipped.
- Step 3: Catalog growth — batch 22 committed (beb083f):
  - kroki (unified diagram rendering API — 30+ types: PlantUML, Mermaid, Graphviz, D2, etc.)
  - supertokens (open-source Auth0 alternative — email/password, passwordless, social, MFA, multi-tenancy)
  - fluent-bit (lightweight CNCF telemetry agent — logs/metrics/traces, 70+ plugins)
  - argocd (declarative GitOps CD for Kubernetes — CNCF graduated, web UI)
  - flux (GitOps CD toolkit for Kubernetes — CNCF graduated, CRD-native, no UI)
- Total processed: 110 apps across 22 batches

## 2026-05-04 19:14 UTC
- Batch 23: watchtower, adminer, cockpit, mongo-express, flame (115 total, 23 batches)
- Commit: fe1ab84

## 2026-05-04 19:29 UTC
- Batch 24: trilium, standardnotes, omnivore, nitter, teddit (120 total, 24 batches)
- Commit: df68e95

## 2026-05-04 19:44 UTC
- Batch 24: hyperdx, coroot, thanos, librenms, icinga2 (120 total, 24 batches)
- Commit: 6415dbe

## 2026-05-04 19:59 UTC
- Batch 25: grafana-mimir, grafana-tempo, grafana-pyroscope, rancher, headlamp (125 total, 25 batches)
- Commit: b6172d3

## 2026-05-04 20:14 UTC
- Batch 26: grafana-alloy, victoria-metrics, wg-easy, zerotier, checkmk (130 total, 26 batches)
- Commit: d0a577b

## 2026-05-04 20:44 UTC
- Batch 27: tolgee, jitsi, mockoon, netmaker, pritunl (135 total, 27 batches)
- Commit: 61f9c1c

## 2026-05-04 20:59 UTC
- Batch 28: litellm, text-generation-webui, concourse, dependency-track, defectdojo (140 total, 28 batches)
- Commit: 962d91d

## 2026-05-04T22:14:00Z — Batch 29
- Apps: jan, openlit, openebs, mlflow, kubeflow
- Commit: 3881592
- Total apps: 145 across 29 batches

## 2026-05-04T22:29:00Z — Batch 30
- Apps: langflow, datahub, trufflehog, agenta, clickhouse
- Skipped: aleph (project sunsetting, maintenance ended Dec 2025)
- Commit: db05f6c
- Total apps: 150 across 30 batches

## 2026-05-04T23:29Z — Batch 32
- Committed: bagisto, frappe-hr, canvas-lms, countly-community-edition, apostrophe
- Commit: 25d3805
- Total: 160 apps across 32 batches

## 2026-05-05T00:30:00Z — Batch 33 + 34
- Batch 33 (commit 1bb8093): dex, gitbucket, loomio, phpipam, spegel (165 apps total)
- Batch 34 (commit c70c284): thelounge, revolt, spacedrive, sabnzbd, transmission (170 apps total)
- Note: revolt rebranded to "Stoat" in Feb 2026; recipe documents both names
- Note: spacedrive uses FSL license (not OSI open source); v2 is major rewrite in active dev

## 2026-05-05T00:59:00Z — Batch 35

**Source:** awesome-selfhosted-data (batch 35/?)
**Apps added (5):** prometheus-node-exporter, nzbhydra2, rxresume, netbootxyz, tt-rss
**Commit:** 3ceacd6
**Total processed:** 175 apps across 35 batches
**Issues:** 0 open
**Freshness check:** skipped (last run 2026-05-04, within 7-day window)

## 2026-05-05T01:29:00Z — Batch 36

**Source:** awesome-selfhosted-data (batch 36/?)
**Apps added (5):** asterisk, artalk, azimutt, aptabase, aimeos
**Commit:** 0f91a7a
**Total processed:** 180 apps across 36 batches
**Issues:** 0 open
**Freshness check:** skipped (last run 2026-05-04, within 7-day window)

## 2026-05-05T02:08:00Z — Batch 37

**Apps added:** baikal, aleph, beelzebub, alfio, atomic-server
**Stars (approx):** baikal 3145, aleph 2359, beelzebub 1980, alfio 1577, atomic-server 1542
**Commit:** 85ea50e
**Total apps processed:** 185 (37 batches)

## 2026-05-05T02:38:00Z — Batch 38

**Apps added:** apache-solr, ckan, beets, cncjs, buku
**Stars (approx):** apache/solr 1611, ckan/ckan 5017, beetbox/beets 15076, cncjs/cncjs 2593, jarun/buku 7121
**Commit:** db4021b
**Total apps processed:** 190 (38 batches)

## 2026-05-05T02:53:00Z — Batch 39

**Apps added:** diaspora, corteza, deluge, django-wiki, documize
**Stars (approx):** diaspora 13688, corteza 2063, deluge 1760, django-wiki 1920, documize 2386
**Commit:** fb3b8f8
**Total apps processed:** 195 (39 batches)

## 2026-05-05T03:08:00Z — Batch 40

**Apps added:** domoticz, drupal, apache-druid, dreamfactory, databunker
**Stars (approx):** domoticz 3741, drupal 4260, apache/druid 13984, dreamfactory 1765, databunker 1414
**Commit:** ba7f05b
**Total apps processed:** 200 (40 batches)

## 2026-05-05T03:48:00Z — Batch 41
- Apps: elasticsearch (76k★), sentry-self-hosted (9.3k★), ejabberd (6.7k★), redmine (5.9k★), mediawiki (5k★)
- Commit: d9abaee
- Skipped: openmediavault (cannot run in container), firezone (v2 cloud-only), emqx (BSL 1.1 non-OSS)
- Total processed: 205 apps across 41 batches

## 2026-05-05 04:48 UTC — Batch 42

- Synced repo (already up to date)
- 0 open GitHub issues
- Catalog growth: added 5 recipes from awesome-selfhosted-data source
  - algernon (3,005★) — Go web server, Docker + binary install
  - bittorrent-tracker (1,923★) — Node.js BitTorrent tracker, npm CLI
  - alfio (1,576★) — Event ticketing system, Docker Compose + Java
  - accent (1,483★) — Translation management, Docker + Elixir/Phoenix
  - bludit (1,416★) — Flat-file CMS, Docker + PHP
- Committed: 3383a05 — "open-forge: batch 42 — algernon, bittorrent-tracker, alfio, accent, bludit"
- Total processed slugs: ~214 (210 prev + 4 new unique; alfio was already in list)

## 2026-05-05 06:03 UTC — Batch 43

**Source:** awesome-selfhosted-data (In progress)
**Apps processed this batch:** 5
**Total processed:** 210

| Slug | Stars | Notes |
|---|---|---|
| emqx | 16,222 | MQTT platform, BSL 1.1 license |
| goaccess | 20,508 | Real-time web log analyzer |
| gollum | 14,269 | Git-based wiki (Ruby) |
| imgproxy | 10,681 | On-the-fly image resizing server |
| halo | 38,424 | Java CMS/website builder |

**Skipped this session:** firezone (production self-hosting not officially supported), kodi (media player client, not server), google-webfonts-helper (depends_3rdparty)

**Commit:** 85b88d2

## 2026-05-05 07:18 UTC — Batch 44

**Source:** awesome-selfhosted-data (In progress)
**Apps processed this batch:** 5
**Total processed:** 220

| Slug | Stars | Notes |
|---|---|---|
| canary-tokens | 2,856 | Honeytoken/tripwire system, Docker Compose |
| coral | 1,981 | Commenting platform, Node.js + MongoDB |
| cytube | 1,570 | Synchronized media + chat, Node.js |
| conduit | 941 | Matrix homeserver, Rust |
| chiefonboarding | 892 | Employee onboarding, Django/Python |

**Also fixed:** progress JSON batches_completed/apps_processed updated to 44/220 (was stuck at 43/215 from last session).

**Commit:** c87a615

## 2026-05-05 07:48 UTC — Batch 45

**Source:** awesome-selfhosted-data (In progress)
**Apps processed this batch:** 4 (draw.io already existed — skipped)
**Total processed:** 224

| Slug | Stars | Notes |
|---|---|---|
| eclipse-che | 7,167★ | Kubernetes-native cloud IDE platform |
| evidence | 6,270★ | SQL + markdown BI/reports as static sites |
| flipt | 4,784★ | Git-native feature flag management |
| erxes | 3,972★ | CRM/XOS platform, plugin-based |

**Skipped:** draw.io (already in catalog as draw-io.md + drawio.md)

**Commit:** 6276d9a

## 2026-05-05 08:18 UTC — Batch 46

**Source:** awesome-selfhosted-data (In progress)
**Apps processed this batch:** 3 net-new (subagent also rewrote 4 files already in catalog — flowise, activepieces, formbricks, maybe-finance; those were no-ops)
**Total processed:** 227

| Slug | Stars | Notes |
|---|---|---|
| airbyte | ~16,000★ | Open-source data integration / ETL platform |
| cal-diy | ~35,000★ | MIT-licensed scheduling platform (Cal.com fork, community edition) |
| redash | ~26,000★ | SQL-based data visualization and dashboard tool |

**Commit:** b8a6016

## 2026-05-05 09:18 UTC
- Batch 47 completed: actual, btcpay-server, claper, focalboard, onlyoffice-docs
- apps_processed: 232, batches_completed: 47
- Commit: cb7efcd
- No open GitHub issues

## 2026-05-05T11:36:00Z — Batch 49
- Source: awesome-selfhosted-data (Source 2, in progress)
- apps_processed: 242, batches_completed: 49
- New recipes: freeswitch, easy-appointments, go-doxy, fava, go-feature-flag
- Commit: ba29c18
- No open GitHub issues

## 2026-05-05 13:55 UTC — Batch 50

- **Step 0**: repo up to date
- **Step 1**: no open GitHub issues
- **Step 2**: catalog-check last ran 2026-05-04; within 7-day window, skipped
- **Step 3**: awesome-selfhosted batch 50
  - Ranked 696 remaining candidates by star count
  - Top 5 not already in catalog: revealjs (71k★), vane (34k★), srs (28k★), composio (28k★), tasmota (24k★)
  - Wrote 5 recipe files; build passed; committed `18f6ffd`
  - Progress: 247 apps processed, 50 batches complete

## 2026-05-05 14:15 UTC — Batch 51

- **Step 0**: repo up to date
- **Step 1**: no open GitHub issues
- **Step 2**: catalog-check within 7-day window, skipped
- **Step 3**: awesome-selfhosted batch 51
  - Top 5 unprocessed by stars: krayin (22k★), kodi (21k★), lila (18k★), leon (17k★), libre-translate (14k★)
  - Wrote 5 recipe files; build passed; committed `c58f5a7`
  - Progress: 252 apps processed, 51 batches complete

## 2026-05-05 14:46 UTC — Batch 52

- **Step 0**: repo up to date
- **Step 1**: no open GitHub issues
- **Step 2**: catalog-check within 7-day window, skipped
- **Step 3**: awesome-selfhosted batch 52
  - Top 5: google-webfonts-helper (13k★), stalwart-mail-server (12k★), sftpgo-community-edition (12k★), tyk (10k★), thumbor (10k★)
  - Wrote 5 recipe files; build passed; committed `34c292f`
  - Progress: 257 apps processed, 52 batches complete

## 2026-05-05T15:39Z

- Heartbeat: recovered uncommitted batch files from prior session
- Committed batch 53: mindsdb (39k★), mediamtx (18k★), luanti (12k★), keystonejs (9.8k★), tipi (9.3k★) — commit 97b4122
- Wrote + committed batch 54: janus (9k★), sylius (8.4k★), technitium-dns-server (8.3k★), maybe (54k★), umbrel (11k★) — commit 43882e1
- Progress: batches_completed=54, apps_processed=267
- Fixed progress JSON duplicate slug entries (mindsdb/mediamtx/luanti were listed twice)
- No open GitHub issues
- Pushed both batches to origin/main

## 2026-05-05 16:54 UTC

- Step 1: No open GitHub issues
- Step 3: Catalog growth — batch 56 committed and pushed
  - outline-server (6.2k★), ansible-nas (3.7k★), craftcms (3.6k★), backdrop-cms (1k★), chamilo-lms (947★)
  - batches_completed: 56, apps_processed: 277
  - Commit: b918713

## 2026-05-05 18:09 UTC

- Step 1: No open GitHub issues
- Step 3: Catalog growth — batch 57 committed and pushed
  - alf.io (1.6k★), audioserve (829★), cloudlog (555★), clearflask (437★), chyrp-lite (485★)
  - batches_completed: 57, apps_processed: 282
  - Commit: e883c7e

## 2026-05-05 21:02 UTC — Batch 59

Batch 59 (top 5 by stars from 660 unprocessed candidates):

| App | Stars | License | Recipe file |
|---|---|---|---|
| triliumnext-notes | 35,849 | AGPL-3.0 | triliumnext-notes.md |
| netron | 32,833 | MIT | netron.md |
| nginx | 30,152 | BSD-2-Clause | nginx.md |
| homepage-by-gethomepage | 29,857 | GPL-3.0 | homepage-by-gethomepage.md |
| onyx-community-edition | 28,870 | MIT | onyx-community-edition.md |

Also recorded 5 previously-untracked batch-58 slugs (admidio, concrete-5-cms, davmail, debops, dietpi) in progress JSON.

Progress: batches_completed=60, apps_processed=297, ~655 candidates remaining.

## 2026-05-05T22:19:00Z — Batch 62

**Step 0 (sync):** `git pull` — already up to date.

**Step 1 (GitHub issues):** No new open issues requiring code changes.

**Step 2 (catalog freshness):** Skipped — catalog-check.json last run not yet 7 days old.

**Step 3 (catalog growth):** Batch 62 — 5 new recipes added (awesome-selfhosted source).

| Slug | Stars | Notes |
|---|---|---|
| docs | 16,466 | La Suite Docs — French govt collaborative wiki/editor |
| mindustry | 27,432 | Mindustry game server (Java) |
| thingsboard | 21,631 | IoT platform — device mgmt + dashboards |
| october-cms | 11,133 | October CMS — Laravel-based PHP CMS |
| openmediavault | 6,683 | NAS solution on Debian — bare-metal only |

Committed: 3832751. Total processed: 307 / ~645 candidates.

## 2026-05-05T23:04:00Z — Batch 63

**Step 0 (sync):** Already up to date.
**Step 1 (issues):** No open issues.
**Step 2 (freshness):** Skipped — not 7 days since last run.
**Step 3 (growth):** Batch 63 — 5 new recipes.

| Slug | Stars | Notes |
|---|---|---|
| uvdesk | 18,539 | PHP/Symfony helpdesk with email piping and workflows |
| transfer-sh | 15,834 | Go file sharing server — curl upload, S3/local backends |
| spree-commerce | 13,282 | Rails headless eCommerce with Next.js storefront |
| tinode | 13,282 | Go instant messaging — open WhatsApp/Telegram alternative |
| mopidy | 8,499 | Python music server, MPD-compatible, extensible |

Committed: 66676fd. Total processed: 312 / ~641 candidates.

## 2026-05-05T23:34:00Z — Batch 64

**Step 0 (sync):** Already up to date.
**Step 1 (issues):** No open issues.
**Step 2 (freshness):** Skipped — not 7 days since last run.
**Step 3 (growth):** Batch 64 — 5 new recipes. (Skipped `lura` — it's a Go library/framework, not a deployable server; KrakenD CE already in catalog.)

| Slug | Stars | Notes |
|---|---|---|
| iodine | 7,834 | IPv4-over-DNS tunnel — firewall bypass via DNS |
| openttd | 7,830 | Transport sim game dedicated server |
| snapcast | 7,608 | Synchronous multiroom audio — Pi-based whole-home audio |
| maddy-mail-server | 5,953 | All-in-one Go mail server (Postfix+Dovecot replacement) |
| haraka | 5,565 | Node.js SMTP filtering MTA with plugin architecture |

Committed: d3f14fb. Total processed: 317 / ~636 candidates.

## 2026-05-06T00:04:00Z — Batch 65

**Step 0 (sync):** Already up to date.
**Step 1 (issues):** No open issues.
**Step 2 (freshness):** Skipped.
**Step 3 (growth):** Batch 65 — 5 new recipes.

| Slug | Stars | Notes |
|---|---|---|
| isso | 5,275 | Lightweight Disqus-replacement comment server (Python/SQLite) |
| open-meteo | 5,265 | Self-hosted weather API — 16-day forecasts, 80yr history |
| musikcube | 4,762 | Terminal audio player + streaming server (C++, Pi-friendly) |
| local-deep-research | 4,502 | AI research assistant with Ollama + SearXNG integration |
| mirotalk-p2p | 4,491 | WebRTC P2P video conferencing — unlimited rooms/time |

Committed: 0eaad46. Total processed: 322 / ~631 candidates.

## 2026-05-06T00:34:00Z — Batch 66

**Step 0 (sync):** Already up to date.
**Step 1 (issues):** No open issues.
**Step 2 (freshness):** Skipped.
**Step 3 (growth):** Batch 66 — 5 new recipes.

| Slug | Stars | Notes |
|---|---|---|
| workadventure | 5,420 | Virtual office as 16-bit RPG — complex self-host (Livekit+Coturn) |
| suitecrm | 5,410 | Enterprise open-source CRM (SugarCRM fork) — PHP/MySQL |
| solidus | 5,291 | Rails eCommerce engine — Spree fork, stability-focused |
| tagspaces | 5,105 | Offline file organizer/tagger — Nextcloud WebDAV integration |
| umbraco | 5,168 | Friendly .NET CMS — dotnet CLI install |

Committed: 8f0c224. Total processed: 327 / ~626 candidates.

## 2026-05-06 01:55 UTC — Batch 67

Wrote 5 new recipes (apps 328–332):
- druid (13,985★) — Apache Druid, real-time analytics database, Docker Compose
- qloapps (13,085★) — Hotel reservation system and booking engine, PHP/MySQL
- myip (10,239★) — All-in-one IP toolbox, Docker
- remark42 (5,484★) — Privacy-respecting comment engine, Docker
- kill-bill (5,452★) — Subscription billing and payments platform, Docker Compose

Commit: bdc6a36 | batches_completed=67 | apps_processed=332

## 2026-05-06 01:55 UTC — Batch 67

Wrote 5 new recipes (apps 328-332):
- druid (13,985 stars) — Apache Druid, real-time analytics database, Docker Compose
- qloapps (13,085 stars) — Hotel reservation system and booking engine, PHP/MySQL
- myip (10,239 stars) — All-in-one IP toolbox, Docker
- remark42 (5,484 stars) — Privacy-respecting comment engine, Docker
- kill-bill (5,452 stars) — Subscription billing and payments platform, Docker Compose

Commit: bdc6a36 | batches_completed=67 | apps_processed=332

## 2026-05-06 01:55 UTC — Batch 67

Wrote 5 new recipes (apps 328-332):
- druid (13,985 stars) — Apache Druid, real-time analytics database, Docker Compose
- qloapps (13,085 stars) — Hotel reservation system and booking engine, PHP/MySQL
- myip (10,239 stars) — All-in-one IP toolbox, Docker
- remark42 (5,484 stars) — Privacy-respecting comment engine, Docker
- kill-bill (5,452 stars) — Subscription billing and payments platform, Docker Compose

Commit: bdc6a36 | batch 67

## 2026-05-06 02:40 UTC — Batch 68

Wrote 5 new recipes (apps 333-337):
- draw.io (5,167 stars) — Self-hosted diagramming, Docker single-container
- rstudio-server (4,989 stars) — Web IDE for R, Docker via rocker/rstudio
- pomerium (4,770 stars) — Identity-aware reverse proxy, Docker
- hi.events (3,766 stars) — Event ticketing platform, Docker all-in-one
- headphones (3,745 stars) — Automated music downloader, Python/Docker

Commit: 28926d3 | batch 68 | apps_processed=337

## 2026-05-06 03:10 UTC — Batch 69

Wrote 5 new recipes (apps 338-342):
- converse.js (3,247 stars) — Browser XMPP chat client, static/Node.js deploy
- jitsi-video-bridge (3,073 stars) — WebRTC SFU for Jitsi Meet, Debian/Docker
- gonic (2,373 stars) — Subsonic-compatible music streaming server, Docker
- gitit (2,261 stars) — Git-backed wiki, Haskell/stack install
- fusio (2,086 stars) — API management platform, Docker Compose

Commit: 0ca7d26 | batch 69 | apps_processed=342

## 2026-05-06 03:40 UTC — Batch 70

Wrote 5 new recipes (apps 343-347):
- ovenmediaengine (3,127 stars) — Sub-second latency streaming server, Docker
- kamailio (2,806 stars) — SIP signaling server, Debian/.deb + Docker
- fusion (2,069 stars) — Lightweight RSS reader, Docker/binary
- indico (2,065 stars) — CERN event management system, Docker Compose
- iredmail (1,792 stars) — Full mail server (Postfix+Dovecot), shell installer + Docker

Commit: d9a8718 | batch 70 | apps_processed=347

## 2026-05-06 03:55 UTC — Batch 71

Wrote 5 new recipes (apps 348-352):
- openstreetmap (2,709 stars) — OSM website/API Ruby on Rails app, Docker/Passenger
- peergos (2,403 stars) — Encrypted P2P file storage + social platform, Java/Docker
- pretix (2,386 stars) — Event ticket sales platform, Docker Compose
- pydio (2,200 stars) — Enterprise file sharing platform (Pydio Cells), Docker
- pigallery-2 (2,174 stars) — Directory-first photo gallery, Docker

Commit: 6a4d842 | batch 71 | apps_processed=352

## 2026-05-06T04:10:00Z

- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open issues, nothing to address
- Step 2: catalog-check.json last_checked_at=2026-05-04 (2 days ago) — within 7-day window, skipped
- Step 3: catalog growth (awesome-selfhosted-data, batch 67)
  - 599 net-new candidates identified
  - Top 5 by stars (excluding already-in-catalog): vendure (8088), lura (6767), stackstorm (6458), onlyoffice (6485), tiny-file-manager (5876)
  - Recipes authored and committed: commit dd47f7c
  - batches_completed: 67, apps_processed: 332

## 2026-05-06T04:33:00Z

- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open issues
- Step 2: catalog-check within 7-day window — skipped
- Step 3: catalog growth (awesome-selfhosted-data, batch 68)
  - Top 5 by stars (skipping proprietary/games/already-in-catalog): octobot (5841), tinyproxy (5816), unison (5259), trailbase (4869), sish (4595)
  - Recipes authored and committed: commit c0ef8e1
  - batches_completed: 68, apps_processed: 337

## 2026-05-06T04:52:00Z

- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open issues
- Step 2: catalog-check within 7-day window — skipped
- Step 3: catalog growth (awesome-selfhosted-data, batch 69)
  - Top 5 by stars (skipping proprietary/games/already-in-catalog): joomla (5077), motioneye (4584), octobox (4462), nominatim (4228), open-source-pos (4186)
  - Recipes authored and committed: commit c7daf5b
  - batches_completed: 69, apps_processed: 342

## 2026-05-06T05:11:00Z

- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open issues
- Step 2: catalog-check within 7-day window — skipped
- Step 3: catalog growth (awesome-selfhosted-data, batch 70)
  - Top 5 by stars (skipping recurring skips): easy-appointments (4170), judge0-ce (4142), nullboard (4135), stringer (4113), openziti (4125)
  - Recipes authored and committed: commit 0bffe5d
  - batches_completed: 70, apps_processed: 347

## 2026-05-06T05:30:00Z

- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open issues
- Step 2: catalog-check within 7-day window — skipped
- Step 3: catalog growth (awesome-selfhosted-data, batch 71)
  - Top 5 by stars: yacy (3904), nextcloud-memories (3758), swag (3651), modoboa (3480), pimcore (3749)
  - Recipes authored and committed: commit 43fef5a
  - batches_completed: 71, apps_processed: 352

## 2026-05-06T07:18Z — Batch 72

- Git pull: already up to date
- GitHub issues: 0 open
- Catalog check: skipped (within 7-day window)
- Batch 72 (5 recipes added, commit 29a9da7):
  - microweber (3,407 ⭐) MIT — drag-and-drop CMS/website builder on Laravel
  - shopware-community-edition (3,331 ⭐) MIT — headless e-commerce platform on Symfony/Vue
  - openfire (3,022 ⭐) Apache-2.0 — XMPP/Jabber real-time collaboration server
  - lowdefy (2,961 ⭐) Apache-2.0 — config-first internal tools builder on Next.js
  - mirotalk-sfu (2,958 ⭐) AGPL-3.0 — self-hosted WebRTC video conferencing (mediasoup SFU)
- Skips this run: lobehub (proprietary), wiki.js/element (in catalog), october/a-dark-room/wesnoth/untrusted (proprietary/games), sure/transfer.sh (in catalog), rudderstack (Elastic-2.0), joomla!/easy!appointments/judge0-ce/swag/pimcore (prior batches or non-OSI), openspeedtest (speed-test slug in catalog)
- Progress: batches_completed=72, apps_processed=357

## 2026-05-06T07:53Z — Batch 73

- Git pull: already up to date
- GitHub issues: 0 open
- Catalog check: within 7-day window, skipped
- Batch 73 (5 recipes, commit 1c7d0b9):
  - weechat (3,315 ⭐) GPL-3.0 — fast extensible terminal IRC/chat client
  - svix (3,185 ⭐) MIT — enterprise webhook delivery service (self-hosted)
  - baikal (3,138 ⭐) GPL-3.0 — lightweight CalDAV/CardDAV server (sabre/dav)
  - llm-harbor (2,898 ⭐) Apache-2.0 — local LLM stack orchestrator via Docker Compose
  - nextcloudpi (2,897 ⭐) GPL-2.0 — Nextcloud image/installer optimized for Raspberry Pi
- Progress: batches_completed=73, apps_processed=362
- 2026-05-06: batch 74 — dub, misago, mpd, matchering, directory-lister

## 2026-05-06 13:16 UTC

- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open issues, nothing to action
- Step 2: catalog-check — last_checked_at 2026-05-04, <7 days ago, skipped
- Step 3: catalog growth (awesome-selfhosted, batch 81)
  - Committed batch 80 (retroshare, routr, sabredav, middleware, revive-adserver) — 592c66d
  - Wrote 5 new recipes: apaxy (1921★), briefkasten (1175★), bitcart (934★), scoold (916★), bugzilla (822★)
  - Committed batch 81 — dd92324
  - Progress: batches_completed=81, apps_processed=402

## 2026-05-06 13:31 UTC

- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open, nothing to action
- Step 2: catalog-check — last_checked_at 2026-05-04, <7 days, skipped
- Step 3: catalog growth (awesome-selfhosted, batch 82)
  - Wrote 5 new recipes: cups (1600★), dspace (1060★), docat (896★), domjudge (885★), bencher (832★)
  - Committed batch 82 — e73b180
  - Progress: batches_completed=82, apps_processed=407

## 2026-05-06 13:51 UTC

- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open, nothing to action
- Step 2: catalog-check — last_checked_at 2026-05-04, <7 days, skipped
- Step 3: catalog growth (awesome-selfhosted, batch 83)
  - Wrote 5 new recipes: featbit (1797★), fluidd (1729★), forward-email (1572★), globaleaks (1475★), htmly (1330★)
  - Committed batch 83 — 93974c7
  - Progress: batches_completed=83, apps_processed=412

## 2026-05-06 14:10 UTC

- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open, nothing to action
- Step 2: catalog-check — <7 days since last check, skipped
- Step 3: catalog growth (awesome-selfhosted, batch 84)
  - Wrote 5 new recipes: homelabos (1279★), farmos (1268★), flyimg (1203★), gerrit (1177★), homegallery (1117★)
  - Committed batch 84 — 4d3a957
  - Progress: batches_completed=84, apps_processed=417

## 2026-05-06 14:25 UTC

- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open, nothing to action
- Step 2: catalog-check — last_checked_at 2026-05-04, <7 days, skipped
- Step 3: catalog growth (awesome-selfhosted, batch 85)
  - Wrote 5 new recipes: elgg (1671★), elabftw (1327★), discount-bandit (676★), bin (660★), dpaste (636★)
  - Committed batch 85 — e2cd11b
  - Progress: batches_completed=85, apps_processed=422

## 2026-05-06T15:07:58Z
- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open
- Step 2: catalog freshness — skip (last checked 2026-05-04, within 7-day window)
- Step 3: catalog growth
  - Batch 86 committed (from previous session): cyrus-imap, bolt-cms, django-crm, contao, archivesspace — commit 06e86fe
  - Batch 87: hypersomnia (1524★), kirby (1500★), keygen (1444★), iobroker (1365★), inspircd (1314★) — commit 913a285
  - Recipes in catalog: 1707 | Batches completed: 87 | Apps processed: 437

## 2026-05-06T15:28:27Z
- Step 0: git pull — already up to date
- Step 1: GitHub issues — 0 open
- Step 2: catalog freshness — skip (last checked 2026-05-04, within 7-day window)
- Step 3: catalog growth
  - Batch 88: it-tools-by-sharevb (1309★), hyphanet (1175★), fess (1109★), fusionpbx (1001★), glowing-bear (971★) — commit 6622029
  - Recipes in catalog: 1712 | Batches completed: 88 | Apps processed: 442

## 2026-05-06T16:23Z — Batches 89 & 90
- Synced repo (up to date), 0 open GitHub issues
- **Batch 89** committed (608de09): kiwi-irc, itflow, espial, gaseous-server, karaoke-eternal
- **Batch 90** committed (f2fd477): kottster (1152★), known (1112★), kiwix-serve (855★), haven (773★), kibitzr (714★)
- Progress: batches_completed=90, apps_processed=452, recipes_in_catalog=1717
- ~493 candidates remaining

## 2026-05-06T16:41:18Z — Batch 91
- **Batch 91** committed (ec534bb): lancache (874★), firefox-account-server (674★), enigma-12-bbs (641★), fredy (615★), gibbon (602★)
- Progress: batches_completed=91, apps_processed=457, recipes_in_catalog=1722
- ~488 candidates remaining

## 2026-05-06T16:45:09Z — Batch 92
- **Batch 92** committed (15c4913): koha (559★), graphweaver (549★), ledgersmb (532★), ilias (482★), hitobito (466★)
- Progress: batches_completed=92, apps_processed=462, recipes_in_catalog=1727
- ~483 candidates remaining

## 2026-05-06T17:35:00Z — Batch 93
- Synced repo (up to date after batch 92 commit)
- GitHub issues: 0 open
- Catalog freshness check: not due until ~2026-05-11
- Rebuilt candidate list: ~321 remaining after fresh comm diff
- Batch 93 (5 recipes): openrouteservice (1885★), mantisbt (1762★), openremote (1744★), part-db (1607★), livecodes (1429★)
- Built dist bundles, committed 438659b, pushed to main
- Catalog: 1737 recipes total

## 2026-05-06T18:00:00Z — Batch 94
- Synced repo (up to date)
- GitHub issues: 0 open
- Batch 94 (5 recipes): mta-sa (1744★), mongooseim (1735★), opensips (1464★), otter-wiki (1411★), modx (1395★)
- Built dist bundles, committed 3d7334b, pushed to main

## 2026-05-06T18:20:00Z — Batch 95
- Synced repo (up to date)
- GitHub issues: 0 open
- Batch 95 (5 recipes): moode-audio (1331★), open-food-network (1241★), nefarious (1234★), mybb (1215★), ossn (1206★)
- Built dist bundles, committed 1f249a5, pushed to main

## 2026-05-06 19:04 UTC

- Completed batch 96: ofbiz, offen, libretime (commit 83cb24c)
- Completed batch 97: osem, pictshare, pretalx, notifo, opentrashmail (commit 4926bac)
- Catalog now at ~1752 recipes, 487 apps processed from awesome-selfhosted source
- GitHub issues: 0 open

## 2026-05-06T20:54:00Z

- Committed batch 101 (leftover untracked files): tileserver-gl, yopass, wbo, sqlpage, selfoss → commit 728f017
- Fixed malformed awesome-selfhosted-progress.json
- Verified no open GitHub issues (0 open issues)
- catalog-check.json: last_checked 2026-05-04 — not yet 7 days, skipped
- Batch 102 (by star count from remaining 440 candidates): lobehub (75k★), easy-appointments (4k★), october-cms (11k★), mirotalk-c2c (507★), servas (805★) → commit 3b980f1
- Catalog now: 1780 recipes, 512 apps processed from awesome-selfhosted-data, 102 batches

## 2026-05-06T21:24:00Z

- GitHub issues: 0 open — nothing to do
- catalog-check.json: last checked 2026-05-04, not yet 7 days — skipped
- Batch 103 (by star count): shelf (2.6k★), sharetribe (2.4k★), sogo (2.1k★), sipcapture-homer (1.9k★), socioboard (1.4k★) → commit f2e29b6
- Catalog now: 1783 recipes, 517 apps processed from awesome-selfhosted-data, 103 batches, 432 candidates remaining

## 2026-05-06T21:45:00Z

- GitHub issues: 0 open — nothing to do
- catalog-check: last checked 2026-05-04 — not yet 7 days, skipped
- Batch 104 (by star count): sure (8k★), transfer-sh (15.8k★), the-battle-for-wesnoth (6.6k★), untrusted (4.7k★), webthings-gateway (2.6k★) → commit 633224a
- Catalog now: 1788 recipes, 522 apps processed, 104 batches, 427 candidates remaining

## 2026-05-06T22:45:00Z — Batch 105

**Step 0:** git pull — already up to date.
**Step 1:** GitHub issues — 0 open, nothing to action.
**Step 2:** Catalog freshness — last_checked_at 2026-05-04, not yet 7 days, skipped.
**Step 3:** Batch 105 — 5 recipes written and pushed:
- veloren (2,400★) — GPL-3.0 voxel RPG dedicated server
- static-web-server (2,200★) — Apache-2.0/MIT Rust static file server
- tox (2,600★) — GPL-3.0 P2P encrypted messaging bootstrap node
- wayback (2,182★) — GPL-3.0 web archiving toolkit
- znc (2,108★) — Apache-2.0 IRC bouncer

**Commit:** f7370e0 | **Catalog size:** 1,794 | **Apps processed:** 527/817

## 2026-05-06T23:20:00Z — Batch 106

**Step 0:** git pull — already up to date.
**Step 1:** GitHub issues — 0 open, nothing to action.
**Step 2:** Catalog freshness — last_checked_at 2026-05-04, not yet 7 days, skipped.
**Step 3:** Batch 106 — 5 recipes written and pushed (skipped zim — desktop GUI app):
- zot-oci-registry (2,137★) — Apache-2.0 OCI-native container registry
- traduora (2,118★) — AGPL-3.0 translation management platform
- tasks.md (2,101★) — MIT file-based Kanban board
- websoft9 (2,096★) — LGPL-3.0 web-based PaaS / app deployment panel
- wildduck (2,091★) — EUPL-1.2 scalable IMAP/POP3 mail server

**Commit:** 93bd32a | **Catalog size:** 1,799 | **Apps processed:** 532/817

## 2026-05-06T23:50:00Z — Batch 107

**Step 0:** git pull — already up to date.
**Step 1:** GitHub issues — 0 open, nothing to action.
**Step 2:** Catalog freshness — last_checked_at 2026-05-04, not yet 7 days, skipped.
**Step 3:** Batch 107 — 5 recipes written and pushed (skipped zim — desktop GUI):
- tuwunel (2,007★) — Apache-2.0 high-perf Matrix homeserver in Rust
- ustreamer (1,969★) — GPL-3.0 MJPEG V4L2 streaming server
- zenko-cloudserver (1,917★) — Apache-2.0 S3-compatible object storage
- swingmusic (1,857★) — MIT self-hosted music streaming server
- startos (1,842★) — MIT personal server Linux OS with browser GUI

**Commit:** 28b8144 | **Catalog size:** 1,804 | **Apps processed:** 537/817

## 2026-05-07T00:10Z — Batch 108
- git pull: already up to date
- GitHub issues: 0 open
- Catalog freshness: last checked 2026-05-04, not yet 7 days — skipped
- Batch 108 apps (by stars): µstreamer (1969★), talkyard (1808★), teampass (1788★), statistics-for-strava (1691★), uusec-waf (1643★)
- Skipped (already in catalog): wiki.js, transfer.sh, joomla, swag, openspeedtest, october-cms, baikal
- Skipped: zim (desktop GUI text editor, not a server app)
- Commit: df2af73
- Remaining candidates: ~407

## 2026-05-07T00:22Z — Heartbeat

- git pull: already up to date
- GitHub issues: 0 open
- Catalog freshness: last checked 2026-05-04, not yet 7 days — skipped
- µStreamer (1969★) already existed as ustreamer.md — skipped
- Batch 108: zentao (1594★), wintercms (1490★), utask (1374★), sist2 (1253★), tracks (1227★)
- Commit: f62ac58 — pushed to main
- Catalog size: 1813 recipes
- Apps processed: 542 / ~817 remaining candidates: ~273

## 2026-05-07T00:37Z — Heartbeat

- Continued mid-batch from prior turn
- Batch 109: weewx (1157★), uguu (1151★), websurfx (1092★), vvveb-cms (1048★), sigal (938★)
- Commit: b2e4e3b — pushed to main
- Catalog size: 1818 recipes
- Apps processed: 547

## 2026-05-07T00:52Z — Heartbeat

- git pull: already up to date
- GitHub issues: 0 open
- Catalog freshness: skipped (checked 2026-05-04, not yet 7 days)
- Scanned uncatalogued slugs: 399 remaining; many high-star ones already exist under alternate slugs
- Batch 110: zim (2156★), writing (1114★), shaper (1108★), thelia (873★), textpattern (862★)
- Commit: 7cd4bc4 — pushed to main
- Catalog size: 1823 recipes

## 2026-05-07T00:57Z — Heartbeat

- Continued mid-batch from prior turn
- Batch 111: wondercms (722★), simple-machines-forum (718★), superdesk (731★), zero-k (800★), rconcli (655★)
- Commit: 8a54160 — pushed to main
- Catalog size: 1828 recipes
- Remaining uncatalogued: ~389 items, mostly sub-600★ or commercial/proprietary

## 2026-05-07T01:30Z — Heartbeat

- Batch 112: scribble-rs (633), stretto (632), webtor (566), shkeeper (561), rei3 (560)
- Fixed truncated shkeeper.md from prior heredoc error
- Commit: 983a827 — pushed to main
- Catalog size: 1833 recipes
- 0 open GitHub issues
- Next: xandikos (559), omeka (534), unrealircd (513), red-eclipse-2 (511), titra (493)

## 2026-05-07T01:45Z — Heartbeat

- Batch 113: xandikos (559), omeka (534), unrealircd (513), red-eclipse-2 (511), titra (493)
- Commit: b1e91ff — pushed to main
- Catalog size: 1838 recipes
- 0 open GitHub issues
- Next candidates: mistserver (492), omeka-s (481), readflow (468), rss-monster (466), operational.co (460)

## 2026-05-07T02:15Z — Heartbeat

- Batch 114: mistserver (492), omeka-s (481), readflow (468), rss-monster (466), inventaire (458)
- Commit: 902d560 — pushed to main
- Catalog size: 1843 recipes
- 0 open GitHub issues
- Next candidates: operational.co (460), plugnmeet (456), self-host-blocks (455), teammapper (454), suroi (450)

## 2026-05-07T02:30Z — Heartbeat

- Batch 115: operational-co (460), plugnmeet (456), self-host-blocks (455), teammapper (454), suroi (450)
- Commit: 5b7bbae — pushed to main
- Catalog size: 1848 recipes
- 0 open GitHub issues
- Next candidates: check uncatalogued list for ~450★ and below

## 2026-05-07T02:45Z — Heartbeat

- Batch 116: awstats (425), couchcms (372), collective-access-providence (367), daily-stars-explorer (352), bitpoll (303)
- Commit: 83198e8 — pushed to main
- Catalog size: 1853 recipes
- 0 open GitHub issues
- Next candidates from uncatalogued: channeltube (301), bookbounty (277), bluecherry (269), deleterr (299), coreshop (290)

## 2026-05-07T03:00Z — Heartbeat

- Batch 117: channeltube (301), bookbounty (277), deleterr (299), bluecherry (269), coreshop (290)
- Commit: c626356 — pushed to main
- Catalog size: 1858 recipes
- 0 open GitHub issues
- Uncatalogued list running low (< 60 items) — need rescan to find more

## 2026-05-07T05:10Z
- git pull: already up to date
- GitHub issues: 0 open
- catalog-check.json: last_checked_at 2026-05-04 (3 days ago), skipping freshness check (threshold 7 days)
- catalog growth: wrote 5 new recipes (rss2email 445★, wavelog 427★, qpixel 438★, syncloud 433★, relate 422★)
- committed batch 119 as e4541a7, pushed to main
- catalog now at 1,868 recipes; 354 uncatalogued ASD candidates remain

## 2026-05-07T06:15Z
- git pull: already up to date
- GitHub issues: 0 open
- catalog-check.json: last_checked_at 2026-05-04 (3 days ago), skipping freshness check (threshold 7 days)
- catalog growth: wrote 5 new recipes (f-droid 440★, openolat 421★, spectrum-2 417★, shhh 414★, xsrv 400★)
- committed batch 120 as 4a18cb6, pushed to main
- catalog now at 1,873 recipes

## 2026-05-07T06:40Z
- git pull: already up to date
- GitHub issues: 0 open
- catalog-check.json: last_checked_at 2026-05-04, skipping freshness check (3 days, threshold 7)
- catalog growth: wrote 5 new recipes (neonlink 397★, recipya 396★, plainpad 396★, geneweb 374★, synctube 373★)
- committed batch 121 as 6f9023d, pushed to main
- catalog now at 1,878 recipes

## 2026-05-07T07:10Z
- git pull: already up to date
- GitHub issues: 0 open
- catalog-check.json: last_checked_at 2026-05-04, skipping freshness check (3 days, threshold 7)
- catalog growth: wrote 5 new recipes (mycorrhiza-wiki 371★, vod2pod-rss 369★, ifm 367★, sourcebans++ 362★, mikochi 360★)
- committed batch 122 as ad5de21, pushed to main
- catalog now at 1,883 recipes

## 2026-05-07T08:07Z
- git pull: already up to date
- GitHub issues: 0 open
- catalog-check.json: last_checked_at 2026-05-04, skipping (3 days < 7 day threshold)
- Recomputed uncatalogued ranked list (335 remaining candidates)
- catalog growth: wrote 5 new recipes (mataroa 345★, lidatube 334★, kresus 334★, genealogy 334★, otobo 323★)
- committed batch 124 as 4745068, pushed to main
- catalog now at 1,893 recipes

## 2026-05-07T08:29Z
- git pull: already up to date
- GitHub issues: 0 open
- catalog-check.json: skipping (3 days < 7 day threshold)
- catalog growth: wrote 5 new recipes (homepage-by-tomershvueli 322★, zenphoto 317★, openreader 314★, youtubedl-server 309★, simple-nixos-mailserver 309★)
- committed batch 125 as ba5e0c3, pushed to main
- catalog now at 1,898 recipes

## 2026-05-07T08:44Z
- git pull: already up to date
- GitHub issues: 0 open
- catalog-check.json: skipping (3 days < 7 day threshold)
- skipped send(301) — already catalogued as send-visee.md
- catalog growth: wrote 5 new recipes (piler 304★, string-is 301★, fx 301★, goploader 300★, sympa 299★)
- committed batch 126 as e3d2582, pushed to main
- catalog now at 1,903 recipes

## 2026-05-07T09:29Z
- git pull: already up to date
- GitHub issues: 0 open
- catalog-check.json: skipping (3 days < 7 day threshold)
- catalog growth: wrote 5 new recipes (egroupware 290★, tiledesk 289★, supysonic 289★, ui-bakery 288★, kriss-feed 288★)
- committed batch 127 as 6d4bac6, pushed to main
- catalog now at 1,908 recipes

## 2026-05-07T10:29Z — Batches 128 + 129

**Batch 128** (`5335769`): files-sharing, mere-medical, mosparo, seatsurfing, tracim
**Batch 129** (`5da1bfb`): genea-app (265★), myfin-budget (264★), group-office (261★), dragonfly-mta (256★), fedora-commons-repository (250★)
Catalog: 1918 recipes. 0 open GitHub issues.
Next: hatsu (245★), buddypress (245★), easywi (244★), openhabittracker (241★), oxid-eshop (238★)

## 2026-05-07T10:44Z — Batch 130

**Batch 130** (`a9684e0`): hatsu (245★), buddypress (245★), easywi (244★), openhabittracker (241★), oxid-eshop (238★)
Catalog: 1923 recipes. 0 open GitHub issues.
Next: pluxml (234★), inginious (234★), ydl_api_ng (232★), piqueserver (232★), bubo-reader (231★)

## 2026-05-07T10:59Z — Batch 131

**Batch 131** (`68a25bc`): pluxml (234★), inginious (234★), ydl_api_ng (232★), piqueserver (232★), bubo-reader (231★)
Catalog: 1928 recipes. 0 open GitHub issues.
Next: feedmixer (228★), serendipity (224★), hyperkitty (221★), alfresco-community-edition (214★)
## 2026-05-07T11:48:42Z — batch 132
- feedmixer (228★), serendipity (224★), hyperkitty (221★), alfresco-community-edition (214★), amusewiki (213★)
- commit: 4f2b6ea
- 0 open GitHub issues


## 2026-05-07T11:59:00Z — batch 133
- flatpress (209★), rgit (208★), txtdot (207★), gramps-web (203★), traq (202★)
- commit: 25fdb6f
- 0 open GitHub issues

## 2026-05-07T11:59:00Z — batch 133
- flatpress (209★), rgit (208★), txtdot (207★), gramps-web (203★), traq (202★)
- commit: 25fdb6f
- 0 open GitHub issues

## 2026-05-07T11:59:00Z — batch 133
- flatpress (209★), rgit (208★), txtdot (207★), gramps-web (203★), traq (202★)
- commit: 25fdb6f
- 0 open GitHub issues

## 2026-05-07T12:29:00Z — batch 134
- local-content-share (446★), 015 (348★), dragonfly-mail-agent (256★), samvera-hyrax (197★), robust-irc (194★)
- commit: fb2b496
- 0 open GitHub issues

## 2026-05-07T12:49:00Z — batch 135
- cmyflix (192★), hiccup (191★), fmd-server (191★), eda (191★), mytinytodo (190★)
- skipped cloud-seeder (proprietary license)
- commit: a66f0f1
- 0 open GitHub issues

## 2026-05-07T13:08:00Z — batch 136
- poenskelisten (190★), our-shopping-list (187★), mejiro (186★), flexisip (181★), atsumeru (176★)
- commit: 87143c4
- 0 open GitHub issues

## 2026-05-07T13:27:00Z — batch 137
- scm-manager (169★), clipbucket (162★), open-eclass (160★), islandora (157★), inveniordm (157★)
- commit: 89547cd
- 0 open GitHub issues

## 2026-05-07T13:48:00Z — batch 138
- sama (154★), evergreen (151★), motion-tools-antragsgruen (141★), mindwendel (133★), jarr (130★)
- commit: e4b4ca5
- 0 open GitHub issues
## 2026-05-07 14:40 UTC — Batch 139
- Synced repo: already up to date
- GitHub issues: 0 open
- Catalog freshness: last checked 2026-05-04, skipped (< 7 days)
- Batch 139 committed: depay(128★), privydrop(127★), prisme-analytics(125★), foodcoopshop(116★), flare(116★)
- Commit: 2bf528b
- Total apps processed: 697, catalog: 1968 files
- Next batch 140 candidates: hubleys(114★), portkey(107★), grr(101★), geo2tz(94★), dropserver(84★)

## 2026-05-07 15:00 UTC — Batch 140
- Batch 140 committed: hubleys(114★), portkey(107★), grr(101★), geo2tz(94★), dropserver(84★)
- Commit: e78d792
- Total apps processed: 702, catalog: ~1973 files
- Next batch 141 candidates: oddmuse(89★), rero-ils(87★), postorius(86★), llmkube(68★), galette(68★)

## 2026-05-07 15:15 UTC — Batch 141
- Batch 141 committed: oddmuse(89★), rero-ils(87★), postorius(86★), llmkube(68★), galette(68★)
- Commit: 5bc4fdf
- Total apps processed: 707, catalog: ~1978 files
- Next batch 142 candidates: rosariosis(65★), noosfero(65★), fork-recipes(65★), open-quartermaster(63★), homeserverhq(63★)

## 2026-05-07 15:30 UTC — Batch 142
- Batch 142 committed: rosariosis(65★), noosfero(65★), fork-recipes(65★), open-quartermaster(63★), homeserverhq(63★)
- Commit: e30743c
- Total apps processed: 712, catalog: ~1983 files
- Next batch 143 candidates: managemeals(59★), librekb(59★), limbas(58★), github-ntfy(58★), juntagrico(54★)

## 2026-05-07 15:45 UTC — Batch 143
- Batch 143 committed: managemeals(59★), librekb(59★), limbas(58★), github-ntfy(58★), juntagrico(54★)
- Commit: c259243
- Total apps processed: 717, catalog: ~1988 files
- Remaining high-star uncatalogued apps largely exhausted. May need re-scan for sub-54 star apps.

## 2026-05-07 16:00 UTC — Batch 144
- Re-scanned uncatalogued apps (165 total remaining), identified starred ones
- Batch 144 committed: antville(89★), bit(85★), engity-s-bifrost(79★), acp-admin(75★), econumo(73★)
- Commit: dd79ece
- Total apps processed: 722, catalog: ~1993 files
- Next batch 145 candidates: bicimon(62★), pomjs(49★), libreserver(48★), hitkeep(46★), minimal-git-server(44★)

## 2026-05-07 16:04 UTC — Batch 145
- Batch 145 committed: bicimon(62★), pomjs(49★), libreserver(48★), hitkeep(46★), minimal-git-server(44★)
- Commit: 5573069
- Total apps processed: 727, catalog: ~1998 files
- Remaining starred uncatalogued: minus-games(43), eprints(41), analog(38), e-label(36) — then sub-30 star apps only


## 2026-05-07 16:51 UTC — Batch 144

Apps: minus-games (43★), eprints (41★), analog (38★), e-label (36★), jirafeau (30★)
Commit: f61925f
Remaining uncatalogued: ~151 apps all under 30 stars

## 2026-05-07 17:06 UTC — Batch 145

Apps: poenskelisten (190★), memtly (27★), cubiks-2048 (25★), hive-pal (23★), esmira (22★)
Commit: 1ddac38
Note: poenskelisten was missed in earlier scans due to special character in slug (ø). Catalog now at ~2008 recipes.

## 2026-05-07 17:26 UTC — Batch 146

Apps: elixire (29★), openolitor (20★), mymangadb (19★), mybucks-online (18★), binpastes (15★)
Commit: 2eeef26
Catalog now at ~2013 recipes. ~141 uncatalogued remaining, all sub-15 stars.

## 2026-05-07 17:30 UTC — Batch 147

Apps: not-th-re (14★), gobookmarks (14★), lha (12★), d8a-tech (10★), listaway (8★)
Commit: 5068338
~136 uncatalogued remaining, all sub-8 stars.

## 2026-05-07 18:04 UTC — Batch 148

Apps: lesma (8★), s-cart (7★), cgit (GPL-2.0/C), chasquid (Apache-2.0/Go), citadel (GPL-3.0/C)
Commit: 1db3feb
~135 uncatalogued remaining.

## 2026-05-07 18:19 UTC — Batch 149

Apps: cardea (EUPL/Go), botwave (GPL/Python), 42links (BSD/CommonLisp), asmbb (EUPL/Assembly), clink (AGPL/C)
Commit: 9f39a83 (clink followup commit)
~129 uncatalogued remaining.

## 2026-05-07 18:52 UTC — Batch 150

Apps: collabora-online-development-edition (MPL-2.0/C++), cozy-cloud (GPL-3.0/Go), courier-mta (GPL-3.0/C), dotclear (GPL-2.0/PHP), exim (GPL-3.0/C)
Commit: 50f3e03
~125 uncatalogued remaining.

## 2026-05-07 19:07 UTC — Batch 151

Apps: cms-made-simple (GPL-2.0/PHP), emailrelay (GPL-3.0/C++), fhem (GPL-3.0/Perl), fossil (BSD-2-Clause/C), framadate (CECILL-B/PHP)
Commit: d2c8fdf
~120 uncatalogued remaining.

## 2026-05-07 19:37 UTC — Batch 152

Apps: feather-wiki (AGPL-3.0/JS), freepbx (GPL-2.0/PHP), g3proxy (Apache-2.0/Rust), garagehq (AGPL-3.0/Rust), git-annex (GPL-3.0/Haskell)
Commit: 9a8ace8
~115 uncatalogued remaining.

## 2026-05-07 19:52 UTC — Batch 153

Apps: gnunet (GPL-3.0/C), hamsterbase-tasks (AGPL-3.0/Docker), icecast-2 (GPL-2.0/C), form-io (MIT/Node.js), geeftlist (GPL-3.0/PHP+Docker)
Commit: 9cc11cc
~110 uncatalogued remaining.

## 2026-05-07 batch 154+155

- **Batch 154** (completing from prior session): drupal-commerce, edx, ownfoil, pacebin, pagure — commit ced8b0c
- **Batch 155**: dify-ai (139k stars, Apache-2.0+Commons-Clause, Docker), changedetection-io (31k stars, Apache-2.0, Docker/Python), prosody-im (MIT, Lua, XMPP server), samba (GPL-3.0, C, SMB/CIFS file sharing), jami (GPL-3.0, C++, distributed comms) — commit ab8de61
- ~96 uncatalogued slugs remaining (includes proprietary and special-char duplicates)
- Next batch candidates: Ladigitale digi* suite (10+ apps), apache-http-server, postfix, converse.js, plone

## 2026-05-07 20:52 UTC — Batch 156

- Apps: 0-a.d., apache-http-server, b1gmail, digiboard, digibunch
- Commit: f75e187
- Uncatalogued remaining: ~98
- Notes: Batch 155 (dify-ai, changedetection-io, prosody-im, samba, jami) already committed in prior session. 92five skipped (proprietary). digi* suite started (digiboard, digibunch). 0 open GitHub issues.

## 2026-05-07 21:07 UTC — Batch 157

- Apps: digibuzzer, digicard, digicut, digiface, digiflashcards
- Commit: a5a5af4
- Notes: Completed 5 more Ladigitale digi* apps. digicut requires COOP/COEP headers for FFMPEG.wasm. digiflashcards requires PHP 8.4+ strictly. ~93 uncatalogued remaining.

## 2026-05-07 21:22 UTC — Batch 158

- Apps: digimerge, digimindmap, digipad, digiquiz, digiread
- Commit: 8b1d26d
- Notes: digimerge repo uses capital-D "Digimerge" on Codeberg. digipad is heaviest digi* app (GraphicsMagick + Ghostscript + LibreOffice required). digiquiz bundles all H5P libraries. digiread has depends_3rdparty (server-side URL fetch). ~88 uncatalogued remaining.

## 2026-05-07 21:37 UTC — Batch 159

- Apps: digirecord, digiscreen, digislides, digisteps, digistorm
- Commit: 53b73d4
- Notes: digirecord/digisteps require PHP 8.4+ strictly + Composer. digisteps needs SQLite + GD extensions. digiscreen Composer optional (only for Digidrive). digislides repo is capital-D "Digislides". digistorm is Node.js+Redis (like digibuzzer/digipad) with S3_SERVER_TYPE aws/minio distinction. ~83 uncatalogued remaining.

## 2026-05-08 04:11 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues. Nothing to address.
- Step 2: Catalog freshness check → Skipped (last_checked_at: 2026-05-04, <7 days ago).
- Step 3: Catalog growth → Both batch sources (selfh.st, awesome-selfhosted-data) Complete. Self-Host Weekly 2026-05-08 not yet published (too early, expected ~16:00 UTC). No new signal to process.
- Status: Nothing to do. HEARTBEAT_OK.

## 2026-05-08 07:11 UTC — Heartbeat check

- Step 0: git pull → Already up to date.
- Step 1: GitHub issues → 0 open issues.
- Step 2: Catalog freshness → Skipped (<7 days since 2026-05-04).
- Step 3: Catalog growth → No new newsletter (2026-05-08 issue not yet published). No batch sources pending.
- Status: HEARTBEAT_OK.

## 2026-05-08 08:56 UTC — Heartbeat check

- Step 0: git pull → Already up to date.
- Step 1: GitHub issues → 0 open issues.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, <7 days).
- Step 3: Catalog growth → No new newsletter (latest still 2026-05-01; 2026-05-08 expected ~16:00 UTC). No new signal. Both batch sources complete.
- Status: Nothing to do. HEARTBEAT_OK.

## 2026-05-08 10:11 UTC — Heartbeat check

- Step 0: git pull → Already up to date.
- Step 1: GitHub issues → 0 open issues.
- Step 2: Catalog freshness → Skipped (<7 days since 2026-05-04).
- Step 3: Catalog growth → No new signal. Self-Host Weekly 2026-05-08 not yet published (expected ~16:00 UTC).
- Status: HEARTBEAT_OK.

## 2026-05-08 11:11 UTC — Heartbeat check

- Step 0: git pull → Already up to date.
- Step 1: GitHub issues → 0 open. Nothing to address.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, <7 days).
- Step 3: Newsletter → 2026-05-08 issue not yet published (expected ~16:00 UTC). No new signal.
- Status: HEARTBEAT_OK.

## 2026-05-08 11:41 UTC — Heartbeat check

- Step 0: git pull → Already up to date.
- Step 1: GitHub issues → 0 open. Nothing to address.
- Step 2: Catalog freshness → Skipped (<7 days since 2026-05-04).
- Step 3: Catalog growth → Self-Host Weekly 2026-05-08 not yet published (~16:00 UTC expected). No new signal.
- Status: HEARTBEAT_OK.

## 2026-05-09 04:12 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues. Nothing to address.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, 5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources (selfh.st, awesome-selfhosted-data) complete. Self-Host Weekly 2026-05-08 not yet published (latest is 2026-05-01, expected ~16:00 UTC today). No new signal to process.
- Status: HEARTBEAT_OK.

## 2026-05-09 05:11 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues. Nothing to address.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, 5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources (selfh.st, awesome-selfhosted-data) complete. Self-Host Weekly 2026-05-08 not yet published (latest still 2026-05-01). No new signal to process.
- Status: HEARTBEAT_OK.

## 2026-05-09 05:27 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues. Nothing to address.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, 5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources (selfh.st, awesome-selfhosted-data) complete. Self-Host Weekly 2026-05-08 not yet published (latest in RSS feed is still 2026-05-01; 2026-05-08 URL returns 404). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 05:42 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (GitHub API returned empty array).
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, 5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted 817 net-new). Self-Host Weekly 2026-05-08 still not published (RSS latest = 2026-05-01; 2026-05-08 URL returns 404). No new signal. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 05:57 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array).
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, 5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted 817 net-new, 169 batches). Self-Host Weekly 2026-05-08 not yet published (RSS latest still 2026-05-01; 2026-05-08 URL returns 404). No new signal. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 06:12 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, 5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted 817 net-new, 169 batches). Self-Host Weekly 2026-05-08 still not published (selfh.st/weekly latest still 2026-05-01; 2026-05-08 URL returns 404). No new signal. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 06:27 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, 5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted 817 net-new, 169 batches). Self-Host Weekly 2026-05-08 still not published (HTTP 404; latest in RSS = 2026-05-01, already processed via issue #43). No new signal. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 06:42 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, 5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches) complete. Self-Host Weekly 2026-05-08 still not published (RSS latest = 2026-05-01; 2026-05-08 URL returns 404). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 06:56 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, 5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Self-Host Weekly 2026-05-08 still not published (HTTP 404; RSS latest = 2026-05-01). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 07:12 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, 5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Continuous sources: no open GitHub issues; Self-Host Weekly 2026-05-08 not yet published. No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 07:27 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, ~5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Continuous sources: no open GitHub issues; Self-Host Weekly 2026-05-08 still not published (HTTP 404; RSS latest = 2026-05-01, already processed via issue #43). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 07:42 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, ~5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Continuous sources: no open GitHub issues; Self-Host Weekly 2026-05-08 still not published (HTTP 404; RSS latest = 2026-05-01, already processed via issue #43). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 07:57 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, ~5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Continuous sources: no open GitHub issues; Self-Host Weekly 2026-05-08 still not published (HTTP 301 → homepage; RSS latest = 2026-05-01, already processed via issue #43). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 08:12 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array). issues-log.json initialized (was missing in /workspace/progress/).
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, ~5 days ago — <7 day threshold not met). Spot-checked 20 repos manually: all active (not archived), all pushed within last ~30 days. Repos checked: Bubka/2FAuth (v6.1.3), actualbudget/actual (v26.5.2), AdguardTeam/AdGuardHome (v0.107.74), Admidio/admidio (v5.0.9), activepieces/activepieces (v0.82.2), electerious/Ackee (v3.6.0), 1Panel-dev/1Panel (v2.1.12), bakito/adguardhome-sync (v0.9.0), ActivityWatch/activitywatch (v0.13.2), RARgames/4gaBoards (v3.3.6), vrana/adminer (v5.4.2), adnanh/webhook (2.8.3), seanmorley15/AdventureLog (v0.12.0), toeverything/AFFiNE (v0.26.3), agregarr/agregarr (v2.4.2), Aider-AI/aider (v0.86.0), airbytehq/airbyte (v2.0.0). No archived/moved/renamed repos found. No recipe updates needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Continuous sources: no open GitHub issues; Self-Host Weekly 2026-05-08 still not published (RSS latest = 2026-05-01, already processed via issue #43). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 08:27 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, ~5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Continuous sources: no open GitHub issues; Self-Host Weekly 2026-05-08 still not published (HTTP 404; RSS latest = 2026-05-01, already processed). Newsletter noted taking break next week; next issue expected 2026-05-15. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 08:42 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, ~5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Continuous sources: no open GitHub issues; Self-Host Weekly 2026-05-08 still not published (HTTP 404; RSS latest = 2026-05-01, already processed). Newsletter noted taking break — next issue expected 2026-05-15. No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 08:57 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, ~5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Continuous sources: no open GitHub issues; Self-Host Weekly newsletter latest issue still 2026-05-01 (already processed via issue #43). Newsletter on break; next issue expected 2026-05-15. No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 09:12 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, ~5 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Continuous sources: no open GitHub issues; Self-Host Weekly RSS latest still 2026-05-01 (already processed via issue #43). Newsletter confirmed on break; next issue expected 2026-05-15. No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 09:27 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04, ~4.76 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Continuous sources: no open GitHub issues; Self-Host Weekly RSS latest still 2026-05-01 (already processed via issue #43; newsletter on break, next issue expected 2026-05-15). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 09:42 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-04T15:14Z, ~4.75 days ago — <7 day threshold not met).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Continuous sources: no open GitHub issues; Self-Host Weekly RSS latest still 2026-05-01 (already processed via issue #43; newsletter on break, next issue expected 2026-05-15). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 10:00 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated with new timestamp.
- Step 2: Catalog freshness → Run on 19 recipes (catalog-check.json previously at 2026-05-04, ~5 days old — threshold check triggered early due to missing progress/catalog-check.json in workspace). Checked: activepieces, actual-budget, adguard-home, ackee, affine, gitea, nextcloud, vaultwarden, immich, paperless-ngx, uptime-kuma, portainer, mealie, stirling-pdf, grocy, homer, linkwarden, komga, jellyfin. **4 updates made:**
  - `mealie.md`: v3.16.0 → v3.17.0 (upstream latest 2026-05-06)
  - `immich.md`: example version pin v2.1.0 → v2.7.5 (upstream latest 2026-04-13)
  - `linkwarden.md`: meilisearch v1.12.8 → v1.43.0 (upstream latest 2026-05-04)
  - `activepieces.md`: example compose note updated to 0.82.2 (upstream latest 2026-05-07)
  - Commit: `4da5c73` — pushed to main.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Newsletter: latest is Self-Host Weekly 2026-05-01 (already processed); next expected 2026-05-15 (Fridays). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK (with freshness updates committed).

## 2026-05-09 10:15 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-09T10:00:00Z, only 15 minutes ago — well within 7-day threshold). Prior run at 10:00 UTC already performed freshness check with 4 updates committed (mealie, immich, linkwarden, activepieces).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Continuous sources: no open GitHub issues; Self-Host Weekly newsletter on break, latest is 2026-05-01 (already processed via issue #43), next expected 2026-05-15. No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 10:30 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (last_checked_at 2026-05-09T10:00:00Z — only ~30 min ago, well within 7-day threshold). Freshness run at 10:00 UTC already committed 4 updates (mealie, immich, linkwarden, activepieces).
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Continuous sources: no open GitHub issues; Self-Host Weekly 2026-05-08 returns HTTP 404 (newsletter on break; next issue expected 2026-05-15). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 10:45 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json unchanged (last_checked_at: 2026-05-09T10:30:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~45 min ago, well within 7-day threshold). Freshness run at 10:00 UTC committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → All batch sources complete. selfh.st: 1,274/1,274 (1,257 done + 17 skipped). awesome-selfhosted-data: 169 batches, ~817 net-new, source complete as of 2026-05-08T02:26:00Z. awesome-selfhosted upstream: only bot metadata update since 2026-05-08 (no new apps). Self-Host Weekly newsletter: latest is 2026-05-01 (already processed), 2026-05-08 issue still 404 (not yet published). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 11:00 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated with new timestamp (2026-05-09T11:00:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~1 hour ago, well within 7-day threshold). Freshness run at 10:00 UTC committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → All batch sources complete. selfh.st: 1,274/1,274 (1,257 done + 17 skipped). awesome-selfhosted-data: 169 batches, ~817 net-new, source complete as of 2026-05-08T02:26:00Z. Self-Host Weekly newsletter: 2026-05-09 issue returns HTTP 404 (not yet published; next expected 2026-05-15). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 11:15 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~1h15m ago, well within 7-day threshold). Freshness run at 10:00 UTC committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → All batch sources complete. selfh.st: 1,274/1,274 (1,257 done + 17 skipped). awesome-selfhosted-data: 169 batches, ~817 net-new, source complete as of 2026-05-08T02:26:00Z. Self-Host Weekly newsletter: next expected 2026-05-15 (2026-05-08 issue still 404). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 11:30 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json unchanged.
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~1h30m ago, well within 7-day threshold). Freshness run at 10:00 UTC committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → All batch sources complete. selfh.st: 1,274/1,274 (1,257 done + 17 skipped). awesome-selfhosted-data: 169 batches, ~817 net-new, source complete as of 2026-05-08T02:26:00Z. Self-Host Weekly newsletter: 2026-05-08 issue still HTTP 404 (not yet published; next expected 2026-05-15). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 11:46 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json unchanged (last_checked_at: 2026-05-09T10:45:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~1h46m ago, well within 7-day threshold). Freshness run at 10:00 UTC already committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → All batch sources complete. selfh.st: 1,274/1,274 (1,257 done + 17 skipped). awesome-selfhosted-data: 169 batches, ~817 net-new, source complete as of 2026-05-08T02:26:00Z. Self-Host Weekly newsletter: 2026-05-09 issue returns HTTP 404 (not yet published; next expected 2026-05-15). No new signal to process. Catalog at 2,117 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 12:00 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T12:00:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~2h ago, well within 7-day threshold). Freshness run at 10:00 UTC committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 817 net-new, 169 batches). Self-Host Weekly newsletter: latest is 2026-05-01 (already processed via issue #43). Newsletter on break; next issue expected 2026-05-15. NEW: Found that `hound.md` was missing from catalog despite Hound being mentioned in the 2026-05-01 newsletter (Content Spotlight app `grimmory` was processed but `hound` — mentioned in Weekly Highlights — was not). Fetched upstream README (github.com/Hound-Media-Server/hound) and docker-compose.yml. Wrote `hound.md` recipe. Build: `./scripts/build-dist.sh all` → OK. Committed + pushed: fa567bb "open-forge: add hound — hybrid media server (P2P+local library)". Catalog now at 2,118 recipes.
- Status: 1 new recipe added (hound.md).

## 2026-05-09 12:16 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T12:16:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~2h16m ago, well within 7-day threshold). Previous freshness run committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: RSS feed confirms latest issue is 2026-05-01 (already processed). 2026-05-08 and 2026-05-15 issues both return HTTP 404. No new signal to process. Catalog at 2,118 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 12:30 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T12:30:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~2h30m ago, well within 7-day threshold). Previous freshness run committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: RSS feed confirms latest issue is still 2026-05-01 (already processed). 2026-05-08 and 2026-05-15 issues both return HTTP 404. No new signal to process. Catalog at 2,118 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 12:45 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T12:45:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~2h45m ago, well within 7-day threshold). Previous freshness run committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: RSS feed confirms latest issue is still 2026-05-01 (already processed). 2026-05-08 and 2026-05-15 issues both return HTTP 404. No new signal to process. Catalog at 2,118 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 13:01 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T13:01:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~3h01m ago, well within 7-day threshold). Previous freshness run committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: RSS confirms latest issue is 2026-05-01 (already processed). 2026-05-08 issue returns HTTP 404 (not yet published). NEW: Found `rahoot.md` missing from catalog — Rahoot (github.com/Ralex91/Rahoot) was mentioned in the 2026-05-01 newsletter but not previously catalogued. Fetched upstream README and compose.yml. Wrote `rahoot.md` recipe. Build: `./scripts/build-dist.sh all` → OK. Committed + pushed: 7c91dd8 "open-forge: batch 170 — rahoot (self-hosted Kahoot-style quiz platform)". Catalog now at 2,119 recipes.
- Status: 1 new recipe added (rahoot.md).

## 2026-05-09 13:15 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T13:15:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~3h15m ago, well within 7-day threshold). Previous freshness run committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: Ghost API confirms latest issue is 2026-05-01 (already processed). 2026-05-08 and 2026-05-15 both return HTTP 404 (not yet published). Next newsletter expected 2026-05-15. No new signal to process. Catalog at 2,119 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 13:31 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T13:31:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~3h31m ago, well within 7-day threshold). Previous freshness run committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: 2026-05-08 and 2026-05-15 both return HTTP 404 (not yet published). Latest processed issue remains 2026-05-01. No new signal to process. Catalog at 2,119 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 13:46 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T13:46:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~3h46m ago, well within 7-day threshold). Previous freshness run committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: RSS confirms latest issue is still 2026-05-01 (already processed). 2026-05-08 and 2026-05-15 both return HTTP 404 (not yet published). Next newsletter expected 2026-05-15. No new signal to process. Catalog at 2,119 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 14:01 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T14:01:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~4h01m ago, well within 7-day threshold). Previous freshness run committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: RSS confirms latest issue is still 2026-05-01 (already processed). 2026-05-08 and 2026-05-15 both return HTTP 404 (not yet published). Next newsletter expected 2026-05-15. No new signal to process. Catalog at 2,119 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 14:16 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T14:16:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~4h16m ago, well within 7-day threshold). Previous freshness run committed 4 updates (mealie, immich, linkwarden, activepieces). No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: 2026-05-08 and 2026-05-15 both return HTTP 404 (not yet published). Latest processed issue remains 2026-05-01. Next newsletter expected 2026-05-15. No new signal to process. Catalog at 2,119 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 14:31 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T14:31:00Z).
- Step 2: Catalog freshness → catalog-check.json was missing from workspace root progress/ (previous sessions wrote to open-forge/progress/). Ran freshness check on 15 recipes. Findings:
  - `activepieces.md`: upstream compose.yml now ships `0.83.0`; recipe referenced stale `0.82.2` note — updated. Committed + pushed: b6ae88b.
  - All other 14 checked recipes: no stale versions, no archived/moved repos (akkoma on akkoma.dev, aliasvault confirmed at aliasvault/aliasvault). No other changes needed.
  - Created catalog-check.json at progress/ root.
- Step 3: Catalog growth → Both batch sources complete. Self-Host Weekly: 2026-05-08 and 2026-05-15 both return HTTP 404 (not yet published). Latest processed issue remains 2026-05-01. Next newsletter expected 2026-05-15. No new signal to process. Catalog at 2,119 recipes.
- Status: 1 recipe updated (activepieces.md — compose version reference 0.82.2 → 0.83.0).

## 2026-05-09 14:45 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T14:45:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T14:31:00Z — only ~14 min ago, well within 7-day threshold). Previous freshness run checked 15 recipes, updated activepieces.md (0.82.2 → 0.83.0). No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: RSS feed confirms latest issue is still 2026-05-01 (already processed). 2026-05-08 and 2026-05-15 both return HTTP 404 (not yet published). Next newsletter expected 2026-05-08 (Friday). No new signal to process. Catalog at 2,119 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 15:01 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T15:01:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~5h01m ago, well within 7-day threshold). Previous freshness run checked 15 recipes, updated activepieces.md (0.83.0). No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: 2026-05-08 and 2026-05-15 both return HTTP 404 (not yet published). Latest processed issue remains 2026-05-01. Next newsletter expected 2026-05-15. No new signal to process. Catalog at 2,119 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 15:16 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T15:16:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~5h16m ago, well within 7-day threshold). Previous freshness run checked 15 recipes, updated activepieces.md (0.83.0), mealie.md, immich.md, linkwarden.md. No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches). Self-Host Weekly: RSS confirms latest issue is still 2026-05-01 (already processed — all 7 newsletter apps verified in catalog). 2026-05-08 and 2026-05-09 both return HTTP 404 (not yet published). Next newsletter expected 2026-05-15. No new signal to process. Catalog at 2,119 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 15:31 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T15:31:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T14:31:00Z — only ~1h ago, well within 7-day threshold). Previous freshness run (10:00 UTC) checked recipes and updated mealie.md, immich.md, linkwarden.md, activepieces.md. Second run (14:31 UTC) confirmed activepieces 0.83.0. No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: RSS feed confirms latest issue is still 2026-05-01 (already processed). 2026-05-08 returns HTTP 404 (not yet published). Next newsletter expected 2026-05-15. No new signal to process. Catalog at 2,119 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 15:46 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T15:46:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — well within 7-day threshold). Previous freshness runs today updated mealie.md, immich.md, linkwarden.md, activepieces.md. No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: Issues #123, #124, #125 all return HTTP 404 — not yet published. Latest processed issue remains 2026-05-01. Next newsletter expected 2026-05-15. No new signal to process. Catalog at 2,119 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 16:01 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T16:01:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~6h ago, well within 7-day threshold). Previous freshness runs today updated mealie.md, immich.md, linkwarden.md, activepieces.md (0.83.0). No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: RSS feed confirms latest issue is still 2026-05-01 (already processed). 2026-05-08 returns HTTP 404 (not yet published). Next newsletter expected 2026-05-15. No new signal to process. Catalog at 2,119 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 16:16 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T16:16:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~6h16m ago, well within 7-day threshold). Previous freshness runs today updated mealie.md, immich.md, linkwarden.md, activepieces.md (0.83.0). No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: 2026-05-08 and 2026-05-15 both return HTTP 404 (not yet published). Latest processed issue remains 2026-05-01. Next newsletter expected 2026-05-15. No new signal to process. Catalog at 2,119 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 16:31 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T16:31:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~6.5h ago, well within 7-day threshold). Previous freshness run updated mealie.md, immich.md, linkwarden.md, activepieces.md. No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: RSS feed confirms latest issue is still 2026-05-01 (already processed). The 2026-05-08 issue returns HTTP 301 redirect to a 404 "Page not found" — not yet published. Newsletter publishes on Fridays; next expected 2026-05-15. No new signal to process. Catalog at 2,119 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09 16:46 UTC — Heartbeat check

- Step 0: `git pull --rebase --autostash` → Already up to date.
- Step 1: GitHub issues → 0 open issues (API returned empty array []). issues-log.json updated (last_checked_at: 2026-05-09T16:46:00Z).
- Step 2: Catalog freshness → Skipped (catalog-check.json last_checked_at: 2026-05-09T10:00:00Z — only ~6h46m ago, well within 7-day threshold). Previous freshness runs today updated mealie.md, immich.md, linkwarden.md, activepieces.md. No re-check needed.
- Step 3: Catalog growth → Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: 2026-05-08 and 2026-05-15 both return HTTP 404 (not yet published). Latest processed issue remains 2026-05-01. Next newsletter expected 2026-05-15. No new signal to process. Catalog at 2,119 recipes.
- Status: HEARTBEAT_OK.

## 2026-05-09T17:05:00Z

- Step 0: git pull — already up to date (531bef9).
- Step 1: GitHub issues — 0 open issues, nothing to action. Updated issues-log.json timestamp.
- Step 2: Catalog freshness — last checked 2026-05-09T14:31:00Z (~2.5h ago), within 7-day window, skipped.
- Step 3: Catalog growth — Both batch sources complete (selfh.st 1,274/1,274; awesome-selfhosted-data 169 batches, ~817 net-new). Self-Host Weekly newsletter: RSS feed confirms latest issue is still 2026-05-01 (already processed). 2026-05-08 returns HTTP 404 (not yet published). Next newsletter expected 2026-05-15.
  - Cross-referenced selfh.st directory (1,282 slugs) against 2,119 existing recipes → found 39 uncatalogued slugs.
  - After deduplication (cosmos-server→cosmos.md, ara-records-ansible→ara.md, gladys-assistant→gladys.md, zot-registry→zot.md, an-otter-wiki→otterwiki.md, zaneops→zane-ops.md, z-wave-js-ui→zwave-js-ui.md, lightweight-music-server→lms.md) — 31 genuinely new candidates remain.
  - Skipped: dockhand (BSL 1.1, README explicitly prohibits AI scraping), runson (AWS CloudFormation, not standard Docker self-host), global-threat-map (requires Mapbox+Valyu API keys, no Docker compose), nextcloud-office (Nextcloud plugin/app, not standalone).
  - Wrote 4 new recipes (batch 171):
    - `operately.md` — Open-source company OS (OKRs/goals/projects/teams), Apache 2.0, Docker Compose single-host installer, 457★
    - `cmintey-wishlist.md` — Sharable wishlist for friends/family, MIT, single Docker container + SQLite, 548★
    - `mybibliotecha.md` — Personal library & reading tracker (Goodreads alternative), MIT, Docker Compose + KuzuDB, 562★
    - `proxcenter.md` — Proxmox VE multi-cluster management UI (CE edition), AGPL-3.0, curl installer → Docker Compose, 873★
  - Build: `./scripts/build-dist.sh all` → OK.
  - Committed + pushed: 9e4688f "open-forge: batch 171 — operately, cmintey-wishlist, mybibliotecha, proxcenter".
  - Catalog now at 2,123 recipes.
