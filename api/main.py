import os
import psycopg2
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Watch Demand Index API")


# -----------------------------
# CORS (for dashboard later)
# -----------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# -----------------------------
# Database connection
# -----------------------------

def get_conn():

    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
    )


# -----------------------------
# Health check
# -----------------------------

@app.get("/health")
def health():

    return {"status": "ok"}


# -----------------------------
# Market index endpoint
# -----------------------------

@app.get("/market-index")
def market_index():

    conn = get_conn()

    cursor = conn.cursor()

    cursor.execute("""

        SELECT
            index_date,
            lot_count,
            total_value,
            avg_price,
            median_price,
            unique_brands,
            unique_references,
            demand_score

        FROM watch_index_market_daily

        ORDER BY index_date DESC

        LIMIT 365

    """)

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    return [

        {
            "date": r[0],
            "lot_count": r[1],
            "total_value": float(r[2]),
            "avg_price": float(r[3]),
            "median_price": float(r[4]) if r[4] else None,
            "unique_brands": r[5],
            "unique_references": r[6],
            "demand_score": float(r[7])
        }

        for r in rows
    ]


# -----------------------------
# Brand index endpoint
# -----------------------------

@app.get("/brand-index")
def brand_index():

    conn = get_conn()

    cursor = conn.cursor()

    cursor.execute("""

        SELECT
            index_date,
            brand,
            lot_count,
            total_value,
            avg_price,
            demand_score

        FROM watch_index_brand_daily

        ORDER BY index_date DESC

        LIMIT 1000

    """)

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    return [

        {
            "date": r[0],
            "brand": r[1],
            "lot_count": r[2],
            "total_value": float(r[3]),
            "avg_price": float(r[4]),
            "demand_score": float(r[5])
        }

        for r in rows
    ]


# -----------------------------
# Leaderboard endpoint
# -----------------------------

@app.get("/leaderboard")
def leaderboard():

    conn = get_conn()

    cursor = conn.cursor()

    cursor.execute("""

        SELECT
            brand,
            SUM(price) as total_value,
            COUNT(*) as lot_count,
            AVG(price) as avg_price

        FROM auction_lots

        GROUP BY brand

        ORDER BY total_value DESC

        LIMIT 50

    """)

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    return [

        {
            "brand": r[0],
            "total_value": float(r[1]),
            "lot_count": r[2],
            "avg_price": float(r[3])
        }

        for r in rows
    ]