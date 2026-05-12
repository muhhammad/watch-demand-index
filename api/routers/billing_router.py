"""
Stripe billing router.

Endpoints:
  POST /billing/checkout   — create a Stripe Checkout Session (returns redirect URL)
  POST /billing/portal     — create a Stripe Customer Portal session
  GET  /billing/status     — current subscription status for the tenant
  POST /billing/webhook    — Stripe webhook (updates plan_tier on subscription events)

Required env vars:
  STRIPE_SECRET_KEY        — sk_live_... or sk_test_...
  STRIPE_WEBHOOK_SECRET    — whsec_... (from Stripe dashboard / stripe listen)
  STRIPE_PRICE_STARTER     — price_... for starter plan
  STRIPE_PRICE_PRO         — price_... for pro plan
  APP_BASE_URL             — e.g. https://app.watchdemandindex.com (no trailing slash)
"""
import logging
import os

import stripe
from fastapi import APIRouter, Depends, Header, HTTPException, Request
from pydantic import BaseModel

from api.auth import CurrentUser, get_current_user
from api.db import get_conn

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/billing", tags=["Billing"])

stripe.api_key = os.getenv("STRIPE_SECRET_KEY", "")
_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "")
_BASE_URL = os.getenv("APP_BASE_URL", "http://localhost:5173")

_PRICE_MAP = {
    "starter": os.getenv("STRIPE_PRICE_STARTER", ""),
    "pro":     os.getenv("STRIPE_PRICE_PRO", ""),
}
_PLAN_FROM_PRICE: dict[str, str] = {v: k for k, v in _PRICE_MAP.items() if v}


class CheckoutRequest(BaseModel):
    plan: str


def _get_or_create_customer(tenant_id: str, email: str) -> str:
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT stripe_customer_id FROM tenants WHERE tenant_id = %s", (tenant_id,))
            row = cur.fetchone()
    finally:
        conn.close()

    if row and row[0]:
        return row[0]

    customer = stripe.Customer.create(email=email, metadata={"tenant_id": tenant_id})
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE tenants SET stripe_customer_id = %s WHERE tenant_id = %s",
                (customer.id, tenant_id),
            )
            conn.commit()
    finally:
        conn.close()
    return customer.id


def _sync_subscription(subscription: stripe.Subscription) -> None:
    customer_id = subscription.customer if isinstance(subscription.customer, str) else subscription.customer.id
    price_id = subscription.items.data[0].price.id if subscription.items.data else None
    plan_tier = _PLAN_FROM_PRICE.get(price_id, "starter") if price_id else "starter"
    period_end = subscription.current_period_end

    status_map = {
        "active": "active", "trialing": "active", "past_due": "active",
        "canceled": "active", "unpaid": "suspended", "incomplete_expired": "suspended",
    }
    tenant_status = status_map.get(subscription.status, "active")

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                UPDATE tenants
                SET plan_tier              = %s,
                    status                 = %s,
                    stripe_subscription_id = %s,
                    stripe_price_id        = %s,
                    current_period_end     = to_timestamp(%s)
                WHERE stripe_customer_id   = %s
                """,
                (plan_tier, tenant_status, subscription.id, price_id, period_end, customer_id),
            )
            conn.commit()
    finally:
        conn.close()
    logger.info("Synced subscription %s → plan=%s status=%s", subscription.id, plan_tier, tenant_status)


@router.post("/checkout")
def create_checkout(body: CheckoutRequest, user: CurrentUser = Depends(get_current_user)):
    if body.plan not in _PRICE_MAP:
        raise HTTPException(400, f"Unknown plan '{body.plan}'. Choose: {list(_PRICE_MAP)}")
    price_id = _PRICE_MAP[body.plan]
    if not price_id:
        raise HTTPException(503, f"Stripe price ID for '{body.plan}' not configured")
    if not stripe.api_key:
        raise HTTPException(503, "Stripe not configured")

    customer_id = _get_or_create_customer(user.tenant_id, user.email)
    session = stripe.checkout.Session.create(
        customer=customer_id,
        payment_method_types=["card"],
        line_items=[{"price": price_id, "quantity": 1}],
        mode="subscription",
        success_url=f"{_BASE_URL}/billing/success?session_id={{CHECKOUT_SESSION_ID}}",
        cancel_url=f"{_BASE_URL}/settings",
        metadata={"tenant_id": user.tenant_id},
    )
    return {"checkout_url": session.url}


@router.post("/portal")
def create_portal(user: CurrentUser = Depends(get_current_user)):
    if not stripe.api_key:
        raise HTTPException(503, "Stripe not configured")

    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT stripe_customer_id FROM tenants WHERE tenant_id = %s", (user.tenant_id,))
            row = cur.fetchone()
    finally:
        conn.close()

    if not row or not row[0]:
        raise HTTPException(404, "No billing account found. Complete a checkout first.")

    session = stripe.billing_portal.Session.create(
        customer=row[0],
        return_url=f"{_BASE_URL}/settings",
    )
    return {"portal_url": session.url}


@router.get("/status")
def billing_status(user: CurrentUser = Depends(get_current_user)):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT plan_tier, status, stripe_subscription_id, current_period_end "
                "FROM tenants WHERE tenant_id = %s",
                (user.tenant_id,),
            )
            row = cur.fetchone()
    finally:
        conn.close()

    if not row:
        raise HTTPException(404, "Tenant not found")

    return {
        "plan":                   str(row[0]),
        "status":                 str(row[1]),
        "stripe_subscription_id": row[2],
        "current_period_end":     str(row[3]) if row[3] else None,
    }


@router.post("/webhook")
async def stripe_webhook(request: Request, stripe_signature: str = Header(None)):
    if not _WEBHOOK_SECRET:
        raise HTTPException(503, "Webhook secret not configured")

    payload = await request.body()

    try:
        event = stripe.Webhook.construct_event(payload, stripe_signature, _WEBHOOK_SECRET)
    except stripe.error.SignatureVerificationError:
        raise HTTPException(400, "Invalid Stripe signature")
    except Exception as exc:
        raise HTTPException(400, f"Webhook error: {exc}")

    event_type = event["type"]
    logger.info("Stripe webhook: %s", event_type)

    obj = event.get("data", {}).get("object", {})
    customer_id = obj.get("customer") if isinstance(obj, dict) else getattr(obj, "customer", None)
    if customer_id and not isinstance(customer_id, str):
        customer_id = getattr(customer_id, "id", None)

    tenant_id = None
    if customer_id:
        conn = get_conn()
        try:
            with conn.cursor() as cur:
                cur.execute("SELECT tenant_id FROM tenants WHERE stripe_customer_id = %s", (customer_id,))
                row = cur.fetchone()
                if row:
                    tenant_id = str(row[0])
        finally:
            conn.close()

    try:
        conn = get_conn()
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO billing_events(stripe_event_id, tenant_id, event_type, payload) "
                "VALUES (%s, %s, %s, %s) ON CONFLICT (stripe_event_id) DO NOTHING",
                (event["id"], tenant_id, event_type, str(event)),
            )
            conn.commit()
        conn.close()
    except Exception as exc:
        logger.warning("Failed to persist billing event: %s", exc)

    if event_type in (
        "customer.subscription.created",
        "customer.subscription.updated",
        "customer.subscription.deleted",
        "customer.subscription.trial_will_end",
    ):
        _sync_subscription(event["data"]["object"])

    return {"received": True}
