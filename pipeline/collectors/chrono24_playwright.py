from playwright.sync_api import sync_playwright
from datetime import date
import re
import time


def fetch_chrono24_listings(reference_code: str):
    url = (
        "https://www.chrono24.com/search/index.htm"
        f"?query={reference_code}&dosearch=true"
    )

    listings = []
    snapshot_date = date.today()

    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=True,
            args=["--disable-blink-features=AutomationControlled"]
        )
        page = browser.new_page()

        page.goto(url, timeout=60000)

        # -------------------------------
        # 1️⃣ Handle cookie consent
        # -------------------------------
        try:
            time.sleep(3)
            buttons = page.locator(
                "button:has-text('Accept'), button:has-text('OK'), button:has-text('Agree')",
                strict=False
            )
            if buttons.count() > 0:
                buttons.first.click(force=True)
                time.sleep(2)
        except Exception:
            pass

        # -------------------------------
        # 2️⃣ Force rendering via scroll
        # -------------------------------
        for _ in range(3):
            page.mouse.wheel(0, 4000)
            time.sleep(1.5)

        # -------------------------------
        # 3️⃣ Extract prices (best-effort)
        # -------------------------------
        price_elements = page.locator("[data-price]")
        count = price_elements.count()

        for i in range(count):
            try:
                price = float(price_elements.nth(i).get_attribute("data-price"))

                parent = price_elements.nth(i).locator("xpath=ancestor::article")
                text = parent.inner_text() if parent.count() else ""

                match = re.search(r"(\d+)\s+days", text, re.IGNORECASE)
                days_on_market = int(match.group(1)) if match else None

                listings.append(
                    {
                        "price": price,
                        "days_on_market": days_on_market,
                        "snapshot_date": snapshot_date
                    }
                )
            except Exception:
                continue

        browser.close()

    return listings