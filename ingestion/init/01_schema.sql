-- =========================================================
-- WATCH DEMAND INDEX – SCHEMA v1
-- =========================================================

-- -----------------------------
-- Clean reset (DEV / DEMO ONLY)
-- -----------------------------
DROP TABLE IF EXISTS demand_scores CASCADE;
DROP TABLE IF EXISTS listings_daily CASCADE;
DROP TABLE IF EXISTS watch_references CASCADE;
DROP TABLE IF EXISTS models CASCADE;
DROP TABLE IF EXISTS brands CASCADE;


-- -----------------------------
-- Brands
-- -----------------------------
CREATE TABLE brands (
    brand_id SERIAL PRIMARY KEY,
    brand_name TEXT NOT NULL UNIQUE
);


-- -----------------------------
-- Models
-- -----------------------------
CREATE TABLE models (
    model_id SERIAL PRIMARY KEY,
    brand_id INT NOT NULL REFERENCES brands(brand_id),
    model_name TEXT NOT NULL,

    UNIQUE (brand_id, model_name)
);


-- -----------------------------
-- Watch references
-- -----------------------------
CREATE TABLE watch_references (
    reference_id SERIAL PRIMARY KEY,
    model_id INT NOT NULL REFERENCES models(model_id),
    reference_code TEXT NOT NULL UNIQUE
);


-- -----------------------------
-- Daily aggregated listings
-- -----------------------------
CREATE TABLE listings_daily (
    snapshot_date DATE NOT NULL,
    reference_id INT NOT NULL REFERENCES watch_references(reference_id),
    avg_price NUMERIC NOT NULL,
    min_price NUMERIC NOT NULL,
    listing_count INT NOT NULL,
    avg_days_on_market INT,

    PRIMARY KEY (snapshot_date, reference_id)
);


-- -----------------------------
-- Demand scores (derived)
-- -----------------------------
CREATE TABLE demand_scores (
    snapshot_date DATE NOT NULL,
    reference_id INT NOT NULL REFERENCES watch_references(reference_id),
    sellability_score INT NOT NULL CHECK (sellability_score BETWEEN 0 AND 100),
    exit_confidence TEXT NOT NULL CHECK (exit_confidence IN ('High', 'Medium', 'Low')),
    expected_exit_min INT NOT NULL,
    expected_exit_max INT NOT NULL,
    price_risk_band TEXT NOT NULL CHECK (price_risk_band IN ('Low', 'Medium', 'High')),
    market_depth TEXT NOT NULL CHECK (market_depth IN ('Thin', 'Moderate', 'Deep')),

    PRIMARY KEY (snapshot_date, reference_id)
);


-- ============================================
-- Market listings (Chrono24, dealers, etc.)
-- ============================================

CREATE TABLE IF NOT EXISTS market_listings (

    id SERIAL PRIMARY KEY,
    source TEXT NOT NULL,              -- e.g. CHRONO24
    brand TEXT,
    model TEXT,
    reference_code TEXT,
    price NUMERIC,
    currency TEXT,
    url TEXT NOT NULL UNIQUE,
    collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS watch_index_daily (
    id BIGSERIAL PRIMARY KEY,
    brand TEXT NOT NULL,
    reference_code TEXT NULL,
    index_date DATE NOT NULL,
    lot_count INTEGER NOT NULL,
    total_value NUMERIC(18,2) NOT NULL,
    avg_price NUMERIC(18,2) NOT NULL,
    median_price NUMERIC(18,2) NULL,
    demand_score NUMERIC(10,4) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE (brand, reference_code, index_date)
);


CREATE TABLE IF NOT EXISTS watch_index_brand_daily (
    id BIGSERIAL PRIMARY KEY,
    brand TEXT NOT NULL,
    index_date DATE NOT NULL,
    lot_count INTEGER NOT NULL,
    total_value NUMERIC(18,2) NOT NULL,
    avg_price NUMERIC(18,2) NOT NULL,
    median_price NUMERIC(18,2),
    unique_references INTEGER NOT NULL,
    demand_score NUMERIC(10,4) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE (brand, index_date)
);