import express from 'express';
import { registerUser, loginUser } from '../services/auth.service.js';
const router = express.Router();

//Register User
router.post('/register', async (req, res) => {
    const { email, password, domain } = req.body;
    try {
        const result = await registerUser(email, password, domain);
        res.json(result);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

//Login User
router.post('/login', async (req, res) => {
    const { email, password } = req.body;
    try {
        const result = await loginUser(email, password);
        res.json(result);
    } catch (err) {
        res.status(401).json({ error: err.message });
    }
});

export default router;