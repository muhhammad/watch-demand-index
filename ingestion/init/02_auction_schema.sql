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

CREATE TABLE auction_lots (
    lot_id SERIAL PRIMARY KEY,
    auction_id INT REFERENCES auctions(auction_id),

    lot_number VARCHAR(20),

    title TEXT,
    description TEXT,

    brand_name VARCHAR(100),

    reference_code VARCHAR(50),
    reference_id INT REFERENCES watch_references(reference_id),

    estimate_low NUMERIC,
    estimate_high NUMERIC,
    hammer_price NUMERIC,
    currency VARCHAR(10)
);