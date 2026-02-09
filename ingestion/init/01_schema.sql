-- 01_schema.sql

CREATE TABLE brands (
    brand_id SERIAL PRIMARY KEY,
    brand_name TEXT UNIQUE NOT NULL
);

CREATE TABLE models (
    model_id SERIAL PRIMARY KEY,
    brand_id INT NOT NULL REFERENCES brands(brand_id),
    model_name TEXT NOT NULL,
    UNIQUE (brand_id, model_name)
);

CREATE TABLE watch_references (
    reference_id SERIAL PRIMARY KEY,
    model_id INT NOT NULL REFERENCES models(model_id),
    reference_code TEXT NOT NULL,
    UNIQUE (model_id, reference_code)
);

CREATE TABLE listings_daily (
    snapshot_date DATE NOT NULL,
    reference_id INT NOT NULL REFERENCES watch_references(reference_id),
    avg_price NUMERIC,
    min_price NUMERIC,
    avg_days_on_market INT,
    PRIMARY KEY (snapshot_date, reference_id)
);

CREATE TABLE demand_scores (
    snapshot_date DATE NOT NULL,
    reference_id INT NOT NULL REFERENCES watch_references(reference_id),
    sellability_score INT,
    exit_confidence TEXT,
    expected_exit_min INT,
    expected_exit_max INT,
    price_risk_band TEXT,
    market_depth TEXT,
    PRIMARY KEY (snapshot_date, reference_id)
);
