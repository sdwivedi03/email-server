const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('./dbService');
const { jwtSecret } = require('../config');

async function registerUser(email, password, domain) {
    const hash = await bcrypt.hash(password, 10);

    let domainResult = await pool.query('SELECT id FROM domains WHERE name=$1', [domain]);
    let domainId;

    if (domainResult.rows.length === 0) {
        let insertDomain = await pool.query(
            'INSERT INTO domains (name) VALUES ($1) RETURNING id',
            [domain]
        );
        domainId = insertDomain.rows[0].id;
    } else {
        domainId = domainResult.rows[0].id;
    }

    await pool.query(
        'INSERT INTO users (email, password_hash, domain_id) VALUES ($1, $2, $3)',
        [email, hash, domainId]
    );

    return { email, domain };
}

async function loginUser(email, password) {
    const userResult = await pool.query('SELECT * FROM users WHERE email=$1', [email]);
    if (userResult.rows.length === 0) throw new Error('User not found');

    const user = userResult.rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) throw new Error('Invalid password');

    const token = jwt.sign({ id: user.id, email: user.email }, jwtSecret, { expiresIn: '12h' });
    return { token };
}

module.exports = { registerUser, loginUser };