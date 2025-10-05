#!/bin/bash
set -euo pipefail

# Create vmail user/group and directory
VMAIL_UID=${VMAIL_UID:-5000}
VMAIL_GID=${VMAIL_GID:-5000}
VMAIL_DIR=${VMAIL_DIR:-/var/vmail}
getent group vmail >/dev/null 2>&1 || groupadd -g "$VMAIL_GID" vmail || true
id -u vmail >/dev/null 2>&1 || useradd -u "$VMAIL_UID" -g "$VMAIL_GID" -d "$VMAIL_DIR" -m -s /usr/sbin/nologin vmail || true
mkdir -p "$VMAIL_DIR"
chown -R vmail:vmail "$VMAIL_DIR"

# Initialize ClamAV database on first run if missing
if [ ! -s /var/lib/clamav/daily.cvd ] && [ ! -s /var/lib/clamav/daily.cld ]; then
  freshclam || true
fi

# Configure OpenDKIM
MAIL_DOMAIN=${MAIL_DOMAIN:-example.com}
DKIM_DIR="/etc/opendkim/keys/${MAIL_DOMAIN}"
mkdir -p "$DKIM_DIR"
if [ ! -f "$DKIM_DIR/mail.private" ]; then
  opendkim-genkey -D "$DKIM_DIR/" -d "$MAIL_DOMAIN" -s mail
  chown -R opendkim:opendkim "$DKIM_DIR"
  chmod 600 "$DKIM_DIR/mail.private"
fi

cat > /etc/opendkim.conf <<EOL
Syslog          yes
UMask           002
Domain          ${MAIL_DOMAIN}
KeyFile         ${DKIM_DIR}/mail.private
Selector        mail
Socket          inet:8891@localhost
EOL

# Configure Postfix virtual mailboxes via MySQL
DB_HOST=${DB_HOST:-mariadb}
DB_NAME=${DB_NAME:-mailserver}
DB_USER=${DB_USER:-postfix}
DB_PASS=${DB_PASS:-change_me}

mkdir -p /etc/postfix
cat > /etc/postfix/mysql-virtual-domains.cf <<EOL
user = ${DB_USER}
password = ${DB_PASS}
hosts = ${DB_HOST}
dbname = ${DB_NAME}
query = SELECT name FROM domains WHERE name='%s' AND enabled=1
EOL

cat > /etc/postfix/mysql-virtual-mailboxes.cf <<EOL
user = ${DB_USER}
password = ${DB_PASS}
hosts = ${DB_HOST}
dbname = ${DB_NAME}
query = SELECT 1 FROM users WHERE email='%s' AND enabled=1
EOL

cat > /etc/postfix/mysql-virtual-aliases.cf <<EOL
user = ${DB_USER}
password = ${DB_PASS}
hosts = ${DB_HOST}
dbname = ${DB_NAME}
query = SELECT destination FROM aliases WHERE source='%s' AND enabled=1
EOL

# Postfix main configuration additions
postfix_main_cf=/etc/postfix/main.cf
postfix_master_cf=/etc/postfix/master.cf
if ! grep -q "virtual_mailbox_domains" "$postfix_main_cf" 2>/dev/null; then
  cat >> "$postfix_main_cf" <<EOL
virtual_mailbox_domains = mysql:/etc/postfix/mysql-virtual-domains.cf
virtual_mailbox_maps = mysql:/etc/postfix/mysql-virtual-mailboxes.cf
virtual_alias_maps = mysql:/etc/postfix/mysql-virtual-aliases.cf
virtual_transport = lmtp:unix:private/dovecot-lmtp
virtual_mailbox_base = ${VMAIL_DIR}
virtual_minimum_uid = ${VMAIL_UID}
virtual_uid_maps = static:${VMAIL_UID}
virtual_gid_maps = static:${VMAIL_GID}
EOL
fi

# Dovecot configuration for SQL auth and LMTP
mkdir -p /etc/dovecot/conf.d
cat > /etc/dovecot/dovecot-sql.conf.ext <<EOL
driver = mysql
connect = host=${DB_HOST} dbname=${DB_NAME} user=${DB_USER} password=${DB_PASS}
default_pass_scheme = SHA512-CRYPT
password_query = SELECT email as user, password FROM users WHERE email = '%u' AND enabled=1
user_query = SELECT '${VMAIL_DIR}/%d/%n' as home, 'maildir:${VMAIL_DIR}/%d/%n/Maildir' as mail, ${VMAIL_UID} as uid, ${VMAIL_GID} as gid FROM users WHERE email = '%u' AND enabled=1
EOL

