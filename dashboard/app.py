import sys
from pathlib import Path
import os

# Allow imports from project root
ROOT_DIR = Path(__file__).resolve().parents[1]
sys.path.append(str(ROOT_DIR))

import pandas as pd
import psycopg2
import streamlit as st

from analytics.pricing import calculate_target_buy_price


# -----------------------------
# Page config
# -----------------------------
st.set_page_config(
    page_title="Watch Demand Index",
    layout="wide"
)

st.title("⌚ Watch Demand Index – Dealer Dashboard")
st.caption("Liquidity & exit intelligence for professional watch dealers")


# -----------------------------
# Database connection
# -----------------------------
@st.cache_resource
def get_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "postgres"),
        port=int(os.getenv("DB_PORT", 5432)),
        database=os.getenv("DB_NAME", "watchdb"),
        user=os.getenv("DB_USER", "watchuser"),
        password=os.getenv("DB_PASSWORD", "watchpass")
    )

conn = get_connection()


# -----------------------------
# Load data (LATEST SNAPSHOT)
# -----------------------------
query = """
WITH latest_snapshot AS (
    SELECT MAX(snapshot_date) AS snapshot_date
    FROM demand_scores
)
SELECT
    d.snapshot_date,
    b.brand_name,
    m.model_name,
    r.reference_code,
    d.sellability_score,
    d.exit_confidence,
    d.expected_exit_min,
    d.expected_exit_max,
    d.price_risk_band,
    d.market_depth,
    l.avg_price,
    l.min_price,
    l.avg_days_on_market
FROM demand_scores d
JOIN latest_snapshot ls
  ON d.snapshot_date = ls.snapshot_date
JOIN watch_references r
  ON d.reference_id = r.reference_id
JOIN models m
  ON r.model_id = m.model_id
JOIN brands b
  ON m.brand_id = b.brand_id
JOIN listings_daily l
  ON l.reference_id = d.reference_id
 AND l.snapshot_date = d.snapshot_date
ORDER BY d.sellability_score DESC;
"""

df = pd.read_sql(query, conn)


# ============================================================
# SIDEBAR
# ============================================================

# -----------------------------
# Dealer profile (TOP, isolated)
# -----------------------------
with st.sidebar.expander("🧮 Dealer Profile", expanded=True):
    dealer_profile = st.selectbox(
        "Trading style",
        ["Conservative", "Balanced", "Aggressive"]
    )

PROFILE_CONFIG = {
    "Conservative": {
        "min_profit_per_day": 800,
        "min_sellability": 70,
        "require_high_exit": True
    },
    "Balanced": {
        "min_profit_per_day": 500,
        "min_sellability": 60,
        "require_high_exit": False
    },
    "Aggressive": {
        "min_profit_per_day": 200,
        "min_sellability": 50,
        "require_high_exit": False
    }
}

profile = PROFILE_CONFIG[dealer_profile]


# -----------------------------
# Alerts (separate section)
# -----------------------------
with st.sidebar.expander("🔔 Alerts", expanded=True):
    alert_enabled = st.checkbox(
        "Enable BUY NOW alerts",
        value=True
    )

    alert_min_profit_per_day = st.number_input(
        "Minimum Profit / Day ($)",
        min_value=0,
        value=profile["min_profit_per_day"],
        step=100
    )


# -----------------------------
# Filters (clearly separated)
# -----------------------------
st.sidebar.markdown("---")
st.sidebar.header("🔎 Filters")

brand_filter = st.sidebar.multiselect(
    "Brand",
    options=sorted(df["brand_name"].unique()),
    default=list(df["brand_name"].unique())
)

risk_filter = st.sidebar.multiselect(
    "Price Risk",
    options=sorted(df["price_risk_band"].unique()),
    default=list(df["price_risk_band"].unique())
)

exit_conf_filter = st.sidebar.multiselect(
    "Exit Confidence",
    options=sorted(df["exit_confidence"].unique()),
    default=list(df["exit_confidence"].unique())
)

min_score = st.sidebar.slider(
    "Minimum Sellability Score",
    min_value=0,
    max_value=100,
    value=profile["min_sellability"]
)


# ============================================================
# MAIN LOGIC
# ============================================================

# -----------------------------
# Apply filters
# -----------------------------
filtered = df[
    (df["brand_name"].isin(brand_filter)) &
    (df["price_risk_band"].isin(risk_filter)) &
    (df["exit_confidence"].isin(exit_conf_filter)) &
    (df["sellability_score"] >= min_score)
].copy()


