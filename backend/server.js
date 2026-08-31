require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const { createAuthRouter } = require('./routes/auth');
const { createQuickMatchRouter } = require('./routes/quick_match');
const { createRoomsRouter } = require('./routes/rooms');
const { createRankedRouter } = require('./routes/ranked');
const { createMatchesRouter } = require('./routes/matches');

const app = express();
app.use(express.json());

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use('/auth', createAuthRouter(pool));
app.use('/quick-match', createQuickMatchRouter(pool));
app.use('/rooms', createRoomsRouter(pool));
app.use('/ranked', createRankedRouter(pool));
app.use('/matches', createMatchesRouter(pool));

const PORT = process.env.PORT || 3000;
if (require.main === module) {
  app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}

module.exports = { app, pool };