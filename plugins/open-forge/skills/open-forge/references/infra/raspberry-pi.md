---
name: raspberry-pi-infra
description: Raspberry Pi infra adapter — install OpenClaw on a Pi 4 or Pi 5 running 64-bit Raspberry Pi OS for an always-on home self-host. Pair with `runtimes/native.md` for the install. Picked when the user has a Pi (or a small ARM SBC) and wants always-on operation with no recurring cloud bill.
---

# Raspberry Pi adapter

A Raspberry Pi 4 or 5 with 4 GB+ RAM is a great always-on host for OpenClaw — the gateway is lightweight (models run in the cloud via API), so even a Pi 4 handles it well. Power draw is ~5 W, so total electricity cost is < $1/month.

This is structurally a `byo-vps`-style adapter — open-forge does not flash the SD card or boot the Pi (that's a one-time physical act). Once the Pi is on the network with SSH enabled, we drive everything over SSH.

## Prerequisites

- Pi 4 or Pi 5 with 2 GB+ RAM (4 GB strongly recommended).
- 16 GB+ MicroSD card or USB SSD (SSD is dramatically faster + lasts longer).
- Official Pi power supply (under-volt warnings throttle CPU).
- 64-bit Raspberry Pi OS (**not** the 32-bit variant — many Node modules need ARM64).
- Network: Ethernet preferred; Wi-Fi works but flakier.

## Inputs to collect

| When | Question | Tool / format | Default |
|---|---|---|---|
| End of preflight | "Already flashed + booted?" | `AskUserQuestion`: `Yes — give me SSH details` / `No — walk me through Imager` | — |
| End of preflight (if No) | (instructions only) | Walk through Imager steps below | — |
| End of preflight | "Pi hostname?" | Free-text | `gateway-host` |
| End of preflight | "SSH user?" | Free-text | `<user from Imager>` |
| End of preflight | "Pi IP or hostname?" | Free-text | `<hostname>.local` (mDNS) |
| End of preflight | "RAM?" | `AskUserQuestion`: `2 GB` / `4 GB` / `8 GB` | — |
| End of preflight | "Timezone?" | Free-text (IANA, e.g. `America/Chicago`) | — |

Derived:

| Recorded as | Derived from |
|---|---|
| `outputs.host_user` | The user account from Imager |
| `outputs.public_address` | Pi's LAN IP or `<hostname>.local` |
| `outputs.add_swap` | `true` if RAM ≤ 2 GB |

## Flashing the OS (one-time, user-driven)

Walk the user through **Raspberry Pi Imager** (<https://www.raspberrypi.com/software/>):

1. Open Imager.
2. **Choose OS:** Raspberry Pi OS Lite (64-bit). Lite is headless — no desktop, smaller footprint, faster boot.
3. **Choose Storage:** SD card or USB SSD.
4. **Settings (gear icon):**
   - **Hostname:** `<user-chosen>`
   - **Enable SSH:** yes (use password or paste public key)
   - **Username + password:** save these — open-forge needs them later
   - **Wi-Fi:** if not Ethernet
   - **Locale + keyboard**
5. **Write.** Eject. Insert into the Pi. Boot.

After ~60s, the Pi joins the network. mDNS name is `<hostname>.local` from any LAN device that supports mDNS (most do).

## SSH in

```bash
ssh "<user>@<hostname>.local"
# or by IP from the user's router admin page
```

If the connection hangs, check that the LED on the Pi is steady (booted) and that mDNS resolution works (`ping <hostname>.local`). On Linux mDNS may need `avahi-daemon` running.

## Initial host setup

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y git curl ca-certificates build-essential

# Timezone (matters for cron + reminders)
sudo timedatectl set-timezone "$TIMEZONE"
```

`build-essential` is required because Node modules sometimes compile from source on ARM64.

### Add swap (mandatory for ≤ 2 GB Pis)

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Reduce swappiness — better for low-RAM ARM
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

Skip on Pi 4/5 with 8 GB if you'd rather not add swap.

### Install Node.js 24

The openclaw native installer auto-installs Node, but on Pi we pre-install via NodeSource for predictability:

```bash
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version       # expect v24.x
```

## Lightweight tweaks (optional but recommended)

```bash
# Free GPU memory on a headless Pi
echo 'gpu_mem=16' | sudo tee -a /boot/config.txt

# Disable services you won't use
sudo systemctl disable bluetooth cups avahi-daemon

# Disable Wi-Fi power management (drops are common otherwise)
sudo iwconfig wlan0 power off

# Wake-and-keep-CPU-cache for low-power Pi
grep -q 'NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache' ~/.bashrc || cat >> ~/.bashrc <<'EOF'
export NODE_COMPILE_CACHE=/var/tmp/openclaw-compile-cache
mkdir -p /var/tmp/openclaw-compile-cache
export OPENCLAW_NO_RESPAWN=1
EOF
```

`NODE_COMPILE_CACHE` speeds up repeated `openclaw` invocations on lower-power Pis.

## Now hand off to runtimes/native.md

```bash
curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash
exec $SHELL -l
openclaw onboard --install-daemon
sudo loginctl enable-linger "$USER"     # daemon survives logout
```

For ARM (aarch64), most Node modules work; native binaries occasionally need `linux-arm64` or `aarch64` releases. Check `uname -m` (should print `aarch64`) before troubleshooting.

## Access

Gateway binds to `127.0.0.1:18789`. Two paths:

```bash
# From a laptop on the same LAN — SSH tunnel
ssh -N -L 18789:127.0.0.1:18789 "<user>@<hostname>.local"
# Open: http://localhost:18789/#token=<TOKEN>

# Print the dashboard URL with token:
ssh "<user>@<hostname>.local" 'openclaw dashboard --no-open'
```

For remote-from-anywhere access, see [Tailscale integration](https://docs.openclaw.ai/gateway/tailscale) — install Tailscale on the Pi (`curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up --ssh`) and access from any device on the tailnet.

## Verification

Mark `provision` done only when all of:

- `ssh "<user>@<host>" 'openclaw status'` returns healthy.
- `ssh "<user>@<host>" 'systemctl --user is-active openclaw-gateway.service'` prints `active`.
- `free -h` shows swap configured (if RAM ≤ 2 GB).
- `vcgencmd get_throttled` returns `0x0` (no thermal/voltage throttling).

## Gotchas

- **32-bit Raspberry Pi OS will not work.** OpenClaw needs ARM64 (aarch64). Confirm with `uname -m`.
- **SD-card wear.** Heavy write workloads (logs, swap) wear out SD cards in months. USB SSD is strongly recommended for any always-on Pi.
- **Under-voltage throttles CPU silently.** `vcgencmd get_throttled` returns non-zero if the power supply is undersized. Use the official Pi PSU (5 V / 3 A for Pi 4, 5 V / 5 A for Pi 5).
- **Swap is mandatory on 2 GB Pis.** OpenClaw + Node fits in 2 GB at idle but spikes during plugin work — OOM-kill is common without swap.
- **Wi-Fi power management drops connections.** `iwconfig wlan0 power off` is a stable workaround; alternatively use Ethernet.
- **`enable-linger` is mandatory for headless reboot.** Without it, the gateway dies on logout and never starts back up.
- **Pi 4 + 4 GB is the practical minimum.** Pi 3 / Zero 2 W technically run aarch64 Linux but openclaw + Node makes them very slow; not recommended.

## Reference

- Raspberry Pi OS download: <https://www.raspberrypi.com/software/>
- USB SSD boot guide: <https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#usb-mass-storage-boot>
- Tailscale on Linux: <https://tailscale.com/kb/1031/install-linux>
- OpenClaw on Pi (upstream): <https://docs.openclaw.ai/install/raspberry-pi>
