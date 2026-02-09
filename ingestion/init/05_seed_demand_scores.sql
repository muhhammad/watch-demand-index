-- 05_seed_demand_scores.sql

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
    '2026-02-05',
    r.reference_id,
    v.score,
    v.exit_conf,
    v.exit_min,
    v.exit_max,
    v.risk_band,
    v.depth
FROM watch_references r
JOIN (VALUES
    ('116500LN', 80, 'High', 16, 28, 'Medium', 'Deep'),
    ('116506', 75, 'High', 16, 28, 'High', 'Deep'),
    ('116719BLRO', 75, 'Medium', 23, 35, 'High', 'Deep'),
    ('5711/1A', 71, 'Medium', 23, 35, 'Medium', 'Moderate'),
    ('5712/1A-001', 71, 'High', 20, 32, 'Medium', 'Moderate'),
    ('5270P', 71, 'High', 20, 32, 'Low', 'Moderate'),
    ('15202ST', 42, 'Medium', 32, 44, 'High', 'Thin'),
    ('26574ST', 47, 'Medium', 32, 44, 'High', 'Thin'),
    ('LSLS1A', 80, 'High', 16, 28, 'High', 'Deep'),
    ('403.035', 71, 'High', 20, 32, 'Low', 'Moderate')
) v(reference_code, score, exit_conf, exit_min, exit_max, risk_band, depth)
ON r.reference_code = v.reference_code
ON CONFLICT DO NOTHING;
