"""
Chrono24 listing collector.

Uses Playwright to scrape live dealer listings from Chrono24 for a given
watch reference code and returns normalised price + days-on-market data
for the pipeline's daily aggregation step.
"""
import logging
import re
import time
from typing import Optional

from playwright.sync_api import sync_playwright, TimeoutError as PWTimeout

logger = logging.getLogger(__name__)

_SEARCH_URL = "https://www.chrono24.com/search/index.htm?query={query}&dosearch=true&searchexplain=1&showpage=1"
_PAGE_TIMEOUT = 30_000
_RETRY_DELAY = 3


def fetch_chrono24_listings(api_key: str, reference_code: str) -> list[dict]:
    query = reference_code.replace("/", " ").strip()
    url   = _SEARCH_URL.format(query=query)

    for attempt in range(1, 4):
        try:
            listings = _scrape(url, reference_code)
            logger.info("Chrono24 [%s]: %d listings found (attempt %d)", reference_code, len(listings), attempt)
            return listings
        except Exception as exc:
            logger.warning("Chrono24 [%s] attempt %d failed: %s", reference_code, attempt, exc)
            if attempt < 3:
                time.sleep(_RETRY_DELAY * attempt)

    logger.error("Chrono24 [%s]: all attempts failed, returning empty list", reference_code)
    return []


def _scrape(url: str, reference_code: str) -> list[dict]:
    with sync_playwright() as pw:
        browser = pw.chromium.launch(headless=True, args=["--no-sandbox", "--disable-dev-shm-usage"])
        context = browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
            ),
            locale="en-US",
            viewport={"width": 1280, "height": 800},
        )
        page = context.new_page()
        try:
            page.goto(url, wait_until="domcontentloaded", timeout=_PAGE_TIMEOUT)
            _dismiss_cookie_banner(page)
            try:
                page.wait_for_selector(
                    "article.article-item, .js-article-item, [data-article-id]",
                    timeout=_PAGE_TIMEOUT,
                )
            except PWTimeout:
                logger.warning("No article cards found for %s", reference_code)
                return []
            listings = _extract_listings(page)
        finally:
            browser.close()
    return listings


def _dismiss_cookie_banner(page) -> None:
    try:
        page.locator(
            "button:has-text('Accept'), button:has-text('accept all'), "
            "[id*='accept'], [class*='accept-all']"
        ).first.click(timeout=4_000)
    except Exception:
        pass


def _extract_listings(page) -> list[dict]:
    cards = []
    for sel in ["article.article-item", ".js-article-item", "[data-article-id]", ".search-result-item"]:
        cards = page.query_selector_all(sel)
        if cards:
            break

    if not cards:
        logger.warning("Could not locate listing cards on page")
        return []

    listings = []
    for card in cards[:50]:
        price = _extract_price(card)
        days  = _extract_days(card)
        if price is None:
            continue
        listings.append({"price": price, "currency": "CHF", "days_on_market": days if days is not None else 30})
    return listings


def _extract_price(card) -> Optional[float]:
    for sel in [".rsp-price", ".text-xlarge.text-bold", "[class*='price']", ".price"]:
        el = card.query_selector(sel)
        if el:
            price = _parse_number(el.inner_text().strip())
            if price and price > 100:
                return price
    return None


def _extract_days(card) -> Optional[int]:
    for sel in [".text-muted", "[class*='age']", "[class*='date']", ".listing-date"]:
        for el in card.query_selector_all(sel):
            days = _parse_age_text(el.inner_text().strip().lower())
            if days is not None:
                return days
    return None


def _parse_number(text: str) -> Optional[float]:
    cleaned = re.sub(r"[^\d.,]", "", text).replace(",", "")
    if "." not in cleaned and "," in text:
        cleaned = cleaned.replace(",", ".")
    try:
        return float(cleaned)
    except ValueError:
        return None


def _parse_age_text(text: str) -> Optional[int]:
    if "today" in text or "just" in text:
        return 0
    if "yesterday" in text:
        return 1
    match = re.search(r"(\d+)\s*(day|week|month|year)", text)
    if not match:
        return None
    n, unit = int(match.group(1)), match.group(2)
    return {"day": n, "week": n * 7, "month": n * 30, "year": n * 365}.get(unit)
