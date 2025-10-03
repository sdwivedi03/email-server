import dotenv from 'dotenv';
dotenv.config();

module.exports = {
    db: {
        user: process.env.DB_USER,
        host: process.env.DB_HOST,
        database: process.env.DB_NAME,
        password: process.env.DB_PASS,
        port: 5432
    },
    jwtSecret: process.env.JWT_SECRET || 'change_this_secret',
    mail: {
        imapHost: 'mail.yourdomain.com',
        smtpHost: 'mail.yourdomain.com',
        imapPort: 993,
        smtpPort: 587
    }
};