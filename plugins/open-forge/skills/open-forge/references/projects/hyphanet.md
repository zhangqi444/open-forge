---
name: hyphanet
description: Hyphanet recipe for open-forge. Censorship-resistant peer-to-peer anonymous network for sharing files, browsing freesites, and chatting. Formerly known as Freenet. Java-based daemon with a local web UI. Source: https://github.com/hyphanet/fred
---

# Hyphanet

Censorship-resistant peer-to-peer platform for anonymous communication and file sharing. Provides a distributed, encrypted, decentralized datastore. Supports anonymous file sharing, freesites (web sites hosted within the network), forums (FMS, Sone), and chat — all accessible only through a locally running Hyphanet node. Formerly known as Freenet (project renamed in 2023). Java-based daemon with a browser-based local web UI. Upstream: https://github.com/hyphanet/fred. Website: https://www.hyphanet.org/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Java installer (GUI) | Linux / macOS / Windows | Recommended. GUI wizard + auto-update. |
| Java installer (CLI/headless) | Linux (server) | Non-interactive headless install |
| Build from source | Linux / macOS / Windows | Gradle-based build |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | "Java version?" | Java 17+ required |
| install | "Installation directory?" | e.g. ~/hyphanet |
| setup | "Security level?" | Low (friends-only) / Normal (opennet) / High (darknet) |
| setup | "Datastore size?" | Amount of disk to allocate for the distributed datastore |
| setup | "Max RAM?" | Recommended: 512 MB minimum; 1 GB+ for better performance |
| network | "Opennet or darknet?" | Opennet: connect to strangers. Darknet: trusted friends only. |

## Software-layer concerns

### Install via Java installer (Linux GUI)

  # Download from https://www.hyphanet.org/download.html
  wget https://github.com/hyphanet/java_installer/releases/latest/download/new_installer_offline.jar
  java -jar new_installer_offline.jar

  # Headless / server install:
  java -jar new_installer_offline.jar -console

  # Follow wizard to select install directory, security level, datastore size.

### First-run setup

  # After install, the node starts automatically.
  # Access the setup wizard at:
  http://127.0.0.1:8888/

  # Complete the FProxy setup:
  # 1. Choose opennet (connect to anyone) or darknet (trusted friends only)
  # 2. Set datastore size (minimum 1 GB; more = better for the network)
  # 3. Set memory limit
  # 4. (Optional) Add friend node references for darknet mode

### Start / stop

  # On Linux, the installer creates startup scripts:
  ~/hyphanet/run.sh start
  ~/hyphanet/run.sh stop
  ~/hyphanet/run.sh status

  # Run as a system service (created by installer on systemd systems):
  systemctl --user start hyphanet

### Key ports

  8888/tcp   # FProxy (local web UI and freesite browser) — localhost only by default
  8080/tcp   # HTTP proxy for browsing freesites from external browser (optional)
  29900/tcp  # Opennet peer connections (configurable)

  # FProxy should NEVER be exposed to the internet — it gives full control of your node.

### Configuration

  # Main config: ~/hyphanet/freenet.ini
  # Key settings:
  node.listenPort=29900          # P2P listen port
  fproxy.port=8888               # Local web UI port
  fproxy.bindTo=127.0.0.1        # Bind FProxy to localhost only!
  node.storeSize=10G             # Datastore size
  node.outputBandwidthLimit=131072  # Upload bandwidth limit (bytes/sec)

### Headless / remote access

  # FProxy binds to 127.0.0.1 by default. To access from another machine:
  # Option 1: SSH tunnel
  ssh -L 8888:localhost:8888 user@server

  # Option 2: Change bindTo in freenet.ini (security risk — requires password auth)
  fproxy.bindTo=0.0.0.0
  fproxy.hashedPassword=<hash>   # Set a password if binding to non-localhost!

### Build from source

  git clone https://github.com/hyphanet/fred.git
  cd fred
  ./gradlew jar
  # Output: dist/freenet.jar

## Upgrade procedure

  # Hyphanet auto-updates itself by default when a new version is available.
  # To update manually:
  ~/hyphanet/run.sh stop
  # Download new installer and re-run over existing install directory
  java -jar new_installer_offline.jar -console
  ~/hyphanet/run.sh start

## Gotchas

- **Java 17+ required**: older Java versions are not supported. Install a modern JRE/JDK before running the installer.
- **FProxy = full node control**: the FProxy web UI (port 8888) gives complete access to your node including configuration and friend management. Never expose it to the internet.
- **Anonymous ≠ instant**: Hyphanet's anonymity comes at the cost of speed. Downloads can be slow, especially for content that hasn't been recently accessed (needs to be "found" in the distributed store).
- **Datastore is permanent**: once content is inserted into the datastore, it cannot be easily removed. Be thoughtful about what you insert.
- **Opennet vs darknet**: opennet connects to strangers and is easier to set up but offers weaker anonymity. Darknet (trusted friends only) is slower but stronger. Most users start with opennet.
- **Renamed from Freenet**: the project renamed from "Freenet" to "Hyphanet" in 2023. The GitHub repo is `hyphanet/fred`; older documentation may still say "Freenet".
- **Not a general-purpose VPN**: Hyphanet is specifically for anonymous content sharing within its own network, not for general internet anonymization (use Tor for that).

## References

- Upstream GitHub: https://github.com/hyphanet/fred
- Website: https://www.hyphanet.org/
- Download page: https://www.hyphanet.org/download.html
- Java installer repo: https://github.com/hyphanet/java_installer
- Documentation: https://www.hyphanet.org/documentation.html
- Contributing: https://github.com/hyphanet/fred/blob/next/CONTRIBUTING.md
