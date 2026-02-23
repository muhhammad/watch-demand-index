import { useEffect, useState } from "react"
import {
  BarChart, Bar, XAxis, YAxis, Tooltip,
  CartesianGrid, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from "recharts"


// =====================================
// CONFIG
// =====================================

// API SERVICE URL (NOT dashboard URL)
const API_BASE = "https://web-production-a02be.up.railway.app"

const COLORS = [
  "#2563eb", "#16a34a", "#dc2626", "#ca8a04",
  "#9333ea", "#0891b2", "#f97316", "#14b8a6"
]


// =====================================
// FORMATTERS
// =====================================

const formatCurrency = v =>
  v ? "CHF " + Number(v).toLocaleString() : "-"

const formatPercent = v =>
  v ? v.toFixed(1) + "%" : "-"


// =====================================
// MAIN APP
// =====================================

function App() {

  const [page, setPage] = useState("index")

  return (

    <div style={containerStyle}>

      <Header page={page} setPage={setPage} />

      {page === "index" && <DemandIndexPage />}

      {page === "arbitrage" && <ArbitragePage />}

    </div>

  )
}


// =====================================
// HEADER / NAV
// =====================================

function Header({ page, setPage }) {

  return (

    <div style={headerStyle}>

      <div style={titleStyle}>
        Watch Demand Intelligence
      </div>

      <div style={navStyle}>

        <button
          onClick={() => setPage("index")}
          style={page === "index"
            ? activeNavStyle
            : navButtonStyle}
        >
          Market Index
        </button>

        <button
          onClick={() => setPage("arbitrage")}
          style={page === "arbitrage"
            ? activeNavStyle
            : navButtonStyle}
        >
          Arbitrage Finder
        </button>

      </div>

    </div>

  )
}


// =====================================
// DEMAND INDEX PAGE
// =====================================

function DemandIndexPage() {

  const [brandIndex, setBrandIndex] = useState([])
  const [metrics, setMetrics] = useState(null)

  useEffect(() => {

    fetch(API_BASE + "/brand_index")
      .then(r => r.json())
      .then(setBrandIndex)

    fetch(API_BASE + "/metrics")
      .then(r => r.json())
      .then(setMetrics)

  }, [])

  return (

    <>

      {metrics &&
        <MetricsRow metrics={metrics} />
      }

      <ChartCard title="Total Value by Brand">

        <ResponsiveContainer width="100%" height={500}>

          <BarChart
            data={brandIndex}
            margin={{
              top: 20,
              right: 30,
              left: 20,
              bottom: 80
            }}
          >

            <CartesianGrid strokeDasharray="3 3"/>

            <XAxis
              dataKey="brand"
              interval={0}
              angle={-35}
              textAnchor="end"
              height={160}
              tickMargin={30}
            />

            <YAxis/>

            <Tooltip formatter={formatCurrency}/>

            <Bar dataKey="total_value">

              {brandIndex.map((e,i)=>
                <Cell key={i}
                  fill={COLORS[i % COLORS.length]}
                />
              )}

            </Bar>

          </BarChart>

        </ResponsiveContainer>

      </ChartCard>


      <ChartCard title="Market Share">

        <ResponsiveContainer width="100%" height={500}>

          <PieChart>

            <Pie
              data={brandIndex}
              dataKey="total_value"
              nameKey="brand"
              cx="50%"
              cy="45%"
              outerRadius={140}
            >

              {brandIndex.map((e,i)=>
                <Cell key={i}
                  fill={COLORS[i % COLORS.length]}
                />
              )}

            </Pie>

            <Tooltip formatter={formatCurrency}/>

            <Legend verticalAlign="bottom"/>

          </PieChart>

        </ResponsiveContainer>

      </ChartCard>

    </>

  )
}


// =====================================
// ARBITRAGE PAGE
// =====================================

function ArbitragePage() {

  const [data, setData] = useState([])

  useEffect(() => {

    fetch(API_BASE + "/arbitrage")
      .then(r => r.json())
      .then(setData)

  }, [])

  return (

    <ChartCard title="Best Arbitrage Opportunities">

      <table style={tableStyle}>

        <thead>

          <tr>
            <th style={thStyle}>Brand</th>
            <th style={thStyle}>Reference</th>
            <th style={thStyle}>Dealer Price</th>
            <th style={thStyle}>Market Median</th>
            <th style={thStyle}>Profit</th>
            <th style={thStyle}>Grade</th>
          </tr>

        </thead>

        <tbody>

          {data.map((row, i) => (

            <tr key={i}>

              <td style={tdStyle}>{row.brand}</td>

              <td style={tdStyle}>{row.reference}</td>

              <td style={tdStyle}>
                {formatCurrency(row.dealer_price)}
              </td>

              <td style={tdStyle}>
                {formatCurrency(row.median_price)}
              </td>

              <td style={{
                ...tdStyle,
                color:
                  row.profit_percent > 10
                    ? "green"
                    : "black"
              }}>
                {formatPercent(row.profit_percent)}
              </td>

              <td style={tdStyle}>
                {row.opportunity_grade}
              </td>

            </tr>

          ))}

        </tbody>

      </table>

    </ChartCard>

  )
}


// =====================================
// METRICS
// =====================================

function MetricsRow({ metrics }) {

  return (

    <div style={metricsRowStyle}>

      <MetricCard
        title="Total Lots"
        value={metrics.total_lots}
      />

      <MetricCard
        title="Total Value"
        value={formatCurrency(metrics.total_value)}
      />

      <MetricCard
        title="Average Price"
        value={formatCurrency(metrics.avg_price)}
      />

      <MetricCard
        title="Top Brand"
        value={metrics.top_brand}
      />

    </div>

  )
}


// =====================================
// UI COMPONENTS
// =====================================

function ChartCard({ title, children }) {

  return (

    <div style={cardStyle}>

      <h2>{title}</h2>

      {children}

    </div>

  )
}


function MetricCard({ title, value }) {

  return (

    <div style={metricCardStyle}>

      <div>{title}</div>

      <div style={metricValueStyle}>
        {value}
      </div>

    </div>

  )
}


// =====================================
// STYLES
// =====================================

const containerStyle = {
  padding: "20px 40px",
  maxWidth: "1400px",
  margin: "0 auto"
}

const headerStyle = {
  display: "flex",
  justifyContent: "space-between",
  marginBottom: "30px"
}

const titleStyle = {
  fontSize: "26px",
  fontWeight: "bold"
}

const navStyle = {
  display: "flex",
  gap: "10px"
}

const navButtonStyle = {
  padding: "10px 16px",
  border: "1px solid #ddd",
  background: "white",
  cursor: "pointer"
}

const activeNavStyle = {
  ...navButtonStyle,
  background: "#2563eb",
  color: "white"
}

const cardStyle = {
  background: "white",
  padding: "20px",
  marginBottom: "30px",
  borderRadius: "8px"
}

const metricsRowStyle = {
  display: "flex",
  gap: "20px",
  marginBottom: "30px"
}

const metricCardStyle = {
  background: "white",
  padding: "20px",
  borderRadius: "8px"
}

const metricValueStyle = {
  fontSize: "22px",
  fontWeight: "bold"
}

const tableStyle = {
  width: "100%",
  borderCollapse: "collapse"
}

const thStyle = {
  border: "1px solid #ddd",
  padding: "10px",
  background: "#f3f4f6"
}

const tdStyle = {
  border: "1px solid #ddd",
  padding: "10px"
}


// =====================================

export default App