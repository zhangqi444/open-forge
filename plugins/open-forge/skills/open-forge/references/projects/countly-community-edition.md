---
name: countly-community-edition
description: Countly Community Edition recipe for open-forge. Covers Docker and shell installer. Privacy-first analytics and customer engagement platform; tracks mobile, web, desktop, and IoT; plugin-based architecture; supports push notifications, crash reporting, and remote configuration. Sourced from https://github.com/countly/countly-server and https://support.countly.com/.
---

# Countly Community Edition

Privacy-first, AI-ready analytics and customer engagement platform. Tracks user behavior across mobile, web, desktop, and connected devices. Features: session analytics, event tracking, crash reporting, push notifications, remote configuration, A/B testing, in-app ratings, data compliance (GDPR), and customizable dashboards. Plugin-based architecture for modularity. Upstream: https://github.com/countly/countly-server. Docs: https://support.countly.com/. AGPL-3.0 (Countly Lite/Community Edition).

Countly also offers commercial Enterprise and Flex (managed) editions.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker | https://registry.hub.docker.com/r/countly/countly-server/ | Quick start and dev |
| Shell installer | https://support.countly.com/hc/en-us/articles/360036862332-Installing-the-Countly-Server | Ubuntu/CentOS production |
| Manual | https://support.countly.com/ | Custom environments |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Docker or shell installer?" | Drives path |
| domain | "Public URL or IP?" | For SDK configuration and API calls |
| port | "Expose on port 80 or custom port?" | Nginx listens on 80/443 |
| admin | "Admin email and password?" | Created on first start |

## Docker install

```sh
# Pull and run (includes MongoDB and Nginx internally)
docker run -d \
  --name countly \
  -p 80:80 \
  -p 443:443 \
  -v countly-data:/var/lib/mongodb \
  -v countly-logs:/opt/countly/log \
  countly/countly-server:latest
```

Access at http://localhost on first start — complete the setup wizard to create the admin account.

## Docker Compose

```yaml
version: "3.8"
services:
  countly:
    image: countly/countly-server:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - countly-data:/var/lib/mongodb
      - countly-logs:/opt/countly/log
    restart: unless-stopped

volumes:
  countly-data:
  countly-logs:
```

## Shell installer (Ubuntu/CentOS)

```sh
# Ubuntu
wget -qO- https://c.ly/install | bash

# Or use the bundled script from a release
wget https://github.com/Countly/countly-server/releases/download/vX.Y.Z/countly-server-X.Y.Z.tar.gz
tar -xzf countly-server-*.tar.gz
cd countly-server-*
bash bin/countly.install.sh
```

The installer sets up MongoDB, Nginx, and all Countly services automatically.

## SDK integration (example: web)

```html
<script>
  var Countly = Countly || {};
  Countly.q = Countly.q || [];
  Countly.app_key = 'YOUR_APP_KEY';
  Countly.url = 'http://your-countly-server.example.com';
  Countly.q.push(['track_sessions']);
  Countly.q.push(['track_pageview']);
  (function() {
    var d = document, g = d.createElement('script');
    g.type = 'text/javascript'; g.async = true;
    g.src = 'https://cdnjs.cloudflare.com/ajax/libs/countly-sdk-web/latest/countly.min.js';
    d.getElementsByTagName('head')[0].appendChild(g);
  })();
</script>
```

## Key ports

| Port | Purpose |
|---|---|
| 80/443 | Countly web dashboard + API endpoint |
| 27017 | MongoDB (internal; do not expose) |

## Upgrade procedure

```sh
# Shell install
cd /opt/countly
sudo bash bin/countly.upgrade.sh

# Docker: pull new image and recreate
docker pull countly/countly-server:latest
docker stop countly && docker rm countly
# Re-run docker run command with same volumes
```

Always back up MongoDB before upgrading. Countly upgrades migrate the schema automatically.

## Gotchas

- **MongoDB bundled** — The Docker image and shell installer include MongoDB internally; for production at scale, use an external MongoDB replica set and configure `config.js`.
- **AGPL-3.0 license** — Countly Community Edition is AGPL-3.0; if you modify and serve it over a network, you must release modifications. Enterprise/Flex editions are commercial.
- **SDK App Key** — Each app/platform (iOS, Android, web) gets a unique App Key from the dashboard; use this key (not the API key) in SDKs.
- **Push notifications** — Requires APNs (Apple) and FCM (Firebase) credentials configured per-app in the dashboard.
- **Data retention** — Community Edition does not include data aggregation limits; configure MongoDB size limits or `config.js` data retention settings for high-volume deployments.
- **Plugins** — Features are plugin-based; enable/disable plugins from Admin → Plugins. Some plugins (e.g., A/B testing, funnels) may be Enterprise-only.

## Links

- GitHub: https://github.com/countly/countly-server
- Installation guide: https://support.countly.com/hc/en-us/articles/360036862332-Installing-the-Countly-Server
- Docker image: https://hub.docker.com/r/countly/countly-server/
- SDK list: https://support.countly.com/hc/en-us/articles/360037236571-Downloading-and-Installing-SDKs
- API reference: https://api.count.ly/reference/
