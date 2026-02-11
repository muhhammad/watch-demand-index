from playwright.sync_api import sync_playwright

URL = "https://www.phillips.com/auction/CH080425"

def run():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False, slow_mo=50)
        page = browser.new_page()

        def on_response(response):
            try:
                url = response.url.lower()
                if any(keyword in url for keyword in ["lot", "auction", "sale"]):
                    print("\n--- MATCHED RESPONSE ---")
                    print("URL:", response.url)
                    print("Status:", response.status)
            except:
                pass

        page.on("response", on_response)

        page.goto(URL, timeout=60000)

        # Scroll aggressively
        for _ in range(8):
            page.mouse.wheel(0, 6000)
            page.wait_for_timeout(2000)

        # Wait extra time
        page.wait_for_timeout(20000)

        browser.close()

if __name__ == "__main__":
    run()