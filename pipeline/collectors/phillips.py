import psycopg2
from playwright.sync_api import sync_playwright
from datetime import datetime

AUCTION_URL = "https://www.phillips.com/auction/CH080425"


# -----------------------------
# Fetch lots from Phillips
# -----------------------------
def fetch_phillips_lots(url):

    lots = []

    p = sync_playwright().start()

    browser = p.chromium.launch(
        headless=True,
        args=["--disable-blink-features=AutomationControlled"]
    )

    context = browser.new_context(
        viewport={"width": 1280, "height": 2000}
    )

    page = context.new_page()

    print("Opening Phillips auction page...")
    page.goto(url, timeout=60000)

    # Accept cookie consent
    try:
        consent = page.locator("button:has-text('Accept')")
        if consent.count() > 0:
            consent.first.click(timeout=5000)
    except:
        pass

    print("Waiting for lots to render...")
    page.wait_for_selector("div[data-testid='grid-item']", timeout=60000)

    print("Scrolling to load all lots...")

    previous_height = 0

    while True:

        page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
        page.wait_for_timeout(1500)

        current_height = page.evaluate("document.body.scrollHeight")

        if current_height == previous_height:
            break

        previous_height = current_height

    cards = page.locator("div[data-testid='grid-item']")
    count = cards.count()

    print(f"Lots extracted: {count}")

    import re

    for i in range(count):

        text = cards.nth(i).inner_text()

        lot_match = re.search(r"Lot\s*(\d+)", text)
        price_match = re.search(r"CHF\s*([\d,]+)", text)

        lot_number = lot_match.group(1) if lot_match else None

        hammer_price = (
            float(price_match.group(1).replace(",", ""))
            if price_match else None
        )

        lots.append({
            "lot_number": lot_number,
            "hammer_price": hammer_price,
            "currency": "CHF"
        })

    # CRITICAL FIX: force close everything immediately
    browser.close()
    p.stop()

    print("Browser closed cleanly.")

    return lots


# -----------------------------
# Insert lots into Postgres
# -----------------------------
def insert_auction_lots(lots):

    conn = psycopg2.connect(
        host="localhost",
        database="watchdb",
        user="watchuser",
        password="watchpass"
    )

    cur = conn.cursor()

    for lot in lots:

        cur.execute("""
            INSERT INTO auction_lots
            (
                auction_event_id,
                lot_number,
                hammer_price,
                currency,
                created_at
            )
            VALUES (%s,%s,%s,%s,%s)
        """, (
            7,
            lot["lot_number"],
            lot["hammer_price"],
            lot["currency"],
            datetime.now()
        ))

    conn.commit()

    cur.close()
    conn.close()

    print("Inserted into database.")


# -----------------------------
# Main runner
# -----------------------------
def main():

    lots = fetch_phillips_lots(AUCTION_URL)

    if lots:
        insert_auction_lots(lots)

    print("Done.")


if __name__ == "__main__":
    main()