# ⌚ Watch Demand Index – Dealer Dashboard

## Overview

The **Watch Demand Index** is a dealer-focused dashboard designed to provide **actionable insights** for professional luxury watch dealers. It helps dealers understand:

- Which watches to consider buying  
- How fast they can realistically exit  
- The maximum price they should pay to ensure profitable and low-risk trades  

The dashboard combines **market intelligence** with **historical listing data** to produce transparent, explainable metrics that support real-world decision-making.

---

## Features

1. **Dealer Signals**
   - Assigns watches into categories based on **sellability score**:
     - `🔥 Flip Fast` – Highly liquid, strong exit confidence
     - `🟡 Selective Buy` – Moderate liquidity, acceptable risk
     - `🧊 Capital Trap` – Low liquidity or high risk

2. **Target Buy Price**
   - Computes a **maximum safe buy price** per watch reference based on:
     - Market prices (`avg_price`, `min_price`)  
     - Market depth (`Deep`, `Medium`, `Thin`)  
     - Price risk band (`Low`, `Medium`, `High`)  
     - Average days on market vs desired exit window  
     - Dealer profit buffer (default 12%)

3. **Market Delta**
   - Shows the difference between current market average price and the **Target Buy Price**.  
   - Quickly highlights **overpriced vs good buy opportunities**.

4. **Expected Exit Window**
   - Displays `expected_exit_min` – `expected_exit_max` in days to guide dealer timing.

5. **Filters**
   - By brand, price risk, exit confidence, and minimum sellability score.

---

## How It Works – Data Logic

### 1. Data Sources
The dashboard uses the following tables from a PostgreSQL database:

| Table | Purpose |
|-------|--------|
| `brands` | Watch brand information |
| `models` | Watch models linked to brands |
| `watch_references` | Specific watch references (SKU-level) |
| `listings_daily` | Daily listing data including `avg_price`, `min_price`, `avg_days_on_market` |
| `demand_scores` | Derived metrics: `sellability_score`, `exit_confidence`, `price_risk_band`, `market_depth` |

---

### 2. Sellability Score
- Each watch reference receives a **score (0-100)** that measures:
  - Historical market activity  
  - Liquidity  
  - Speed of previous exits  

**Dealer Signal mapping:**

| Score | Signal |
|-------|--------|
| 75+   | 🔥 Flip Fast |
| 60-74 | 🟡 Selective Buy |
| <60   | 🧊 Capital Trap |

---

### 3. Target Buy Price Logic

The Target Buy Price is calculated with **a conservative approach** to ensure dealers do not overpay:

1. **Base Exit Price**
   - Start from `avg_price` adjusted for **market liquidity**:
     - `Deep` → 3% discount  
     - `Medium` → 6% discount  
     - `Thin` → 10% discount  

2. **Time Penalty**
   - If a dealer wants to exit faster than the historical `avg_days_on_market`, a **time penalty** is applied:
     ```
     time_penalty_discount = ((avg_days_on_market - desired_exit_days) / avg_days_on_market) * 0.25
     ```
   - Ensures shorter exit windows reduce expected price.

3. **Risk Adjustment**
   - Price is adjusted based on `price_risk_band`:
     - Low → 1.0x (no adjustment)  
     - Medium → 0.95x  
     - High → 0.88x  

4. **Profit Buffer**
   - Default 12% profit buffer applied to ensure dealers maintain a safe margin.

5. **Guardrails**
   - The final Target Buy Price is **never above `avg_price`**  
   - The price is **never below 95% of `min_price`** to avoid unrealistic undervaluation

**Formula Summary:**

