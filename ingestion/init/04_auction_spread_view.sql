CREATE OR REPLACE VIEW auction_vs_retail_spread AS

WITH latest_snapshot AS (
    SELECT MAX(snapshot_date) AS snapshot_date
    FROM listings_daily
),

latest_retail AS (
    SELECT
        l.reference_id,
        l.avg_price,
        l.snapshot_date
    FROM listings_daily l
    JOIN latest_snapshot s
        ON l.snapshot_date = s.snapshot_date
)

SELECT
    r.reference_code,
    b.brand_name,
    AVG(a.hammer_price) AS avg_auction_price,
    lr.avg_price AS avg_retail_price,

    ROUND(
        (lr.avg_price - AVG(a.hammer_price))
        / NULLIF(AVG(a.hammer_price), 0)
        * 100,
        2
    ) AS spread_percent

FROM auction_lots a
JOIN watch_references r
    ON r.reference_code = a.reference_code
JOIN models m
    ON r.model_id = m.model_id
JOIN brands b
    ON m.brand_id = b.brand_id
JOIN latest_retail lr
    ON lr.reference_id = r.reference_id

WHERE a.hammer_price IS NOT NULL

GROUP BY
    r.reference_code,
    b.brand_name,
    lr.avg_price;