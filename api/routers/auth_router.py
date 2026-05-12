"""
Auth endpoints: register, login, token refresh, logout, current user,
and API key management.
"""
import hashlib
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, EmailStr

from api.auth import (
    REFRESH_TOKEN_EXPIRE_DAYS, CurrentUser, create_access_token,
    create_refresh_token, generate_api_key, get_current_user,
    hash_password, verify_password,
)
from api.db import get_conn

router = APIRouter(prefix="/auth", tags=["Authentication"])


class RegisterRequest(BaseModel):
    company_name: str
    email: EmailStr
    password: str
    plan_tier: str = "starter"

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenRefreshRequest(BaseModel):
    refresh_token: str

class CreateApiKeyRequest(BaseModel):
    name: str
    expires_in_days: Optional[int] = None


@router.post("/register", status_code=201)
def register(request: Request, body: RegisterRequest):
    if body.plan_tier not in ("starter", "pro", "enterprise"):
        raise HTTPException(400, "plan_tier must be starter, pro, or enterprise")
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM users WHERE email = %s", (body.email,))
            if cur.fetchone():
                raise HTTPException(409, "Email already registered")
            cur.execute("INSERT INTO tenants (name, plan_tier) VALUES (%s, %s) RETURNING tenant_id",
                        (body.company_name, body.plan_tier))
            tenant_id = cur.fetchone()[0]
            cur.execute("INSERT INTO users (tenant_id, email, hashed_password, role) "
                        "VALUES (%s, %s, %s, 'admin') RETURNING user_id",
                        (tenant_id, body.email, hash_password(body.password)))
            user_id = cur.fetchone()[0]
        conn.commit()
    except HTTPException:
        conn.rollback(); raise
    except Exception as exc:
        conn.rollback(); raise HTTPException(500, "Registration failed") from exc
    finally:
        conn.close()
    access_token = create_access_token(str(user_id), str(tenant_id), "admin")
    raw_refresh, refresh_hash = create_refresh_token()
    _persist_refresh_token(str(user_id), refresh_hash)
    return {"access_token": access_token, "refresh_token": raw_refresh,
            "token_type": "bearer", "user_id": str(user_id), "tenant_id": str(tenant_id)}


@router.post("/login")
def login(request: Request, body: LoginRequest):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT user_id, tenant_id, hashed_password, role, is_active FROM users WHERE email = %s",
                        (body.email,))
            row = cur.fetchone()
    finally:
        conn.close()
    if not row or not row[4] or not verify_password(body.password, row[2]):
        raise HTTPException(401, "Invalid credentials")
    user_id, tenant_id, _, role, _ = row
    conn2 = get_conn()
    try:
        with conn2.cursor() as cur:
            cur.execute("UPDATE users SET last_login_at = NOW() WHERE user_id = %s", (user_id,))
        conn2.commit()
    finally:
        conn2.close()
    access_token = create_access_token(str(user_id), str(tenant_id), str(role))
    raw_refresh, refresh_hash = create_refresh_token()
    _persist_refresh_token(str(user_id), refresh_hash)
    return {"access_token": access_token, "refresh_token": raw_refresh, "token_type": "bearer"}


@router.post("/refresh")
def refresh(body: TokenRefreshRequest):
    token_hash = hashlib.sha256(body.refresh_token.encode()).hexdigest()
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT rt.user_id, rt.expires_at, u.tenant_id, u.role "
                        "FROM refresh_tokens rt JOIN users u ON u.user_id = rt.user_id "
                        "WHERE rt.token_hash = %s", (token_hash,))
            row = cur.fetchone()
            if not row:
                raise HTTPException(401, "Invalid refresh token")
            user_id, expires_at, tenant_id, role = row
            if expires_at < datetime.now(timezone.utc):
                raise HTTPException(401, "Refresh token expired")
            cur.execute("DELETE FROM refresh_tokens WHERE token_hash = %s", (token_hash,))
        conn.commit()
    except HTTPException:
        conn.rollback(); raise
    finally:
        conn.close()
    raw_refresh, refresh_hash = create_refresh_token()
    _persist_refresh_token(str(user_id), refresh_hash)
    return {"access_token": create_access_token(str(user_id), str(tenant_id), str(role)),
            "refresh_token": raw_refresh, "token_type": "bearer"}


@router.post("/logout")
def logout(body: TokenRefreshRequest):
    token_hash = hashlib.sha256(body.refresh_token.encode()).hexdigest()
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM refresh_tokens WHERE token_hash = %s", (token_hash,))
        conn.commit()
    finally:
        conn.close()
    return {"detail": "Logged out"}


@router.get("/me")
def me(user: CurrentUser = Depends(get_current_user)):
    return {"user_id": user.user_id, "tenant_id": user.tenant_id, "email": user.email, "role": user.role}


@router.get("/api-keys")
def list_api_keys(user: CurrentUser = Depends(get_current_user)):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT key_id, name, last_used_at, expires_at, created_at "
                        "FROM api_keys WHERE tenant_id = %s AND is_active = TRUE ORDER BY created_at DESC",
                        (user.tenant_id,))
            rows = cur.fetchall()
    finally:
        conn.close()
    return [{"key_id": str(r[0]), "name": r[1], "last_used_at": r[2].isoformat() if r[2] else None,
             "expires_at": r[3].isoformat() if r[3] else None, "created_at": r[4].isoformat()} for r in rows]


@router.post("/api-keys", status_code=201)
def create_api_key(body: CreateApiKeyRequest, user: CurrentUser = Depends(get_current_user)):
    """Raw key returned ONCE in `key` field — store it securely."""
    raw_key, key_hash = generate_api_key()
    expires_at = (datetime.now(timezone.utc) + timedelta(days=body.expires_in_days)
                  if body.expires_in_days else None)
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("INSERT INTO api_keys (tenant_id, user_id, key_hash, name, expires_at) "
                        "VALUES (%s, %s, %s, %s, %s) RETURNING key_id, created_at",
                        (user.tenant_id, user.user_id, key_hash, body.name, expires_at))
            key_id, created_at = cur.fetchone()
        conn.commit()
    finally:
        conn.close()
    return {"key_id": str(key_id), "name": body.name, "key": raw_key,
            "created_at": created_at.isoformat(), "expires_at": expires_at.isoformat() if expires_at else None}


@router.delete("/api-keys/{key_id}", status_code=204)
def revoke_api_key(key_id: str, user: CurrentUser = Depends(get_current_user)):
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("UPDATE api_keys SET is_active = FALSE WHERE key_id = %s AND tenant_id = %s",
                        (key_id, user.tenant_id))
            if cur.rowcount == 0:
                raise HTTPException(404, "API key not found")
        conn.commit()
    except HTTPException:
        conn.rollback(); raise
    finally:
        conn.close()


def _persist_refresh_token(user_id: str, token_hash: str) -> None:
    expires_at = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute("INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES (%s, %s, %s)",
                        (user_id, token_hash, expires_at))
        conn.commit()
    finally:
        conn.close()