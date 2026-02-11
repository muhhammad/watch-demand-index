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
    lot_id SERIAL PRIMARY KEY,
    auction_event_id INTEGER REFERENCES auction_events(auction_event_id),

    brand_name TEXT,
    model_name TEXT,
    reference_code TEXT,

    lot_number TEXT,
    hammer_price NUMERIC,
    low_estimate NUMERIC,
    high_estimate NUMERIC,
    currency TEXT,

    case_material TEXT,
    year TEXT,
    condition_notes TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);