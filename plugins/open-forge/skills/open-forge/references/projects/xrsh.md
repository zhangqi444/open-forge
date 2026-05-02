# XRSH

**What it is:** XR-friendly shells in the browser — a self-hosted WebXR operating environment that runs a full Linux-like shell experience inside a VR/AR headset or desktop browser. Boots a v86 (x86 emulator) environment in-browser, supporting multiple "apps" (xterms, editors, file managers) as floating XR panels. No server-side compute required — everything runs client-side in WebAssembly.

**Official URL:** https://xrsh.isvery.ninja
**Repo:** https://forgejo.isvery.ninja/xrsh/xrsh
**Container:** `docker.io/coderofsalvation/xrsh`
**License:** See repo
**Stack:** JavaScript/WebAssembly (v86); Docker (static file server only)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS | Docker (static server) | Serves the browser app over HTTP/HTTPS |
| Local machine (Linux/Mac) | Standalone binary | `./xrsh.com` opens browser at `https://127.0.0.1:8080` |
| NixOS | nix-shell | `nix-shell -p xrsh thttpd` |
| Codeberg Pages | Static hosting | Push the repo to Codeberg to serve via Pages |

---

## Inputs to Collect

### Docker run (optional)
- Port — default `8080`
- Custom ISO — mount a custom `.iso` file for a custom environment
- TLS certificates — optional; mount cert/key for HTTPS

---

## Software-Layer Concerns

**Quickest start (no self-hosting needed):** Just visit https://xrsh.isvery.ninja — it's fully public.

**Standalone binary:**
```bash
# Download xrsh.com from the Forgejo repo
chmod +x xrsh.com
./xrsh.com          # opens https://127.0.0.1:8080 in your browser
./xrsh.com -p 9090  # custom port
```

**Docker (basic):**
```bash
docker run -p 8080:8080 docker.io/coderofsalvation/xrsh
# Visit http://localhost:8080
```

**Docker with custom ISO and TLS:**
```bash
mkdir data
cp your-custom.iso data/
docker run -p 8080:8080 \
  -v data/cert:/etc/cert \
  -v data:/data \
  docker.io/coderofsalvation/xrsh \
  /xrsh.com -D /data -c 0 -C /etc/cert/cert.pem -K /etc/cert/key.pem
```

**NixOS:**
```bash
nix-shell -p xrsh thttpd
thttpd -p 8080 -d /nix/store/<xrsh-path>
```

**Keyboard shortcut inside XRSH:** `Ctrl/Cmd+A+0` opens the manual, or run `man xrsh`.

**Upgrade procedure:**
- Docker: `docker pull docker.io/coderofsalvation/xrsh && docker run ...`
- Binary: download the latest `xrsh.com` from the Forgejo repo

---

## Gotchas

- **All computation is client-side** — the server only serves static files; no backend processing; performance depends on the user's device/browser
- **WebXR requires HTTPS** — use TLS or a reverse proxy with HTTPS if deploying for VR headset use; HTTP only works for desktop browsers
- **Public hosted version available** — self-hosting is optional; https://xrsh.isvery.ninja is free to use
- **v86 emulator** — runs a limited x86 Linux environment in-browser; not a full Linux VM; some software won't work

---

## Links
- Website: https://xrsh.isvery.ninja
- Forgejo: https://forgejo.isvery.ninja/xrsh/xrsh
- Docker Hub: https://hub.docker.com/r/coderofsalvation/xrsh
- Manual: https://forgejo.isvery.ninja/xrsh/xrsh-buildroot/src/branch/main/buildroot-v86/board/v86/rootfs_overlay/root/manual.md
