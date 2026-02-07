def calculate_target_buy_price(
    avg_price: float,
    min_price: float,
    avg_days_on_market: int,
    desired_exit_days: int,
    price_risk_band: str,
    market_depth: str,
    profit_buffer: float = 0.12
):
    """
    Calculates the maximum target buy price for a watch reference.

    Returns:
        target_buy_price (float)
        breakdown (dict) – for dashboard explainability
    """

    # 1. Base exit price (liquidity-adjusted)
    market_depth = market_depth.lower()

    if market_depth == "deep":
        liquidity_discount = 0.03
    elif market_depth == "moderate":
        liquidity_discount = 0.06
    else:  # thin
        liquidity_discount = 0.10

    base_exit_price = avg_price * (1 - liquidity_discount)

    # 2. Time penalty (only if faster than market)
    if desired_exit_days < avg_days_on_market:
        time_penalty_ratio = (
            (avg_days_on_market - desired_exit_days) / avg_days_on_market
        )
    else:
        time_penalty_ratio = 0

    time_penalty_discount = time_penalty_ratio * 0.25
    time_adjusted_price = base_exit_price * (1 - time_penalty_discount)

    # 3. Risk band adjustment
    price_risk_band = price_risk_band.lower()

    if price_risk_band == "low":
        risk_multiplier = 1.00
    elif price_risk_band == "medium":
        risk_multiplier = 0.95
    else:  # high
        risk_multiplier = 0.88

    risk_adjusted_price = time_adjusted_price * risk_multiplier

    # 4. Profit buffer
    target_buy_price = risk_adjusted_price * (1 - profit_buffer)

    # 5. Guardrails
    target_buy_price = min(target_buy_price, avg_price)
    target_buy_price = max(target_buy_price, min_price * 0.95)

    # Round for dealer readability
    target_buy_price = round(target_buy_price, -2)

    # 6. Explainability payload
    breakdown = {
        "avg_price": avg_price,
        "min_price": min_price,
        "base_exit_price": round(base_exit_price, 2),
        "liquidity_discount_pct": liquidity_discount * 100,
        "time_penalty_pct": round(time_penalty_discount * 100, 2),
        "risk_multiplier": risk_multiplier,
        "profit_buffer_pct": profit_buffer * 100,
        "final_target_buy_price": target_buy_price
    }

    return target_buy_price, breakdown
