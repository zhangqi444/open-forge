---
name: dragonfly-mta
description: DragonFly Mail Agent (dma) recipe for open-forge. Small MTA for home and office use. Accepts local mail and relays to a smarthost via SMTP with TLS/STARTTLS and auth. No daemon, no port 25. C. BSD-3-Clause. Source: https://github.com/corecode/dma
---

# DragonFly Mail Agent (dma)

Minimal Mail Transfer Agent (MTA) for home and office Linux/BSD systems. Accepts mail from local programs (cron, scripts, servers) and delivers it either locally or by relaying to a remote SMTP smarthost. Supports TLS/SSL, STARTTLS, and SMTP authentication. No listening daemon -- does not accept inbound SMTP connections on port 25. Written in C. BSD-3-Clause licensed.

Common use case: route system mail (cron job alerts, server notifications) through Gmail, Fastmail, or any SMTP relay without running a full MTA like Postfix.

Upstream: https://github.com/corecode/dma | Man page: https://man.freebsd.org/cgi/man.cgi?query=dma | Arch Wiki: https://wiki.archlinux.org/title/Dma

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux | APT (Ubuntu/Debian) | sudo apt install dma |
| FreeBSD | pkg | pkg install dma |
| Arch Linux | AUR | yaourt -S dma |
| Linux | Build from source | make && make install ... |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | SMARTHOST | Relay hostname, e.g. smtp.gmail.com |
| config | PORT | SMTP port (25, 465, or 587) |
| config | SMTP username | Usually your email address |
| config | SMTP password | App password for Gmail, etc. |
| config | TLS mode | SECURETRANSFER (SSL/TLS) or STARTTLS |

## Software-layer concerns

### Config files

| Path | Description |
|---|---|
| /etc/dma/dma.conf | Main config: smarthost, port, TLS flags |
| /etc/dma/auth.conf | SMTP credentials (user|host:password) |
| /var/spool/dma/ | Mail spool (created by make install-spool-dirs) |

### Key dma.conf directives

| Directive | Description |
|---|---|
| SMARTHOST | Relay hostname |
| PORT | SMTP port |
| AUTHPATH | Path to auth.conf (uncomment to enable auth) |
| SECURETRANSFER | Enable TLS/SSL (uncomment) |
| STARTTLS | Enable STARTTLS (with SECURETRANSFER) |
| VERIFYCERT | Verify server certificate (recommended) |

## Install -- Ubuntu/Debian

```bash
sudo apt install dma
sudo dpkg-reconfigure dma   # interactive config (Debian)
```

## Install -- Build from source (Linux)

```bash
sudo apt install gcc flex bison libssl-dev make
git clone https://github.com/corecode/dma.git
cd dma
make
sudo make install sendmail-link mailq-link install-spool-dirs install-etc
```

## Configuration -- Gmail relay example

/etc/dma/dma.conf:

```
SMARTHOST smtp.gmail.com
PORT 587
AUTHPATH /etc/dma/auth.conf
SECURETRANSFER
STARTTLS
VERIFYCERT
```

/etc/dma/auth.conf (mode 600, owned by root):

```
your@gmail.com|smtp.gmail.com:your-app-password
```

```bash
sudo chmod 600 /etc/dma/auth.conf
# Test
echo "Test mail" | mail -s "dma test" you@example.com
```

## Upgrade procedure

```bash
# Via package manager (Ubuntu):
sudo apt update && sudo apt upgrade dma

# From source:
cd dma && git pull && make && sudo make install
```

## Gotchas

- dma does NOT listen on port 25: it only delivers outbound mail. For inbound mail, you need a full MTA (Postfix, Exim).
- Gmail requires an App Password: if you use Gmail with 2FA (recommended), generate an App Password at myaccount.google.com/apppasswords -- do not use your main Gmail password.
- auth.conf must be mode 600: the file contains plaintext credentials; world-readable permissions will cause authentication to be refused.
- On Debian: use dpkg-reconfigure dma instead of editing dma.conf directly -- Debian manages the config via debconf and may overwrite manual edits.
- sendmail-link: the install creates /usr/sbin/sendmail as a symlink to dma, so applications that call sendmail directly (cron, PHP mail(), etc.) use dma transparently.

## Links

- Source: https://github.com/corecode/dma
- Man page (FreeBSD): https://man.freebsd.org/cgi/man.cgi?query=dma
- Arch Wiki: https://wiki.archlinux.org/title/Dma
