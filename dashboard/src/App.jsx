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


// ===============================
// CONFIG
// ===============================

const API_BASE = "https://web-production-a02be.up.railway.app"

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


// ===============================
// FORMATTERS
// ===============================

const formatCurrency = (value) =>
  value ? "CHF " + value.toLocaleString() : "-"

const formatMillions = (value) =>
  "CHF " + (value / 1000000).toFixed(2) + "M"


// ===============================
// MAIN COMPONENT
// ===============================

function App() {

  const [lots, setLots] = useState([])
  const [metrics, setMetrics] = useState(null)
  const [brandIndex, setBrandIndex] = useState([])

  const [selectedBrand, setSelectedBrand] = useState("ALL")

  const [showAllLots, setShowAllLots] = useState(false)
  const [showAllBrands, setShowAllBrands] = useState(false)

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const [lastUpdated, setLastUpdated] = useState(null)


  // ===============================
  // LOAD DATA
  // ===============================

  useEffect(() => {

    async function loadData() {

      try {

        setLoading(true)

        const [lotsRes, metricsRes, brandRes] =
          await Promise.all([
            fetch(`${API_BASE}/auction_lots`),
            fetch(`${API_BASE}/metrics`),
            fetch(`${API_BASE}/brand_index`)
          ])

        if (!lotsRes.ok) throw new Error("API unavailable")

        const lotsData = await lotsRes.json()
        const metricsData = await metricsRes.json()
        const brandData = await brandRes.json()

        setLots(lotsData)
        setMetrics(metricsData)
        setBrandIndex(brandData)

        setLastUpdated(new Date())

      } catch (err) {

        setError(err.message)

      } finally {

        setLoading(false)

      }

    }

    loadData()

  }, [])


  // ===============================
  // FILTERING
  // ===============================

  const brands = ["ALL", ...brandIndex.map(b => b.brand)]

  const filteredLots =
    selectedBrand === "ALL"
      ? lots
      : lots.filter(l => l.brand === selectedBrand)

  const visibleLots =
    showAllLots
      ? filteredLots
      : filteredLots.slice(0, 10)

  const visibleBrands =
    showAllBrands
      ? brandIndex
      : brandIndex.slice(0, 5)


  // ===============================
  // LOADING STATE
  // ===============================

  if (loading)
    return (
      <CenteredMessage>
        Loading Watch Demand Index...
      </CenteredMessage>
    )


  // ===============================
  // ERROR STATE
  // ===============================

  if (error)
    return (
      <CenteredMessage>
        Error: {error}
      </CenteredMessage>
    )


  // ===============================
  // UI
  // ===============================

  return (

    <div style={containerStyle}>

      <Header lastUpdated={lastUpdated} />


      {/* SCOREBOARD */}
      <ChartCard title="Demand Index Scoreboard">

        <Scoreboard brandIndex={brandIndex} />

      </ChartCard>


      {/* METRICS */}
      {metrics && (

        <MetricsRow metrics={metrics} />

      )}


      {/* BRAND FILTER */}
      <ChartCard title="Filter">

        <select
          value={selectedBrand}
          onChange={(e) => setSelectedBrand(e.target.value)}
          style={dropdownStyle}
        >
          {brands.map(b =>
            <option key={b} value={b}>{b}</option>
          )}
        </select>

      </ChartCard>


      {/* BRAND TABLE */}
      <BrandTable
        visibleBrands={visibleBrands}
        brandIndex={brandIndex}
        showAllBrands={showAllBrands}
        setShowAllBrands={setShowAllBrands}
      />


      {/* BAR CHART TOTAL VALUE */}
      <BrandValueChart brandIndex={brandIndex} />


      {/* AVG PRICE CHART */}
      <BrandAvgChart brandIndex={brandIndex} />


      {/* PIE CHART */}
      <BrandPieChart brandIndex={brandIndex} />


      {/* LOT TABLE */}
      <LotsTable
        visibleLots={visibleLots}
        filteredLots={filteredLots}
        showAllLots={showAllLots}
        setShowAllLots={setShowAllLots}
      />

    </div>

  )

}


// ===============================
// HEADER
// ===============================

function Header({ lastUpdated }) {

  return (

    <div style={{ marginBottom: 20 }}>

      <h1>Watch Demand Index</h1>

      {lastUpdated &&
        <p style={{ color: "#666" }}>
          Last updated: {lastUpdated.toLocaleString()}
        </p>
      }

    </div>

  )

}


// ===============================
// SCOREBOARD
// ===============================

function Scoreboard({ brandIndex }) {

  const top = brandIndex.slice(0, 5)

  return (

    <div style={{
      display: "flex",
      gap: 20
    }}>

      {top.map(b => (

        <div key={b.brand}
          style={scoreCardStyle}
        >

          <div>{b.brand}</div>

          <div style={scoreValueStyle}>
            {Math.round(b.demand_index)}
          </div>

        </div>

      ))}

    </div>

  )

}


// ===============================
// METRICS ROW
// ===============================

function MetricsRow({ metrics }) {

  return (

    <div style={{
      display: "flex",
      gap: 20,
      marginBottom: 30
    }}>

      <Card title="Total Lots"
        value={metrics.total_lots}
      />

      <Card title="Average Price"
        value={formatCurrency(metrics.avg_price)}
      />

      <Card title="Total Value"
        value={formatCurrency(metrics.total_value)}
      />

      <Card title="Top Brand"
        value={metrics.top_brand}
      />

    </div>

  )

}


