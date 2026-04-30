---
name: Easy!Appointments
description: "Open-source web appointment scheduler — customers book slots with you via web UI, Google Calendar sync, email notifications, multiple services + providers. PHP (CodeIgniter) + MySQL. GPL-3.0."
---

# Easy!Appointments

Easy!Appointments is **"self-hosted Calendly"** — a PHP web app where customers book appointments with you (or your providers) via a polished public-facing booking page. You define services, providers, working hours, and booking rules; customers pick a slot; both sides get email confirmation; optionally sync to Google Calendar so bookings appear in your phone/laptop calendar alongside personal events.

Built + maintained by **Alex Tselegidis** (Greek developer). **GPL-3.0 — commercial use permitted** (upstream is explicit: "you can download and install even for commercial use"). 10+ year old project; mature codebase; CodeIgniter-based PHP application.

Use cases: (a) doctor/dentist/therapist appointment booking (b) hairdresser/barber/salon booking (c) consultant/coach 1-on-1 sessions (d) service business (car wash, mobile repair) (e) school/university office hours (f) any service where customers need to book specific time slots.

Features:

- **Customers + appointments management** — CRM-lite
- **Services + providers** — multi-provider; services have durations + prices
- **Working plan** — define availability per provider (weekly + exceptions)
- **Booking rules** — buffer times, notice periods, limits
- **Google Calendar sync** — bi-directional
- **Email notifications** — customer + provider on booking
- **Self-hosted** install
- **Translated UI** — 30+ languages
- **Shared database** — installs in a sub-folder of existing site OK

- Upstream repo: <https://github.com/alextselegidis/easyappointments>
- Homepage: <https://easyappointments.org>
- Docs: <https://easyappointments.org/docs.html>
- Discord: <https://discord.com/invite/UeeSkaw>

## Architecture in one minute

- **PHP 7.4+ / 8.x**
- **CodeIgniter** 4 framework
- **MySQL 5.6+ / MariaDB** — only supported DB
- **Apache or Nginx** with PHP-FPM
- **Runs on shared hosting** — yes (rare; see Gotchas)
- **Resource**: tiny — 50-200MB RAM

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Shared hosting     | **Upload ZIP + run installer** — works on cPanel et al.        | **Lowest-barrier path**                                                            |
| VPS + LAMP/LEMP    | Standard PHP + MySQL                                                       | Full control                                                                               |
| Docker             | Community images (unofficial)                                                        | Works; pin carefully                                                                                  |
| Bare-metal         | Git clone + install                                                                              | Developer-mode                                                                                                    |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain / URL         | `booking.example.com` or `example.com/booking`                         | URL          | Subfolder install supported                                                                              |
| DB                   | MySQL / MariaDB                                                         | DB           | Create DB + user ahead                                                                          |
| SMTP                 | for email notifications                                                               | Email        | **Required** for confirmations                                                                                  |
| Google Calendar OAuth (opt) | GCP project + OAuth consent                                                                         | Calendar     | For bi-directional sync                                                                                              |
| Timezone             | your business's timezone                                                                                           | Config       | Affects slot boundaries                                                                                              |
| Admin user           | first-run installer creates                                                                                                        | Bootstrap    |                                                                                                                 |

## Install (VPS path)

```sh
# Download latest release ZIP
wget https://github.com/alextselegidis/easyappointments/releases/latest/download/easyappointments-*.zip
unzip easyappointments-*.zip -d /var/www/booking
# Create DB + user in MySQL
# Point webserver at /var/www/booking (public)
# Browse to URL → installer walks through setup
```

See <https://easyappointments.org/docs.html> for authoritative steps.

## First boot

1. Run installer → fill DB creds + admin email/password
2. Configure SMTP → send test email to verify
3. Create Service (name, duration, price)
4. Create Provider (name, schedule, services they offer)
5. Configure business hours / booking rules
6. Test customer flow: browse public URL → book a slot → verify email sent to customer + provider
7. (opt) Configure Google Calendar sync per provider
8. Put behind TLS
9. Back up DB

## Data & config layout

- **MySQL DB** — customers, appointments, services, providers, config
- **`config.php`** — DB creds + base URL + timezone
- **`storage/` / `uploads/`** — avatars + attachments (small)

## Backup

```sh
mysqldump -u easy_appointments -p easy_appointments | gzip > ea-$(date +%F).sql.gz
sudo tar czf ea-files-$(date +%F).tgz /var/www/booking/config.php /var/www/booking/storage
```

## Upgrade

