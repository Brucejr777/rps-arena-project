CREATE TABLE account (
  player_id SERIAL PRIMARY KEY,
  username VARCHAR(16) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  rating INTEGER NOT NULL DEFAULT 1000,
  rank VARCHAR(20) NOT NULL DEFAULT 'Bronze'
);

CREATE TABLE player_statistic (
  player_id INTEGER PRIMARY KEY REFERENCES account(player_id),
  matches_played INTEGER NOT NULL DEFAULT 0,
  matches_won INTEGER NOT NULL DEFAULT 0,
  matches_lost INTEGER NOT NULL DEFAULT 0,
  rounds_won INTEGER NOT NULL DEFAULT 0,
  rounds_lost INTEGER NOT NULL DEFAULT 0,
  draws INTEGER NOT NULL DEFAULT 0,
  rock_selections INTEGER NOT NULL DEFAULT 0,
  paper_selections INTEGER NOT NULL DEFAULT 0,
  scissors_selections INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE match (
  match_id SERIAL PRIMARY KEY,
  mode VARCHAR(20) NOT NULL,
  format_type VARCHAR(20) NOT NULL,
  wins_required INTEGER NOT NULL,
  player_a_id INTEGER REFERENCES account(player_id),
  player_b_id INTEGER REFERENCES account(player_id),
  winner_id INTEGER REFERENCES account(player_id),
  match_draw BOOLEAN NOT NULL DEFAULT FALSE,
  total_rounds INTEGER NOT NULL DEFAULT 0,
  draw_count INTEGER NOT NULL DEFAULT 0,
  rating_change_a INTEGER,
  rating_change_b INTEGER,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE round (
  id SERIAL PRIMARY KEY,
  match_id INTEGER REFERENCES match(match_id),
  round_number INTEGER NOT NULL,
  player_a_move VARCHAR(10),
  player_b_move VARCHAR(10),
  player_a_auto BOOLEAN NOT NULL DEFAULT FALSE,
  player_b_auto BOOLEAN NOT NULL DEFAULT FALSE,
  result VARCHAR(10)
);

CREATE TABLE room (
  room_code CHAR(6) PRIMARY KEY,
  host_id INTEGER REFERENCES account(player_id),
  guest_id INTEGER REFERENCES account(player_id),
  status VARCHAR(20) NOT NULL DEFAULT 'waiting',
  format_type VARCHAR(20) NOT NULL,
  wins_required INTEGER NOT NULL
);

CREATE TABLE leaderboard (
  player_id INTEGER PRIMARY KEY REFERENCES account(player_id),
  rating INTEGER NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE match_history (
  history_id SERIAL PRIMARY KEY,
  player_id INTEGER REFERENCES account(player_id),
  match_id INTEGER REFERENCES match(match_id),
  opponent_id INTEGER REFERENCES account(player_id),
  mode VARCHAR(20) NOT NULL,
  format_type VARCHAR(20) NOT NULL,
  result VARCHAR(10) NOT NULL,
  rating_before INTEGER,
  rating_after INTEGER,
  rank_change VARCHAR(20),
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);