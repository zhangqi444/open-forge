# Request Tracker (RT)

Request Tracker (RT) is an enterprise-grade issue tracking system built in Perl. It supports ticketing, queues, custom workflows, email integration, SLA tracking, dashboards, and a rich permissions model. Widely used by IT departments, support teams, and software projects.

**Website:** https://www.bestpractical.com/rt/
**Source:** https://github.com/bestpractical/rt
**License:** GPL-2.0
**Stars:** ~1,111

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux (Debian/Ubuntu/RHEL) | Perl + MySQL/MariaDB/PostgreSQL + Apache/nginx | Traditional |
| Docker | Community/custom image | No official Docker image |
| FreeBSD | pkg + manual | Supported |

---

## Inputs to Collect

### Phase 1 — Planning
- Database: MySQL 5.7+, MariaDB 10+, or PostgreSQL 9.3+
- Web server: Apache (with `mod_perl` for best performance) or nginx + FastCGI
- Perl 5.10.1+
- Email: inbound (queue email aliases) and outbound (SMTP)
- `RT_WEBSITE_DOMAIN`: hostname

### Phase 2 — Deployment
- `DatabaseType`: mysql / Pg
- `DatabaseHost`, `DatabaseName`, `DatabaseUser`, `DatabasePassword`
- `WebDomain`, `WebPort`, `WebPath`
- `rtname`: unique identifier for this RT installation (used in email subjects)
- `Organization`: your org name
- SMTP / sendmail config

---

## Software-Layer Concerns

### Installation from Source (Debian/Ubuntu)

```bash
# Install dependencies
sudo apt-get install -y perl libssl-dev libexpat1-dev libz-dev \
  libmysqlclient-dev apache2 libapache2-mod-perl2

# Download RT
wget https://download.bestpractical.com/pub/rt/release/rt-6.0.2.tar.gz
tar -xzf rt-6.0.2.tar.gz && cd rt-6.0.2

# Configure (choose prefix and database type)
./configure --with-db-type=mysql \
            --with-web-user=www-data \
            --with-web-group=www-data \
            --prefix=/opt/rt6

# Install Perl dependencies (can take a while)
make fixdeps

# Test dependencies
make testdeps

# Install RT
sudo make install
```

### Database Setup
```bash
# Create database and load schema
sudo /opt/rt6/sbin/rt-setup-database --action init

# Creates tables and initial data
# Default admin user: root / password (change immediately!)
```

### RT Config (`/opt/rt6/etc/RT_SiteConfig.pm`)
```perl
Set($rtname, 'example-rt');
Set($Organization, 'Example Corp');
Set($WebDomain, 'rt.example.com');
Set($WebPort, 443);
Set($WebPath, '');

# Database
Set($DatabaseType, 'mysql');
Set($DatabaseHost, 'localhost');
Set($DatabaseName, 'rt6');
Set($DatabaseUser, 'rt_user');
Set($DatabasePassword, 'rt_password');

# Email
Set($CorrespondAddress, 'rt@example.com');
Set($CommentAddress, 'rt-comment@example.com');
Set($SendmailArguments, '-t -oi -f rt@example.com');
```

### Apache with mod_perl (`/etc/apache2/sites-available/rt.conf`)
```apache
<VirtualHost *:443>
    ServerName rt.example.com
    DocumentRoot /opt/rt6/share/html

    PerlRequire /opt/rt6/bin/webmux.pl

    <Location />
        SetHandler perl-script
        PerlResponseHandler Plack::Handler::Apache2
        PerlSetVar psgi_app /opt/rt6/sbin/rt-server
    </Location>

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/rt.crt
    SSLCertificateKeyFile /etc/ssl/private/rt.key
</VirtualHost>
```

### nginx + FastCGI
```nginx
server {
    listen 443 ssl;
    server_name rt.example.com;

    location / {
        fastcgi_pass unix:/var/run/rt/rt.socket;
        fastcgi_param SCRIPT_NAME "";
        fastcgi_param PATH_INFO $uri;
        include fastcgi_params;
    }
}
```

```bash
# Start FastCGI server
/opt/rt6/sbin/rt-server --server FCGI \
  --listen /var/run/rt/rt.socket \
  --user www-data --group www-data &
```

### Email Integration
RT processes email via aliases or a mail filtering script:
```
# /etc/aliases (Postfix/sendmail)
rt:          "|/opt/rt6/bin/rt-mailgate --queue General --action correspond"
rt-comment:  "|/opt/rt6/bin/rt-mailgate --queue General --action comment"
```

Run `newaliases` after editing.

---

## Upgrade Procedure

```bash
# Download new release and extract
tar -xzf rt-new.tar.gz && cd rt-new

# Re-run configure with same options as original install
./configure --with-db-type=mysql --prefix=/opt/rt6 ...

# Install (overwrites code, preserves config/data)
sudo make upgrade

# Upgrade database schema
sudo /opt/rt6/sbin/rt-setup-database --action upgrade

# Restart web server
sudo systemctl restart apache2
```

---

## Gotchas

- **No official Docker image**: RT requires Perl module compilation (`make fixdeps`) which is complex to containerize. Most production deployments use bare-metal or VM installs.
- **mod_perl vs FastCGI**: Apache with `mod_perl2` gives best performance. nginx requires FastCGI mode which needs manual process management.
- **Email configuration is critical**: RT's core workflow revolves around email; incorrect aliases or SMTP config breaks ticket creation and notifications.
- **`make fixdeps` takes time**: Installing CPAN dependencies on first install can take 15-30 minutes. Run in a screen/tmux session.
- **`rtname` should never change**: It is embedded in email subjects for ticket threading. Changing it breaks Reply-to-ticket via email.
- **Default admin password**: Change `root`'s password immediately after initial setup.
- **Performance at scale**: For high-volume installs, configure MySQL/PostgreSQL with appropriate indexes and consider enabling RT's caching features.

---

## Links
- Docs: https://docs.bestpractical.com/rt/latest/
- Installation Guide: https://docs.bestpractical.com/rt/latest/install.html
- GitHub Releases: https://github.com/bestpractical/rt/releases
- Community: https://forum.bestpractical.com/
- Download: https://download.bestpractical.com/pub/rt/release/
