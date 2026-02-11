import requests
from bs4 import BeautifulSoup
from datetime import date
import re
import time


HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0 Safari/537.36"
    )
}


def fetch_chrono24_listings(brand: str, reference_code: str):
    """
    Fetch public Chrono24 search results for a watch reference.

    Returns a list of dicts:
    {
        price: float,
        days_on_market: int | None,
        snapshot_date: date
    }

    NOTE:
    - Public pages only
    - No login
    - Demo-safe (low frequency)
    """

    query = reference_code.replace(" ", "+")
    url = (
        "https://www.chrono24.com/search/index.htm"
        f"?query={query}&dosearch=true"
    )

    print(f"  🌐 GET {url}")

    response = requests.get(url, headers=HEADERS, timeout=30)
    response.raise_for_status()

    soup = BeautifulSoup(response.text, "html.parser")

    listings = []
    snapshot_date = date.today()

    # Chrono24 listings are rendered as article cards
    cards = soup.find_all("article")

    for card in cards:
        try:
            # -----------------------------
            # Price extraction
            # -----------------------------
            price_tag = card.find(attrs={"data-price": True})
            if not price_tag:
                continue

            price = float(price_tag["data-price"])

            # -----------------------------
            # Days on market (best-effort)
            # -----------------------------
            text = card.get_text(" ", strip=True)

            days_match = re.search(r"(\d+)\s+days", text, re.IGNORECASE)
            days_on_market = int(days_match.group(1)) if days_match else None

            listings.append(
                {
                    "price": price,
                    "days_on_market": days_on_market,
                    "snapshot_date": snapshot_date
                }
            )

        except Exception:
            # Skip malformed cards silently (demo-safe)
            continue

    # Polite pause (important for demo credibility)
    time.sleep(1)

    return listings