// ===============================
// BRAND TABLE COMPONENT
// ===============================

function BrandTable({
  visibleBrands,
  brandIndex,
  showAllBrands,
  setShowAllBrands
}) {

  return (

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

          {visibleBrands.map((b, i) => (

            <tr key={b.brand}>
              <td>{i + 1}</td>
              <td>{b.brand}</td>
              <td>{b.total_lots}</td>
              <td>{formatCurrency(b.avg_price)}</td>
              <td>{formatCurrency(b.total_value)}</td>
              <td><b>{b.demand_index}</b></td>
            </tr>

          ))}

        </tbody>

      </table>

      {brandIndex.length > 5 &&
        <button style={buttonStyle}
          onClick={() =>
            setShowAllBrands(!showAllBrands)
          }
        >
          {showAllBrands ? "Show Less" : "Show All"}
        </button>
      }

    </ChartCard>

  )

}


// ===============================
// CHART COMPONENTS
// ===============================

function BrandValueChart({ brandIndex }) {

  return (

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

          <YAxis tickFormatter={formatMillions}/>

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

  )

}


function BrandAvgChart({ brandIndex }) {

  return (

    <ChartCard title="Average Price by Brand">

      <ResponsiveContainer width="100%" height={500}>

        <BarChart
          data={brandIndex}
          margin={{
            top:20,right:30,left:20,bottom:80
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

          <YAxis tickFormatter={formatMillions}/>

          <Tooltip formatter={formatCurrency}/>

          <Bar dataKey="avg_price">

            {brandIndex.map((e,i)=>
              <Cell key={i}
                fill={COLORS[i % COLORS.length]}
              />
            )}

          </Bar>

        </BarChart>

      </ResponsiveContainer>

    </ChartCard>

  )

}


function BrandPieChart({ brandIndex }) {

  return (

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
            innerRadius={60}
          >

            {brandIndex.map((e,i)=>
              <Cell key={i}
                fill={COLORS[i % COLORS.length]}
              />
            )}

          </Pie>

          <Tooltip formatter={formatCurrency}/>

          <Legend
            verticalAlign="bottom"
            height={100}
          />

        </PieChart>

      </ResponsiveContainer>

    </ChartCard>

  )

}


// ===============================
// LOT TABLE
// ===============================

function LotsTable({
  visibleLots,
  filteredLots,
  showAllLots,
  setShowAllLots
}) {

  return (

    <ChartCard title="Auction Lots">

      <table border="1" cellPadding="8" width="100%">

        <thead>
          <tr>
            <th>Auction</th>
            <th>Lot</th>
            <th>Brand</th>
            <th>Model</th>
            <th>Price</th>
          </tr>
        </thead>

        <tbody>

          {visibleLots.map((lot,i)=>(
            <tr key={i}>
              <td>{lot.auction_house}</td>
              <td>{lot.lot}</td>
              <td>{lot.brand}</td>
              <td>{lot.model}</td>
              <td>{formatCurrency(lot.price)}</td>
            </tr>
          ))}

        </tbody>

      </table>

      {filteredLots.length > 10 &&
        <button style={buttonStyle}
          onClick={()=>setShowAllLots(!showAllLots)}
        >
          {showAllLots?"Show Less":"Show All"}
        </button>
      }

    </ChartCard>

  )

}


// ===============================
// UI COMPONENTS
// ===============================

function ChartCard({title, children}){

  return(
    <div style={cardStyle}>
      <h2>{title}</h2>
      {children}
    </div>
  )
}


function Card({title,value}){

  return(
    <div style={metricCardStyle}>
      <h3>{title}</h3>
      <p style={metricValueStyle}>{value}</p>
    </div>
  )
}


function CenteredMessage({children}){

  return(
    <div style={{
      display:"flex",
      justifyContent:"center",
      alignItems:"center",
      height:"100vh"
    }}>
      {children}
    </div>
  )
}


// ===============================
// STYLES
// ===============================

const containerStyle = {
  padding:30,
  background:"#f3f4f6",
  minHeight:"100vh",
  color:"#111"
}

const cardStyle = {
  background:"white",
  padding:20,
  borderRadius:10,
  marginBottom:30,
  boxShadow:"0 2px 6px rgba(0,0,0,0.1)"
}

const metricCardStyle = {
  background:"white",
  padding:15,
  borderRadius:10,
  minWidth:180,
  boxShadow:"0 2px 6px rgba(0,0,0,0.1)"
}

const metricValueStyle = {
  fontSize:20,
  fontWeight:"bold"
}

const dropdownStyle = {
  padding:10,
  fontSize:16
}

const buttonStyle = {
  marginTop:10,
  padding:"8px 16px",
  background:"#2563eb",
  color:"white",
  border:"none",
  borderRadius:6,
  cursor:"pointer"
}

const scoreCardStyle = {
  background:"#2563eb",
  color:"white",
  padding:15,
  borderRadius:10,
  minWidth:120,
  textAlign:"center"
}

const scoreValueStyle = {
  fontSize:28,
  fontWeight:"bold"
}


// ===============================

export default App