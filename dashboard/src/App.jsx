import { useEffect, useState, useMemo } from "react"

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend
} from "recharts"

const COLORS = [
  "#2563eb",
  "#16a34a",
  "#dc2626",
  "#ca8a04",
  "#9333ea",
  "#0891b2",
  "#f97316",
  "#14b8a6",
  "#be123c",
  "#4338ca",
]

const formatCurrency = (value) =>
  "CHF " + value.toLocaleString()

const formatMillions = (value) =>
  "CHF " + (value / 1000000).toFixed(2) + "M"


function App() {

  const [lots, setLots] = useState([])
  const [metrics, setMetrics] = useState(null)
  const [brandIndex, setBrandIndex] = useState([])

  const [selectedBrand, setSelectedBrand] = useState("ALL")

  const [showAllLots, setShowAllLots] = useState(false)
  const [showAllBrands, setShowAllBrands] = useState(false)


  useEffect(() => {

    const API_BASE = "https://web-production-a02be.up.railway.app"

    fetch(`${API_BASE}/auction_lots`)
      .then(res => res.json())
      .then(setLots)

    fetch(`${API_BASE}/metrics`)
      .then(res => res.json())
      .then(setMetrics)

    fetch(`${API_BASE}/brand_index`)
      .then(res => res.json())
      .then(setBrandIndex)

  }, [])


  /* FILTERED DATA */

  const filteredLots = useMemo(() => {

    if (selectedBrand === "ALL")
      return lots

    return lots.filter(l =>
      l.brand?.toLowerCase() === selectedBrand.toLowerCase()
    )

  }, [lots, selectedBrand])


  const filteredBrandIndex = useMemo(() => {

    if (selectedBrand === "ALL")
      return brandIndex

    return brandIndex.filter(b =>
      b.brand?.toLowerCase() === selectedBrand.toLowerCase()
    )

  }, [brandIndex, selectedBrand])


  const visibleLots =
    showAllLots ? filteredLots : filteredLots.slice(0, 10)

  const visibleBrands =
    showAllBrands
      ? filteredBrandIndex
      : filteredBrandIndex.slice(0, 5)



  /* FILTERED METRICS */

  const filteredMetrics = useMemo(() => {

    if (selectedBrand === "ALL")
      return metrics

    const totalLots = filteredLots.length

    const totalValue =
      filteredLots.reduce((a, b) => a + (b.price || 0), 0)

    const avgPrice =
      totalLots > 0 ? totalValue / totalLots : 0

    return {
      total_lots: totalLots,
      total_value: totalValue,
      avg_price: avgPrice,
      top_brand: selectedBrand
    }

  }, [metrics, filteredLots, selectedBrand])



  return (

    <div style={{
      padding: "30px",
      background: "#f3f4f6",
      minHeight: "100vh",
      color: "#111"
    }}>


      <h1>Watch Demand Index — Auction Results</h1>


      {/* BRAND FILTER DROPDOWN */}

      <div style={{ marginBottom: "20px" }}>

        <label style={{ fontWeight: "bold" }}>
          Filter by Brand:
        </label>

        <select
          value={selectedBrand}
          onChange={(e) =>
            setSelectedBrand(e.target.value)
          }
          style={{
            marginLeft: "10px",
            padding: "6px",
            fontSize: "14px"
          }}
        >

          <option value="ALL">All Brands</option>

          {brandIndex.map(b => (
            <option key={b.brand} value={b.brand}>
              {b.brand}
            </option>
          ))}

        </select>

      </div>



      {/* METRICS */}

      {filteredMetrics && (

        <div style={{
          display: "flex",
          gap: "20px",
          marginBottom: "30px"
        }}>

          <Card
            title="Total Lots"
            value={filteredMetrics.total_lots}
          />

          <Card
            title="Average Price"
            value={formatCurrency(
              Math.round(filteredMetrics.avg_price)
            )}
          />

          <Card
            title="Total Value"
            value={formatCurrency(
              Math.round(filteredMetrics.total_value)
            )}
          />

          <Card
            title="Selected Brand"
            value={selectedBrand}
          />

        </div>

      )}



      {/* BRAND TABLE */}

      <ChartCard title="Brand Demand Index">

        <table border="1" cellPadding="8" width="100%">

          <thead>
            <tr>
              <th>Rank</th>
              <th>Brand</th>
              <th>Total Lots</th>
              <th>Average Price</th>
              <th>Total Value</th>
              <th>Demand Index</th>
            </tr>
          </thead>

          <tbody>

            {visibleBrands.map((brand, i) => (

              <tr key={brand.brand}>
                <td>{i + 1}</td>
                <td>{brand.brand}</td>
                <td>{brand.total_lots}</td>
                <td>{formatCurrency(Math.round(brand.avg_price))}</td>
                <td>{formatCurrency(Math.round(brand.total_value))}</td>
                <td><b>{brand.demand_index}</b></td>
              </tr>

            ))}

          </tbody>

        </table>

        {filteredBrandIndex.length > 5 && (
          <button
            onClick={() => setShowAllBrands(!showAllBrands)}
            style={buttonStyle}>
            {showAllBrands ? "Show Less" : "Show All Brands"}
          </button>
        )}

      </ChartCard>



      {/* BAR CHART — TOTAL VALUE */}

      <ChartCard title="Watch Demand Index (Total Value by Brand)">

        <ResponsiveContainer width="100%" height={500}>

          <BarChart
            data={filteredBrandIndex}
            margin={{
              top: 20,
              right: 30,
              left: 20,
              bottom: 50
            }}
          >

            <CartesianGrid strokeDasharray="3 3" />

            <XAxis
              dataKey="brand"
              interval={0}
              angle={-35}
              textAnchor="end"
              height={160}
              tickMargin={25}
              tick={{ fontSize: 12 }}
            />

            <YAxis tickFormatter={formatMillions} />

            <Tooltip formatter={(v) => formatCurrency(v)} />

            <Bar dataKey="total_value" radius={[6,6,0,0]}>

              {filteredBrandIndex.map((entry, index) => (
                <Cell
                  key={entry.brand}
                  fill={COLORS[index % COLORS.length]}
                />
              ))}

            </Bar>

          </BarChart>

        </ResponsiveContainer>

      </ChartCard>



      {/* BAR CHART — AVG PRICE */}

      <ChartCard title="Average Price by Brand">

        <ResponsiveContainer width="100%" height={500}>

          <BarChart
            data={filteredBrandIndex}
            margin={{
              top: 20,
              right: 30,
              left: 20,
              bottom: 50
            }}
          >

            <CartesianGrid strokeDasharray="3 3" />

            <XAxis
              dataKey="brand"
              interval={0}
              angle={-35}
              textAnchor="end"
              height={160}
              tickMargin={25}
              tick={{ fontSize: 12 }}
            />

            <YAxis tickFormatter={formatMillions} />

            <Tooltip formatter={(v) => formatCurrency(v)} />

            <Bar dataKey="avg_price">

              {filteredBrandIndex.map((entry, index) => (
                <Cell
                  key={entry.brand}
                  fill={COLORS[index % COLORS.length]}
                />
              ))}

            </Bar>

          </BarChart>

        </ResponsiveContainer>

      </ChartCard>



      {/* PIE CHART */}

      <ChartCard title="Market Share by Brand">

        <ResponsiveContainer width="100%" height={500}>

          <PieChart>

            <Pie
              data={filteredBrandIndex}
              dataKey="total_value"
              nameKey="brand"
              cx="50%"
              cy="45%"
              outerRadius={140}
              innerRadius={60}
              paddingAngle={2}
            >

              {filteredBrandIndex.map((entry, index) => (
                <Cell
                  key={entry.brand}
                  fill={COLORS[index % COLORS.length]}
                />
              ))}

            </Pie>

            <Tooltip formatter={(v) => formatCurrency(v)} />

            <Legend
              verticalAlign="bottom"
              align="center"
              layout="horizontal"
              wrapperStyle={{
                maxHeight: "120px",
                overflowY: "auto",
                fontSize: "12px"
              }}
            />

          </PieChart>

        </ResponsiveContainer>

      </ChartCard>



      {/* LOT TABLE */}

      <ChartCard title="Auction Lots">

        <table border="1" cellPadding="8" width="100%">

          <thead>
            <tr>
              <th>Auction</th>
              <th>Lot</th>
              <th>Brand</th>
              <th>Reference</th>
              <th>Model</th>
              <th>Price</th>
              <th>Date</th>
            </tr>
          </thead>

          <tbody>

            {visibleLots.map(lot => (

              <tr key={lot.id}>
                <td>{lot.auction_house}</td>
                <td>{lot.lot}</td>
                <td>{lot.brand}</td>
                <td>{lot.reference_code}</td>
                <td>{lot.model}</td>
                <td>{formatCurrency(lot.price)}</td>
                <td>{lot.auction_date}</td>
              </tr>

            ))}

          </tbody>

        </table>

        {filteredLots.length > 10 && (
          <button
            onClick={() => setShowAllLots(!showAllLots)}
            style={buttonStyle}
          >
            {showAllLots ? "Show Less" : "Show All Lots"}
          </button>
        )}

      </ChartCard>


    </div>

  )
}



const buttonStyle = {
  marginTop: "10px",
  padding: "8px 16px",
  borderRadius: "6px",
  border: "none",
  background: "#2563eb",
  color: "white",
  cursor: "pointer"
}


function ChartCard({ title, children }) {

  return (
    <div style={{
      background: "white",
      padding: "20px",
      borderRadius: "10px",
      marginBottom: "30px",
      boxShadow: "0 2px 6px rgba(0,0,0,0.1)"
    }}>
      <h2>{title}</h2>
      {children}
    </div>
  )
}


function Card({ title, value }) {

  return (
    <div style={{
      background: "white",
      padding: "15px",
      borderRadius: "10px",
      minWidth: "180px",
      boxShadow: "0 2px 6px rgba(0,0,0,0.1)"
    }}>
      <h3>{title}</h3>
      <p style={{
        fontSize: "20px",
        fontWeight: "bold"
      }}>
        {value}
      </p>
    </div>
  )
}


export default App