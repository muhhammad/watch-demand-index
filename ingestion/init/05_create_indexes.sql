CREATE INDEX idx_brand_reference
ON auction_lots(brand, reference_code);

CREATE INDEX idx_reference_only
ON auction_lots(reference_code);

CREATE INDEX idx_brand_only
ON auction_lots(brand);

CREATE INDEX idx_auction_date
ON auction_lots(auction_date DESC);

CREATE INDEX idx_auction_house
ON auction_lots(auction_house);

CREATE INDEX idx_created_at
ON auction_lots(created_at DESC);