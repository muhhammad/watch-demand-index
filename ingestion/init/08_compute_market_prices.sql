INSERT INTO market_prices (
    reference,
    brand,
    model,
    avg_price,
    median_price,
    low_price,
    high_price,
    updated_at
)
SELECT
    reference_code AS reference,

    MAX(brand) AS brand,
    MAX(model) AS model,

    AVG(price),
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price),
    MIN(price),
    MAX(price),

    NOW()

FROM auction_lots

WHERE reference_code IS NOT NULL
AND price IS NOT NULL

GROUP BY reference_code

ON CONFLICT (reference)
DO UPDATE SET
    avg_price = EXCLUDED.avg_price,
    median_price = EXCLUDED.median_price,
    low_price = EXCLUDED.low_price,
    high_price = EXCLUDED.high_price,
    updated_at = NOW();