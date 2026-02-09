import sys
from pathlib import Path

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
import os

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
# Load data
# -----------------------------
query = """
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
    JOIN watch_references r ON d.reference_id = r.reference_id
    JOIN models m ON r.model_id = m.model_id
    JOIN brands b ON m.brand_id = b.brand_id
    JOIN listings_daily l 
        ON l.reference_id = d.reference_id
    ORDER BY d.sellability_score DESC;
"""

df = pd.read_sql(query, conn)

# -----------------------------
# Sidebar filters
# -----------------------------
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
    value=60
)

# -----------------------------
# Apply filters
# -----------------------------
filtered = df[
    (df["brand_name"].isin(brand_filter)) &
    (df["price_risk_band"].isin(risk_filter)) &
    (df["exit_confidence"].isin(exit_conf_filter)) &
    (df["sellability_score"] >= min_score)
]

# -----------------------------
# Compute Target Buy Price (SAFE, FINAL)
# -----------------------------

filtered = filtered.copy()  # break pandas view

target_prices = []

for _, row in filtered.iterrows():
    price, _ = calculate_target_buy_price(
        avg_price=row["avg_price"],
        min_price=row["min_price"],
        avg_days_on_market=row["avg_days_on_market"],
        desired_exit_days=row["expected_exit_max"],
        price_risk_band=row["price_risk_band"],
        market_depth=row["market_depth"]
    )
    target_prices.append(float(price))

filtered["Target Buy Price"] = target_prices


# -----------------------------
# Dealer-friendly labels
# -----------------------------
def classify(score):
    if score >= 75:
        return "🔥 Flip Fast"
    elif score >= 60:
        return "🟡 Selective Buy"
    else:
        return "🧊 Capital Trap"

filtered["Dealer Signal"] = filtered["sellability_score"].apply(classify)


# -----------------------------
# Main table
# -----------------------------
st.subheader("📊 Current Market Opportunities")

st.dataframe(
    filtered[[
        "Dealer Signal",
        "brand_name",
        "model_name",
        "reference_code",
        "Target Buy Price",
        "sellability_score",
        "exit_confidence",
        "expected_exit_min",
        "expected_exit_max",
        "price_risk_band",
        "market_depth"
    ]],
    use_container_width=True
)


# -----------------------------
# Highlight top pick
# -----------------------------
# -----------------------------
# Highlight top pick
# -----------------------------
st.subheader("🏆 Top Opportunity Right Now")

if not filtered.empty:
    top = filtered.iloc[0]

    col1, col2, col3, col4 = st.columns(4)

    col1.metric("Reference", f"{top['brand_name']} {top['reference_code']}")

    col2.metric(
        "Target Buy Price",
        f"${top['Target Buy Price']:,.0f}"
    )

    col3.metric("Sellability Score", top["sellability_score"])

    col4.metric(
        "Expected Exit (Days)",
        f"{top['expected_exit_min']} – {top['expected_exit_max']}"
    )

    # ---- Market vs Target delta (ADD HERE) ----
    delta = top["avg_price"] - top["Target Buy Price"]

    st.caption(
        f"Market avg: ${top['avg_price']:,.0f} "
        f"({ '+' if delta > 0 else '' }${delta:,.0f} vs target)"
    )

    if delta > 0:
        st.caption(f"🟢 Market trades ${delta:,.0f} above target — negotiable")
    else:
        st.caption(f"🔴 Market trades ${abs(delta):,.0f} below target — overpriced")


    st.success(
        f"**Dealer Insight:** High liquidity with {top['market_depth'].lower()} market depth "
        f"and {top['exit_confidence'].lower()} exit confidence."
    )
else:
    st.warning("No watches match the current filter criteria.")
