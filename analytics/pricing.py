def calculate_target_buy_price(
    avg_price,
    min_price,
    avg_days_on_market,
    desired_exit_days,
    price_risk_band,
    market_depth,
    profit_buffer=0.12
):
    breakdown = {}

    # 1. Market depth adjustment
    depth_discount_map = {
        "Deep": 0.03,
        "Moderate": 0.06,
        "Thin": 0.10
    }
    depth_discount = depth_discount_map.get(market_depth, 0.05)
    depth_adjusted_price = avg_price * (1 - depth_discount)

    breakdown["Market depth discount"] = f"-{int(depth_discount * 100)}%"
    breakdown["After depth adjustment"] = depth_adjusted_price

    # 2. Time pressure adjustment
    if avg_days_on_market and desired_exit_days < avg_days_on_market:
        time_penalty = ((avg_days_on_market - desired_exit_days) / avg_days_on_market) * 0.25
    else:
        time_penalty = 0

    time_adjusted_price = depth_adjusted_price * (1 - time_penalty)

    breakdown["Time pressure discount"] = f"-{int(time_penalty * 100)}%"
    breakdown["After time adjustment"] = time_adjusted_price

    # 3. Risk adjustment
    risk_multiplier_map = {
        "Low": 1.0,
        "Medium": 0.95,
        "High": 0.88
    }
    risk_multiplier = risk_multiplier_map.get(price_risk_band, 0.95)

    risk_adjusted_price = time_adjusted_price * risk_multiplier

    breakdown["Risk adjustment"] = f"x{risk_multiplier}"
    breakdown["After risk adjustment"] = risk_adjusted_price

    # 4. Profit buffer
    final_price = risk_adjusted_price * (1 - profit_buffer)

    breakdown["Dealer profit buffer"] = f"-{int(profit_buffer * 100)}%"
    breakdown["Final target buy price"] = final_price

    # Guardrails
    final_price = min(avg_price, max(min_price * 0.95, final_price))

    breakdown["Guardrails applied"] = "Yes"

    return round(final_price, 0), breakdown
