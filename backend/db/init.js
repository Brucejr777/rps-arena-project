require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

async function init() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });

  try {
    const schemaPath = path.join(__dirname, '..', 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');

    console.log('Connecting to database...');
    await pool.query('SELECT 1');
    console.log('Connected.');

    // Split schema into individual statements and execute each one.
    // This avoids issues with pg not handling multiple statements in one call.
    const statements = schema
      .split(';')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    for (const stmt of statements) {
      await pool.query(stmt);
    }

    console.log(`Executed ${statements.length} statements. All tables created.`);

    // Verify the account table exists with the expected columns
    const result = await pool.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns
      WHERE table_name = 'account'
      ORDER BY ordinal_position
    `);

    console.log('\nAccount table columns:');
    for (const row of result.rows) {
      console.log(
        `  ${row.column_name} (${row.data_type})` +
        `${row.is_nullable === 'NO' ? ' NOT NULL' : ''}` +
        `${row.column_default ? ` DEFAULT ${row.column_default}` : ''}`
      );
    }
  } catch (err) {
    console.error('Database initialization failed:', err.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

init();
