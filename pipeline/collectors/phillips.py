import re
import time
import psycopg2

from datetime import datetime
from playwright.sync_api import sync_playwright


# -----------------------------------------
# CONFIG
# -----------------------------------------

DB_CONFIG = {
    "host": "localhost",
    "database": "watchdb",
    "user": "watchuser",
    "password": "watchpass",
    "port": 5432
}

AUCTION_URL = "https://www.phillips.com/auction/CH080425"

BASE_URL = "https://www.phillips.com"


# -----------------------------------------
# Extract lot URLs from auction page
# -----------------------------------------

def extract_lot_urls(page):

    print("Extracting lot URLs...")

    # Fast navigation (do NOT wait for full load)
    page.goto(
        AUCTION_URL,
        timeout=30000,
        wait_until="domcontentloaded"
    )

    # Accept cookies if present (non-blocking)
    try:
        cookie_btn = page.locator("#onetrust-accept-btn-handler")
        if cookie_btn.is_visible(timeout=3000):
            cookie_btn.click()
    except:
        pass

    # Wait for grid container
    page.wait_for_selector(
        '[data-testid="grid-item"]',
        timeout=20000
    )

    # Ensure all lots load (important)
    page.wait_for_timeout(2000)

    links = page.locator('[data-testid="grid-item"] a').all()

    urls = []

    for link in links:

        href = link.get_attribute("href")

        if not href:
            continue

        if "/detail/" not in href:
            continue

        if href.startswith("http"):
            urls.append(href)
        else:
            urls.append(BASE_URL + href)

    # Remove duplicates while preserving order
    urls = list(dict.fromkeys(urls))

    print(f"Found {len(urls)} lots")

    return urls


# -----------------------------------------
# Extract brand
# -----------------------------------------

def extract_brand(page):

    try:

        el = page.locator(
            "h2.pah-lot-placard__maker-name span"
        ).first

        if el.count():
            return el.inner_text().strip()

        return None

    except:
        return None


# -----------------------------------------
# Extract reference
# -----------------------------------------

def extract_reference(page):

    try:

        elements = page.locator(
            ".pah-lot-placard__details "
            "h3.pah-watch-lot-placard__italic"
        ).all()

        for el in elements:

            text = el.inner_text().strip()

            if not text:
                continue

            match = re.search(
                r"Ref\.?\s*([A-Za-z0-9\.\-]+)",
                text,
                re.IGNORECASE
            )

            if match:
                return match.group(1)

            match = re.search(
                r"Model\s*No\.?\s*([A-Za-z0-9\.\-]+)",
                text,
                re.IGNORECASE
            )

            if match:
                return match.group(1)

            match = re.search(
                r"Reference\s*([A-Za-z0-9\.\-]+)",
                text,
                re.IGNORECASE
            )

            if match:
                return match.group(1)

        return None

    except:
        return None


# -----------------------------------------
# Extract model name fallback
# -----------------------------------------

def extract_model_name(page):

    try:

        elements = page.locator(
            ".pah-lot-placard__details "
            "h3.pah-watch-lot-placard__italic"
        ).all()

        for el in elements:

            text = el.inner_text().strip()

            if not text:
                continue

            if re.search(
                r"(Ref\.?|Model\s*No\.?|Reference)",
                text,
                re.IGNORECASE
            ):
                continue

            return text

        return None

    except:
        return None


# -----------------------------------------
# Extract hammer price
# -----------------------------------------

def extract_price(page):

    try:

        price_label = page.locator(
            "dt:has-text('Sold For')"
        )

        if price_label.count():

            price_el = price_label.locator(
                "xpath=following-sibling::dd"
            ).first

            text = price_el.inner_text()

            match = re.search(r"CHF\s*([\d,]+)", text)

            if match:
                return float(match.group(1).replace(",", ""))

        return None

    except:
        return None


# -----------------------------------------
# Extract lot number
# -----------------------------------------

def extract_lot_number(page):

    try:

        el = page.locator(
            "li[aria-label^='Lot'] span"
        ).first

        text = el.inner_text()

        match = re.search(r"Lot\s+(\d+)", text)

        if match:
            return match.group(1)

        return None

    except:
        return None


# -----------------------------------------
# Fetch lots
# -----------------------------------------

def fetch_phillips_lots():

    lots = []

    with sync_playwright() as p:

        browser = p.chromium.launch(headless=True)

        context = browser.new_context()

        page = context.new_page()

        lot_urls = extract_lot_urls(page)

        for url in lot_urls:

            try:

                page.goto(url, timeout=60000)

                brand = extract_brand(page)

                reference = extract_reference(page)

                model_name = None

                if not reference:
                    model_name = extract_model_name(page)

                price = extract_price(page)

                lot_number = extract_lot_number(page)

                print(
                    f"Lot {lot_number} → Brand {brand} → Ref {reference} → Model {model_name} → Price {price}"
                )

                lots.append({

                    "lot_number": lot_number,
                    "brand_name": brand,
                    "reference_code": reference,
                    "model_name": model_name,
                    "hammer_price": price,
                    "currency": "CHF"

                })

            except Exception as e:

                print("Error:", url, e)

        browser.close()

    print(f"\nExtracted {len(lots)} lots")

    return lots


# -----------------------------------------
# Insert into database
# -----------------------------------------

def insert_auction_lots(lots):

    conn = psycopg2.connect(**DB_CONFIG)

    cur = conn.cursor()

    inserted = 0

    for lot in lots:

        if not lot["hammer_price"]:
            continue

        cur.execute(
            """
            INSERT INTO auction_lots
            (
                auction_event_id,
                lot_number,
                brand_name,
                reference_code,
                model_name,
                hammer_price,
                currency,
                created_at
            )
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """,
            (
                7,
                lot["lot_number"],
                lot["brand_name"],
                lot["reference_code"],
                lot["model_name"],
                lot["hammer_price"],
                lot["currency"],
                datetime.utcnow()
            )
        )

        inserted += 1

    conn.commit()

    cur.close()
    conn.close()

    print(f"Inserted {inserted} lots into database.")


# -----------------------------------------
# MAIN
# -----------------------------------------

def main():

    lots = fetch_phillips_lots()

    insert_auction_lots(lots)


if __name__ == "__main__":
    main()