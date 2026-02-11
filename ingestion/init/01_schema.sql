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


-- -----------------------------
-- Performance indexes
-- -----------------------------
CREATE INDEX idx_listings_reference_date
    ON listings_daily (reference_id, snapshot_date);

CREATE INDEX idx_demand_scores_reference_date
    ON demand_scores (reference_id, snapshot_date);

CREATE INDEX idx_demand_scores_sellability
    ON demand_scores (sellability_score DESC);