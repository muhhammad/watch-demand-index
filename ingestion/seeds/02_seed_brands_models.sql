-- 02_seed_brands_models.sql

INSERT INTO brands (brand_name) VALUES
('Rolex'),
('Patek Philippe'),
('Audemars Piguet'),
('A. Lange & Söhne')
ON CONFLICT DO NOTHING;

INSERT INTO models (brand_id, model_name)
SELECT b.brand_id, v.model_name
FROM brands b
JOIN (VALUES
    ('Rolex', 'Daytona'),
    ('Rolex', 'GMT-Master II'),
    ('Patek Philippe', 'Nautilus'),
    ('Patek Philippe', 'Perpetual Calendar'),
    ('Audemars Piguet', 'Royal Oak'),
    ('A. Lange & Söhne', 'Lange 1'),
    ('A. Lange & Söhne', 'Datograph')
) v(brand_name, model_name)
ON b.brand_name = v.brand_name
ON CONFLICT DO NOTHING;
