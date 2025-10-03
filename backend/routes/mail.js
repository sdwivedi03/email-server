import express from 'express';
import imaps from 'imap-simple';
import nodemailer from 'nodemailer';
import dotenv from 'dotenv';
import { fetchInboxEmails } from '../services/imap.service.js';
import { sendEmail } from '../services/smtp.service.js';
dotenv.config();

const router = express.Router();

//Get Inbox Emails
router.get('/inbox', async (req, res) => {
  const config = {
    imap: {
      user: process.env.MAIL_USER,
      password: process.env.MAIL_PASS,
      host: process.env.MAIL_HOST,
      port: process.env.MAIL_IMAP_PORT,
      tls: true,
      authTimeout: 3000
    }
  };
  try {
    const connection = await imaps.connect(config);
    await connection.openBox('INBOX');
    const results = await connection.search(['ALL'], { bodies: ['HEADER', 'TEXT'], struct: true });
    res.json(results);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

//Send Email
  router.post('/send', async (req, res) => {
  const { to, subject, text } = req.body;
  const transporter = nodemailer.createTransport({
    host: process.env.MAIL_HOST,
    port: process.env.MAIL_SMTP_PORT,
    secure: false,
    auth: { user: process.env.MAIL_USER, pass: process.env.MAIL_PASS }
  });
  try {
    const info = await transporter.sendMail({ from: process.env.MAIL_USER, to, subject, text });
    res.json({ messageId: info.messageId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


//New

// Get inbox emails
router.get('/inbox', authenticateToken, async (req, res) => {
    const { email, password } = req.query;
    try {
        const emails = await fetchInboxEmails(email, password);
        res.json(emails);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Send email
router.post('/send', authenticateToken, async (req, res) => {
    const { email, password, to, subject, message } = req.body;
    try {
        const result = await sendEmail(email, password, to, subject, message);
        res.json({ status: 'sent', result });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

export default router;
