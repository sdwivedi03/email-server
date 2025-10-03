import express from 'express';
import bodyParser from 'body-parser';
import dotenv from 'dotenv';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import morgan from 'morgan';
import authRoutes from './routes/auth.js';
import mailRoutes from './routes/mail.js';
import calendarRoutes from './routes/calendar.js';
import contactsRoutes from './routes/contacts.js';

dotenv.config();

const app = express();
app.use(bodyParser.json());
app.use(cors());
app.use(helmet());
app.use(rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100
}));
app.use(morgan('combined'));
app.use('/auth', authRoutes);
app.use('/mail', mailRoutes);
app.use('/calendar', calendarRoutes);
app.use('/contacts', contactsRoutes);
app.use(errorHandler);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