1. Releases: <https://github.com/alextselegidis/easyappointments/releases>. Moderate cadence.
2. **Back up DB + `config.php` FIRST.**
3. Upload new version over install OR use the built-in auto-updater (if enabled).
4. Run DB migrations if required (installer handles).
5. Read CHANGELOG for breaking changes — especially between major versions.

## Gotchas

- **Timezone bugs are the #1 source of appointment-scheduling issues.** Getting timezones wrong → customer books 2 PM, provider sees 7 PM. Configure:
  - PHP `date.timezone` in `php.ini`
  - MySQL `time_zone`
  - Easy!Appointments config timezone
  - Provider-specific timezone (if providers are in different TZs)
  - All must align. Test ACTIVELY (not just "it looks right").
- **SMTP is required.** No email = no booking confirmations = customer uncertainty = missed appointments. Set up BEFORE going live.
- **Customer PII stored**: name, email, phone. GDPR + data-retention policy applicable. Provide a data-export + delete-account path (especially for EU customers).
- **Google Calendar sync caveats**:
  - Requires Google Cloud project (free) + OAuth consent screen
  - Google changed OAuth review policies (some apps need "verified app" review for sensitive scopes)
  - Per-provider OAuth — each provider re-authorizes individually
  - **Two-way sync can create race conditions** — if appointment is deleted in Calendar while ALSO being deleted in EA, duplicate delete attempts. Test your failure modes.
- **No payment integration by default.** Easy!Appointments handles BOOKINGS, not PAYMENTS. For paid services: collect payment separately (PayPal, Stripe link in the service description) or use a commercial tool with payments built-in (Calendly Pro, Cal.com, SimplyBook.me).
- **Cal.com is the modern open-source alternative** — Next.js stack, better UX, integrated payments. But: SaaS-first architecture; self-host is more complex. Easy!Appointments is the simpler PHP-stack choice.
- **No booking-widget embedding out of the box** (check current version) — customers go to the booking URL. For embedding into your existing website, iframe the booking page.
- **Rescheduling + cancellation flow**: customers need a way to reschedule. Easy!Appointments emails include a link for customers to manage their booking. Verify this works; missing links = customer confusion + support email flood.
- **No-show tracking / deposits**: not built-in. For service businesses with chronic no-shows, consider requiring a deposit (which EA doesn't support natively) → switch to Cal.com or a SaaS.
- **Multi-provider scheduling politics**: who gets booked first? Easy!Appointments offers "any provider" OR specific selection. Decide your booking strategy intentionally.
- **Works on shared hosting** — rare for feature-rich tool. Tradeoff: cheap to run; limited to shared-host PHP version + MySQL version; no queue workers possible → email sends happen synchronously in the booking flow (can be slow).
- **Recurring appointments**: check current version — historically limited. For therapy/ongoing relationships, ensure the flow you need is supported.
- **Project health**: solo-maintained by Alex Tselegidis + community. Mature (10+ years). Bus-factor-1 mitigated by (a) GPL open-source (b) large existing install base + community (c) simple PHP stack (d) Discord + forum community.
- **License**: **GPL-3.0** — commercial use permitted (upstream is explicit). Self-host free forever.
- **Alternatives worth knowing:**
  - **Cal.com** — modern open-source Calendly-alternative; Next.js; excellent UX; self-host complex
  - **BookStack** (not to confuse with documentation BookStack) — no relation
  - **Timetrex** — workforce-focused scheduling; more HR/time-clock
  - **OpenEMR** (batch 74) + appointments module — if you're specifically in healthcare
  - **Calendly** / **SavvyCal** / **Acuity** / **YouCanBook.me** — commercial SaaS
  - **SimplyBook.me** — commercial; payments included
  - **BookedScheduler** — PHP-based resource scheduler (rooms, equipment)
  - **Choose Easy!Appointments if:** PHP/MySQL comfort + shared hosting OK + simple service-business scheduling + free forever.
  - **Choose Cal.com if:** modern JS stack + want polished UX + integrated payments.
  - **Choose BookedScheduler if:** resource scheduling (meeting rooms, equipment) rather than customer-facing services.

## Links

- Repo: <https://github.com/alextselegidis/easyappointments>
- Homepage: <https://easyappointments.org>
- Docs: <https://easyappointments.org/docs.html>
- Releases: <https://github.com/alextselegidis/easyappointments/releases>
- Discord: <https://discord.com/invite/UeeSkaw>
- Cal.com (alt): <https://cal.com>
- BookedScheduler (alt): <https://www.bookedscheduler.com>
- Calendly (commercial): <https://calendly.com>
