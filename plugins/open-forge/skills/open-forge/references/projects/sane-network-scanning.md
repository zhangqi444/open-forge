---
name: sane-network-scanning-project
description: SANE Network Scanning recipe for open-forge. Allows remote network access to locally-attached scanners via saned daemon. Covers apt install and saned configuration. Based on upstream docs at http://sane-project.org/man/saned.8.html.
---

# SANE Network Scanning

Share locally-attached image acquisition devices (scanners, cameras) over the network using the SANE (Scanner Access Now Easy) daemon (`saned`). Clients anywhere on the LAN can scan using the remote device as if it were local. GPL-2.0. Upstream: http://sane-project.org. Docs: http://sane-project.org/man/saned.8.html.

SANE has two parts: the server (`saned`) runs on the machine with the physical scanner and exposes it on TCP port 6566. Clients install SANE and configure it to use the remote host — then any SANE-compatible app (GIMP, XSane, simple-scan) can scan over the network.

## Compatible install methods

| Method | Platform | When to use |
|---|---|---|
| apt / package manager | Debian, Ubuntu, Raspbian | Standard; simplest |
| Source build | Any Linux | Latest features; custom backends |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| config | "IP addresses/hostnames allowed to connect?" | Comma-separated IPs or CIDRs | Written to /etc/sane.d/saned.conf |
| config | "Scanner device (for testing)?" | e.g. /dev/usb/... | Used to verify detection |
| config | "Run saned as systemd socket-activated or standalone?" | systemd / standalone | systemd is standard on modern distros |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Server package | sane-utils (contains saned) |
| Client package | libsane (already present in sane-utils) |
| Port | TCP 6566 |
| Config (server) | /etc/sane.d/saned.conf — lists allowed client IPs |
| Config (client) | /etc/sane.d/net.conf — lists server hostname/IP |
| User/group | saned daemon runs as saned user; scanner device must be accessible to that user |
| USB scanners | May need udev rules for the saned user to access the USB device |
| systemd | Activated via saned.socket + saned@.service (modern distros) |

## Install: Server (machine with scanner attached)

Source: http://sane-project.org/man/saned.8.html

```bash
sudo apt-get update
sudo apt-get install sane-utils

# Verify scanner is detected locally
scanimage -L
```

### Configure allowed clients

Edit /etc/sane.d/saned.conf — add client IPs/hostnames one per line:

```
# /etc/sane.d/saned.conf
## Allow these hosts to connect:
192.168.1.0/24
192.168.1.50
```

### Enable saned via systemd socket activation

```bash
sudo systemctl enable saned.socket
sudo systemctl start saned.socket
sudo systemctl status saned.socket
```

### USB device permissions

If saned cannot access the scanner, add the saned user to the scanner group:

```bash
sudo usermod -aG scanner saned
# Also check /etc/udev/rules.d/ — some scanners need a udev rule:
# ATTRS{idVendor}=="04a9", ATTRS{idProduct}=="2228", MODE="0664", GROUP="scanner"
sudo udevadm control --reload-rules
sudo udevadm trigger
```

## Install: Client (machine that wants to scan remotely)

```bash
sudo apt-get install sane-utils

# Add server to net backend config
echo "192.168.1.100" | sudo tee -a /etc/sane.d/net.conf

# Verify the remote scanner is visible
scanimage -L
# Should show: device `net:192.168.1.100:...' ...
```

Use any SANE-compatible scanning app (simple-scan, XSane, GIMP) — they will use the remote scanner automatically.

## Firewall

On the server, allow TCP 6566 from the LAN:

```bash
sudo ufw allow from 192.168.1.0/24 to any port 6566 proto tcp
```

## Upgrade procedure

```bash
sudo apt-get upgrade sane-utils
sudo systemctl restart saned.socket
```

## Gotchas

- USB permissions are the most common failure: The saned user must have read/write access to the USB device. Add it to the scanner group and check udev rules.
- saned.conf must list client IPs: An empty or missing saned.conf will reject all connections.
- net.conf on client must list server: SANE clients won't discover remote scanners automatically — the server host must be in /etc/sane.d/net.conf.
- Local scanning still works: Enabling saned doesn't break local scanning on the server machine.
- LAN-only by design: SANE network scanning is unencrypted and unauthenticated beyond IP allowlisting. Do not expose port 6566 to the internet.

## Links

- Upstream: http://sane-project.org
- saned man page: http://sane-project.org/man/saned.8.html
- SANE net backend: http://sane-project.org/man/sane-net.5.html
- Debian wiki: https://wiki.debian.org/SaneOverNetwork
