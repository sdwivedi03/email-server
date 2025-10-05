FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    DOMAIN=mail.example.com \
    MAIL_DOMAIN=example.com \
    SSL_EMAIL=admin@example.com

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg2 lsb-release apt-transport-https \
      supervisor rsyslog \
      postfix postfix-mysql \
      dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql \
      rspamd \
      clamav clamav-daemon \
      opendkim opendkim-tools \
      radicale apache2-utils \
      fail2ban \
      certbot && \
    rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /var/run/opendkim /etc/opendkim/keys /var/lib/radicale/collections /var/log/supervisor

# Copy supervisor config and entrypoint
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose common mail, sieve, rspamd web, and radicale ports
EXPOSE 25 465 587 110 995 143 993 4190 11334 5232

# Volumes to persist data and config
VOLUME [ \
  "/etc/postfix", \
  "/var/spool/postfix", \
  "/etc/dovecot", \
  "/var/lib/dovecot", \
  "/var/lib/rspamd", \
  "/var/lib/clamav", \
  "/etc/opendkim/keys", \
  "/var/lib/radicale/collections", \
  "/var/vmail", \
  "/etc/letsencrypt" \
]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]


