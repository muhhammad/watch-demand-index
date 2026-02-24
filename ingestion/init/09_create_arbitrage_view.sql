DROP VIEW IF EXISTS arbitrage_opportunities;

CREATE VIEW arbitrage_opportunities AS
SELECT
    dl.id,
    dl.source,
    dl.source_priority,
    dl.seller,
    dl.location,
    dl.brand,
    dl.model,
    dl.reference,
    dl.price AS dealer_price,
    dl.currency,
    dl.condition,
    
    mp.median_price,
    mp.low_price,
    mp.high_price,

    (mp.median_price - dl.price) AS absolute_profit,

    CASE
        WHEN dl.price > 0
        THEN ROUND(
            ((mp.median_price - dl.price) / dl.price * 100)::numeric,
            2
        )
        ELSE NULL
    END AS profit_percent,

    CASE
        WHEN ((mp.median_price - dl.price) / dl.price) > 0.20 THEN 'A+'
        WHEN ((mp.median_price - dl.price) / dl.price) > 0.15 THEN 'A'
        WHEN ((mp.median_price - dl.price) / dl.price) > 0.10 THEN 'B'
        WHEN ((mp.median_price - dl.price) / dl.price) > 0.05 THEN 'C'
        ELSE 'D'
    END AS opportunity_grade,

    dl.created_at

FROM dealer_listings dl

JOIN market_prices mp
ON dl.reference = mp.reference

WHERE dl.price < mp.median_price;