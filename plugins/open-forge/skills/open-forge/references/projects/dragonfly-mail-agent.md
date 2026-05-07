# DragonFly Mail Agent (dma)

**Small, lightweight MTA (Mail Transfer Agent)** for home and office use. Accepts mail from locally installed MUAs and delivers it locally or to a remote SMTP server. Supports TLS/SSL and SMTP authentication. Not a replacement for full MTAs like Postfix or Sendmail — does not listen on port 25.

**Source:** https://github.com/corecode/dma  
**Man page:** https://man.freebsd.org/cgi/man.cgi?query=dma  
**Arch Wiki:** https://wiki.archlinux.org/title/Dma  
**License:** BSD-3-Clause

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux (Debian/Ubuntu/Arch) | Native package | Easiest path |
| FreeBSD | Native package | First-class support |
| Linux | Build from source | Requires C toolchain |

> **No Docker image.** dma integrates with the system MTA interface (`sendmail`/`mailq`) and is not containerized.

---

## System Requirements

- C compiler (gcc)
- lex (flex)
- yacc (bison)
- make (GNU or BSD)
- OpenSSL (for TLS)

---

## Inputs to Collect

### Config phase
| Input | Description | Default |
|-------|-------------|---------|
| `SMARTHOST` | Upstream relay SMTP server (leave blank for direct delivery) | — |
| `PORT` | SMTP port to use | `25` |
| `SECURETRANSFER` | Enable TLS/SSL | disabled |
| `STARTTLS` | Enable STARTTLS (requires SECURETRANSFER) | disabled |
| `VERIFYCERT` | Verify server TLS certificate | disabled |
| `AUTHPATH` | Path to SMTP auth credentials file | `/etc/dma/auth.conf` |

---

## Software-layer Concerns

### Package install (recommended)
```bash
# Debian/Ubuntu
sudo apt install dma

# FreeBSD
pkg install dma

# Arch
yay -S dma
```

### Build from source (Linux)
```bash
git clone https://github.com/corecode/dma
cd dma
make
sudo make install sendmail-link mailq-link install-spool-dirs install-etc
```

### Config paths
| Path | Purpose |
|------|---------|
| `/etc/dma/dma.conf` | Main configuration file |
| `/etc/dma/auth.conf` | SMTP authentication credentials |
| `/var/spool/dma` | Mail spool directory |
| `/etc/aliases` | Local mail aliases |

### `dma.conf` (key settings)
```conf
# Relay outbound mail through a smarthost
SMARTHOST mail.example.com
PORT 587

# Enable TLS + STARTTLS
SECURETRANSFER
STARTTLS
VERIFYCERT

# Auth credentials file
AUTHPATH /etc/dma/auth.conf
```

### `auth.conf` (SMTP credentials)
```
user|smarthost:password
```
Example for Gmail:
```
you@gmail.com|smtp.gmail.com:app-password-here
```
Set permissions: `chmod 600 /etc/dma/auth.conf`

### Replacing sendmail
The install step (`sendmail-link`) creates a symlink so that programs calling `/usr/sbin/sendmail` or `/usr/bin/sendmail` use dma automatically. On Debian, use `dpkg-reconfigure dma` to manage MTA registration.

---

## Upgrade Procedure

```bash
# Package
sudo apt upgrade dma

# From source
git pull
make
sudo make install
```
Config files are not overwritten by `make install`.

---

## Gotchas

- **Does not receive inbound mail.** dma only sends mail (outbound delivery). It does not listen on port 25.
- **On Debian, configure via `dpkg-reconfigure dma`** — do not edit `dma.conf` directly for the SMARTHOST setting; Debian manages it via debconf.
- **STARTTLS requires SECURETRANSFER.** Both directives must be uncommented together.
- **`auth.conf` must be `chmod 600`** — dma refuses to read world-readable credential files.
- **Spool directory must exist.** Created by `install-spool-dirs`; if missing, dma will silently fail to queue mail.
- **Not suitable for high-volume sending.** Designed for sending system notifications and personal mail, not bulk email.

---

## References

- Upstream README: https://github.com/corecode/dma/blob/master/README.markdown
- dma man page: https://man.freebsd.org/cgi/man.cgi?query=dma
- Arch Wiki: https://wiki.archlinux.org/title/Dma
