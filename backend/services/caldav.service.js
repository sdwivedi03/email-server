import dav from 'dav';

async function getCalendarEvents(username, password) {
    const xhr = new dav.transport.Basic(
        new dav.Credentials({ username, password })
    );

    const account = await dav.createAccount({
        server: `http://mail.yourdomain.com:5232`,
        accountType: 'caldav',
        loadCollections: true,
        loadObjects: true,
        xhr
    });

    const events = [];
    account.calendars.forEach(cal => {
        cal.objects.forEach(obj => {
            events.push(obj);
        });
    });

    return events;
}

async function addCalendarEvent(username, password, eventData) {
    // You can use ical.js to create proper iCal format
}

export default { getCalendarEvents, addCalendarEvent };