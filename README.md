# Full Email + Groupware Server

This setup provides:
- Email (SMTP/IMAP/POP3)
- Spam & virus protection
- DKIM, SPF, DMARC for email authenticity
- Calendar (CalDAV) & Contacts (CardDAV)
- SSL encryption
- Brute-force protection
- Node.js REST API with JWT authentication
- PostgreSQL for user and domain management


---

## Components

### 1. Postfix
- **Type:** SMTP server
- **Use:** Sends outgoing email & receives incoming email.
- **Why needed:** Without it, your server can’t send or accept messages.

### 2. Dovecot
- **Type:** IMAP/POP3 server
- **Use:** Stores and serves email to clients (webmail, mobile apps).
- **Why needed:** Lets users read and manage their email.

### 3. MariaDB
- **Type:** Database
- **Use:** Stores email accounts, domains, and passwords.
- **Why needed:** Central user management for the mail system.

### 4. Rspamd
- **Type:** Spam filter
- **Use:** Detects and blocks unwanted spam messages.
- **Why needed:** Keeps inboxes clean and protects from phishing.

### 5. ClamAV
- **Type:** Antivirus
- **Use:** Scans incoming/outgoing messages for malware.
- **Why needed:** Prevents spreading infected files.

### 6. OpenDKIM
- **Type:** DKIM signing tool
- **Use:** Signs outgoing messages to prove they came from your domain.
- **Why needed:** Prevents spoofing and improves email deliverability.

### 7. SPF
- **Type:** DNS record
- **Use:** Lists servers allowed to send email for your domain.
- **Why needed:** Helps recipient servers verify your messages.

### 8. DMARC
- **Type:** DNS policy
- **Use:** Tells recipient servers how to handle messages failing SPF/DKIM.
- **Why needed:** Adds an extra layer of protection against spoofing.

### 9. Radicale
- **Type:** CalDAV & CardDAV server
- **Use:** Provides calendar & contacts sync.
- **Why needed:** Lets users manage events and contacts like Google Calendar/Contacts.

### 10. Fail2Ban
- **Type:** Security tool
- **Use:** Blocks IPs after repeated failed login attempts.
- **Why needed:** Protects against brute-force attacks.

### 11. Certbot
- **Type:** SSL tool
- **Use:** Generates Let’s Encrypt certificates.
- **Why needed:** Encrypts email and web connections.

### 12. Node 18+
- **Type:** SSL tool
- **Use:** Generates Let’s Encrypt certificates.
- **Why needed:** Encrypts email and web connections.
---

## How It Works
1. Postfix handles email delivery.
2. Dovecot stores and serves messages.
3. Rspamd + ClamAV filter spam & viruses.
4. OpenDKIM + SPF + DMARC verify authenticity.
5. Radicale handles calendars & contacts.
6. Fail2Ban blocks malicious login attempts.
7. Certbot secures everything with SSL.

---

## Setup Instructions

1. Infrastructure setup:
   ```bash
   chmod +x setup-mailserver.sh
   sudo ./setup-mailserver.sh
   ```


2. Install dependencies:
   ```bash
   npm install
   ```

3. Create the database and import schema:
   ```bash
   psql -U your_db_user -d your_db_name -f db_schema.sql
   ```

4. Configure `.env` file.

5. Run the server:
   ```bash
   node server.js
   ```