import { Pool } from 'pg';
import { db } from '../config.js';

const pool = new Pool(db);

export default pool;