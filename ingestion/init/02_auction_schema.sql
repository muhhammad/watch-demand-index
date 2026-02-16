-- ============================================
-- 01b_auction_schema.sql
-- Adds auction infrastructure (non-destructive)
-- ============================================
DROP TABLE IF EXISTS auction_houses CASCADE;
DROP TABLE IF EXISTS auction_events CASCADE;
DROP TABLE IF EXISTS auction_lots CASCADE;

CREATE TABLE IF NOT EXISTS auction_houses (
    auction_house_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    website TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS auction_events (
    auction_event_id SERIAL PRIMARY KEY,
    auction_house_id INTEGER REFERENCES auction_houses(auction_house_id),
    event_name TEXT NOT NULL,
    location TEXT,
    event_date DATE,
    currency TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS auction_lots (
    id SERIAL PRIMARY KEY,
    auction_house TEXT,
    auction_id TEXT,
    lot INTEGER,
    brand TEXT,
    reference_code TEXT,
    model TEXT,
    price NUMERIC,
    currency TEXT,
    url TEXT UNIQUE,
    created_at TIMESTAMP
);