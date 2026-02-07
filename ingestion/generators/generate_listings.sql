-- Generate synthetic market listings for last 30 days

INSERT INTO listings_daily (
  snapshot_date,
  reference_id,
  avg_price,
  min_price,
  listing_count,
  avg_days_on_market
)
SELECT
  d::date AS snapshot_date,
  r.reference_id,

  -- avg price: MSRP * market premium factor
  ROUND(
    r.msrp *
    CASE
      WHEN b.brand_name = 'Rolex' THEN 1.8
      WHEN b.brand_name = 'Patek Philippe' THEN 2.2
      WHEN b.brand_name = 'Audemars Piguet' THEN 1.9
      ELSE 1.4
    END
    * (0.95 + random() * 0.1)
  ) AS avg_price,

  -- min price: slightly discounted
  ROUND(
    r.msrp *
    CASE
      WHEN b.brand_name = 'Rolex' THEN 1.6
      WHEN b.brand_name = 'Patek Philippe' THEN 2.0
      WHEN b.brand_name = 'Audemars Piguet' THEN 1.7
      ELSE 1.2
    END
    * (0.95 + random() * 0.1)
  ) AS min_price,

  -- listing depth
  CASE
    WHEN b.brand_name = 'Rolex' THEN 40 + (random() * 30)::int
    WHEN b.brand_name = 'Patek Philippe' THEN 15 + (random() * 10)::int
    ELSE 5 + (random() * 5)::int
  END AS listing_count,

  -- days on market (lower = better)
  CASE
    WHEN b.brand_name = 'Rolex' THEN 18 + (random() * 10)::int
    WHEN b.brand_name = 'Patek Philippe' THEN 25 + (random() * 15)::int
    ELSE 35 + (random() * 20)::int
  END AS avg_days_on_market

FROM watch_references r
JOIN models m ON r.model_id = m.model_id
JOIN brands b ON m.brand_id = b.brand_id
CROSS JOIN generate_series(
  CURRENT_DATE - INTERVAL '30 days',
  CURRENT_DATE,
  INTERVAL '1 day'
) d;
