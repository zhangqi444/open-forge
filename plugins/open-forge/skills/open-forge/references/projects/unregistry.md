---
name: Unregistry
description: "Push Docker images directly to remote servers without an external registry. `docker pussh` CLI plugin — SSH tunnel + temp registry container + missing-layers-only transfer. Like rsync for Docker. Apache-2.0."
---

# Unregistry

Unregistry is **"rsync for Docker images"** — a tiny container registry that serves images directly from a Docker daemon's storage, and a companion `docker pussh` CLI (extra 's' for SSH) that **pushes images to a remote server over SSH** transferring only missing layers. Zero external registry required.

Built by **Pavel Sviderski (psviderski)** — same author as **Uncloud** (batch 74). Created specifically to solve the "I built an image, now I need it on one server, why do I need Docker Hub?" problem for lightweight multi-host Docker deployments.

The flow, in one command:
```
docker pussh myapp:latest user@server
```
Under the hood:
1. SSH tunnel to remote server
2. Start temporary unregistry container on server
3. Forward random localhost port → unregistry port through tunnel
4. `docker push` to unregistry via forwarded port — transfers only missing layers
5. Image instantly available on remote Docker daemon
6. Stop unregistry container + close tunnel

The missing layers are re-used from containerd's existing image store, so pushes are fast + bandwidth-efficient.

- Upstream repo: <https://github.com/psviderski/unregistry>
- Docker image: <https://ghcr.io/psviderski/unregistry>
- Homebrew tap: <https://github.com/psviderski/homebrew-tap>
- Discord: <https://discord.gg/eR35KQJhPu>
- Author's X: <https://x.com/psviderski>
- Sponsor: <https://github.com/sponsors/psviderski>
- Related project: <https://github.com/psviderski/uncloud> (batch 74)

## Architecture in one minute

- **`docker-pussh`** = Bash/shell script; Docker CLI plugin + standalone
- **`unregistry`** container = tiny Docker-registry-v2-API-compatible server that **reads directly from containerd's image store** (no duplicate storage)
- **Requires containerd socket access** (`/run/containerd/containerd.sock`) → runs as root on remote host
- **SSH tunnel** = standard OpenSSH; no custom protocols
- **On first use per remote**: pulls `ghcr.io/psviderski/unregistry:X.Y.Z` from ghcr.io (or preloaded in air-gap case)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| macOS/Linux dev    | **Homebrew** (`psviderski/tap/docker-pussh`) OR direct download   | **Upstream-primary**                                                               |
| Any Docker-equipped target | Nothing installed ahead — pussh pulls unregistry on demand            | Only requires SSH access + Docker permissions                                              |
| Air-gapped target  | Preload `ghcr.io/psviderski/unregistry:X.Y.Z` manually via save/load         | Documented in README                                                                      |
| CI/CD              | docker-pussh works in any Linux CI runner with SSH agent                         | Great for GitHub Actions → VPS deploy                                                                           |

## Inputs to collect

| Input                | Example                                                        | Phase        | Notes                                                                    |
| -------------------- | -------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Remote SSH           | `user@server.example.com`                                          | Connection   | SSH key or agent-forwarded                                                        |
| SSH user             | must be in `docker` group OR passwordless `sudo docker`                       | Perms        | Document in team runbook                                                                             |
| Remote internet      | needs to pull `ghcr.io/psviderski/unregistry:X.Y.Z` on first use                    | Deps         | Or preload for air-gap                                                                                |
| Image to push        | `myapp:latest` (or digest-pinned)                                                       | Deploy       | Any Docker image                                                                                                |

## Install

### macOS / Linux via Homebrew

```sh
brew install psviderski/tap/docker-pussh

# symlink so `docker pussh` works as a CLI plugin:
mkdir -p ~/.docker/cli-plugins
ln -sf $(brew --prefix)/bin/docker-pussh ~/.docker/cli-plugins/docker-pussh
```

### Direct download (Linux/macOS)

```sh
mkdir -p ~/.docker/cli-plugins
curl -sSL https://raw.githubusercontent.com/psviderski/unregistry/v0.4.2/docker-pussh \
  -o ~/.docker/cli-plugins/docker-pussh
chmod +x ~/.docker/cli-plugins/docker-pussh
```

Verify:
```sh
docker pussh --version
```

## First use

```sh
# Build locally
docker build -t myapp:1.0.0 .

# Push to remote server
docker pussh myapp:1.0.0 deploy@prod.example.com

# On remote server:
docker run -d --name myapp myapp:1.0.0
```

## Data & config layout

