import os
import psycopg2
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Railway provides this automatically
DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise Exception("DATABASE_URL environment variable not set")

app = FastAPI()

# Allow dashboard access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# -----------------------------
# Helper function
# -----------------------------
def get_conn():
    return psycopg2.connect(DATABASE_URL)


# -----------------------------
# Root
# -----------------------------
@app.get("/")
def root():
    return {"status": "API running"}


# -----------------------------
# Auction lots endpoint
# -----------------------------
@app.get("/auction_lots")
def get_auction_lots():

    conn = get_conn()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            auction_house,
            auction_id,
            lot,
            brand,
            reference_code,
            model,
            price,
            currency,
            auction_date
        FROM auction_lots
        ORDER BY auction_date DESC, lot ASC
        LIMIT 200
    """)

    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    return [
        {
            "auction_house": r[0],
            "auction_id": r[1],
            "lot": r[2],
            "brand": r[3],
            "reference_code": r[4],
            "model": r[5],
            "price": float(r[6]) if r[6] else None,
            "currency": r[7],
            "auction_date": str(r[8]),
        }
        for r in rows
    ]


# -----------------------------
# Metrics endpoint
# -----------------------------
@app.get("/metrics")
def get_metrics():

    conn = get_conn()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            COUNT(*),
            AVG(price),
            SUM(price)
        FROM auction_lots
        WHERE price IS NOT NULL
    """)

    total_lots, avg_price, total_value = cursor.fetchone()

    cursor.execute("""
        SELECT brand, COUNT(*)
        FROM auction_lots
        GROUP BY brand
        ORDER BY COUNT(*) DESC
        LIMIT 1
    """)

    result = cursor.fetchone()

    top_brand = result[0] if result else None

    cursor.close()
    conn.close()

    return {
        "total_lots": total_lots or 0,
        "avg_price": float(avg_price or 0),
        "total_value": float(total_value or 0),
        "top_brand": top_brand
    }


# -----------------------------
# Brand index endpoint
# -----------------------------
@app.get("/brand_index")
def get_brand_index():

    conn = get_conn()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            brand,
            COUNT(*),
            AVG(price),
            SUM(price)
        FROM auction_lots
        WHERE price IS NOT NULL
        GROUP BY brand
        ORDER BY SUM(price) DESC
    """)

    results = []

    for brand, total_lots, avg_price, total_value in cursor.fetchall():

        demand_index = (total_lots * avg_price) / 1000

        results.append({
            "brand": brand,
            "total_lots": total_lots,
            "avg_price": float(avg_price),
            "total_value": float(total_value),
            "demand_index": round(demand_index, 2)
        })

    cursor.close()
    conn.close()

    return results