-- =========================================================
-- Compute demand scores from latest real listing data
-- =========================================================

-- 1️⃣ Identify latest snapshot
WITH latest_snapshot AS (
    SELECT MAX(snapshot_date) AS snapshot_date
    FROM listings_daily
),

-- 2️⃣ Base market signals
base AS (
    SELECT
        l.snapshot_date,
        l.reference_id,
        l.avg_price,
        l.min_price,
        l.listing_count,
        l.avg_days_on_market
    FROM listings_daily l
    JOIN latest_snapshot s
      ON l.snapshot_date = s.snapshot_date
),

-- 3️⃣ Scoring logic (transparent & tunable)
scored AS (
    SELECT
        snapshot_date,
        reference_id,

        -- -----------------------------
        -- Sellability score (0–100)
        -- -----------------------------
        LEAST(
            100,
            GREATEST(
                0,
                100
                - COALESCE(avg_days_on_market, 40)
                - CASE
                    WHEN listing_count >= 50 THEN 15
                    WHEN listing_count >= 20 THEN 8
                    WHEN listing_count >= 10 THEN 4
                    ELSE 0
                  END
            )
        )::INT AS sellability_score,

        -- -----------------------------
        -- Exit confidence
        -- -----------------------------
        CASE
            WHEN avg_days_on_market <= 20 THEN 'High'
            WHEN avg_days_on_market <= 35 THEN 'Medium'
            ELSE 'Low'
        END AS exit_confidence,

        -- -----------------------------
        -- Expected exit window (days)
        -- -----------------------------
        GREATEST(7, COALESCE(avg_days_on_market, 40) - 5) AS expected_exit_min,
        COALESCE(avg_days_on_market, 40) + 10             AS expected_exit_max,

        -- -----------------------------
        -- Price risk (crowding proxy)
        -- -----------------------------
        CASE
            WHEN listing_count >= 50 THEN 'High'
            WHEN listing_count >= 20 THEN 'Medium'
            ELSE 'Low'
        END AS price_risk_band,

        -- -----------------------------
        -- Market depth (liquidity)
        -- -----------------------------
        CASE
            WHEN listing_count >= 50 THEN 'Deep'
            WHEN listing_count >= 20 THEN 'Moderate'
            ELSE 'Thin'
        END AS market_depth

    FROM base
)

-- 4️⃣ Upsert into demand_scores
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
    sellability_score,
    exit_confidence,
    expected_exit_min,
    expected_exit_max,
    price_risk_band,
    market_depth
FROM scored
ON CONFLICT (snapshot_date, reference_id)
DO UPDATE SET
    sellability_score = EXCLUDED.sellability_score,
    exit_confidence   = EXCLUDED.exit_confidence,
    expected_exit_min = EXCLUDED.expected_exit_min,
    expected_exit_max = EXCLUDED.expected_exit_max,
    price_risk_band   = EXCLUDED.price_risk_band,
    market_depth      = EXCLUDED.market_depth;