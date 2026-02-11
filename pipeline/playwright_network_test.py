from playwright.sync_api import sync_playwright

URL = "https://www.chrono24.com/search/index.htm?query=116500LN&dosearch=true"

def run():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False, slow_mo=50)

        context = browser.new_context()

        # ---------------------------------------------
        # Pre-seed OneTrust consent cookies
        # ---------------------------------------------
        context.add_cookies([
            {
                "name": "OptanonConsent",
                "value": "isIABGlobal=false&datestamp=2026-02-10T00:00:00Z",
                "domain": ".chrono24.com",
                "path": "/",
            },
            {
                "name": "OptanonAlertBoxClosed",
                "value": "true",
                "domain": ".chrono24.com",
                "path": "/",
            },
        ])

        page = context.new_page()

        def on_response(response):
            try:
                if response.request.resource_type == "xhr":
                    url = response.url.lower()
                    if "search" in url or "result" in url or "listing" in url:
                        print("\n--- XHR RESPONSE ---")
                        print("URL:", response.url)
                        print("Status:", response.status)
                        text = response.text()
                        if text and text.startswith("{"):
                            print(text[:800])
            except Exception:
                pass

        page.on("response", on_response)

        page.goto(URL, timeout=60000)

        # Trigger loading
        for _ in range(3):
            page.mouse.wheel(0, 5000)
            page.wait_for_timeout(2000)

        print("Waiting for network activity…")
        page.wait_for_timeout(20000)

        browser.close()

if __name__ == "__main__":
    run()