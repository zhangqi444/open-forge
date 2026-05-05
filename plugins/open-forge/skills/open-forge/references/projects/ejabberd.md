# ejabberd

ejabberd is a robust, massively-scalable, open-source XMPP server written in Erlang/OTP. It also includes an MQTT broker and SIP service. Used by major companies to power real-time messaging at scale.

**Official site:** https://www.ejabberd.im  
**GitHub:** https://github.com/processone/ejabberd  
**Upstream README:** https://github.com/processone/ejabberd/blob/master/README.md  
**Container docs:** https://github.com/processone/ejabberd/blob/master/CONTAINER.md  
**Docker image:** `ghcr.io/processone/ejabberd` (multi-arch) or `ejabberd/ecs` on Docker Hub (x64 only)  
**License:** GPL-2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker (single container) | Simplest deployment |
| Any Linux VM / VPS | Docker Compose | With database backend |
| Kubernetes | Helm (`sando38/helm-ejabberd`) | Community Helm chart |
| Bare metal | `.deb` / `.rpm` / installer | Official packages from ProcessOne |

---

## Inputs to Collect

### Before deployment
- XMPP domain (e.g. `example.com`) — this is **permanent**; clients use it as their JID domain
- Admin JID(s) (e.g. `admin@example.com`)
- TLS certificates for the XMPP domain (Let's Encrypt / bring your own)
- Database backend: internal Mnesia (default, small deployments) or external PostgreSQL / MySQL (recommended for production)
- `ERLANG_COOKIE` — secret for Erlang cluster communication (required if clustering)

### Optional
- STUN/TURN server for voice/video (ejabberd includes built-in STUN/TURN)
- LDAP / external auth backend
- S3 / upload module for file sharing (mod_http_upload)
- Cluster node count

---

## Software-Layer Concerns

### Docker single-node (quickstart)
```bash
docker run --name ejabberd -d \
  -p 5222:5222 -p 5269:5269 -p 5280:5280 \
  -e XMPP_DOMAIN=example.com \
  -v ejabberd:/home/ejabberd \
  ghcr.io/processone/ejabberd
```

### Docker Compose with PostgreSQL

```yaml
version: "3.8"
services:
  ejabberd:
    image: ghcr.io/processone/ejabberd:latest
    container_name: ejabberd
    environment:
      - XMPP_DOMAIN=example.com
      - ERLANG_COOKIE=supersecretcookie
    ports:
      - "5222:5222"   # XMPP client
      - "5269:5269"   # XMPP server-to-server
      - "5280:5280"   # HTTP / admin web
      - "5281:5281"   # HTTPS
      - "1883:1883"   # MQTT
    volumes:
      - ejabberd_data:/home/ejabberd
    restart: unless-stopped

volumes:
  ejabberd_data:
```

### Config file
- `ejabberd.yml` — main config; can be mounted at `/home/ejabberd/conf/ejabberd.yml`
- Full reference: https://docs.ejabberd.im/admin/configuration/

### Key ports
| Port | Protocol | Purpose |
|------|---------|---------|
| 5222 | TCP | XMPP client connections (STARTTLS) |
| 5223 | TCP | XMPP client connections (legacy SSL) |
| 5269 | TCP | XMPP server-to-server federation |
| 5280 | TCP | HTTP (admin console, BOSH, WebSocket) |
| 5281 | TCP | HTTPS |
| 1883 | TCP | MQTT |
| 3478 | UDP/TCP | STUN/TURN |

### Data directory
- Container: `/home/ejabberd/` (database, logs, certs, config, uploads)
- Always mount this as a persistent volume

### Admin user creation
```bash
docker exec -it ejabberd bin/ejabberdctl register admin example.com secretpassword
docker exec -it ejabberd bin/ejabberdctl grant_role admin@example.com administrator
```

---

## Upgrade Procedure

1. Pull new image: `docker pull ghcr.io/processone/ejabberd:latest`
2. Stop: `docker compose down`
3. Start with new image: `docker compose up -d`
4. ejabberd performs DB schema migrations automatically on startup
5. Check logs: `docker logs ejabberd`

---

## Gotchas

- **XMPP domain is permanent** — changing the domain after user accounts are created requires a full database migration; choose wisely
- **TLS required for federation** — server-to-server federation with other XMPP servers requires valid TLS certificates (not self-signed)
- **Mnesia vs SQL** — built-in Mnesia database is fine for small deployments but doesn't support SQL queries or easy inspection; switch to PostgreSQL for anything production
- **Port 5269 must be reachable** — for federation with other XMPP servers; requires firewall/NAT rules
- **`register` is open by default** — disable `mod_register` in `ejabberd.yml` if you don't want public self-registration
- **MQTT port** — the built-in MQTT broker listens on 1883; useful for IoT alongside messaging

---

## Links

- Docs: https://docs.ejabberd.im/
- Configuration: https://docs.ejabberd.im/admin/configuration/
- Container guide: https://github.com/processone/ejabberd/blob/master/CONTAINER.md
- Helm chart: https://github.com/sando38/helm-ejabberd
