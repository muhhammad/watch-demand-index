import re
import time
import random
import psycopg2

from playwright.sync_api import sync_playwright, TimeoutError


BASE_URL = "https://www.chrono24.com"

SEARCH_URLS = [

    # Core brands for demo
    "https://www.chrono24.com/rolex/index.htm",
    "https://www.chrono24.com/patekphilippe/index.htm",
    "https://www.chrono24.com/audemarspiguet/index.htm",
    "https://www.chrono24.com/richardmille/index.htm",
    "https://www.chrono24.com/fpjourn/index.htm",
    "https://www.chrono24.com/omegasa/index.htm"

]


DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "database": "watchdb",
    "user": "watchuser",
    "password": "watchpass"
}


# ---------------------------------------
# Database
# ---------------------------------------

def init_db():

    conn = psycopg2.connect(**DB_CONFIG)

    conn.autocommit = False

    print("Connected to PostgreSQL")

    return conn


def insert_listing(conn, result):

    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO market_listings (
            source,
            brand,
            model,
            reference_code,
            price,
            currency,
            url
        )
        VALUES (%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT (url) DO NOTHING
    """, (

        result["source"],
        result["brand"],
        result["model"],
        result["reference_code"],
        result["price"],
        result["currency"],
        result["url"]

    ))

    cursor.close()


# ---------------------------------------
# Helpers
# ---------------------------------------

def block_resources(page):

    def handler(route, request):

        if request.resource_type in ["image", "font", "media"]:
            route.abort()
        else:
            route.continue_()

    page.route("**/*", handler)


def extract_price(text):

    try:

        currency = None

        if "CHF" in text:
            currency = "CHF"
        elif "USD" in text:
            currency = "USD"
        elif "EUR" in text:
            currency = "EUR"

        numeric = re.sub(r"[^\d]", "", text)

        if not numeric:
            return None, None

        price = float(numeric)

        return price, currency

    except:

        return None, None


def extract_reference(text):

    match = re.search(r"\b\d{3,}\b", text)

    if match:
        return match.group(0)

    return None


# ---------------------------------------
# Extract listings from page
# ---------------------------------------

def extract_page_listings(page):

    page.wait_for_selector("[data-testid='listing-card']", timeout=30000)

    cards = page.locator("[data-testid='listing-card']")

    count = cards.count()

    results = []

    for i in range(count):

        try:

            card = cards.nth(i)

            title = card.locator("[data-testid='listing-card-title']").inner_text()

            url = card.locator("a").first.get_attribute("href")

            price_text = card.locator("[data-testid='listing-card-price']").inner_text()

            price, currency = extract_price(price_text)

            brand = title.split()[0]

            reference = extract_reference(title)

            if url and not url.startswith("http"):
                url = BASE_URL + url

            result = {

                "source": "CHRONO24",

                "brand": brand,

                "model": title,

                "reference_code": reference,

                "price": price,

                "currency": currency,

                "url": url

            }

            print(f"{brand} → {reference} → {price}")

            results.append(result)

        except Exception as e:

            continue

    return results


# ---------------------------------------
# Main extraction
# ---------------------------------------

def accept_consent(page):

    try:

        # main consent button
        page.locator("#didomi-notice-agree-button").click(timeout=5000)

        print("Consent accepted (main)")

        page.wait_for_timeout(2000)

        return

    except:
        pass

    # iframe fallback
    try:

        frame = page.frame_locator("iframe[src*='didomi']")

        frame.locator("#didomi-notice-agree-button").click(timeout=5000)

        print("Consent accepted (iframe)")

        page.wait_for_timeout(2000)

    except:
        pass


def extract_all_listings(page):

    all_results = []

    for search_url in SEARCH_URLS:

        print(f"\nExtracting {search_url}")

        page.goto(search_url, timeout=60000, wait_until="domcontentloaded")

        print(page.content())

        accept_consent(page)

        # correct selector
        page.wait_for_selector(
            "article[data-testid='search-result-item']",
            timeout=60000
        )

        page.wait_for_timeout(2000)

        results = extract_page_listings(page)

        print(f"Found {len(results)} listings")

        all_results.extend(results)

    return all_results


# ---------------------------------------
# Main
# ---------------------------------------

def main():

    conn = init_db()

    inserted = 0

    with sync_playwright() as p:

        browser = p.chromium.launch_persistent_context(

            user_data_dir="./playwright_session",

            headless=False,   # critical

            viewport={"width": 1280, "height": 900},

            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/120 Safari/537.36"
            ),

            locale="en-US",

            timezone_id="Europe/Zurich"
        )

        page = browser.new_page()

        block_resources(page)

        results = extract_all_listings(page)

        browser.close()

    print()

    for result in results:

        if not result["url"]:
            continue

        try:

            insert_listing(conn, result)

            inserted += 1

        except Exception as e:

            print("Insert failed:", e)

    conn.commit()

    conn.close()

    print()
    print(f"Inserted {inserted} listings")


# ---------------------------------------

if __name__ == "__main__":

    main()