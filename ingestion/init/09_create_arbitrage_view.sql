DROP VIEW IF EXISTS arbitrage_opportunities;

CREATE VIEW arbitrage_opportunities AS
SELECT
    d.id,
    d.source,
    d.seller,
    d.location,
    d.brand,
    d.model,
    d.reference,
    d.price AS dealer_price,
    d.currency,
    d.condition,

    mp.median_price,
    mp.low_price,
    mp.high_price,

    (mp.median_price - d.price) AS absolute_profit,

    ROUND(
        ((mp.median_price - d.price) / d.price) * 100,
        2
    ) AS profit_percent,

    CASE
        WHEN ((mp.median_price - d.price) / d.price) * 100 >= 15 THEN 'STEAL'
        WHEN ((mp.median_price - d.price) / d.price) * 100 >= 10 THEN 'STRONG BUY'
        WHEN ((mp.median_price - d.price) / d.price) * 100 >= 5 THEN 'BUY'
        ELSE 'PASS'
    END AS opportunity_grade,

    d.created_at

FROM dealer_listings d

JOIN market_prices mp
ON mp.reference LIKE d.reference || '%'

WHERE mp.median_price > d.price;