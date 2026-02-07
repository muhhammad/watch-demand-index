-- Brands
INSERT INTO brands (brand_name) VALUES
 ('Patek Philippe'),
 ('Audemars Piguet'),
 ('Rolex'),
 ('A. Lange & Söhne');

-- Models
INSERT INTO models (brand_id, model_name)
SELECT brand_id, 'Nautilus' FROM brands WHERE brand_name='Patek Philippe';
INSERT INTO models (brand_id, model_name)
SELECT brand_id, 'Perpetual Calendar' FROM brands WHERE brand_name='Patek Philippe';

INSERT INTO models (brand_id, model_name)
SELECT brand_id, 'Royal Oak' FROM brands WHERE brand_name='Audemars Piguet';

INSERT INTO models (brand_id, model_name)
SELECT brand_id, 'Daytona' FROM brands WHERE brand_name='Rolex';
INSERT INTO models (brand_id, model_name)
SELECT brand_id, 'GMT-Master II' FROM brands WHERE brand_name='Rolex';

INSERT INTO models (brand_id, model_name)
SELECT brand_id, 'Lange 1' FROM brands WHERE brand_name='A. Lange & Söhne';
INSERT INTO models (brand_id, model_name)
SELECT brand_id, 'Datograph' FROM brands WHERE brand_name='A. Lange & Söhne';

-- Watch References
INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT model_id, '5711/1A', 'Steel', 34400 FROM models WHERE model_name='Nautilus';

INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT model_id, '5980/1A', 'Steel', 60500 FROM models WHERE model_name='Nautilus';

INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT model_id, '5270P', 'Platinum', 176000 FROM models WHERE model_name='Perpetual Calendar';

INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT model_id, '5208P', 'Platinum', 950000 FROM models WHERE model_name='Perpetual Calendar';

INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT model_id, '15202ST', 'Steel', 30000 FROM models WHERE model_name='Royal Oak';

INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT model_id, '26574ST', 'Steel', 55000 FROM models WHERE model_name='Royal Oak';

INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT model_id, '26331ST', 'Steel', 38000 FROM models WHERE model_name='Royal Oak';

INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT model_id, '116500LN Panda', 'Steel', 14500 FROM models WHERE model_name='Daytona';

INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT model_id, '116506', 'Platinum', 75000 FROM models WHERE model_name='Daytona';

INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT model_id, '116719BLRO', 'White Gold', 40000 FROM models WHERE model_name='GMT-Master II';

INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT model_id, 'Time Zone', 'White Gold', 89000 FROM models WHERE model_name='Lange 1';

INSERT INTO watch_references (model_id, reference_code, material, msrp)
SELECT model_id, '403.035', 'Platinum', 90000 FROM models WHERE model_name='Datograph';
