"""
Centralised database connection.

Supports both:
  - DATABASE_URL  (Railway / Heroku / Render)
  - Individual DB_* env vars (local Docker Compose)
"""
import os

import psycopg2
from dotenv import load_dotenv

load_dotenv()


def get_conn() -> psycopg2.extensions.connection:
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        return psycopg2.connect(database_url)
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", 5432)),
        database=os.getenv("DB_NAME", "watchdb"),
        user=os.getenv("DB_USER", "watchuser"),
        password=os.getenv("DB_PASSWORD", "watchpass"),
    )