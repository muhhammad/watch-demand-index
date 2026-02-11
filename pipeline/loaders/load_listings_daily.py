import psycopg2

def upsert_listings_daily(conn, snapshot_date, reference_id, agg):
    """
    Upsert aggregated listing data into listings_daily.
    One row per reference per snapshot_date.
    """
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO listings_daily (
                snapshot_date,
                reference_id,
                avg_price,
                min_price,
                listing_count,
                avg_days_on_market
            )
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (snapshot_date, reference_id)
            DO UPDATE SET
                avg_price = EXCLUDED.avg_price,
                min_price = EXCLUDED.min_price,
                listing_count = EXCLUDED.listing_count,
                avg_days_on_market = EXCLUDED.avg_days_on_market
            """,
            (
                snapshot_date,
                reference_id,
                agg["avg_price"],
                agg["min_price"],
                agg["listing_count"],
                agg["avg_days_on_market"]
            )
        )
    conn.commit()