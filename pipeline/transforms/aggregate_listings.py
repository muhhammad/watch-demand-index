import statistics

def aggregate_listings(listings):
    prices = [l["price"] for l in listings if l["price"] and l["price"] > 0]
    days = [l["days_on_market"] for l in listings if l["days_on_market"] is not None]

    if not prices:
        return None

    return {
        "avg_price": round(statistics.mean(prices), 0),
        "min_price": round(min(prices), 0),
        "listing_count": len(prices),
        "avg_days_on_market": round(statistics.mean(days), 0) if days else None
    }