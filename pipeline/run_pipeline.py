import psycopg2
from datetime import date

from collectors.chrono24 import fetch_chrono24_listings
from transforms.aggregate_listings import aggregate_listings
from loaders.load_listings_daily import upsert_listings_daily


def main():
    conn = psycopg2.connect(
        host="localhost",
        port=5432,
        database="watchdb",
        user="watchuser",
        password="watchpass"
    )

    snapshot_date = date.today()

    # ------------------------------------------------
    # Fetch all references dynamically
    # ------------------------------------------------
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT reference_id, reference_code
            FROM watch_references
            ORDER BY reference_code;
            """
        )
        references = cur.fetchall()

    print(f"▶ Processing {len(references)} references for {snapshot_date}")

    # ------------------------------------------------
    # Process each reference
    # ------------------------------------------------
    for reference_id, reference_code in references:
        print(f"\nFetching listings for {reference_code}...")

        listings = fetch_chrono24_listings("", reference_code)
        agg = aggregate_listings(listings)

        if not agg:
            print("  ❌ No valid listings found")
            continue

        upsert_listings_daily(
            conn,
            snapshot_date,
            reference_id,
            agg
        )

        print(
            f"  ✅ Loaded {agg['listing_count']} listings | "
            f"Avg ${agg['avg_price']} | Min ${agg['min_price']}"
        )

    conn.close()
    print("\n✔ listings_daily population complete")


if __name__ == "__main__":
    main()