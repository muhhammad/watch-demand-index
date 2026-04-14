"""
Tenant watchlist router.

Endpoints:
  GET    /watchlist          — list all saved watches for the tenant
  POST   /watchlist          — add a watch reference
  PATCH  /watchlist/{id}     — update notes or alert toggle
  DELETE /watchlist/{id}     — remove a watch from the list
"""
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from api.auth import CurrentUser, get_current_user
from api.db import get_conn

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/watchlist", tags=["Watchlist"])


class WatchlistAdd(BaseModel):
    reference_code: str = Field(..., min_length=1, max_length=64)
    brand: Optional[str] = Field(None, max_length=64)
    notes: Optional[str] = Field(None, max_length=500)
    alert_enabled: bool = True


class WatchlistUpdate(BaseModel):
    notes: Optional[str] = Field(None, max_length=500)
    alert_enabled: Optional[bool] = None


def _row_to_dict(row) -> dict:
    return {
        "item_id":        str(row[0]),
        "reference_code": row[1],
        "brand":          row[2],
        "notes":          row[3],
        "alert_enabled":  row[4],
        "created_at":     str(row[5]),
    }


@router.get("")
def list_watchlist(user: CurrentUser = Depends(get_current_user)):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT item_id, reference_code, brand, notes, alert_enabled, created_at "
                "FROM watchlist_items WHERE tenant_id = %s ORDER BY created_at DESC",
                (user.tenant_id,),
            )
            rows = cur.fetchall()
    finally:
        conn.close()
    return [_row_to_dict(r) for r in rows]


@router.post("", status_code=201)
def add_to_watchlist(body: WatchlistAdd, user: CurrentUser = Depends(get_current_user)):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO watchlist_items(tenant_id, reference_code, brand, notes, alert_enabled)
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (tenant_id, reference_code) DO NOTHING
                RETURNING item_id, reference_code, brand, notes, alert_enabled, created_at
                """,
                (user.tenant_id, body.reference_code, body.brand, body.notes, body.alert_enabled),
            )
            row = cur.fetchone()
            conn.commit()
    except Exception as exc:
        conn.rollback()
        conn.close()
        raise HTTPException(500, f"Database error: {exc}")
    finally:
        conn.close()

    if not row:
        raise HTTPException(409, f"Reference '{body.reference_code}' is already on your watchlist")
    return _row_to_dict(row)


@router.patch("/{item_id}")
def update_watchlist_item(item_id: str, body: WatchlistUpdate, user: CurrentUser = Depends(get_current_user)):
    fields, values = [], []
    if body.notes is not None:
        fields.append("notes = %s"); values.append(body.notes)
    if body.alert_enabled is not None:
        fields.append("alert_enabled = %s"); values.append(body.alert_enabled)

    if not fields:
        raise HTTPException(400, "No fields to update")

    values += [item_id, user.tenant_id]
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                f"UPDATE watchlist_items SET {', '.join(fields)} "
                f"WHERE item_id = %s AND tenant_id = %s "
                f"RETURNING item_id, reference_code, brand, notes, alert_enabled, created_at",
                values,
            )
            row = cur.fetchone()
            conn.commit()
    finally:
        conn.close()

    if not row:
        raise HTTPException(404, "Watchlist item not found")
    return _row_to_dict(row)


@router.delete("/{item_id}", status_code=204)
def remove_from_watchlist(item_id: str, user: CurrentUser = Depends(get_current_user)):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "DELETE FROM watchlist_items WHERE item_id = %s AND tenant_id = %s RETURNING item_id",
                (item_id, user.tenant_id),
            )
            row = cur.fetchone()
            conn.commit()
    finally:
        conn.close()

    if not row:
        raise HTTPException(404, "Watchlist item not found")
