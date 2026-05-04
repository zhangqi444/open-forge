# OpenReplay

Open-source session replay and product analytics platform. Watch how users interact with your app — see clicks, scrolls, rage clicks, network activity, JS errors, console logs, and Redux/Vuex store state. Self-hostable alternative to FullStory and LogRocket. 12K+ GitHub stars. Upstream: <https://github.com/openreplay/openreplay>. Docs: <https://docs.openreplay.com>.

> **Architecture note:** OpenReplay is a multi-service platform (20+ microservices). It is designed for deployment on a dedicated server (minimum 2 vCPU / 8 GB RAM) using a Docker Compose install script, or on Kubernetes via Helm.

## Compatible install methods

Verified against upstream README at <https://github.com/openreplay/openreplay#deployment-options>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (install script) | `git clone ... && bash scripts/docker-compose/install.sh` | ✅ | Standard self-hosted path. Recommended starting point. |
| Helm (Kubernetes) | <https://docs.openreplay.com/deployment/deploy-kubernetes> | ✅ | Production K8s deploy. |
| AWS | <https://docs.openreplay.com/deployment/deploy-aws> | ✅ | 1-click CloudFormation deployment. |
| GCP | <https://docs.openreplay.com/deployment/deploy-gcp> | ✅ | GCP marketplace / CLI deploy. |
| Azure | <https://docs.openreplay.com/deployment/deploy-azure> | ✅ | Azure deploy. |
| DigitalOcean | <https://docs.openreplay.com/deployment/deploy-digitalocean> | ✅ | DO 1-click droplet. |
| OpenReplay Cloud | <https://app.openreplay.com/signup> | ✅ (hosted) | Managed SaaS — free tier available. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| domain | "Domain for OpenReplay (e.g. `replay.example.com`)?" | Free-text | All |
| email | "Admin email address?" | Free-text | All |
| smtp | "SMTP host for notification emails (optional)?" | Free-text | Optional |

## Software-layer concerns

### System requirements

| Resource | Minimum | Recommended |
|---|---|---|
| CPU | 2 vCPU | 4 vCPU |
| RAM | 8 GB | 16 GB |
| Disk | 50 GB | 100 GB+ SSD |
| OS | Ubuntu 20.04+ | Ubuntu 22.04 |

OpenReplay is **not suitable for Docker Desktop or low-memory VMs.** Plan for a dedicated VM or cloud instance.

### Docker Compose install

```bash
git clone https://github.com/openreplay/openreplay
cd openreplay/scripts/docker-compose

# Run the interactive install script
bash install.sh
```

The install script will:
1. Check system requirements
2. Prompt for domain name and email
3. Generate configuration files
4. Pull all images and start the stack
5. Configure SSL via Let's Encrypt (if domain is set)

### Post-install

After install, visit `https://your-domain.com`. The setup wizard prompts you to create an admin account.

Get the initial admin invite link from the install output or:

```bash
cd openreplay/scripts/docker-compose
docker compose exec http python3 manage.py get_admin_link
```

### Tracker snippet

Add to your app's `<head>`:

```html
<script>
  var initOpts = {
    projectKey: "your-project-key",
    ingestPoint: "https://replay.example.com/ingest",
  };
  var startOpts = { userID: "" };
  (function(A,s,a,y,e,r){
    r=window.OpenReplay=[e,r,y,[s-1,e]];
    s=document.createElement('script');s.src=A;s.async=!s.defer;
    document.getElementsByTagName('head')[0].appendChild(s);
    r.start=function(v){r.push([0])};
    r.stop=function(v){r.push([1])};
  }("//static.openreplay.com/latest/openreplay.js",1,0,initOpts,startOpts));
</script>
```

Or via npm:

```bash
npm install @openreplay/tracker
```

```js
import OpenReplay from '@openreplay/tracker';

const tracker = new OpenReplay({
  projectKey: 'your-project-key',
  ingestPoint: 'https://replay.example.com/ingest',
});
tracker.start();
```

### Key features

- **Session replay** — pixel-perfect replay of user sessions
- **DevTools** — network requests, JS errors, console logs, store state (Redux, Vuex, MobX, NgRx)
- **Heatmaps** — click and scroll maps per page
- **Funnels** — conversion funnel analysis
- **Feature flags** — built-in flag management
- **Alerts** — notify on error spikes, performance regressions
- **Co-browsing** — assist users in real-time during a session

### Architecture

OpenReplay is composed of 20+ microservices. Key components:

| Component | Role |
|---|---|
| `http` | Main API + admin dashboard (Django) |
| `chalice` | Session data ingestion API |
| `sink` | Writes session data to object storage |
| `storage` | Serves recordings from object storage |
| `ender` | Ends sessions, triggers post-processing |
| `assets` | Serves static assets |
| `db` | PostgreSQL — metadata, projects, users |
| `minio` | Default object storage for recordings |
| `redis` | Cache and pub/sub |
| `kafka` | Event streaming between services |
| `caddy` | Reverse proxy + TLS |

### Data storage

| What | Where |
|---|---|
| Session metadata | PostgreSQL |
| Session recordings | MinIO (local object storage) or S3-compatible external |
| Assets (JS, CSS snapshots) | MinIO / object storage |

For production, configure an external S3 bucket by setting `S3_*` variables in `docker-compose/common.env`.

## Upgrade procedure

```bash
cd openreplay/scripts/docker-compose
git pull
bash install.sh --upgrade
```

Or follow the version-specific upgrade guide: <https://docs.openreplay.com/deployment/upgrade>

## Gotchas

- **Heavy system requirements.** 8 GB RAM minimum — OpenReplay runs 20+ microservices. A $5 VPS will not work.
- **Domain + TLS required for production.** The tracker snippet requires HTTPS to record in most browsers. Use the built-in Caddy TLS or put a load balancer with TLS in front.
- **MinIO is the default storage.** Session recordings are stored in local MinIO. For high-volume deployments, switch to S3-compatible external storage.
- **Kafka dependency.** OpenReplay uses Kafka for inter-service messaging — this adds significant memory overhead.
- **Not a stateless app.** State is spread across PostgreSQL, MinIO, and Redis. All three must be backed up together.
- **Privacy controls built-in.** You can sanitize inputs (`obscureInputs`), block specific elements, and exclude pages from recording.
- **License: ELv2 (Elastic License 2.0).** Free to self-host; cannot offer as a managed service to third parties.

## Links

- Upstream: <https://github.com/openreplay/openreplay>
- Docs: <https://docs.openreplay.com>
- Docker Compose deploy: <https://docs.openreplay.com/deployment/deploy-docker-compose>
- Kubernetes deploy: <https://docs.openreplay.com/deployment/deploy-kubernetes>
- Tracker JS reference: <https://docs.openreplay.com/sdk/constructor>
- Upgrade guide: <https://docs.openreplay.com/deployment/upgrade>
