const nodemailer = require('nodemailer');

async function sendEmail(user, password, to, subject, text) {
    let transporter = nodemailer.createTransport({
        host: 'mail.yourdomain.com',
        port: 587,
        secure: false,
        auth: { user, pass: password }
    });

    let info = await transporter.sendMail({
        from: user,
        to,
        subject,
        text
    });

    return info;
}

module.exports = { sendEmail };