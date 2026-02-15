-- =========================================================
-- Seed watch references
-- =========================================================

INSERT INTO watch_references (model_id, reference_code)
SELECT m.model_id, r.reference_code
FROM models m
JOIN brands b ON b.brand_id = m.brand_id
JOIN (
    VALUES
        ('Rolex', 'Daytona', '116500LN'),
        ('Rolex', 'Daytona', '116506'),
        ('Rolex', 'GMT-Master II', '116719BLRO'),

        ('Patek Philippe', 'Nautilus', '5711/1A'),
        ('Patek Philippe', 'Nautilus', '5711/1A-010'),
        ('Patek Philippe', 'Nautilus', '5712/1A-001'),
        ('Patek Philippe', 'Nautilus', '5980/1A'),

        ('Patek Philippe', 'Perpetual Calendar', '5270P'),
        ('Patek Philippe', 'Perpetual Calendar', '5208P'),

        ('Audemars Piguet', 'Royal Oak', '15202ST'),
        ('Audemars Piguet', 'Royal Oak', '16202ST.OO.1240ST.01'),
        ('Audemars Piguet', 'Royal Oak', '26574ST'),

        ('A. Lange & Söhne', 'Lange 1', 'LSLS1A'),
        ('A. Lange & Söhne', 'Lange 1', 'Time Zone'),
        ('A. Lange & Söhne', 'Datograph', '403.035')
) AS r(brand_name, model_name, reference_code)
ON b.brand_name = r.brand_name
AND m.model_name = r.model_name
ON CONFLICT DO NOTHING;