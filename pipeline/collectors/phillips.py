import re
import os
import time
import random
import psycopg2
from datetime import datetime, UTC

from playwright.sync_api import sync_playwright, TimeoutError


BASE_URL = "https://www.phillips.com"
AUCTION_URL = "https://www.phillips.com/auction/CH080425"

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

PROJECT_ROOT = os.path.abspath(os.path.join(BASE_DIR, "..", ".."))

DB_PATH = os.path.join(PROJECT_ROOT, "watch_index.db")

print("Using database:", DB_PATH)


# -----------------------------
# Database
# -----------------------------

def init_db():

    conn = psycopg2.connect(
        host="localhost",
        port=5432,
        database="watchdb",
        user="watchuser",
        password="watchpass"  # change to your real password
    )

    conn.autocommit = True

    print("Connected to PostgreSQL")

    return conn


def insert_result(conn, result):

    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO auction_lots
        (
            auction_house,
            auction_id,
            lot,
            brand,
            reference_code,
            model,
            price,
            currency,
            url,
            created_at
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (url) DO NOTHING
    """, (
        "Phillips",
        "CH080425",
        result["lot"],
        result["brand"],
        result["reference"],
        result["model"],
        result["price"],
        "CHF",
        result["url"],
        datetime.now(UTC)
    ))

    cursor.close()


# -----------------------------
# URL extraction
# -----------------------------

def extract_lot_urls(page):

    print("Extracting lot URLs...")

    page.goto(AUCTION_URL, timeout=60000)

    try:
        page.click("#onetrust-accept-btn-handler", timeout=3000)
    except:
        pass

    page.wait_for_timeout(5000)

    anchors = page.locator("a[href*='/detail/']").all()

    urls = []

    for a in anchors:

        href = a.get_attribute("href")

        if not href:
            continue

        if not href.startswith("http"):
            href = BASE_URL + href

        urls.append(href)

    urls = sorted(list(set(urls)))

    print(f"Found {len(urls)} lots")

    return urls


# -----------------------------
# Extraction helpers
# -----------------------------

def extract_lot_number(page):

    try:

        text = page.locator(
            ".pah-lot-placard__symbols"
        ).inner_text()

        return int(text.strip())

    except:

        return None


def extract_brand(page):

    try:

        return page.locator(
            ".pah-lot-placard__maker-name"
        ).inner_text().strip()

    except:

        return None


def extract_reference_and_model(page):

    reference = None
    model = None

    try:

        elements = page.locator(
            ".pah-lot-placard__details h3"
        ).all()

        for el in elements:

            text = el.inner_text().strip()

            if not text:
                continue

            ref_match = re.search(
                r"(Ref|Reference|Model\s*No)\.?\s*(.+)",
                text,
                re.IGNORECASE
            )

            if ref_match:

                reference = ref_match.group(2).strip()

            else:

                if not model:
                    model = text

    except:
        pass

    return reference, model


def extract_price(page):

    try:

        label = page.locator(
            "dt:has-text('Sold For') + dd"
        )

        text = label.inner_text()

        numeric = re.sub(r"[^\d.]", "", text)

        return float(numeric)

    except:

        return None


# -----------------------------
# Lot processing
# -----------------------------

def process_lot(page, url):

    try:

        page.goto(url, timeout=60000)

        lot = extract_lot_number(page)

        brand = extract_brand(page)

        reference, model = extract_reference_and_model(page)

        price = extract_price(page)

        print(
            f"Lot {lot} → Brand {brand} → Ref {reference} → Model {model} → Price {price}"
        )

        return {

            "lot": lot,
            "brand": brand,
            "reference": reference,
            "model": model,
            "price": price,
            "url": url
        }

    except TimeoutError:

        print(f"Timeout: {url}")

        return None

    except Exception as e:

        print(f"Error: {url} → {e}")

        return None


# -----------------------------
# Main
# -----------------------------

def main():

    conn = init_db()

    results = []

    with sync_playwright() as p:

        browser = p.chromium.launch_persistent_context(

            user_data_dir="./playwright_session",

            headless=True,

            viewport={"width": 1280, "height": 900},

            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/120 Safari/537.36"
            ),

            args=[
                "--disable-blink-features=AutomationControlled"
            ]
        )

        page = browser.new_page()

        urls = extract_lot_urls(page)

        print()

        for url in urls:

            result = process_lot(page, url)

            if result:

                insert_result(conn, result)

                results.append(result)

            time.sleep(random.uniform(0.3, 0.8))

        browser.close()

    print()

    print(f"Extracted {len(results)} lots")

    print(f"Inserted {len(results)} lots into database")


# -----------------------------

if __name__ == "__main__":

    main()