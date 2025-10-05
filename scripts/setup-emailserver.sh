#!/bin/bash
set -e
# Full Email Server Installation Script
# Postfix, Dovecot, Rspamd, ClamAV, Radicale, DKIM, SPF, DMARC, SSL, Fail2Ban

# NOTE: This is a simplified placeholder. For the complete detailed script,
# refer to the ChatGPT conversation export.

echo "Starting email server setup..."

#apt install -y postfix dovecot-core dovecot-imapd dovecot-pop3d rspamd clamav clamav-daemon radicale mariadb-server fail2ban certbot opendkim opendkim-tools



# ===============================
# Variables (edit these)
# ===============================
DOMAIN="mail.tridevsoft.com"       # Mail server hostname
MAIL_DOMAIN="tridevsoft.com"       # Email domain
DB_ROOT_PASS="MyDBPass"
MAIL_DB_PASS="MyDbPass"
MAIL_USER="postfix"
SSL_EMAIL="admin@tridevsoft.com"

# ===============================
# Update system
# ===============================
apt update && apt upgrade -y

# ===============================
# Install core packages
# ===============================
apt install -y software-properties-common curl gnupg2 lsb-release apt-transport-https

# ===============================
# Install MariaDB
# ===============================
apt install -y mariadb-server mariadb-client
mysql_secure_installation <<EOF

y
$DB_ROOT_PASS
$DB_ROOT_PASS
y
y
y
y
EOF

# Create mail database and user
mysql -uroot -p$DB_ROOT_PASS <<MYSQL_SCRIPT
CREATE DATABASE mailserver;
CREATE USER '$MAIL_USER'@'localhost' IDENTIFIED BY '$MAIL_DB_PASS';
GRANT ALL PRIVILEGES ON mailserver.* TO '$MAIL_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# ===============================
# Install Postfix, Dovecot
# ===============================
DEBIAN_FRONTEND=noninteractive apt install -y postfix postfix-mysql dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql

# ===============================
# Install Spam & Antivirus
# ===============================
apt install -y rspamd clamav clamav-daemon

# ===============================
# Install DKIM Signing
# ===============================
apt install -y opendkim opendkim-tools
mkdir -p /etc/opendkim/keys/$MAIL_DOMAIN

# Generate DKIM keys
opendkim-genkey -D /etc/opendkim/keys/$MAIL_DOMAIN/ -d $MAIL_DOMAIN -s mail
chown opendkim:opendkim /etc/opendkim/keys/$MAIL_DOMAIN/mail.private
chmod 600 /etc/opendkim/keys/$MAIL_DOMAIN/mail.private

# Configure OpenDKIM
cat > /etc/opendkim.conf <<EOL
Syslog          yes
UMask           002
Domain          $MAIL_DOMAIN
KeyFile         /etc/opendkim/keys/$MAIL_DOMAIN/mail.private
Selector        mail
Socket          inet:8891@localhost
EOL

# Link OpenDKIM with Postfix
cat >> /etc/postfix/main.cf <<EOL
milter_default_action = accept
milter_protocol = 6
smtpd_milters = inet:localhost:8891
non_smtpd_milters = inet:localhost:8891
EOL

systemctl enable opendkim
systemctl restart opendkim

# ===============================
# Install Radicale (CalDAV + CardDAV)
# ===============================
apt install -y radicale apache2-utils
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

htpasswd -B /etc/radicale/users user@$MAIL_DOMAIN

systemctl enable radicale
systemctl restart radicale

# ===============================
# Install Fail2Ban
# ===============================
apt install -y fail2ban
systemctl enable fail2ban

# ===============================
# Install SSL Certificates
# ===============================
apt install -y certbot
certbot certonly --standalone -d $DOMAIN -d $MAIL_DOMAIN --non-interactive --agree-tos -m $SSL_EMAIL

# ===============================
# Restart services
# ===============================
systemctl restart postfix dovecot rspamd clamav-daemon fail2ban

# ===============================
# Output DNS records
# ===============================
echo "✅ Setup complete!"
echo ""
echo "Add these DNS records:"
echo "MX: $MAIL_DOMAIN → $DOMAIN"
echo "SPF: v=spf1 mx ~all"
echo "DKIM: $(cat /etc/opendkim/keys/$MAIL_DOMAIN/mail.txt)"
echo "DMARC: v=DMARC1; p=quarantine; rua=mailto:postmaster@$MAIL_DOMAIN"