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

  const [activePage, setActivePage] = useState("market")

  const [lots, setLots] = useState([])
  const [metrics, setMetrics] = useState(null)
  const [brandIndex, setBrandIndex] = useState([])
  const [arbitrage, setArbitrage] = useState([])

  const [selectedBrand, setSelectedBrand] = useState("ALL")

  const [showAllLots, setShowAllLots] = useState(false)
  const [showAllBrands, setShowAllBrands] = useState(false)

  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const [lastUpdated, setLastUpdated] = useState(null)


  useEffect(() => {

    async function loadData() {

      try {

        setLoading(true)

        const [lotsRes, metricsRes, brandRes, arbRes] =
          await Promise.all([
            fetch(`${API_BASE}/auction_lots`),
            fetch(`${API_BASE}/metrics`),
            fetch(`${API_BASE}/brand_index`),
            fetch(`${API_BASE}/arbitrage`)
          ])

        const lotsData = await lotsRes.json()
        const metricsData = await metricsRes.json()
        const brandData = await brandRes.json()
        const arbData = await arbRes.json()

        setLots(lotsData)
        setMetrics(metricsData)
        setBrandIndex(brandData)
        setArbitrage(arbData)

        setLastUpdated(new Date())

      } catch (err) {

        setError(err.message)

      } finally {

        setLoading(false)

      }

    }

    loadData()

  }, [])


  const brands = ["ALL", ...brandIndex.map(b => b.brand)]

  const filteredLots =
    selectedBrand === "ALL"
      ? lots
      : lots.filter(l => l.brand === selectedBrand)

  const visibleLots =
    showAllLots ? filteredLots : filteredLots.slice(0, 10)

  const visibleBrands =
    showAllBrands ? brandIndex : brandIndex.slice(0, 5)


  if (loading)
    return <CenteredMessage>Loading Watch Demand Index...</CenteredMessage>

  if (error)
    return <CenteredMessage>Error: {error}</CenteredMessage>


  return (

    <div style={containerStyle}>

      <Header lastUpdated={lastUpdated} />


      {/* NAVIGATION */}
      <ChartCard title="Navigation">

        <div style={{display:"flex",gap:10}}>

          <button
            style={activePage==="market"?navButtonActive:navButton}
            onClick={()=>setActivePage("market")}
          >
            Market Index
          </button>

          <button
            style={activePage==="arbitrage"?navButtonActive:navButton}
            onClick={()=>setActivePage("arbitrage")}
          >
            Arbitrage Finder
          </button>

        </div>

      </ChartCard>


      {activePage === "market" && (

        <>
          <ChartCard title="Demand Index Scorecard">
            <Scoreboard brandIndex={brandIndex}/>
          </ChartCard>

          {metrics && <MetricsRow metrics={metrics}/>}

          <ChartCard title="Filter by Brand">

            <select
              value={selectedBrand}
              onChange={(e)=>setSelectedBrand(e.target.value)}
              style={dropdownStyle}
            >
              {brands.map(b => <option key={b}>{b}</option>)}
            </select>

          </ChartCard>


          <BrandTable
            visibleBrands={visibleBrands}
            brandIndex={brandIndex}
            showAllBrands={showAllBrands}
            setShowAllBrands={setShowAllBrands}
          />

          <BrandValueChart brandIndex={brandIndex}/>
          <BrandAvgChart brandIndex={brandIndex}/>
          <BrandPieChart brandIndex={brandIndex}/>

          <LotsTable
            visibleLots={visibleLots}
            filteredLots={filteredLots}
            showAllLots={showAllLots}
            setShowAllLots={setShowAllLots}
          />

        </>
      )}


      {activePage === "arbitrage" && (

        <ArbitrageTable arbitrage={arbitrage}/>

      )}

    </div>

  )

}


// ===============================
// ARBITRAGE COMPONENT
// ===============================

function ArbitrageTable({ arbitrage }) {

  return (

    <ChartCard title="Arbitrage Opportunities">

      <table style={tableStyle}>

        <thead>

          <tr>
            <th style={thStyle}>Brand</th>
            <th style={thStyle}>Reference</th>
            <th style={thStyle}>Dealer Price</th>
            <th style={thStyle}>Market Median</th>
            <th style={thStyle}>Profit %</th>
            <th style={thStyle}>Grade</th>
          </tr>

        </thead>

        <tbody>

          {arbitrage.map((a,i)=>

            <tr key={i}>

              <td style={tdStyle}>{a.brand}</td>
              <td style={tdStyle}>{a.reference}</td>
              <td style={tdStyle}>{formatCurrency(a.dealer_price)}</td>
              <td style={tdStyle}>{formatCurrency(a.median_price)}</td>
              <td style={tdStyle}>
                <b>{a.profit_percent.toFixed(1)}%</b>
              </td>
              <td style={tdStyle}>{a.opportunity_grade}</td>

            </tr>

          )}

        </tbody>

      </table>

    </ChartCard>

  )

}


// ===============================
// YOUR EXISTING COMPONENTS BELOW
// (UNCHANGED)
// ===============================

// Scoreboard, Charts, Tables, Header, Card etc remain exactly same as your code

// ===============================
// STYLES ADDITION
// ===============================

const navButton={
  padding:"10px 20px",
  border:"1px solid #ccc",
  background:"white",
  cursor:"pointer",
  borderRadius:6
}

const navButtonActive={
  ...navButton,
  background:"#2563eb",
  color:"white"
}


// ===============================

export default App