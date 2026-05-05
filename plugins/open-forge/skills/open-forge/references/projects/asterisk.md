# Asterisk

Open-source PBX (Private Branch Exchange) and telephony toolkit. Asterisk provides VoIP call routing, voicemail, conferencing, IVR, and SIP/PJSIP connectivity. It is the foundation for many hosted PBX and call-center systems and supports traditional PSTN as well as internet telephony.

**Official site:** https://www.asterisk.org

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Debian / Ubuntu | deb (native) | Recommended; install from packages or source |
| CentOS / RHEL | RPM (native) | `asterisk` available in EPEL |
| Any Linux host | Docker | Use community images (e.g. `andrius/asterisk`) |
| Raspberry Pi / ARM | Build from source or Docker | ARM64 supported |

---

## Inputs to Collect

### Phase 1 — Planning
- SIP trunk provider credentials (host, username, password, port)
- Extension numbering plan
- Inbound DID numbers and routing rules
- Voicemail storage path
- Whether AGI/AMI/ARI integrations are needed

### Phase 2 — Deployment
- Network interface to bind (SIP default port: `5060` UDP/TCP)
- RTP port range (default `10000–20000` UDP)
- Codec preferences (G.711 u-law/a-law, G.722, Opus)
- Admin/manager credentials for AMI (Asterisk Manager Interface)

---

## Software-Layer Concerns

### Docker (quick start)

```bash
docker run -d \
  --name asterisk \
  --network host \
  -v /etc/asterisk:/etc/asterisk \
  -v /var/spool/asterisk:/var/spool/asterisk \
  andrius/asterisk:latest
```

> **Note:** `--network host` is strongly recommended for VoIP. NAT through bridge networking causes RTP audio issues and requires careful `externip`/`localnet` config in `pjsip.conf` / `sip.conf`.

### Key Config Files
| File | Purpose |
|------|---------|
| `/etc/asterisk/pjsip.conf` | SIP endpoints, trunks, transports (preferred over legacy `sip.conf`) |
| `/etc/asterisk/extensions.conf` | Dialplan — call routing logic |
| `/etc/asterisk/voicemail.conf` | Voicemail boxes and SMTP settings |
| `/etc/asterisk/manager.conf` | AMI (Asterisk Manager Interface) users and permissions |
| `/etc/asterisk/rtp.conf` | RTP port range |
| `/var/spool/asterisk/voicemail/` | Voicemail audio files |

### RTP Port Range (`rtp.conf`)

```ini
[general]
rtpstart=10000
rtpend=20000
```

Open this UDP range on your firewall in addition to `5060/UDP`.

### Debian / Ubuntu Package Install

```bash
sudo apt update && sudo apt install asterisk
sudo systemctl enable --now asterisk
```

For the latest versions, build from source or use the official packages at https://packages.asterisk.org/.

---

## Upgrade Procedure

**Package install:**
```bash
sudo apt update && sudo apt upgrade asterisk
sudo systemctl restart asterisk
```

**From source:** Download new release tarball, run `./configure && make && sudo make install`, then `sudo systemctl restart asterisk`.

Check the [CHANGES](https://github.com/asterisk/asterisk/blob/master/CHANGES) file for breaking config changes between versions.

---

## Gotchas

- **Use `host` networking in Docker** — bridged networking causes one-way audio (RTP mismatch). If bridge is required, configure `externip` and `localnet` in `pjsip.conf`.
- **Firewall rules** — open UDP 5060 (SIP) and your full RTP range (e.g. 10000–20000) between Asterisk and phones/trunks.
- **PJSIP vs legacy `chan_sip`** — `chan_sip` is deprecated since Asterisk 17; use PJSIP (`pjsip.conf`) for all new deployments.
- **NAT traversal** — behind NAT, set `externip`, `externhost`, and `localnet` in PJSIP transport config or calls will connect but have no audio.
- **Dialplan complexity** — `extensions.conf` has a steep learning curve; consider using FreePBX (GUI front-end) for easier management.
- **TLS/SRTP** — enable `transport=tls` in PJSIP and `srtpcapable=yes` for encrypted calls; requires certificate setup.
- **Resource usage** — Asterisk is single-threaded per call channel; scale vertically or via distributed setups for high call volumes.

---

## References
- GitHub: https://github.com/asterisk/asterisk
- Documentation: https://docs.asterisk.org
- PJSIP config guide: https://docs.asterisk.org/Configuration/Channel-Drivers/SIP/Configuring-res_pjsip/
- Community Docker image: https://github.com/andrius/asterisk
