import psycopg2

DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "database": "watchdb",
    "user": "watchuser",
    "password": "watchpass"
}

QUERY = """
INSERT INTO watch_index_daily (
    brand,
    reference_code,
    index_date,
    lot_count,
    total_value,
    avg_price,
    median_price,
    demand_score
)
SELECT
    brand,
    reference_code,
    auction_date,
    COUNT(*),
    SUM(price),
    AVG(price),
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price),
    (
        COUNT(*) * 0.6 +
        LOG(SUM(price) + 1) * 0.4
    )
FROM auction_lots
WHERE price IS NOT NULL
GROUP BY brand, reference_code, auction_date
ON CONFLICT (brand, reference_code, index_date)
DO UPDATE SET
    lot_count = EXCLUDED.lot_count,
    total_value = EXCLUDED.total_value,
    avg_price = EXCLUDED.avg_price,
    median_price = EXCLUDED.median_price,
    demand_score = EXCLUDED.demand_score;
"""

def main():

    conn = psycopg2.connect(**DB_CONFIG)

    cursor = conn.cursor()

    print("Building watch demand index...")

    cursor.execute(QUERY)

    conn.commit()

    cursor.close()
    conn.close()

    print("Index build complete")


if __name__ == "__main__":
    main()