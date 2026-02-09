-- 04_seed_listings_daily.sql

INSERT INTO listings_daily (
    snapshot_date,
    reference_id,
    avg_price,
    min_price,
    avg_days_on_market
)
SELECT
    '2026-02-05',
    r.reference_id,
    v.avg_price,
    v.min_price,
    v.avg_days
FROM watch_references r
JOIN (VALUES
    ('116500LN', 26000, 23500, 21),
    ('116506', 140000, 115000, 21),
    ('116719BLRO', 75000, 62000, 28),
    ('5711/1A', 120000, 110000, 30),
    ('5712/1A-001', 86000, 77000, 25),
    ('5270P', 150000, 140000, 28),
    ('15202ST', 60000, 55000, 25),
    ('26574ST', 65000, 60000, 30),
    ('LSLS1A', 119000, 98700, 35),
    ('403.035', 132000, 111000, 49)
) v(reference_code, avg_price, min_price, avg_days)
ON r.reference_code = v.reference_code
ON CONFLICT DO NOTHING;