# -----------------------------
# Compute pricing, profit/day, signal
# -----------------------------
target_prices = []
profit_per_day_list = []
deal_signal_list = []

for _, row in filtered.iterrows():
    target_price, _ = calculate_target_buy_price(
        avg_price=row["avg_price"],
        min_price=row["min_price"],
        avg_days_on_market=row["avg_days_on_market"],
        desired_exit_days=row["expected_exit_max"],
        price_risk_band=row["price_risk_band"],
        market_depth=row["market_depth"]
    )

    delta = row["avg_price"] - target_price
    days_locked = max(row["expected_exit_max"], 1)
    profit_per_day = delta / days_locked

    if (
        profit_per_day >= profile["min_profit_per_day"]
        and delta > 0
        and (not profile["require_high_exit"] or row["exit_confidence"] == "High")
    ):
        signal = "🟢 BUY NOW"
    elif profit_per_day > 0 and row["market_depth"] in ["Deep", "Moderate"]:
        signal = "🟡 NEGOTIATE"
    else:
        signal = "🔴 AVOID"

    target_prices.append(round(target_price, 0))
    profit_per_day_list.append(round(profit_per_day, 0))
    deal_signal_list.append(signal)

filtered["Target Buy Price"] = target_prices
filtered["Profit / Day"] = profit_per_day_list
filtered["Deal Signal"] = deal_signal_list

filtered = filtered.sort_values("Profit / Day", ascending=False)


# ============================================================
# ALERTS (TOP OF PAGE)
# ============================================================
alerts = filtered[
    (filtered["Deal Signal"] == "🟢 BUY NOW") &
    (filtered["Profit / Day"] >= alert_min_profit_per_day)
]

if alert_enabled and not alerts.empty:
    st.error(f"🚨 BUY NOW ALERTS – {dealer_profile} Profile")

    for _, row in alerts.iterrows():
        st.markdown(
            f"""
            **{row['brand_name']} {row['reference_code']}**  
            💰 Profit / Day: **${row['Profit / Day']:,.0f}**  
            ⏱ Expected Exit: {row['expected_exit_min']}–{row['expected_exit_max']} days  
            📈 Sellability Score: {row['sellability_score']}
            """
        )
else:
    st.info("No BUY NOW alerts at the moment.")


# ============================================================
# MAIN TABLE
# ============================================================
st.subheader("📊 Current Market Opportunities")

st.dataframe(
    filtered[[
        "Deal Signal",
        "brand_name",
        "model_name",
        "reference_code",
        "Target Buy Price",
        "Profit / Day",
        "sellability_score",
        "exit_confidence",
        "expected_exit_min",
        "expected_exit_max",
        "price_risk_band",
        "market_depth"
    ]],
    use_container_width=True
)


# ============================================================
# TOP OPPORTUNITY
# ============================================================
st.subheader("🏆 Top Opportunity Right Now")

if not filtered.empty:
    top = filtered.iloc[0]

    target_price, breakdown = calculate_target_buy_price(
        avg_price=top["avg_price"],
        min_price=top["min_price"],
        avg_days_on_market=top["avg_days_on_market"],
        desired_exit_days=top["expected_exit_max"],
        price_risk_band=top["price_risk_band"],
        market_depth=top["market_depth"]
    )

    delta = top["avg_price"] - target_price
    profit_per_day = delta / max(top["expected_exit_max"], 1)

    col1, col2, col3, col4, col5 = st.columns(5)

    col1.metric("Reference", f"{top['brand_name']} {top['reference_code']}")
    col2.metric("Target Buy Price", f"${target_price:,.0f}")
    col3.metric("Sellability Score", top["sellability_score"])
    col4.metric("Expected Exit (Days)", f"{top['expected_exit_min']} – {top['expected_exit_max']}")
    col5.metric("Profit / Day", f"${profit_per_day:,.0f}")

    st.markdown(f"## {top['Deal Signal']}")

    with st.expander("🔍 Why this target buy price?"):
        for k, v in breakdown.items():
            if isinstance(v, (int, float)):
                st.write(f"**{k}:** ${v:,.0f}")
            else:
                st.write(f"**{k}:** {v}")

else:
    st.warning("No watches match the current filter criteria.")
