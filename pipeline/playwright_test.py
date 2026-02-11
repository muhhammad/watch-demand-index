from playwright.sync_api import sync_playwright

URL = "https://www.chrono24.com/search/index.htm?query=116500LN&dosearch=true"

with sync_playwright() as p:
    browser = p.chromium.launch(headless=False)  # IMPORTANT: visible browser
    page = browser.new_page()

    print("Opening page...")
    page.goto(URL, timeout=60000)

    print("Waiting for content...")
    page.wait_for_timeout(5000)  # let JS render

    print("Page title:", page.title())

    browser.close()