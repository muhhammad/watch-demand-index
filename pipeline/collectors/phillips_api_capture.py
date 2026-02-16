from playwright.sync_api import sync_playwright

URL = "https://www.phillips.com/auction/CH080425"


def run():

    print("Capturing Phillips API responses...")

    with sync_playwright() as p:

        browser = p.chromium.launch(headless=False)

        context = browser.new_context()

        page = context.new_page()

        def handle_response(response):

            url = response.url

            if any(x in url.lower() for x in [
                "auction",
                "lot",
                "api",
                "sync",
                "graphql"
            ]):

                print("\nAPI URL FOUND:")
                print(url)

                try:
                    data = response.json()

                    if isinstance(data, dict) and len(str(data)) > 500:
                        print("Contains structured data")

                except:
                    pass

        page.on("response", handle_response)

        page.goto(URL)

        page.wait_for_timeout(10000)

        browser.close()


run()