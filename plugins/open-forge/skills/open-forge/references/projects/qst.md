---
name: qst
description: QST (QSTonline) recipe for open-forge. Online assessment and quiz software supporting mobile quick quizzes through large-scale proctored desktop testing. Perl/MySQL. GPL-2.0. Based on upstream at https://sourceforge.net/projects/qstonline/ and https://qstonline.org.
---

# QST (QSTonline)

Online assessment software covering everything from quick mobile quizzes to large-scale, high-stakes, proctored desktop testing. Designed to be easy to deploy and economical to run. Supports multiple question types, timed exams, secure browser lockdown for proctored tests, and result reporting. Built in Perl with MySQL. GPL-2.0. Source: https://sourceforge.net/projects/qstonline/. Website: https://qstonline.org.

## Compatible install methods

| Method | When to use |
|---|---|
| Source / Perl + Apache | Standard; Perl web application |
| Shared hosting | Perl CGI compatible with cPanel/Plesk environments |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| database | "MySQL host, database, user, password?" | Strings | MySQL/MariaDB required |
| config | "Base URL / domain?" | FQDN | e.g. quiz.yourdomain.com |
| config | "Admin username and password?" | Strings | Set during install |
| smtp | "SMTP server?" | Host:port | For email notifications/results |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Perl (CGI or FastCGI) |
| Database | MySQL / MariaDB |
| Web server | Apache (mod_cgi or mod_fcgid) |
| Perl modules | DBI, DBD::mysql, and others; install via CPAN or OS packages |
| Session storage | MySQL-backed sessions |
| File uploads | Requires writable upload directory |
| Secure testing | Proctored mode uses browser lockdown features |

## Install: Source

Source: https://sourceforge.net/projects/qstonline/

Download the latest release tarball from SourceForge:

```bash
# Download from https://sourceforge.net/projects/qstonline/files/
tar xzf qst-*.tar.gz
cd qst-*/
```

**Install Perl dependencies:**

```bash
# Debian/Ubuntu
apt install libdbi-perl libdbd-mysql-perl perl libapache2-mod-perl2

# Via CPAN
cpan DBI DBD::mysql
```

**Create database:**

```bash
mysql -u root -p -e "CREATE DATABASE qst; GRANT ALL ON qst.* TO 'qst'@'localhost' IDENTIFIED BY 'CHANGEME';"
```

**Configure:** Edit the configuration file (typically `qst.conf` or similar in the source) with your database credentials, base URL, and SMTP settings.

**Import schema:**

```bash
mysql -u qst -p qst < sql/qst.sql
```

**Configure Apache:**

```apache
Alias /qst /var/www/qst
<Directory /var/www/qst>
    Options +ExecCGI
    AddHandler cgi-script .pl
    AllowOverride All
</Directory>
```

Visit `http://yourdomain/qst/setup.pl` (or equivalent) to complete installation.

## Upgrade procedure

1. Download new release from https://sourceforge.net/projects/qstonline/files/
2. Back up database: `mysqldump qst > qst-backup.sql`
3. Replace files (preserve config)
4. Run any migration scripts from the release notes
5. Reload Apache

## Gotchas

- Perl CGI overhead: Perl CGI has higher per-request overhead than modern frameworks. For heavy load, use FastCGI (`libapache2-mod-fcgid`) or a Perl PSGI server (Plack/Starman) behind a proxy.
- CPAN dependencies: Not all required Perl modules are in every distro's package repository. Some may need CPAN install, which requires a compiler and build tools.
- SourceForge hosting: Source code and releases are on SourceForge, not GitHub/GitLab. Download links and version numbers must be checked at https://sourceforge.net/projects/qstonline/files/.
- Proctored testing: High-stakes proctored exams require additional configuration (browser lockdown, IP restrictions). Review upstream documentation before deploying for formal assessments.
- Free hosted option: QSTonline.org offers free hosted accounts at https://qstonline.org/free_account.htm — self-hosting is optional if you just want to evaluate.
- MySQL required: The application uses MySQL-specific features; PostgreSQL is not supported.

## Links

- Website: https://qstonline.org
- Source (SourceForge): https://sourceforge.net/projects/qstonline/
- Free hosted account: https://qstonline.org/free_account.htm
