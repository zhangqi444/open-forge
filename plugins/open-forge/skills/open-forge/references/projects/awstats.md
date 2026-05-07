---
name: AWStats
description: Log file analyzer generating web, streaming, FTP, or mail server statistics. Visitor counts, pages, hits, referrers, search keywords, bots, and more. GPL-3.0 licensed. NOTE — deprecated November 2025; no longer actively developed.
website: http://www.awstats.org/
source: https://github.com/eldy/awstats
license: GPL-3.0
stars: 425
tags:
  - analytics
  - log-analysis
  - web-statistics
  - deprecated
platforms:
  - Perl
---

# AWStats

> ⚠️ **Deprecated (November 2025)**: AWStats has been officially deprecated and is no longer actively developed. The author recommends migrating to [Matomo Log Analytics](https://matomo.org/log-analytics/). This recipe is preserved for historical reference and existing deployments.

AWStats (Advanced Web Statistics) is a full-featured web server log file analyzer. It parses Apache, IIS, Nginx, and other server logs to generate detailed statistics: unique visitors, pages, hits, duration, countries, referrers, search engine keywords, robots, error pages, and more. It runs as a CGI script or via command line, generating static HTML reports.

Official site: http://www.awstats.org/
Source: https://github.com/eldy/awstats
Migration guide: https://matomo.org/faq/log-analytics-tool/how-do-i-migrate-from-awstats-to-matomo/

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux / BSD | Perl + Apache/Nginx | Traditional CGI or command-line |
| Debian/Ubuntu | apt package | `sudo apt install awstats` |

## Inputs to Collect

**Phase: Planning**
- Web server type (Apache, Nginx, IIS)
- Log file format and path
- Domain name for the AWStats config
- Whether to serve reports via CGI or generate static HTML

## Software-Layer Concerns

**Install (Debian/Ubuntu):**

```bash
sudo apt install awstats
# Config files go to /etc/awstats/
```

**Create site config (`/etc/awstats/awstats.example.com.conf`):**

```perl
LogFile="/var/log/nginx/access.log"
LogFormat="%host %other %logname %time1 %methodurl %code %bytesd %refererquot %uaquot"
SiteDomain="example.com"
HostAliases="www.example.com"
DirData="/var/lib/awstats"
AllowToUpdateStatsFromBrowser=0
```

For Apache combined log format, use `LogFormat=1`.

**Generate/update statistics:**

```bash
sudo /usr/lib/cgi-bin/awstats.pl -config=example.com -update
# Or via awstats_updateall.pl:
sudo /usr/share/doc/awstats/examples/awstats_updateall.pl now -confdir=/etc/awstats -awstatsprog=/usr/lib/cgi-bin/awstats.pl
```

**Automate via cron:**

```cron
0 * * * * www-data /usr/lib/cgi-bin/awstats.pl -config=example.com -update > /dev/null
```

**View reports:**

Either enable the CGI script in your web server config, or generate static HTML:

```bash
awstats_buildstaticpages.pl -config=example.com -dir=/var/www/awstats -awstatsprog=/usr/lib/cgi-bin/awstats.pl
```

**Nginx CGI config (with fcgiwrap):**

```nginx
location /awstats/ {
    auth_basic "AWStats";
    auth_basic_user_file /etc/nginx/.htpasswd;
    fastcgi_pass unix:/var/run/fcgiwrap.socket;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME /usr/lib/cgi-bin/awstats.pl;
}
```

## Upgrade Procedure

AWStats is deprecated — no further releases are planned. For an active alternative, migrate to Matomo: https://matomo.org/log-analytics/

## Gotchas

- **Deprecated**: Official development ended November 2025 — no security fixes or new features will be released
- **Perl required**: AWStats is a Perl CGI script; ensure Perl is installed with required modules
- **Log format must match**: Incorrect `LogFormat` setting produces empty or wrong stats — match exactly to your web server's log format
- **Protect the CGI**: Never expose AWStats CGI publicly without authentication — anyone with access can read full visitor logs
- **Real-time limitations**: AWStats processes log files periodically, not in real time
- **Consider alternatives**: Matomo, GoAccess (terminal-based), or Plausible for modern replacements

## Links

- Upstream README: https://github.com/eldy/awstats/blob/master/README.md
- Official site: http://www.awstats.org/
- Migrate to Matomo: https://matomo.org/faq/log-analytics-tool/how-do-i-migrate-from-awstats-to-matomo/
