-- Patek Philippe
INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT m.model_id, '5711/1A-010', 'Stainless Steel', 30000
FROM models m
JOIN brands b ON b.brand_id = m.brand_id
WHERE b.brand_name = 'Patek Philippe'
  AND m.model_name = 'Nautilus';

INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT m.model_id, '5712/1A-001', 'Stainless Steel', 40000
FROM models m
JOIN brands b ON b.brand_id = m.brand_id
WHERE b.brand_name = 'Patek Philippe'
  AND m.model_name = 'Nautilus';

-- Audemars Piguet
INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT m.model_id, '16202ST.OO.1240ST.01', 'Stainless Steel', 33000
FROM models m
JOIN brands b ON b.brand_id = m.brand_id
WHERE b.brand_name = 'Audemars Piguet'
  AND m.model_name = 'Royal Oak';

-- Rolex
INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT m.model_id, '116500LN', 'Stainless Steel', 14500
FROM models m
JOIN brands b ON b.brand_id = m.brand_id
WHERE b.brand_name = 'Rolex'
  AND m.model_name = 'Daytona';

-- A. Lange & Söhne
INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT m.model_id, 'LSLS1A', 'Platinum', 85000
FROM models m
JOIN brands b ON b.brand_id = m.brand_id
WHERE b.brand_name = 'A. Lange & Söhne'
  AND m.model_name = 'Lange 1';
