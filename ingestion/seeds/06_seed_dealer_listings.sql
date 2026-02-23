INSERT INTO dealer_listings
(
    source,
    seller,
    location,
    brand,
    model,
    reference,
    price,
    currency,
    condition,
    created_at
)

SELECT
    'WatchSouq',

    'Dealer_' || FLOOR(RANDOM()*1000),

    'Hong Kong',

    mp.brand,
    mp.model,
    mp.reference,

    ROUND(
        (mp.median_price * (0.75 + RANDOM()*0.15))::numeric,
        0
    )::numeric AS price,

    'CHF',

    'Very Good',

    NOW()

FROM market_prices mp

WHERE mp.median_price IS NOT NULL

LIMIT 100;