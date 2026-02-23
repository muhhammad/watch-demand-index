CREATE TABLE IF NOT EXISTS market_prices (

    reference TEXT PRIMARY KEY,

    brand TEXT,
    model TEXT,

    avg_price NUMERIC,
    median_price NUMERIC,
    low_price NUMERIC,
    high_price NUMERIC,

    updated_at TIMESTAMP DEFAULT NOW()
);
