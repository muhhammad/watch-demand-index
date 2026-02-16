CREATE INDEX idx_auction_house ON auction_lots(auction_house);

CREATE INDEX idx_brand ON auction_lots(brand);

CREATE INDEX idx_reference_code ON auction_lots(reference_code);

CREATE INDEX idx_auction_date ON auction_lots(auction_date);

CREATE INDEX idx_brand_reference ON auction_lots(brand, reference_code);