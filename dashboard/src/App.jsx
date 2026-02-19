import { useEffect, useState } from "react"

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
]

const formatCurrency = (value) =>
  "CHF " + value.toLocaleString()

const formatMillions = (value) =>
  "CHF " + (value / 1000000).toFixed(2) + "M"

function App() {

  const [lots, setLots] = useState([])
  const [metrics, setMetrics] = useState(null)
  const [brandIndex, setBrandIndex] = useState([])

  useEffect(() => {

    fetch("http://127.0.0.1:8000/auction_lots")
      .then(res => res.json())
      .then(data => setLots(data))

    fetch("http://127.0.0.1:8000/metrics")
      .then(res => res.json())
      .then(data => setMetrics(data))

    fetch("http://127.0.0.1:8000/brand_index")
      .then(res => res.json())
      .then(data => setBrandIndex(data))

  }, [])

  return (

    <div style={{
      padding: "30px",
      background: "#f3f4f6",
      minHeight: "100vh",
      color: "#111827"
    }}>

      <h1 style={{ marginBottom: "20px" }}>
        Watch Demand Index — Auction Results
      </h1>

      {/* METRICS */}

      {metrics && (

        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
          gap: "20px",
          marginBottom: "30px"
        }}>

          <Card title="Total Lots" value={metrics.total_lots} />

          <Card
            title="Average Price"
            value={formatCurrency(Math.round(metrics.avg_price))}
          />

          <Card
            title="Total Value"
            value={formatCurrency(Math.round(metrics.total_value))}
          />

          <Card title="Top Brand" value={metrics.top_brand} />

        </div>

      )}

      {/* BAR CHART */}

      <ChartCard title="Watch Demand Index (Total Value by Brand)">

        <ResponsiveContainer width="100%" height={400}>

          <BarChart
            data={brandIndex}
            margin={{ top: 20, right: 30, left: 20, bottom: 80 }}
          >

            <CartesianGrid strokeDasharray="3 3" />

            <XAxis
              dataKey="brand"
              angle={-30}
              textAnchor="end"
              height={80}
            />

            <YAxis tickFormatter={formatMillions} />

            <Tooltip formatter={formatCurrency} />

            <Bar
              dataKey="total_value"
              radius={[6, 6, 0, 0]}
              animationDuration={800}
            >

              {brandIndex.map((entry, index) => (

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
              data={brandIndex}
              dataKey="total_value"
              nameKey="brand"
              cx="50%"
              cy="50%"
              outerRadius={160}
              innerRadius={60}
              paddingAngle={2}
              label={({ percent }) =>
                `${(percent * 100).toFixed(1)}%`
              }
            >

              {brandIndex.map((entry, index) => (

                <Cell
                  key={entry.brand}
                  fill={COLORS[index % COLORS.length]}
                />

              ))}

            </Pie>

            <Tooltip formatter={formatCurrency} />

            <Legend verticalAlign="bottom" />

          </PieChart>

        </ResponsiveContainer>

      </ChartCard>


      {/* BRAND TABLE */}

      <ChartCard title="Brand Demand Index">

        <table style={tableStyle}>

          <thead>

            <tr>

              <th style={thStyle}>Rank</th>
              <th style={thStyle}>Brand</th>
              <th style={thStyle}>Lots</th>
              <th style={thStyle}>Avg Price</th>
              <th style={thStyle}>Total Value</th>
              <th style={thStyle}>Demand Index</th>

            </tr>

          </thead>

          <tbody>

            {brandIndex.map((brand, i) => (

              <tr key={brand.brand}>

                <td style={tdStyle}>{i + 1}</td>

                <td style={tdStyle}>{brand.brand}</td>

                <td style={tdStyle}>{brand.total_lots}</td>

                <td style={tdStyle}>
                  {formatCurrency(Math.round(brand.avg_price))}
                </td>

                <td style={tdStyle}>
                  {formatCurrency(Math.round(brand.total_value))}
                </td>

                <td style={tdStyle}>
                  <b>{brand.demand_index}</b>
                </td>

              </tr>

            ))}

          </tbody>

        </table>

      </ChartCard>


      {/* LOT TABLE */}

      <ChartCard title="Auction Lots">

        <table style={tableStyle}>

          <thead>

            <tr>

              <th style={thStyle}>Auction</th>
              <th style={thStyle}>Lot</th>
              <th style={thStyle}>Brand</th>
              <th style={thStyle}>Reference</th>
              <th style={thStyle}>Model</th>
              <th style={thStyle}>Price</th>
              <th style={thStyle}>Date</th>

            </tr>

          </thead>

          <tbody>

            {lots.map(lot => (

              <tr key={lot.id}>

                <td style={tdStyle}>{lot.auction_house}</td>

                <td style={tdStyle}>{lot.lot}</td>

                <td style={tdStyle}>{lot.brand}</td>

                <td style={tdStyle}>{lot.reference_code}</td>

                <td style={tdStyle}>{lot.model}</td>

                <td style={tdStyle}>
                  {formatCurrency(lot.price)}
                </td>

                <td style={tdStyle}>{lot.auction_date}</td>

              </tr>

            ))}

          </tbody>

        </table>

      </ChartCard>

    </div>

  )

}


/* COMPONENTS */

function Card({ title, value }) {

  return (

    <div style={cardStyle}>

      <div style={{ fontSize: "14px", color: "#6b7280" }}>
        {title}
      </div>

      <div style={{
        fontSize: "24px",
        fontWeight: "bold",
        marginTop: "5px"
      }}>
        {value}
      </div>

    </div>

  )

}

function ChartCard({ title, children }) {

  return (

    <div style={chartCardStyle}>

      <h2 style={{ marginBottom: "15px" }}>
        {title}
      </h2>

      {children}

    </div>

  )

}


/* STYLES */

const cardStyle = {

  background: "white",
  padding: "20px",
  borderRadius: "10px",
  boxShadow: "0 2px 6px rgba(0,0,0,0.1)"

}

const chartCardStyle = {

  background: "white",
  padding: "20px",
  borderRadius: "10px",
  boxShadow: "0 2px 6px rgba(0,0,0,0.1)",
  marginBottom: "30px"

}

const tableStyle = {

  width: "100%",
  borderCollapse: "collapse"

}

const thStyle = {

  textAlign: "left",
  padding: "10px",
  borderBottom: "2px solid #e5e7eb"

}

const tdStyle = {

  padding: "10px",
  borderBottom: "1px solid #e5e7eb"

}


export default App