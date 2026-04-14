"""
Daily alert digest.

Sends email via Resend summarising arbitrage opportunities for each
tenant's watchlist. Run at 04:00 UTC via scheduler.

Env vars:
  RESEND_API_KEY   — re_...
  ALERT_FROM_EMAIL — e.g. alerts@watchdemandindex.com
  APP_BASE_URL     — e.g. https://app.watchdemandindex.com
"""
import logging
import os

import requests

from api.db import get_conn

logger = logging.getLogger(__name__)

_RESEND_API_KEY = os.getenv("RESEND_API_KEY", "")
_FROM_EMAIL     = os.getenv("ALERT_FROM_EMAIL", "alerts@watchdemandindex.com")
_APP_URL        = os.getenv("APP_BASE_URL", "https://app.watchdemandindex.com")


def run_alerts() -> None:
    tenants = _get_active_tenants_with_watchlists()
    logger.info("Alert run: %d tenants with watchlists", len(tenants))
    for tenant in tenants:
        try:
            _send_digest_for_tenant(tenant)
        except Exception as exc:
            logger.error("Alert failed for tenant %s: %s", tenant["tenant_id"], exc)


def _get_active_tenants_with_watchlists() -> list[dict]:
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT DISTINCT t.tenant_id, t.name AS company, u.email
                FROM tenants t
                JOIN users u ON u.tenant_id = t.tenant_id AND u.role = 'admin' AND u.is_active = TRUE
                JOIN watchlist_items w ON w.tenant_id = t.tenant_id AND w.alert_enabled = TRUE
                WHERE t.status = 'active'
                ORDER BY t.tenant_id
                """
            )
            rows = cur.fetchall()
    finally:
        conn.close()
    return [{"tenant_id": str(r[0]), "company": r[1], "email": r[2]} for r in rows]


def _get_watchlist_opportunities(tenant_id: str) -> list[dict]:
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT ao.reference, ao.brand, ao.source, ao.seller,
                       ao.dealer_price, ao.median_price, ao.absolute_profit,
                       ao.profit_percent, ao.opportunity_grade
                FROM arbitrage_opportunities ao
                JOIN watchlist_items wi
                    ON wi.tenant_id = %s AND wi.alert_enabled = TRUE
                    AND (ao.reference ILIKE wi.reference_code
                         OR ao.reference ILIKE '%%' || wi.reference_code || '%%')
                ORDER BY ao.profit_percent DESC
                LIMIT 20
                """,
                (tenant_id,),
            )
            rows = cur.fetchall()
    finally:
        conn.close()
    return [{"reference": r[0], "brand": r[1], "source": r[2], "seller": r[3],
             "dealer_price": float(r[4]), "median_price": float(r[5]),
             "absolute_profit": float(r[6]), "profit_percent": float(r[7]), "grade": r[8]}
            for r in rows]


def _send_digest_for_tenant(tenant: dict) -> None:
    opportunities = _get_watchlist_opportunities(tenant["tenant_id"])
    if not opportunities:
        logger.info("No opportunities for tenant %s — skipping digest", tenant["tenant_id"])
        return
    html = _build_email_html(tenant["company"], opportunities)
    count = len(opportunities)
    subject = f"[Watch Demand Index] {count} opportunity alert{'s' if count != 1 else ''} today"
    _send_email(to=tenant["email"], subject=subject, html=html)
    _log_alert_sent(tenant["tenant_id"], count, tenant["email"])
    logger.info("Digest sent to %s (%d opportunities)", tenant["email"], count)


def _build_email_html(company: str, opportunities: list[dict]) -> str:
    rows_html = ""
    for o in opportunities:
        colour = {"A": "#16a34a", "B": "#ca8a04", "C": "#dc2626"}.get(o["grade"], "#64748b")
        rows_html += f"""
        <tr>
          <td style="padding:8px 12px;border-bottom:1px solid #e2e8f0">{o['brand']}</td>
          <td style="padding:8px 12px;border-bottom:1px solid #e2e8f0">{o['reference']}</td>
          <td style="padding:8px 12px;border-bottom:1px solid #e2e8f0">{o['source']}</td>
          <td style="padding:8px 12px;border-bottom:1px solid #e2e8f0">CHF {o['dealer_price']:,.0f}</td>
          <td style="padding:8px 12px;border-bottom:1px solid #e2e8f0">CHF {o['absolute_profit']:,.0f} (+{o['profit_percent']:.1f}%)</td>
          <td style="padding:8px 12px;border-bottom:1px solid #e2e8f0;font-weight:700;color:{colour}">{o['grade']}</td>
        </tr>"""
    return f"""<!DOCTYPE html><html><head><meta charset="utf-8"></head>
<body style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;color:#1e293b;max-width:700px;margin:0 auto;padding:24px">
  <div style="background:#0f172a;padding:20px 24px;border-radius:8px 8px 0 0">
    <h1 style="color:#f8fafc;margin:0;font-size:20px">Watch Demand Index</h1>
    <p style="color:#94a3b8;margin:4px 0 0">Daily Opportunity Digest</p>
  </div>
  <div style="background:#f8fafc;padding:20px 24px;border:1px solid #e2e8f0;border-top:none">
    <p>Hi {company},</p>
    <p>Here are today's arbitrage opportunities matching your watchlist:</p>
    <table style="width:100%;border-collapse:collapse;background:#fff;border-radius:6px;border:1px solid #e2e8f0">
      <thead><tr style="background:#1e293b;color:#f8fafc">
        <th style="padding:10px 12px;text-align:left">Brand</th>
        <th style="padding:10px 12px;text-align:left">Reference</th>
        <th style="padding:10px 12px;text-align:left">Source</th>
        <th style="padding:10px 12px;text-align:left">Listed At</th>
        <th style="padding:10px 12px;text-align:left">Profit</th>
        <th style="padding:10px 12px;text-align:left">Grade</th>
      </tr></thead>
      <tbody>{rows_html}</tbody>
    </table>
    <p style="margin-top:20px">
      <a href="{_APP_URL}" style="background:#0f172a;color:#f8fafc;padding:10px 20px;border-radius:6px;text-decoration:none;font-weight:600">View Full Dashboard →</a>
    </p>
    <hr style="border:none;border-top:1px solid #e2e8f0;margin:20px 0">
    <p style="font-size:12px;color:#94a3b8">
      You're receiving this because you have alerts enabled on your watchlist.
      <a href="{_APP_URL}/settings" style="color:#94a3b8">Manage alerts</a>
    </p>
  </div>
</body></html>"""


def _send_email(to: str, subject: str, html: str) -> None:
    if not _RESEND_API_KEY:
        logger.warning("RESEND_API_KEY not set — email not sent to %s", to)
        return
    resp = requests.post(
        "https://api.resend.com/emails",
        headers={"Authorization": f"Bearer {_RESEND_API_KEY}", "Content-Type": "application/json"},
        json={"from": _FROM_EMAIL, "to": [to], "subject": subject, "html": html},
        timeout=15,
    )
    if resp.status_code not in (200, 201):
        raise RuntimeError(f"Resend API error {resp.status_code}: {resp.text}")


def _log_alert_sent(tenant_id: str, item_count: int, recipient: str) -> None:
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO alert_log(tenant_id, alert_type, item_count, recipient) VALUES (%s, %s, %s, %s)",
                (tenant_id, "daily_digest", item_count, recipient),
            )
            conn.commit()
    except Exception as exc:
        logger.warning("Failed to log alert: %s", exc)
    finally:
        conn.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s: %(message)s")
    run_alerts()
