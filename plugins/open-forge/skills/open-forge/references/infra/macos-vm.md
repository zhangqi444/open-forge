---
name: macos-vm-infra
description: Apple Silicon macOS VM infra adapter — provision a sandboxed macOS VM on the user's M-series Mac via Lume, then install via SSH. Pair with `runtimes/native.md` for the application install. Picked when the user specifically needs macOS-only capabilities (iMessage via BlueBubbles), strict isolation from their daily Mac, or instant-reset golden images. Cloud Mac providers (MacStadium etc.) follow the same SSH-in flow once provisioned.
---

# macOS VM (Lume on Apple Silicon) adapter

Run a sandboxed macOS guest on the user's existing M-series Mac via [Lume](https://cua.ai/docs/lume). Useful when the project genuinely needs macOS — typically iMessage integration via BlueBubbles, which is impossible on Linux/Windows.

For most users a Linux VPS is simpler and cheaper. This adapter is for the specific case where macOS-only capabilities are required, or where the user wants instant-reset isolation from their daily Mac.

## Prerequisites

- Apple Silicon Mac (M1/M2/M3/M4) — Intel Macs aren't supported by Lume.
- macOS Sequoia or later on the host.
- ~60 GB free disk space per VM (more if you snapshot golden images).
- ~20 minutes for first-time setup (downloads macOS into the VM image).

## Inputs to collect

| When | Question | Tool / format | Default |
|---|---|---|---|
| End of preflight | "macOS VM name?" | Free-text | Deployment name |
| End of preflight | "VM disk size (GB)?" | `AskUserQuestion`: `60` / `100` / `150` | `60` |
| End of preflight | "macOS version?" | `AskUserQuestion`: `latest` / `Specific IPSW URL` | `latest` |
| End of preflight | "Will you use BlueBubbles for iMessage?" | `AskUserQuestion`: `Yes` / `No` | — |
| End of preflight | "VM user account name?" (created via Setup Assistant) | Free-text | `<deployment-name>` |

Derived:

| Recorded as | Derived from |
|---|---|
| `outputs.vm_name` | Deployment name |
| `outputs.vm_ip` | `lume get <vm-name>` output (typically `192.168.64.x`) |
| `outputs.host_user` | The user-account name created during Setup Assistant |

## Install Lume on the host Mac

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trycua/cua/main/libs/lume/scripts/install.sh)"

# If ~/.local/bin isn't on PATH already:
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc && source ~/.zshrc

lume --version
```

## Create the VM

```bash
lume create "$VM_NAME" --os macos --ipsw latest --disk-size "${DISK_GB}G"
```

A VNC window opens automatically once the IPSW download completes (downloads can take 20+ min on slow connections).

## Setup Assistant (manual — VNC window)

This is the one phase open-forge can't automate; the macOS Setup Assistant needs human input. Walk the user through:

1. Select language / region.
2. **Skip** Apple ID — unless they want iMessage later, in which case sign in (the VM's Apple ID is what BlueBubbles will route through).
3. Create a user account with the username and password they entered as inputs.
4. Skip all optional features (Siri, analytics, screen time, etc.).
5. Once at the desktop: **System Settings → General → Sharing → enable Remote Login**. This turns on SSH inside the VM.

## Connect

```bash
lume get "$VM_NAME"
# → look for the IP (usually 192.168.64.x). Save as VM_IP.

# Set up SSH config for convenience (host alias)
cat >> ~/.ssh/config <<EOF

Host $VM_NAME
  HostName $VM_IP
  User $HOST_USER
EOF

# Test
ssh "$VM_NAME" 'sw_vers'
```

The first SSH connection asks the user to accept the host key — `-o StrictHostKeyChecking=accept-new` if you want it non-interactive.

## Run headless

After Setup Assistant completes, swap to no-display mode:

```bash
lume stop "$VM_NAME"
lume run "$VM_NAME" --no-display
```

The VM continues running in the background. The host Mac must stay awake (System Settings → Energy Saver → keep the Mac from sleeping; consider `caffeinate` if running on battery is unavoidable).

## Save a golden image (recommended before any customization)

```bash
lume stop "$VM_NAME"
lume clone "$VM_NAME" "${VM_NAME}-golden"
lume run "$VM_NAME" --no-display
```

To reset to clean state later:

```bash
lume stop "$VM_NAME" && lume delete "$VM_NAME"
lume clone "${VM_NAME}-golden" "$VM_NAME"
lume run "$VM_NAME" --no-display
```

## SSH convention

```bash
ssh "$VM_NAME"          # via the ~/.ssh/config alias above
# or:
ssh "$HOST_USER@$VM_IP"
```

For one-shot remote commands the runtime / project recipes drive: `ssh "$VM_NAME" 'bash -lc "<command>"'`.

## Verification

Mark `provision` done only when all of:

- `lume list` shows the VM as `running`.
- `ssh "$VM_NAME" 'echo ok'` prints `ok`.
- `ssh "$VM_NAME" 'sw_vers -productVersion'` returns the macOS version.

## Teardown

```bash
lume stop "$VM_NAME"
lume delete "$VM_NAME"
# Optionally also:
lume delete "${VM_NAME}-golden"
```

Disk space reclaimed immediately.

## Gotchas

- **Apple Silicon only.** Lume uses Apple's Virtualization framework which requires M-series silicon. Intel Macs need different tooling (UTM, Parallels) — out of scope here.
- **Setup Assistant is unavoidable.** First-time VM creation requires ~5 minutes of human VNC interaction. Plan for it.
- **Headless host Macs need to stay awake.** macOS will sleep aggressively on default power settings. Disable sleep in Energy Saver, or run `caffeinate -di &` in a separate Terminal session.
- **Lume's VNC doesn't enable SSH automatically.** The user MUST enable Remote Login in the VM's System Settings before any `ssh` will work.
- **WhatsApp / Telegram QR pairing must be done from inside the VM.** Run `openclaw channels login` over SSH to the VM, scan the QR with your phone — not from the host Mac.
- **Cloud Mac providers (MacStadium, etc.) are an alternative.** Once you have SSH access to a hosted Mac, the install flow is the same — skip the Lume sections and start at *Initial host setup*.
- **iMessage requires Apple ID sign-in.** If the user skipped Apple ID during Setup Assistant, BlueBubbles won't have iMessage to relay. Sign in via Settings → Apple Account before installing BlueBubbles.
- **VM disk grows but doesn't auto-shrink.** A 60 GB VM that's run for months may show 50+ GB used even after `rm`. To compact: `lume stop`, then on the host `qemu-img convert` the disk image — fiddly; usually easier to clone fresh from the golden image.

## Reference

- Lume install: <https://cua.ai/docs/lume/guide/getting-started/installation>
- Lume CLI: <https://cua.ai/docs/lume/reference/cli-reference>
- BlueBubbles: <https://bluebubbles.app>
- OpenClaw on macOS VM (upstream): <https://docs.openclaw.ai/install/macos-vm>
