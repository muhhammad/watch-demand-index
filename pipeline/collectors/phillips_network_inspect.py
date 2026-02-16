from playwright.sync_api import sync_playwright
import json


URL = "https://www.phillips.com/auction/CH080425"


def run():

    with sync_playwright() as p:

        browser = p.chromium.launch(headless=False)
        context = browser.new_context()
        page = context.new_page()


        def handle_response(response):

            url = response.url

            if any(x in url.lower() for x in [
                "auction",
                "lot",
                "search",
                "graphql",
                "api"
            ]):

                try:

                    data = response.text()

                    if "lot" in data.lower():

                        print("\nFOUND DATA SOURCE:")
                        print(url)

                        with open("phillips_api_dump.json", "w") as f:
                            f.write(data)

                except:
                    pass


        page.on("response", handle_response)

        page.goto(URL)

        page.wait_for_timeout(15000)

        browser.close()


run()