"""
Authentication utilities: JWT, password hashing, API key generation,
and FastAPI dependency providers (get_current_user, require_roles).
"""
import hashlib
import os
import secrets
from datetime import datetime, timezone
from typing import Optional

from fastapi import Depends, HTTPException, Security, status
from fastapi.security import APIKeyHeader, HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel

from api.db import get_conn

SECRET_KEY = os.getenv("SECRET_KEY", "CHANGE-ME-not-safe-for-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 15
REFRESH_TOKEN_EXPIRE_DAYS = 7

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
bearer_scheme = HTTPBearer(auto_error=False)
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


class CurrentUser(BaseModel):
    user_id: str
    tenant_id: str
    email: str
    role: str


class _TokenData(BaseModel):
    user_id: str
    tenant_id: str
    role: str


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def generate_api_key() -> tuple[str, str]:
    raw = "wdi_" + secrets.token_urlsafe(32)
    return raw, _sha256(raw)


def _sha256(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def create_access_token(user_id: str, tenant_id: str, role: str) -> str:
    from datetime import timedelta
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode(
        {"sub": user_id, "tenant_id": tenant_id, "role": role,
         "exp": expire, "type": "access"},
        SECRET_KEY, algorithm=ALGORITHM,
    )


def create_refresh_token() -> tuple[str, str]:
    raw = secrets.token_urlsafe(64)
    return raw, _sha256(raw)


def _decode_access_token(token: str) -> _TokenData:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "access":
            raise HTTPException(status_code=401, detail="Invalid token type")
        return _TokenData(user_id=payload["sub"], tenant_id=payload["tenant_id"], role=payload["role"])
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


def _user_from_id(user_id: str) -> Optional[CurrentUser]:
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT user_id, tenant_id, email, role FROM users WHERE user_id = %s AND is_active = TRUE",
                (user_id,),
            )
            row = cur.fetchone()
    finally:
        conn.close()
    if not row:
        return None
    return CurrentUser(user_id=str(row[0]), tenant_id=str(row[1]), email=row[2], role=str(row[3]))


def _user_from_api_key(raw_key: str) -> Optional[CurrentUser]:
    key_hash = _sha256(raw_key)
    conn = get_conn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT u.user_id, u.tenant_id, u.email, u.role, ak.key_id, ak.expires_at
                FROM api_keys ak
                JOIN users u ON u.user_id = ak.user_id
                WHERE ak.key_hash = %s AND ak.is_active = TRUE AND u.is_active = TRUE
                """,
                (key_hash,),
            )
            row = cur.fetchone()
            if not row:
                return None
            expires_at = row[5]
            if expires_at and expires_at < datetime.now(timezone.utc):
                return None
            cur.execute("UPDATE api_keys SET last_used_at = NOW() WHERE key_id = %s", (row[4],))
            conn.commit()
    finally:
        conn.close()
    return CurrentUser(user_id=str(row[0]), tenant_id=str(row[1]), email=row[2], role=str(row[3]))


async def get_current_user(
    bearer: Optional[HTTPAuthorizationCredentials] = Security(bearer_scheme),
    api_key: Optional[str] = Security(api_key_header),
) -> CurrentUser:
    if bearer and bearer.credentials:
        token_data = _decode_access_token(bearer.credentials)
        user = _user_from_id(token_data.user_id)
        if user and user.role == token_data.role:
            return user
    if api_key:
        user = _user_from_api_key(api_key)
        if user:
            return user
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated",
                        headers={"WWW-Authenticate": "Bearer"})


def require_roles(*roles: str):
    async def _check(user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
        if user.role not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient permissions")
        return user
    return _check