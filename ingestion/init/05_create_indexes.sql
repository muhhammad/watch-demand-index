-- -----------------------------
-- Performance indexes
-- -----------------------------

CREATE INDEX IF NOT EXISTS idx_brand_reference
    ON auction_lots(brand, reference_code);

CREATE INDEX IF NOT EXISTS idx_auction_brand
    ON auction_lots(brand);

CREATE INDEX IF NOT EXISTS idx_auction_date
    ON auction_lots(auction_date DESC);

CREATE INDEX IF NOT EXISTS idx_auction_house
    ON auction_lots(auction_house);

CREATE INDEX IF NOT EXISTS idx_auction_created_at
    ON auction_lots(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_auction_reference
    ON auction_lots(reference_code);

CREATE INDEX IF NOT EXISTS idx_listings_reference_date
    ON listings_daily (reference_id, snapshot_date);

CREATE INDEX IF NOT EXISTS idx_demand_scores_reference_date
    ON demand_scores (reference_id, snapshot_date);

CREATE INDEX IF NOT EXISTS idx_demand_scores_sellability
    ON demand_scores (sellability_score DESC);

CREATE INDEX IF NOT EXISTS idx_market_brand
    ON market_listings(brand);

CREATE INDEX IF NOT EXISTS idx_market_reference
    ON market_listings(reference_code);

CREATE INDEX IF NOT EXISTS idx_market_price
    ON market_listings(price);