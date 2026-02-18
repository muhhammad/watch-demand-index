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
    id BIGSERIAL PRIMARY KEY,
    -- identity
    auction_house TEXT NOT NULL,
    auction_id TEXT NOT NULL,
    lot INTEGER NOT NULL,
    -- watch identity
    brand TEXT NOT NULL,
    reference_code TEXT,
    model TEXT,
    -- transaction data
    price NUMERIC NOT NULL,
    currency TEXT NOT NULL DEFAULT 'CHF',
    -- metadata
    url TEXT NOT NULL,
    image_url TEXT,
    -- auction timing
    auction_date DATE NOT NULL,
    -- system fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- constraints
    CONSTRAINT unique_url UNIQUE (url),
    CONSTRAINT unique_auction_lot UNIQUE
    (auction_house, auction_id, lot)
);