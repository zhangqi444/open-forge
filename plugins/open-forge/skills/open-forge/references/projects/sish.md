---
name: sish
description: sish recipe for open-forge. Self-hosted SSH tunnel server for HTTP(S)/WS(S)/TCP — an open-source ngrok/serveo alternative. Expose localhost services publicly using only SSH. Source: https://github.com/antoniomika/sish. Docs: https://docs.ssi.sh.
---

# sish

Self-hosted SSH tunneling server — an open-source alternative to ngrok and serveo. Users connect to a running sish server with standard SSH to create public HTTP(S), WS(S), or TCP tunnels to their localhost services. No custom client required; any SSH client works. Upstream: <https://github.com/antoniomika/sish>. Docs: <https://docs.ssi.sh>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS (public IP) | Docker (--net=host) | Recommended; net=host required for transparent TCP port binding |
| VPS (public IP) | Native binary | Pre-built releases for Linux/macOS/Windows |
| VPS (public IP) | Docker Compose | Use network_mode: host in compose |

> sish must run on a VPS or server with a public IP address. It cannot tunnel from behind a NAT (it IS the public endpoint).

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| domain | "Public domain for the sish server?" | e.g. tuns.example.com — subdomains become tunnel URLs |
| ssh | "SSH port for clients to connect to?" | Default: 2222 (avoid 22 to keep host SSH separate) |
| http | "HTTP/HTTPS ports?" | Default: 80/443 |
| auth | "Require SSH public key authentication?" | Recommended; place allowed pubkeys in pubkeys/ dir |
| tls | "TLS: Let's Encrypt or BYO certificates?" | sish can auto-provision Let's Encrypt via ACME |

## Software-layer concerns

- Config: command-line flags (pass in docker run command or entrypoint args); no config file format
- Data dirs:
  - ~/sish/ssl — TLS certificates
  - ~/sish/keys — sish server host keys
  - ~/sish/pubkeys — authorized SSH public keys (one per file)
- Default ports: SSH=2222, HTTP=80, HTTPS=443
- Authentication: --authentication=true + pubkeys/ dir, or --authentication=false for open (dangerous on public internet)
- TCP tunnels: bind to specific ports with -R <port>:localhost:<local-port> in SSH command
- SNI proxying: sish can route TLS by SNI without terminating it

### Docker run (recommended)

```bash
mkdir -p ~/sish/ssl ~/sish/keys ~/sish/pubkeys
cp ~/.ssh/id_ed25519.pub ~/sish/pubkeys/

docker run -itd --name sish \
  -v ~/sish/ssl:/ssl \
  -v ~/sish/keys:/keys \
  -v ~/sish/pubkeys:/pubkeys \
  --net=host \
  antoniomika/sish:latest \
  --ssh-address=:2222 \
  --http-address=:80 \
  --https-address=:443 \
  --https=true \
  --https-certificate-directory=/ssl \
  --authentication-keys-directory=/pubkeys \
  --private-keys-directory=/keys \
  --bind-random-ports=false \
  --domain=example.com
```

### Docker Compose

```yaml
services:
  sish:
    image: antoniomika/sish:latest
    network_mode: host
    volumes:
      - ~/sish/ssl:/ssl
      - ~/sish/keys:/keys
      - ~/sish/pubkeys:/pubkeys
    command: >
      --ssh-address=:2222
      --http-address=:80
      --https-address=:443
      --https=true
      --https-certificate-directory=/ssl
      --authentication-keys-directory=/pubkeys
      --private-keys-directory=/keys
      --bind-random-ports=false
      --domain=example.com
    restart: unless-stopped
```

### Client usage (from any machine)

```bash
# Expose local port 8080 as public HTTPS tunnel
ssh -p 2222 -R 80:localhost:8080 example.com

# Specific subdomain
ssh -p 2222 -R myapp:80:localhost:8080 example.com
# Creates: https://myapp.example.com

# TCP tunnel on port 3306
ssh -p 2222 -R 3306:localhost:3306 example.com
```

## Upgrade procedure

1. `docker pull antoniomika/sish:latest`
2. `docker stop sish && docker rm sish`
3. Re-run the docker run command with the same flags
4. Check release notes: https://github.com/antoniomika/sish/releases

## Gotchas

- **network_mode: host is required** for TCP tunneling to work correctly. Without it, Docker NAT prevents sish from binding arbitrary ports.
- **DNS wildcard record needed**: Add `*.example.com A <VPS-IP>` (and `example.com A <VPS-IP>`) to your DNS. Each tunnel gets a subdomain.
- **Authentication off = open relay**: Without `--authentication=true`, anyone can create tunnels through your server. Always require pubkey auth on public servers.
- **Port 22 conflict**: Run sish SSH on 2222 (or another non-standard port) so it doesn't conflict with the host's own SSH server.
- **Let's Encrypt rate limits**: sish can auto-provision certs per-subdomain. On busy servers with many unique subdomains, this can hit LE rate limits. Consider wildcard certs via DNS challenge instead.
- **Firewall**: Open ports 2222 (SSH), 80 (HTTP), 443 (HTTPS), and any TCP port range you allow for port-forwarding.
- **Managed alternative**: tuns.sh is the managed version of sish operated by the author if you want the convenience without self-hosting.

## Links

- Upstream repo: https://github.com/antoniomika/sish
- Docs: https://docs.ssi.sh
- Docker Hub: https://hub.docker.com/r/antoniomika/sish
- Managed service (tuns.sh): https://tuns.sh
- Release notes: https://github.com/antoniomika/sish/releases
- Sponsored by pico.sh: https://pico.sh
