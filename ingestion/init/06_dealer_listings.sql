CREATE TABLE IF NOT EXISTS dealer_listings (

    id SERIAL PRIMARY KEY,

    source TEXT NOT NULL,
    seller TEXT,
    location TEXT,

    brand TEXT NOT NULL,
    model TEXT,
    reference TEXT,

    price NUMERIC NOT NULL,
    currency TEXT DEFAULT 'USD',

    condition TEXT,

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dealer_reference
ON dealer_listings(reference);

CREATE INDEX IF NOT EXISTS idx_dealer_price
ON dealer_listings(price);