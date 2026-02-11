import requests
from bs4 import BeautifulSoup
import psycopg2
from datetime import date


URL = "https://www.phillips.com/auction/CH080425"


def fetch_html():
    headers = {
        "User-Agent": "Mozilla/5.0"
    }
    response = requests.get(URL, headers=headers)
    response.raise_for_status()
    return response.text


def extract_lots(html):
    soup = BeautifulSoup(html, "html.parser")

    lot_divs = soup.find_all("div", {"data-testid": "grid-item"})

    lots = []

    for div in lot_divs:
        try:
            # Title
            title_tag = div.find("a", {"data-testid": lambda x: x and "object-title" in x})
            title = title_tag.get_text(strip=True) if title_tag else None

            # Lot number
            lot_number_tag = div.find("span", string=lambda x: x and "Lot" in x)
            lot_number = None
            if lot_number_tag:
                lot_number = lot_number_tag.get_text(strip=True).replace("Lot", "").strip()

            # Estimate
            estimate_tag = div.find(string=lambda x: x and "Estimate" in x)
            estimate = estimate_tag.strip() if estimate_tag else None

            # Sold price
            sold_tag = div.find(string=lambda x: x and "Sold" in x)
            sold_price = None
            if sold_tag:
                sold_price = sold_tag.strip()

            lots.append({
                "lot_number": lot_number,
                "title": title,
                "estimate_text": estimate,
                "sold_text": sold_price
            })

        except Exception:
            continue

    return lots


def insert_into_db(lots):
    conn = psycopg2.connect(
        host="localhost",
        database="watchdb",
        user="watchuser",
        password="watchpass"
    )

    with conn:
        with conn.cursor() as cur:

            cur.execute(
                "SELECT auction_house_id FROM auction_houses WHERE name = %s",
                ("Phillips",)
            )
            auction_house_id = cur.fetchone()[0]

            cur.execute("""
                INSERT INTO auction_events (
                    auction_house_id,
                    event_name,
                    event_date,
                    currency
                )
                VALUES (%s, %s, %s, %s)
                RETURNING auction_event_id
            """, (
                auction_house_id,
                "Geneva Watch Auction November 2025",
                date(2025, 11, 8),
                "CHF"
            ))

            auction_event_id = cur.fetchone()[0]

            for lot in lots:
                cur.execute("""
                    INSERT INTO auction_lots (
                        auction_event_id,
                        lot_number,
                        brand_name,
                        model_name,
                        hammer_price,
                        currency
                    )
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (
                    auction_event_id,
                    lot["lot_number"],
                    lot["title"],
                    None,
                    None,
                    "CHF"
                ))

    conn.close()


def main():
    html = fetch_html()
    lots = extract_lots(html)

    print(f"Lots found: {len(lots)}")

    if lots:
        insert_into_db(lots)
        print("Inserted into database.")
    else:
        print("No lots found.")


if __name__ == "__main__":
    main()