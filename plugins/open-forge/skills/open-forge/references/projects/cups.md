---
name: cups
description: CUPS recipe for open-forge. The Common Unix Printing System — standards-based open source print server supporting AirPrint, IPP Everywhere, USB/network printers, and a web admin UI. Source: https://github.com/OpenPrinting/cups
---

# CUPS

The Common Unix Printing System (OpenPrinting CUPS) is the standard print server for Linux and Unix-like systems. Supports AirPrint, IPP Everywhere, USB and network printers via Printer Applications and legacy PPD drivers, and provides a web-based admin UI, System V/Berkeley CLI tools, and a C API. Upstream: https://github.com/OpenPrinting/cups. Docs: https://openprinting.github.io/cups/.

Note: Apple maintains a separate legacy fork at https://github.com/apple/cups. For modern Linux, use OpenPrinting CUPS.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Distro package | Linux (Debian/Ubuntu/Fedora/Arch) | Recommended. Managed by system package manager. |
| Build from source | Linux, macOS | For latest features or custom builds. |
| Docker (community) | Docker | No official image; community images exist for specific use cases. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Allow remote admin access?" | Default: localhost only. Edit /etc/cups/cupsd.conf to allow LAN. |
| setup | "Printers to add?" | USB auto-detected. Network printers need IP/hostname. |
| auth | "Web UI admin user?" | Must be a system user in the lpadmin group. |

## Software-layer concerns

### Distro package install

  # Debian/Ubuntu
  apt-get install cups cups-bsd cups-filters
  systemctl enable --now cups

  # Fedora/RHEL
  dnf install cups
  systemctl enable --now cups

  # Arch Linux
  pacman -S cups
  systemctl enable --now cups.service

### Add user to admin group

  usermod -aG lpadmin <username>

### Web UI

  # Default: http://localhost:631
  # To allow LAN access, edit /etc/cups/cupsd.conf:
  #   Listen *:631
  # And add Allow directives for your subnet:
  #   <Location />
  #     Allow from 192.168.1.0/24
  #   </Location>
  systemctl restart cups

### Key config files

  /etc/cups/cupsd.conf       - main daemon config (listen address, auth, access)
  /etc/cups/printers.conf    - registered printers (managed by cupsd, not hand-edited)
  /etc/cups/ppd/             - PPD files for legacy drivers
  /var/log/cups/             - access and error logs

### Command-line tools

  lpstat -p -d              # list printers and default
  lpadmin -p <name> -E -v <uri> -m <ppd>   # add printer
  lpr -P <printer> file.pdf                # print a file
  lpq -P <printer>                         # check queue

## Upgrade procedure

  # Via package manager (recommended):
  apt-get upgrade cups        # Debian/Ubuntu
  dnf upgrade cups            # Fedora
  systemctl restart cups

  # From source: download new tarball, ./configure && make && make install

## Gotchas

- **SELinux / AppArmor**: may block CUPS from accessing devices. Check audit logs if printers are detected but printing fails.
- **Firewall**: open port 631 (TCP/UDP) for IPP network printing. Use `ufw allow 631` or equivalent.
- **cups-filters**: separate package providing format conversion filters; required for most printing functionality on Linux.
- **USB printers**: require `usblp` kernel module (usually loaded automatically) or `libusb`-based access via Printer Applications.
- **AirPrint**: enable Avahi (mDNS) alongside CUPS for AirPrint discovery: `systemctl enable --now avahi-daemon`.
- **Web UI TLS**: CUPS uses a self-signed cert by default. Browsers will warn; add an exception or replace with a proper cert.
- **Legacy PPDs**: deprecated in favor of Printer Applications (driverless IPP). For older printers, check https://openprinting.github.io/printers/.

## References

- Upstream GitHub: https://github.com/OpenPrinting/cups
- OpenPrinting docs: https://openprinting.github.io/cups/
- Printer Applications: https://openprinting.github.io/printer_driver_revamp/
- cups-filters: https://github.com/OpenPrinting/cups-filters
