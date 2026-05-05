---
name: iodine
description: iodine recipe for open-forge. Tunnel IPv4 over DNS — lets you reach the internet when only DNS queries are allowed. Server (iodined) + client (iodine) setup. Upstream: https://github.com/yarrick/iodine
---

# iodine

Tunnel IPv4 data through a DNS server. When internet access is firewalled but DNS queries are permitted, iodine lets you tunnel traffic through DNS to reach a server you control. Enables a SOCKS5 proxy or full tunnel over DNS.

7,834 stars · ISC

Upstream: https://github.com/yarrick/iodine
Website: https://code.kryo.se/iodine/

## What it is

iodine encodes IPv4 packets as DNS queries/responses, creating a virtual network link through DNS infrastructure. Use cases:

- **Captive portals** — Hotel/airport Wi-Fi that requires payment but allows DNS
- **Locked-down corporate networks** — Where HTTPS is blocked but DNS passes
- **Firewall bypass** — When only UDP/53 or TCP/53 egress is permitted

The setup requires:
1. A VPS/server with a public IP running `iodined` (the server daemon)
2. A domain you control with an NS record delegating a subdomain to your server
3. The client running `iodine` from behind the restrictive network

**Performance note**: DNS tunneling is slow (typically 1–10 KB/s effective throughput depending on the DNS infrastructure). It is intended for emergency access, not regular use.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| apt/package manager | Debian/Ubuntu repos | Easiest on common distros |
| Build from source | https://github.com/yarrick/iodine | Latest version, other platforms |

## Requirements

- A domain you control (e.g., `example.com`)
- A subdomain delegated via NS record to your server's IP (e.g., `t.example.com NS your.server.ip`)
- Server: any Linux/macOS VPS with a public IP and UDP/53 or TCP/53 open
- Client: Linux, macOS, Windows (with OpenVPN TAP driver)
- Both sides must run the **same version** of iodine

## DNS delegation setup (one-time)

Add these DNS records at your domain registrar or DNS provider:

    # A record for your iodine server's name
    ns.example.com.  A  <YOUR_SERVER_IP>

    # NS record delegating the tunnel subdomain to your server
    t.example.com.   NS  ns.example.com.

Replace `example.com` with your domain, `t` with any subdomain label you choose.

**DNS propagation takes up to 48 hours.** Test with: `dig ns t.example.com`

## Install

### Debian/Ubuntu (server and client)

    apt install -y iodine

### Build from source

    apt install -y build-essential libz-dev
    git clone https://github.com/yarrick/iodine.git
    cd iodine
    make
    make install

## Server setup (iodined)

Run on your VPS. Must be run as root (needs TUN device).

    # Basic start (foreground, for testing)
    iodined -f 10.0.0.1 t.example.com

    # With password
    iodined -f -P mysecretpassword 10.0.0.1 t.example.com

    # Specify listen interface/port (useful if port 53 is taken by another service)
    iodined -f -P mysecretpassword -p 5300 10.0.0.1 t.example.com

Arguments:
- `10.0.0.1` — tunnel network IP for the server (clients get addresses like 10.0.0.2, 10.0.0.3...)
- `t.example.com` — the delegated subdomain

### Firewall — open UDP 53

    ufw allow 53/udp
    # Or:
    iptables -A INPUT -p udp --dport 53 -j ACCEPT

### systemd service

    cat > /etc/systemd/system/iodined.service << 'SVCEOF'
    [Unit]
    Description=iodine DNS tunnel server
    After=network.target

    [Service]
    ExecStart=/usr/sbin/iodined -f -P mysecretpassword 10.0.0.1 t.example.com
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target
    SVCEOF

    systemctl daemon-reload
    systemctl enable --now iodined

## Client setup (iodine)

Run on the device behind the restrictive network. Must be run as root.

    # Connect to server
    iodine -f -P mysecretpassword t.example.com

    # If port 53 is blocked too, try TCP:
    iodine -f -T t.example.com -P mysecretpassword t.example.com

    # Specify DNS resolver explicitly (try the open internet resolver, not the local one)
    iodine -f -P mysecretpassword 8.8.8.8 t.example.com

On success, the client gets a tunnel IP (e.g., `10.0.0.2`) and can reach the server at `10.0.0.1`.

## Using the tunnel (SOCKS5 proxy)

Once the tunnel is up, SSH into your server through the tunnel and set up a SOCKS5 proxy:

    ssh -D 1080 -N user@10.0.0.1

Then configure your browser to use SOCKS5 proxy at `127.0.0.1:1080`.

## Upgrade

    apt update && apt upgrade iodine
    # Or rebuild from source and replace binaries

## Gotchas

- **Same version on both sides** — iodine does not maintain protocol backward compatibility. Server and client must be the same version. This is a hard requirement.
- **Root required** — Both `iodined` and `iodine` need root/sudo to create TUN devices.
- **DNS propagation delay** — NS record changes can take minutes to 48 hours to propagate. Test with `dig ns t.example.com @8.8.8.8`.
- **Port 53 conflicts** — If your server runs a DNS resolver (systemd-resolved, named, dnsmasq), it may already occupy UDP/53. Stop it or configure iodined to use a different port (`-p 5300`) and redirect with iptables.
- **Slow throughput** — DNS tunneling tops out at 1–10 KB/s effective. Suitable for SSH sessions and low-bandwidth access; not for streaming or large transfers.
- **Detection risk** — DNS tunneling is detectable by corporate firewalls. High query volume is a signature. Use for genuine emergencies, not regular bypassing.
- **TCP over DNS is very slow** — TCP-over-DNS suffers severe performance issues due to retransmission. Use SSH+SOCKS5 over the tunnel rather than raw TCP applications.

## Links

- GitHub: https://github.com/yarrick/iodine
- Website: https://code.kryo.se/iodine/
- README (full): https://github.com/yarrick/iodine/blob/master/README.md
