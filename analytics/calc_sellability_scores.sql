WITH latest AS (
  SELECT DISTINCT ON (reference_id)
    reference_id,
    snapshot_date,
    avg_price,
    min_price,
    listing_count,
    avg_days_on_market
  FROM listings_daily
  ORDER BY reference_id, snapshot_date DESC
),

base AS (
  SELECT
    l.*,
    b.brand_name
  FROM latest l
  JOIN watch_references r ON l.reference_id = r.reference_id
  JOIN models m ON r.model_id = m.model_id
  JOIN brands b ON m.brand_id = b.brand_id
)

INSERT INTO demand_scores (
  snapshot_date,
  reference_id,
  sellability_score,
  exit_confidence,
  expected_exit_min,
  expected_exit_max,
  price_risk_band,
  market_depth
)
SELECT
  snapshot_date,
  reference_id,

  -- Sellability Score
  LEAST(100,
    -- Depth
    CASE
      WHEN listing_count >= 50 THEN 30
      WHEN listing_count >= 30 THEN 25
      WHEN listing_count >= 15 THEN 18
      WHEN listing_count >= 5 THEN 10
      ELSE 5
    END +

    -- Velocity
    CASE
      WHEN avg_days_on_market <= 20 THEN 40
      WHEN avg_days_on_market <= 30 THEN 30
      WHEN avg_days_on_market <= 40 THEN 20
      WHEN avg_days_on_market <= 50 THEN 10
      ELSE 5
    END +

    -- Price pressure
    CASE
      WHEN min_price / avg_price >= 0.92 THEN 20
      WHEN min_price / avg_price >= 0.88 THEN 15
      WHEN min_price / avg_price >= 0.84 THEN 10
      ELSE 5
    END +

    -- Brand bonus
    CASE
      WHEN brand_name = 'Rolex' THEN 10
      WHEN brand_name = 'Patek Philippe' THEN 8
      WHEN brand_name = 'Audemars Piguet' THEN 7
      WHEN brand_name = 'A. Lange & Söhne' THEN 4
      ELSE 0
    END
  ) AS sellability_score,

  -- Exit confidence
  CASE
    WHEN avg_days_on_market <= 25 THEN 'High'
    WHEN avg_days_on_market <= 40 THEN 'Medium'
    ELSE 'Low'
  END,

  -- Expected exit window
  GREATEST(7, avg_days_on_market - 5),
  avg_days_on_market + 7,

  -- Risk band
  CASE
    WHEN min_price / avg_price >= 0.9 THEN 'Low'
    WHEN min_price / avg_price >= 0.85 THEN 'Medium'
    ELSE 'High'
  END,

  -- Market depth label
  CASE
    WHEN listing_count >= 40 THEN 'Deep'
    WHEN listing_count >= 15 THEN 'Moderate'
    ELSE 'Thin'
  END

FROM base;
