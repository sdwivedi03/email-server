import express from 'express';
import { getCalendarEvents } from '../services/caldav.service.js';
import authenticateToken from '../middleware/auth.middleware.js';

const router = express.Router();

//Get Calendar Events
router.get('/', authenticateToken, async (req, res) => {
    const { email, password } = req.user;
    try {
        const events = await getCalendarEvents(email, password);
        res.json(events);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

export default router;
