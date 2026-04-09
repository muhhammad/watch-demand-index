"""
Watch Demand Index – Production FastAPI application.
"""
import os

from fastapi import Depends, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from api.auth import CurrentUser, get_current_user
from api.db import get_conn
from api.routers.auth_router import router as auth_router

limiter = Limiter(key_func=get_remote_address, default_limits=["100/minute"])

app = FastAPI(
    title="Watch Demand Index API", version="2.0.0",
    description="Enterprise API for luxury watch demand analytics, arbitrage discovery, and market intelligence.",
    docs_url="/docs", redoc_url="/redoc",
)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

_raw_origins = os.getenv("ALLOWED_ORIGINS", "http://localhost:5173,http://localhost:3000")
allowed_origins = [o.strip() for o in _raw_origins.split(",") if o.strip()]

app.add_middleware(
    CORSMiddleware, allow_origins=allowed_origins, allow_credentials=True,
    allow_methods=["GET", "POST", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "X-API-Key", "Content-Type"],
)

app.include_router(auth_router)


@app.get("/", tags=["System"])
def root():
    return {"status": "Watch Demand Index API running", "version": "2.0.0"}


@app.get("/health", tags=["System"])
def health():
    return {"status": "ok"}


@app.get("/auction_lots", tags=["Market Data"])
def get_auction_lots(user: CurrentUser = Depends(get_current_user)):
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT auction_house, auction_id, lot, brand, reference_code,
               model, price, currency, auction_date
        FROM auction_lots ORDER BY auction_date DESC, lot ASC LIMIT 200
    """)
    rows = cursor.fetchall()
    cursor.close(); conn.close()
    return [{"auction_house": r[0], "auction_id": r[1], "lot": r[2], "brand": r[3],
             "reference_code": r[4], "model": r[5], "price": float(r[6]) if r[6] else None,
             "currency": r[7], "auction_date": str(r[8])} for r in rows]


@app.get("/metrics", tags=["Market Data"])
def get_metrics(user: CurrentUser = Depends(get_current_user)):
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*), AVG(price), SUM(price) FROM auction_lots WHERE price IS NOT NULL")
    total_lots, avg_price, total_value = cursor.fetchone()
    cursor.execute("SELECT brand FROM auction_lots GROUP BY brand ORDER BY COUNT(*) DESC LIMIT 1")
    result = cursor.fetchone()
    cursor.close(); conn.close()
    return {"total_lots": total_lots or 0, "avg_price": float(avg_price or 0),
            "total_value": float(total_value or 0), "top_brand": result[0] if result else None}


@app.get("/brand-index", tags=["Indexes"])
def get_brand_index(user: CurrentUser = Depends(get_current_user)):
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("SELECT index_date, brand, lot_count, total_value, avg_price, demand_score "
                   "FROM watch_index_brand_daily ORDER BY index_date DESC LIMIT 1000")
    rows = cursor.fetchall()
    cursor.close(); conn.close()
    return [{"date": str(r[0]), "brand": r[1], "lot_count": r[2],
             "total_value": float(r[3]), "avg_price": float(r[4]), "demand_score": float(r[5])} for r in rows]


@app.get("/market-index", tags=["Indexes"])
def get_market_index(user: CurrentUser = Depends(get_current_user)):
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("SELECT index_date, lot_count, total_value, avg_price, median_price, "
                   "unique_brands, unique_references, demand_score "
                   "FROM watch_index_market_daily ORDER BY index_date DESC LIMIT 365")
    rows = cursor.fetchall()
    cursor.close(); conn.close()
    return [{"date": str(r[0]), "lot_count": r[1], "total_value": float(r[2]), "avg_price": float(r[3]),
             "median_price": float(r[4]) if r[4] else None, "unique_brands": r[5],
             "unique_references": r[6], "demand_score": float(r[7])} for r in rows]


@app.get("/leaderboard", tags=["Indexes"])
def get_leaderboard(user: CurrentUser = Depends(get_current_user)):
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("SELECT brand, SUM(price), COUNT(*), AVG(price) FROM auction_lots "
                   "GROUP BY brand ORDER BY SUM(price) DESC LIMIT 50")
    rows = cursor.fetchall()
    cursor.close(); conn.close()
    return [{"brand": r[0], "total_value": float(r[1]), "lot_count": r[2], "avg_price": float(r[3])} for r in rows]


@app.get("/arbitrage", tags=["Arbitrage"])
def get_arbitrage(user: CurrentUser = Depends(get_current_user)):
    conn = get_conn()
    cursor = conn.cursor()
    cursor.execute("SELECT source, seller, brand, reference, dealer_price, median_price, "
                   "absolute_profit, profit_percent, opportunity_grade, source_priority "
                   "FROM arbitrage_opportunities ORDER BY source_priority ASC, profit_percent DESC LIMIT 200")
    rows = cursor.fetchall()
    cursor.close(); conn.close()
    return [{"source": r[0], "seller": r[1], "brand": r[2], "reference": r[3],
             "dealer_price": float(r[4]), "median_price": float(r[5]), "absolute_profit": float(r[6]),
             "profit_percent": float(r[7]), "opportunity_grade": r[8], "source_priority": r[9]} for r in rows]