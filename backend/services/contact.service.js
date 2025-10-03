const dav = require('dav');

async function getContacts(username, password) {
    const xhr = new dav.transport.Basic(
        new dav.Credentials({ username, password })
    );

    const account = await dav.createAccount({
        server: `http://mail.yourdomain.com:5232`,
        accountType: 'carddav',
        loadCollections: true,
        loadObjects: true,
        xhr
    });

    const contacts = [];
    account.addressBooks.forEach(book => {
        book.objects.forEach(obj => {
            contacts.push(obj);
        });
    });

    return contacts;
}

module.exports = { getContacts };