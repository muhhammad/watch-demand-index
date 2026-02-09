-- 03_seed_watch_references.sql

INSERT INTO watch_references (model_id, reference_code)
SELECT m.model_id, v.reference_code
FROM models m
JOIN brands b ON m.brand_id = b.brand_id
JOIN (VALUES
    ('Rolex', 'Daytona', '116500LN'),
    ('Rolex', 'Daytona', '116506'),
    ('Rolex', 'GMT-Master II', '116719BLRO'),
    ('Patek Philippe', 'Nautilus', '5711/1A'),
    ('Patek Philippe', 'Nautilus', '5712/1A-001'),
    ('Patek Philippe', 'Perpetual Calendar', '5270P'),
    ('Audemars Piguet', 'Royal Oak', '15202ST'),
    ('Audemars Piguet', 'Royal Oak', '26574ST'),
    ('A. Lange & Söhne', 'Lange 1', 'LSLS1A'),
    ('A. Lange & Söhne', 'Datograph', '403.035')
) v(brand_name, model_name, reference_code)
ON b.brand_name = v.brand_name
AND m.model_name = v.model_name
ON CONFLICT DO NOTHING;
