from collectors.chrono24_playwright import fetch_chrono24_listings

listings = fetch_chrono24_listings("116500LN")

print(f"Found {len(listings)} listings")

for l in listings[:5]:
    print(l)