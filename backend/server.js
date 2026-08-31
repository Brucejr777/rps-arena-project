require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const { createAuthRouter } = require('./routes/auth');

const app = express();
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use('/auth', createAuthRouter(pool));

const PORT = process.env.PORT || 3000;
if (require.main === module) {
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}

module.exports = { app, pool };