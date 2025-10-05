### Email server in Docker

Set required env vars in a `.env` next to `docker-compose.yml`:

```env
DOMAIN=mail.example.com
MAIL_DOMAIN=example.com
SSL_EMAIL=admin@example.com
# Optional for Radicale
RADICALE_USER=user@example.com
RADICALE_PASS=strongpassword

# MariaDB for virtual users
DB_ROOT_PASS=change-me-root
DB_NAME=mailserver
DB_USER=postfix
DB_PASS=change-me-app

# vmail user inside container
VMAIL_UID=5000
VMAIL_GID=5000
```

Build and run:

```bash
docker compose build
docker compose up -d
```

First-time database init:
- The file `db/init.sql` is mounted into MariaDB and creates tables: `domains`, `users`, `aliases`.
- Add your domain and users, e.g.:

```sql
INSERT INTO domains (name) VALUES ('example.com');
INSERT INTO users (domain_id, email, password) VALUES (
  (SELECT id FROM domains WHERE name='example.com'),
  'user@example.com',
  -- Hash with SHA512-CRYPT, e.g. via `doveadm pw -s SHA512-CRYPT`
  '$6$rounds=5000$...hashedpassword...'
);
```

You can exec into the DB container and run mysql:
```bash
docker exec -it email-mariadb mysql -u root -p$DB_ROOT_PASS $DB_NAME
```

Volumes are created for persistence: `mysql_data`, `postfix_data`, `postfix_etc`, `dovecot_data`, `dovecot_etc`, `rspamd_data`, `clamav_db`, `opendkim_keys`, `radicale_data`, `letsencrypt`, `vmail`.

DNS to add after first start:
- MX: `MAIL_DOMAIN` → `DOMAIN`
- SPF: `v=spf1 mx ~all`
- DKIM: publish selector `mail` TXT using the content from `/etc/opendkim/keys/$MAIL_DOMAIN/mail.txt`
- DMARC: `v=DMARC1; p=quarantine; rua=mailto:postmaster@$MAIL_DOMAIN`

Notes:
- Certificates: container tries `certbot --standalone`. Prefer terminating TLS at a reverse proxy and mounting certs into `/etc/letsencrypt`.
- Postfix and Dovecot are auto-configured to use MariaDB for virtual domains/users and LMTP delivery to Dovecot. Mail is stored under `/var/vmail/%d/%n/Maildir`.


