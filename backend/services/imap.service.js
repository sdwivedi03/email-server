const { ImapFlow } = require('imapflow');

async function fetchInboxEmails(user, password) {
    const client = new ImapFlow({
        host: 'mail.yourdomain.com',
        port: 993,
        secure: true,
        auth: { user, pass: password }
    });

    await client.connect();
    await client.mailboxOpen('INBOX');

    let emails = [];
    for await (let msg of client.fetch('1:*', { envelope: true })) {
        emails.push({
            subject: msg.envelope.subject,
            from: msg.envelope.from,
            date: msg.envelope.date
        });
    }

    await client.logout();
    return emails;
}

module.exports = { fetchInboxEmails };