"""
Non-destructive database bootstrap for hosted environments.

Railway/Postgres deployments do not run the local Docker init scripts, so we
create the minimal schema needed for auth and empty-state dashboard access at
application startup.
"""
from api.db import get_conn


BOOTSTRAP_STATEMENTS = [
    """
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
    """,
    """
    DO $$ BEGIN CREATE TYPE plan_tier AS ENUM ('starter','pro','enterprise'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    DO $$ BEGIN CREATE TYPE user_role AS ENUM ('admin','analyst','dealer'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    DO $$ BEGIN CREATE TYPE tenant_status AS ENUM ('active','suspended','cancelled'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    """,
    """
    CREATE TABLE IF NOT EXISTS tenants (
        tenant_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name TEXT NOT NULL UNIQUE,
        plan_tier plan_tier NOT NULL DEFAULT 'starter',
        status tenant_status NOT NULL DEFAULT 'active',
        allowed_origins TEXT[],
        stripe_customer_id TEXT,
        stripe_subscription_id TEXT UNIQUE,
        stripe_price_id TEXT,
        current_period_end TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS users (
        user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id UUID NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
        email TEXT NOT NULL UNIQUE,
        hashed_password TEXT NOT NULL,
        role user_role NOT NULL DEFAULT 'dealer',
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        last_login_at TIMESTAMPTZ
    );

    CREATE TABLE IF NOT EXISTS api_keys (
        key_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id UUID NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
        user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
        key_hash TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        is_active BOOLEAN NOT NULL DEFAULT TRUE,
        last_used_at TIMESTAMPTZ,
        expires_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS refresh_tokens (
        token_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
        token_hash TEXT NOT NULL UNIQUE,
        expires_at TIMESTAMPTZ NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE OR REPLACE FUNCTION update_updated_at_column() RETURNS TRIGGER AS $$
    BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;

    DROP TRIGGER IF EXISTS set_tenants_updated_at ON tenants;
    CREATE TRIGGER set_tenants_updated_at BEFORE UPDATE ON tenants
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    """,
    """
    CREATE TABLE IF NOT EXISTS brands (
        brand_id SERIAL PRIMARY KEY,
        brand_name TEXT NOT NULL UNIQUE
    );

    CREATE TABLE IF NOT EXISTS models (
        model_id SERIAL PRIMARY KEY,
        brand_id INT NOT NULL REFERENCES brands(brand_id),
        model_name TEXT NOT NULL,
        UNIQUE (brand_id, model_name)
    );

    CREATE TABLE IF NOT EXISTS watch_references (
        reference_id SERIAL PRIMARY KEY,
        model_id INT NOT NULL REFERENCES models(model_id),
        reference_code TEXT NOT NULL UNIQUE
    );

    CREATE TABLE IF NOT EXISTS listings_daily (
        snapshot_date DATE NOT NULL,
        reference_id INT NOT NULL REFERENCES watch_references(reference_id),
        avg_price NUMERIC NOT NULL,
        min_price NUMERIC NOT NULL,
        listing_count INT NOT NULL,
        avg_days_on_market INT,
        PRIMARY KEY (snapshot_date, reference_id)
    );

    CREATE TABLE IF NOT EXISTS demand_scores (
        snapshot_date DATE NOT NULL,
        reference_id INT NOT NULL REFERENCES watch_references(reference_id),
        sellability_score INT NOT NULL CHECK (sellability_score BETWEEN 0 AND 100),
        exit_confidence TEXT NOT NULL CHECK (exit_confidence IN ('High', 'Medium', 'Low')),
        expected_exit_min INT NOT NULL,
        expected_exit_max INT NOT NULL,
        price_risk_band TEXT NOT NULL CHECK (price_risk_band IN ('Low', 'Medium', 'High')),
        market_depth TEXT NOT NULL CHECK (market_depth IN ('Thin', 'Moderate', 'Deep')),
        PRIMARY KEY (snapshot_date, reference_id)
    );

    CREATE TABLE IF NOT EXISTS market_listings (
        id SERIAL PRIMARY KEY,
        source TEXT NOT NULL,
        brand TEXT,
        model TEXT,
        reference_code TEXT,
        price NUMERIC,
        currency TEXT,
        url TEXT NOT NULL UNIQUE,
        collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS watch_index_daily (
        id BIGSERIAL PRIMARY KEY,
        brand TEXT NOT NULL,
        reference_code TEXT NULL,
        index_date DATE NOT NULL,
        lot_count INTEGER NOT NULL,
        total_value NUMERIC(18,2) NOT NULL,
        avg_price NUMERIC(18,2) NOT NULL,
        median_price NUMERIC(18,2) NULL,
        demand_score NUMERIC(10,4) NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE (brand, reference_code, index_date)
    );

    CREATE TABLE IF NOT EXISTS watch_index_brand_daily (
        id BIGSERIAL PRIMARY KEY,
        brand TEXT NOT NULL,
        index_date DATE NOT NULL,
        lot_count INTEGER NOT NULL,
        total_value NUMERIC(18,2) NOT NULL,
        avg_price NUMERIC(18,2) NOT NULL,
        median_price NUMERIC(18,2),
        unique_references INTEGER NOT NULL,
        demand_score NUMERIC(10,4) NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        UNIQUE (brand, index_date)
    );

    CREATE TABLE IF NOT EXISTS watch_index_market_daily (
        id BIGSERIAL PRIMARY KEY,
        index_date DATE NOT NULL UNIQUE,
        lot_count INTEGER NOT NULL,
        total_value NUMERIC(18,2) NOT NULL,
        avg_price NUMERIC(18,2) NOT NULL,
        median_price NUMERIC(18,2),
        unique_brands INTEGER NOT NULL,
        unique_references INTEGER NOT NULL,
        demand_score NUMERIC(12,4) NOT NULL,
        created_at TIMESTAMPTZ DEFAULT NOW()
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS auction_lots (
        id BIGSERIAL PRIMARY KEY,
        auction_house TEXT NOT NULL,
        auction_id TEXT NOT NULL,
        lot INTEGER NOT NULL,
        brand TEXT NOT NULL,
        reference_code TEXT,
        model TEXT,
        price NUMERIC,
        currency TEXT NOT NULL DEFAULT 'CHF',
        url TEXT NOT NULL,
        image_url TEXT,
        auction_date DATE NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        CONSTRAINT unique_url UNIQUE (url),
        CONSTRAINT unique_auction_lot UNIQUE (auction_house, auction_id, lot)
    );

    CREATE TABLE IF NOT EXISTS dealer_listings (
        id SERIAL PRIMARY KEY,
        source TEXT NOT NULL,
        source_priority INTEGER,
        seller TEXT,
        location TEXT,
        brand TEXT NOT NULL,
        model TEXT,
        reference TEXT,
        price NUMERIC NOT NULL,
        currency TEXT DEFAULT 'USD',
        condition TEXT,
        created_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS market_prices (
        reference TEXT PRIMARY KEY,
        brand TEXT,
        model TEXT,
        avg_price NUMERIC,
        median_price NUMERIC,
        low_price NUMERIC,
        high_price NUMERIC,
        updated_at TIMESTAMP DEFAULT NOW()
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS watchlist_items (
        item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id UUID NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
        brand TEXT,
        reference_code TEXT NOT NULL,
        notes TEXT,
        alert_enabled BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS alert_log (
        log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id UUID NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
        alert_type TEXT NOT NULL,
        sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        item_count INT,
        recipient TEXT
    );

    CREATE TABLE IF NOT EXISTS billing_events (
        event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        stripe_event_id TEXT UNIQUE NOT NULL,
        tenant_id UUID REFERENCES tenants(tenant_id),
        event_type TEXT NOT NULL,
        payload JSONB,
        processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
    """,
    """
    CREATE INDEX IF NOT EXISTS idx_users_tenant ON users(tenant_id);
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
    CREATE INDEX IF NOT EXISTS idx_api_keys_tenant ON api_keys(tenant_id);
    CREATE INDEX IF NOT EXISTS idx_api_keys_hash ON api_keys(key_hash);
    CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);
    CREATE INDEX IF NOT EXISTS idx_refresh_tokens_hash ON refresh_tokens(token_hash);
    CREATE INDEX IF NOT EXISTS idx_watchlist_tenant ON watchlist_items(tenant_id);
    CREATE UNIQUE INDEX IF NOT EXISTS uq_watchlist_ref ON watchlist_items(tenant_id, reference_code);
    CREATE INDEX IF NOT EXISTS idx_alert_log_tenant ON alert_log(tenant_id, sent_at DESC);
    CREATE INDEX IF NOT EXISTS idx_billing_events_tenant ON billing_events(tenant_id, processed_at DESC);
    CREATE INDEX IF NOT EXISTS idx_brand_reference ON auction_lots(brand, reference_code);
    CREATE INDEX IF NOT EXISTS idx_auction_brand ON auction_lots(brand);
    CREATE INDEX IF NOT EXISTS idx_auction_date ON auction_lots(auction_date DESC);
    CREATE INDEX IF NOT EXISTS idx_auction_house ON auction_lots(auction_house);
    CREATE INDEX IF NOT EXISTS idx_auction_created_at ON auction_lots(created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_auction_reference ON auction_lots(reference_code);
    CREATE INDEX IF NOT EXISTS idx_listings_reference_date ON listings_daily(reference_id, snapshot_date);
    CREATE INDEX IF NOT EXISTS idx_demand_scores_reference_date ON demand_scores(reference_id, snapshot_date);
    CREATE INDEX IF NOT EXISTS idx_demand_scores_sellability ON demand_scores(sellability_score DESC);
    CREATE INDEX IF NOT EXISTS idx_market_brand ON market_listings(brand);
    CREATE INDEX IF NOT EXISTS idx_market_reference ON market_listings(reference_code);
    CREATE INDEX IF NOT EXISTS idx_market_price ON market_listings(price);
    CREATE INDEX IF NOT EXISTS idx_dealer_reference ON dealer_listings(reference);
    CREATE INDEX IF NOT EXISTS idx_dealer_price ON dealer_listings(price);
    """,
    """
    CREATE OR REPLACE VIEW arbitrage_opportunities AS
    SELECT
        dl.id,
        dl.source,
        dl.source_priority,
        dl.seller,
        dl.location,
        dl.brand,
        dl.model,
        dl.reference,
        dl.price AS dealer_price,
        dl.currency,
        dl.condition,
        mp.median_price,
        mp.low_price,
        mp.high_price,
        (mp.median_price - dl.price) AS absolute_profit,
        CASE
            WHEN dl.price > 0
            THEN ROUND(((mp.median_price - dl.price) / dl.price * 100)::numeric, 2)
            ELSE NULL
        END AS profit_percent,
        CASE
            WHEN dl.price > 0 AND ((mp.median_price - dl.price) / dl.price) > 0.20 THEN 'A+'
            WHEN dl.price > 0 AND ((mp.median_price - dl.price) / dl.price) > 0.15 THEN 'A'
            WHEN dl.price > 0 AND ((mp.median_price - dl.price) / dl.price) > 0.10 THEN 'B'
            WHEN dl.price > 0 AND ((mp.median_price - dl.price) / dl.price) > 0.05 THEN 'C'
            ELSE 'D'
        END AS opportunity_grade,
        dl.created_at
    FROM dealer_listings dl
    JOIN market_prices mp ON dl.reference = mp.reference
    WHERE dl.price < mp.median_price;
    """,
]


def bootstrap_database() -> None:
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            for statement in BOOTSTRAP_STATEMENTS:
                cur.execute(statement)
        conn.commit()
    finally:
        conn.close()
