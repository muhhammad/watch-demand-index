from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import psycopg2

DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "database": "watchdb",
    "user": "watchuser",
    "password": "watchpass"
}

app = FastAPI()

# Enable CORS for React dashboard
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"status": "API running"}

@app.get("/auction_lots")
def get_auction_lots():

    conn = psycopg2.connect(**DB_CONFIG)
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
            "price": r[6],
            "currency": r[7],
            "auction_date": str(r[8]),
        }
        for r in rows
    ]


@app.get("/metrics")
def get_metrics():

    conn = psycopg2.connect(
        host="localhost",
        port=5432,
        database="watchdb",
        user="watchuser",
        password="watchpass"
    )

    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            COUNT(*) as total_lots,
            AVG(price) as avg_price,
            SUM(price) as total_value
        FROM auction_lots
        WHERE price IS NOT NULL
    """)

    total_lots, avg_price, total_value = cursor.fetchone()

    cursor.execute("""
        SELECT brand, COUNT(*) as count
        FROM auction_lots
        GROUP BY brand
        ORDER BY count DESC
        LIMIT 1
    """)

    result = cursor.fetchone()

    top_brand = result[0] if result else None

    cursor.close()
    conn.close()

    return {
        "total_lots": total_lots,
        "avg_price": float(avg_price or 0),
        "total_value": float(total_value or 0),
        "top_brand": top_brand
    }


@app.get("/brand_index")
def get_brand_index():

    conn = psycopg2.connect(
        host="localhost",
        port=5432,
        database="watchdb",
        user="watchuser",
        password="watchpass"
    )

    cursor = conn.cursor()

    cursor.execute("""
        SELECT
            brand,
            COUNT(*) as total_lots,
            AVG(price) as avg_price,
            SUM(price) as total_value
        FROM auction_lots
        WHERE price IS NOT NULL
        GROUP BY brand
        ORDER BY total_value DESC
    """)

    results = []

    for row in cursor.fetchall():

        brand, total_lots, avg_price, total_value = row

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