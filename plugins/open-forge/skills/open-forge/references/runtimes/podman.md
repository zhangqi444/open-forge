---
name: podman-runtime
description: Cross-cutting runtime module for Podman-based deployments. Loaded whenever the user picks Podman (rootless, Docker-API-compatible) on any infra. Owns Podman install, rootless namespace setup, and Quadlet (systemd-user) integration. Project recipes own their own image / setup script / app-specific env. For OpenClaw specifically, the upstream `scripts/podman/setup.sh` is the source of truth — this module captures the surrounding host concerns.
---

# Podman runtime

A near drop-in replacement for Docker that runs **rootless** by default and integrates with `systemd --user` via Quadlet. Worth picking when:

- Running Docker as root is unacceptable (multi-tenant host, security-conscious deploy).
- The host is RHEL / Fedora / CentOS-derived where Podman is preinstalled.
- You want systemd-managed lifecycle without writing custom unit files.

## When this module is loaded

User answered the **how** question with anything Podman-flavored:

- "BYO VPS + Podman", "Hetzner CX + Podman", "Lightsail Ubuntu + Podman"
- "localhost + Podman" (Linux host; Podman on macOS uses a `podman machine` VM internally)

Skipped when the runtime is bundled by a vendor blueprint, when the chosen path is plain Docker, or when the project doesn't ship a Podman-aware setup script.

## Host requirements

- **Linux**: kernel ≥ 4.18 (for rootless). systemd is required for Quadlet auto-start (optional but recommended).
- **macOS** (Linux container support via `podman machine`): runs containers in a Linux VM under the hood. Some bind-mount edge cases differ from Linux-native — project recipes flag these.
- Disk: ≥ 20 GB free.
- RAM: ≥ 2 GB free; ≥ 4 GB for image builds that compile sources.

## Install Podman on the host

### Debian / Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y podman podman-compose
```

### RHEL / Fedora / Amazon Linux

```bash
sudo dnf install -y podman podman-compose
```

### macOS

```bash
brew install podman
podman machine init
podman machine start
```

Verify:

```bash
podman --version
podman info --format '{{.Host.RootlessNetworkCmd}}'   # should print a non-empty value on Linux rootless
podman run --rm hello-world
```

### Rootless namespace setup (Linux, one-time per user)

If `podman info` warns about subuid/subgid, fix the mappings (most distros do this automatically when the package installs):

```bash
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"
podman system migrate    # rebuilds rootless storage with the new mappings
```

## Rootless container basics

Project recipes specify the image, mounts, ports, and env vars. Generic patterns:

```bash
# Pull / build
podman pull <image>
podman build -t <local-tag> -f Containerfile .

# Run rootless with bind-mounts (note `--userns=keep-id` so host UID maps inside)
podman run -d --name <name> \
  --userns=keep-id \
  -v "$HOME/.<app>:/home/node/.<app>:Z" \   # :Z for SELinux relabeling on Fedora-likes
  -p 127.0.0.1:<port>:<port> \
  <image>

# Lifecycle
podman ps
podman logs -f <name>
podman restart <name>
podman stop <name>
podman rm -f <name>

# Exec / shell
podman exec -it <name> sh
```

`--userns=keep-id` is the critical rootless flag — it maps the host user's UID to the same UID inside the container, so bind-mounted host directories don't end up owned by an unmapped UID after the container writes to them.

## Quadlet (systemd-user integration)

Quadlet lets you write a **`.container`** file (kin to a systemd unit) and have systemd manage the container's lifecycle. No custom shell wrapper needed.

```bash
mkdir -p ~/.config/containers/systemd
cat > ~/.config/containers/systemd/<name>.container <<'EOF'
[Unit]
Description=<Project> rootless gateway

[Container]
Image=<image>:latest
ContainerName=<name>
PublishPort=127.0.0.1:18789:18789
Volume=%h/.<app>:/home/node/.<app>:Z
UserNS=keep-id
EnvironmentFile=%h/.<app>/.env

[Service]
Restart=on-failure
TimeoutStartSec=300

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user start <name>.service
systemctl --user status <name>.service
journalctl --user -u <name>.service -f
```

For boot persistence on a headless / SSH-only host (so the service survives logout):

```bash
sudo loginctl enable-linger "$(whoami)"
```

## docker-compose compatibility

`podman-compose` (a separate package) implements the docker-compose API on top of Podman. Most simple compose files work unchanged. Caveats:

- Compose's `network: host` works on Linux rootful Podman but not always rootless — test before relying.
- Compose `depends_on: condition: service_healthy` requires `podman-compose` v1.3+.
- Some older compose v3 features (`deploy:`) are accepted but ignored.

```bash
podman-compose up -d
podman-compose logs -f
podman-compose down
```

For projects that ship Quadlet files alongside / instead of compose, prefer the Quadlet path — better systemd integration.

## Firewall

Same model as Docker — project recipes specify which ports to expose; open them at the *infra* layer (cloud firewall, `ufw`, etc.). Default: keep app ports bound to `127.0.0.1` and reach via SSH tunnel.

Rootless Podman cannot bind to ports < 1024 by default. Either:

- Bind to a high port (`18789`, `8080`) and reverse-proxy from `:443` via a system-managed Caddy/nginx.
- Or grant the capability: `sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80` (then write to `/etc/sysctl.d/`).

## Common gotchas

- **`:Z` SELinux label trap.** On Fedora/RHEL/Amazon Linux, bind-mounts without `:Z` (or `:z` for shared) get blocked by SELinux at runtime. Symptom: `Permission denied` reading host files from inside the container even though host perms look correct. Fix: add `:Z` to every bind-mount.
- **Rootless can't restart on host reboot without linger.** `systemctl --user enable <name>` alone doesn't survive logout. Pair with `sudo loginctl enable-linger "$(whoami)"` once.
- **`podman` and `docker` produce different image stores.** A `docker pull <image>` won't show up in `podman images` and vice versa. They don't share state. Migrating from Docker → Podman requires re-pulling.
- **`docker.io` namespace.** Podman doesn't default to Docker Hub. Reference images by full name (`docker.io/library/postgres:16` rather than just `postgres:16`) or set a `registries.conf` short-name alias.
- **macOS `podman machine` resource limits.** Default VM is 2 CPU / 2 GB RAM, often too small for image builds. Resize: `podman machine stop && podman machine set --cpus 4 --memory 4096 && podman machine start`.
- **Rootless doesn't see `/var/run/docker.sock`.** Don't try to mount the Docker socket — Podman has its own at `/run/user/$UID/podman/podman.sock` if a project genuinely needs sibling-container access.
- **`podman-compose` is not Compose v2.** Some niche features differ. If a project's compose file relies on Docker-Compose-specific extensions, fall back to Docker.
- **`UserNS=keep-id` is mandatory for bind-mount writability.** Without it, container writes go in as a high subuid the host can't read.

## Reference

- Podman docs: <https://docs.podman.io/>
- Quadlet (systemd integration): <https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html>
- Rootless setup: <https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md>
- `podman-compose`: <https://github.com/containers/podman-compose>