- **No persistent state** — unregistry container is ephemeral per-push
- No local unregistry-specific config
- Existing SSH config (`~/.ssh/config`) respected — use SSH aliases

## Backup

Nothing to back up. The tool is stateless.

## Upgrade

1. Releases: <https://github.com/psviderski/unregistry/releases>. Active.
2. Homebrew: `brew upgrade docker-pussh`.
3. Direct-download: curl-download the new version.
4. `docker pussh --version` shows the `unregistry` container image version it pairs with — they upgrade together.

## Gotchas

- **Remote SSH user needs Docker permissions** — member of `docker` group OR passwordless `sudo docker`. Both options make the SSH user effectively root on the remote (Docker group = root-equivalent; passwordless sudo docker = same). Plan security accordingly: **this user's SSH key is a root credential.**
- **Unregistry container runs as root + needs containerd socket.** Same root-equivalence consideration on the remote host. The container is ephemeral (started per-push + destroyed) but during the push window it has full containerd access. Threat window is seconds, not persistent.
- **First-use per server needs internet access to ghcr.io.** For air-gapped targets, preload via `docker save | ssh target docker load`. Documented pattern.
- **SSH agent / SSH keys must be set up** — no credential prompting during tunnel. Use `ssh-agent` + key-based auth. Avoid passwords.
- **Not a persistent registry.** Unregistry is not a drop-in for Docker Hub / Harbor / GitLab Container Registry:
  - No image indexing / browsing UI
  - No authentication beyond SSH to host
  - No garbage collection / retention policies
  - Only "live" images = ones in Docker's current image store
- **When to use `docker pussh` instead of a registry:**
  - **Single-dev → single-VPS workflows** — pushing built image to production server
  - **Small teams deploying to known Docker hosts over SSH**
  - **Air-gapped environments** where external registry infeasible
  - **CI/CD pushing to fleet** where fleet nodes don't need public registry access
- **When to use a real registry instead:**
  - Multi-server environments pulling the same image (registry = one-to-many)
  - Images shared across orgs / public distribution
  - Need image scanning / signing / vulnerability tracking pipelines
  - Need image retention policies + garbage collection
- **Layers-only transfer optimization** — pushing iterative builds is FAST because unchanged base layers stay put. First push of a novel image = full transfer.
- **Uses standard Docker Registry v2 HTTP API** — compatible with `docker push`; no custom client needed. The unique part is the containerd-direct storage + SSH tunnel wrapping.
- **Integrates with Uncloud** (same author, batch 74): Uncloud uses this registry-less push model as its deploy mechanism. If you use Uncloud, unregistry is already there.
- **Bandwidth patience**: first-time images with large base layers over slow SSH = slow. Subsequent pushes fast. Time the initial deploy.
- **Not for Kubernetes image pulling** — K8s needs a registry that kubelet can pull from. Unregistry's ephemeral start+stop model doesn't fit K8s imagePullPolicy semantics. For K8s, use a real registry.
- **License**: **Apache-2.0**.
- **Project health**: active; single maintainer (psviderski) with strong track record + companion project (Uncloud). Same bus-factor honesty as batch 74 Uncloud note.
- **Alternatives worth knowing:**
  - **Docker Hub / ghcr.io** — public registries
  - **Harbor** — self-hosted registry + scanning + signing
  - **Gitea Container Registry / GitLab Container Registry** — registry integrated with Git hosting
  - **Distribution (upstream registry:2)** — reference Docker registry implementation
  - **`docker save | ssh ... docker load`** — the primitive it replaces (full transfer, no layer dedup)
  - **Skopeo** — works between any two registries; transfer-without-local-storage
  - **Choose unregistry if:** push-to-a-specific-remote-host workflow + want layer-dedup + don't want registry infrastructure.
  - **Choose Harbor if:** multi-team + scanning/signing + registry governance.
  - **Choose save/load if:** one-off + registry overhead not worth it + layer dedup not critical.

## Links

- Repo: <https://github.com/psviderski/unregistry>
- Image: <https://ghcr.io/psviderski/unregistry>
- Homebrew tap: <https://github.com/psviderski/homebrew-tap>
- Releases: <https://github.com/psviderski/unregistry/releases>
- Discord: <https://discord.gg/eR35KQJhPu>
- Sponsor: <https://github.com/sponsors/psviderski>
- Uncloud (sibling project, batch 74): <https://github.com/psviderski/uncloud>
- Docker Registry v2 spec: <https://distribution.github.io/distribution/spec/api/>
- Manage Docker as non-root: <https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user>
- Harbor (alt, full registry): <https://goharbor.io>
- Skopeo (alt): <https://github.com/containers/skopeo>
