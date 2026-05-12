-- Phase 3: Tenant watchlists and Stripe billing metadata
-- Run after 10_tenants_and_auth.sql

-- Stripe billing columns on tenants
ALTER TABLE tenants
    ADD COLUMN IF NOT EXISTS stripe_customer_id      TEXT UNIQUE,
    ADD COLUMN IF NOT EXISTS stripe_subscription_id  TEXT UNIQUE,
    ADD COLUMN IF NOT EXISTS stripe_price_id         TEXT,
    ADD COLUMN IF NOT EXISTS current_period_end      TIMESTAMPTZ;

-- Watchlist
CREATE TABLE IF NOT EXISTS watchlist_items (
    item_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      UUID NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    brand          TEXT,
    reference_code TEXT NOT NULL,
    notes          TEXT,
    alert_enabled  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_watchlist_tenant ON watchlist_items(tenant_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_watchlist_ref ON watchlist_items(tenant_id, reference_code);

-- Alert log
CREATE TABLE IF NOT EXISTS alert_log (
    log_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id  UUID NOT NULL REFERENCES tenants(tenant_id) ON DELETE CASCADE,
    alert_type TEXT NOT NULL,
    sent_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    item_count INT,
    recipient  TEXT
);

CREATE INDEX IF NOT EXISTS idx_alert_log_tenant ON alert_log(tenant_id, sent_at DESC);

-- Stripe billing event audit log
CREATE TABLE IF NOT EXISTS billing_events (
    event_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stripe_event_id TEXT UNIQUE NOT NULL,
    tenant_id       UUID REFERENCES tenants(tenant_id),
    event_type      TEXT NOT NULL,
    payload         JSONB,
    processed_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_billing_events_tenant ON billing_events(tenant_id, processed_at DESC);