# 10-auth.conf: enable sql, disable system
AUTH_CONF=/etc/dovecot/conf.d/10-auth.conf
if [ -f "$AUTH_CONF" ]; then
  sed -i 's/^#!include auth-system.conf.ext/!include auth-system.conf.ext/' "$AUTH_CONF" || true
  sed -i 's/^!include auth-system.conf.ext/#!include auth-system.conf.ext/' "$AUTH_CONF" || true
  if ! grep -q "!include auth-sql.conf.ext" "$AUTH_CONF"; then
    echo "!include auth-sql.conf.ext" >> "$AUTH_CONF"
  fi
else
  echo "disable_plaintext_auth = yes" > "$AUTH_CONF"
  echo "!include auth-sql.conf.ext" >> "$AUTH_CONF"
fi

cat > /etc/dovecot/conf.d/auth-sql.conf.ext <<EOL
passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
userdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
EOL

# 10-mail.conf: set mail_location
MAIL_CONF=/etc/dovecot/conf.d/10-mail.conf
if [ -f "$MAIL_CONF" ]; then
  sed -i "s%^#\?mail_location =.*%mail_location = maildir:${VMAIL_DIR}/%d/%n/Maildir%" "$MAIL_CONF" || true
else
  echo "mail_location = maildir:${VMAIL_DIR}/%d/%n/Maildir" > "$MAIL_CONF"
fi

# 10-master.conf: enable lmtp and postfix auth socket
MASTER_CONF=/etc/dovecot/conf.d/10-master.conf
if [ -f "$MASTER_CONF" ]; then
  # Ensure lmtp service is enabled
  if ! grep -q "service lmtp" "$MASTER_CONF"; then
    cat >> "$MASTER_CONF" <<EOL
service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    mode = 0600
    user = postfix
    group = postfix
  }
}
EOL
  fi
  # Ensure auth socket for postfix
  if ! grep -q "/var/spool/postfix/private/auth" "$MASTER_CONF"; then
    cat >> "$MASTER_CONF" <<EOL
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
EOL
  fi
fi

# Ensure Postfix milter configuration
postfix_main_cf=/etc/postfix/main.cf
if ! grep -q "smtpd_milters = inet:localhost:8891" "$postfix_main_cf" 2>/dev/null; then
  cat >> "$postfix_main_cf" <<EOL
milter_default_action = accept
milter_protocol = 6
smtpd_milters = inet:localhost:8891
non_smtpd_milters = inet:localhost:8891
EOL
fi

# Configure Radicale basic auth if provided
RADICALE_USER=${RADICALE_USER:-}
RADICALE_PASS=${RADICALE_PASS:-}
if [ -n "$RADICALE_USER" ] && [ -n "$RADICALE_PASS" ]; then
  mkdir -p /etc/radicale
  if [ ! -f /etc/radicale/config ]; then
    cat > /etc/radicale/config <<EOL
[server]
hosts = 0.0.0.0:5232

[auth]
type = htpasswd
htpasswd_filename = /etc/radicale/users
htpasswd_encryption = bcrypt

[storage]
filesystem_folder = /var/lib/radicale/collections
EOL
  fi
  if [ ! -f /etc/radicale/users ]; then
    htpasswd -bBC 12 /etc/radicale/users "$RADICALE_USER" "$RADICALE_PASS"
  fi
fi

# Optionally request/renew certs on start if DOMAIN and MAIL_DOMAIN provided
if [ -n "${DOMAIN:-}" ] && [ -n "${MAIL_DOMAIN:-}" ] && [ -n "${SSL_EMAIL:-}" ]; then
  # Use --standalone; requires ports 80/443 not in use in the container
  certbot certonly --standalone \
    -d "$DOMAIN" -d "$MAIL_DOMAIN" \
    --non-interactive --agree-tos -m "$SSL_EMAIL" || true
fi

exec "$@"


