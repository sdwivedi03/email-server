import express from 'express';
import authenticateToken from '../middleware/auth.middleware.js';
import { getContacts } from '../services/contact.service.js';


const router = express.Router();

//Get Contacts
router.get('/', authenticateToken, async (req, res) => {
    try {
        const contacts = await getContacts(req.user.email, req.body.password);
        res.json(contacts);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

export default router;
