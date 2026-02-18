import psycopg2

DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "database": "watchdb",
    "user": "watchuser",
    "password": "watchpass"
}

QUERY = """
INSERT INTO watch_index_brand_daily (

    brand,
    index_date,
    lot_count,
    total_value,
    avg_price,
    median_price,
    unique_references,
    demand_score

)

SELECT

    brand,
    auction_date,
    COUNT(*),
    SUM(price),
    AVG(price),
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price),
    COUNT(DISTINCT reference_code),

    (
        COUNT(*) * 0.5 +
        LOG(SUM(price) + 1) * 0.3 +
        COUNT(DISTINCT reference_code) * 0.2
    )

FROM auction_lots

WHERE price IS NOT NULL

GROUP BY brand, auction_date

ON CONFLICT (brand, index_date)
DO UPDATE SET

    lot_count = EXCLUDED.lot_count,
    total_value = EXCLUDED.total_value,
    avg_price = EXCLUDED.avg_price,
    median_price = EXCLUDED.median_price,
    unique_references = EXCLUDED.unique_references,
    demand_score = EXCLUDED.demand_score;
"""

def main():

    conn = psycopg2.connect(**DB_CONFIG)

    cursor = conn.cursor()

    print("Building brand demand index...")

    cursor.execute(QUERY)

    conn.commit()

    cursor.close()
    conn.close()

    print("Brand index complete")


if __name__ == "__main__":
    main()