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

const API_BASE =
  import.meta.env.DEV
    ? "http://127.0.0.1:8000"
    : "https://web-production-a02be.up.railway.app"

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

  const [page, setPage] = useState("market")
  const [arbitrage, setArbitrage] = useState([])


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

        if (!lotsRes.ok) throw new Error("API unavailable")

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

        <button
          style={{
            ...buttonStyle,
            background: page==="market" ? "#16a34a" : "#2563eb",
            marginRight: 10
          }}
          onClick={()=>setPage("market")}
        >
          Watch Demand Index
        </button>

        <button
          style={{
            ...buttonStyle,
            background: page==="arbitrage" ? "#16a34a" : "#2563eb"
          }}
          onClick={()=>setPage("arbitrage")}
        >
          Dealer Arbitrage Finder
        </button>

      </ChartCard>


      {/* ========================= */}
      {/* MARKET INDEX PAGE */}
      {/* ========================= */}

      {page==="market" && (
        <>

          <ChartCard title="Demand Index Scorecard">
            <Scoreboard brandIndex={brandIndex}/>
          </ChartCard>

          {metrics &&
            <MetricsRow metrics={metrics}/>
          }

          <ChartCard title="Filter by Brand">

            <select
              value={selectedBrand}
              onChange={(e)=>setSelectedBrand(e.target.value)}
              style={dropdownStyle}
            >
              {brands.map(b=>
                <option key={b}>{b}</option>
              )}
            </select>

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
                {visibleBrands.map((b,i)=>
                  <tr key={b.brand}>
                    <td style={tdStyle}>{i+1}</td>
                    <td style={tdStyle}>{b.brand}</td>
                    <td style={tdStyle}>{b.total_lots}</td>
                    <td style={tdStyle}>{formatCurrency(b.avg_price)}</td>
                    <td style={tdStyle}>{formatCurrency(b.total_value)}</td>
                    <td style={tdStyle}><b>{b.demand_index}</b></td>
                  </tr>
                )}
              </tbody>
            </table>

            {brandIndex.length>5 &&
              <button style={buttonStyle}
                onClick={()=>setShowAllBrands(!showAllBrands)}>
                {showAllBrands?"Show Less":"Show All"}
              </button>
            }

          </ChartCard>


          {/* CHARTS */}
          <BrandValueChart brandIndex={brandIndex}/>
          <BrandAvgChart brandIndex={brandIndex}/>
          <BrandPieChart brandIndex={brandIndex}/>


          {/* LOT TABLE */}
          <ChartCard title="Auction Lots">

            <table style={tableStyle}>
              <thead>
                <tr>
                  <th style={thStyle}>Auction</th>
                  <th style={thStyle}>Lot</th>
                  <th style={thStyle}>Brand</th>
                  <th style={thStyle}>Model</th>
                  <th style={thStyle}>Price</th>
                </tr>
              </thead>

              <tbody>
                {visibleLots.map((lot,i)=>
                  <tr key={i}>
                    <td style={tdStyle}>{lot.auction_house}</td>
                    <td style={tdStyle}>{lot.lot}</td>
                    <td style={tdStyle}>{lot.brand}</td>
                    <td style={tdStyle}>{lot.model}</td>
                    <td style={tdStyle}>{formatCurrency(lot.price)}</td>
                  </tr>
                )}
              </tbody>
            </table>

            {filteredLots.length>10 &&
              <button style={buttonStyle}
                onClick={()=>setShowAllLots(!showAllLots)}>
                {showAllLots?"Show Less":"Show All"}
              </button>
            }

          </ChartCard>

        </>
      )}


      {/* ========================= */}
      {/* ARBITRAGE PAGE */}
      {/* ========================= */}

      {page==="arbitrage" && (
        <ArbitragePage/>
      )}


    </div>

  )

}


// ===============================
// SCOREBOARD
// ===============================

function Scoreboard({brandIndex}){

  const top = brandIndex.slice(0,5)

  return(

    <div style={{display:"flex",gap:20}}>

      {top.map(b=>

        <div key={b.brand} style={scoreCardStyle}>

          <div>{b.brand}</div>

          <div style={scoreValueStyle}>
            {Math.round(b.demand_index)}
          </div>

        </div>

      )}

    </div>

  )

}


// ===============================
// CHARTS
// ===============================

function BrandValueChart({brandIndex}){

  return(

    <ChartCard title="Total Value by Brand">

      <ResponsiveContainer width="100%" height={500}>

        <BarChart data={brandIndex}
          margin={{top:20,right:30,left:20,bottom:80}}>

          <CartesianGrid strokeDasharray="3 3"/>

          <XAxis dataKey="brand"
            angle={-35}
            height={160}
            tickMargin={30}
            interval={0}
            textAnchor="end"/>

          <YAxis tickFormatter={formatMillions}/>

          <Tooltip formatter={formatCurrency}/>

          <Bar dataKey="total_value">

            {brandIndex.map((e,i)=>
              <Cell key={i}
                fill={COLORS[i%COLORS.length]}/>
            )}

          </Bar>

        </BarChart>

      </ResponsiveContainer>

    </ChartCard>

  )

}


function BrandAvgChart({brandIndex}){

  return(

    <ChartCard title="Average Price by Brand">

      <ResponsiveContainer width="100%" height={500}>

        <BarChart data={brandIndex}
          margin={{top:20,right:30,left:20,bottom:80}}>

          <CartesianGrid strokeDasharray="3 3"/>

          <XAxis dataKey="brand"
            angle={-35}
            height={160}
            tickMargin={30}
            interval={0}
            textAnchor="end"/>

          <YAxis tickFormatter={formatMillions}/>

          <Tooltip formatter={formatCurrency}/>

          <Bar dataKey="avg_price">

            {brandIndex.map((e,i)=>
              <Cell key={i}
                fill={COLORS[i%COLORS.length]}/>
            )}

          </Bar>

        </BarChart>

      </ResponsiveContainer>

    </ChartCard>

  )

}


function BrandPieChart({brandIndex}){

  return(

    <ChartCard title="Market Share">

      <ResponsiveContainer width="100%" height={500}>

        <PieChart>

          <Pie data={brandIndex}
            dataKey="total_value"
            nameKey="brand"
            cx="50%"
            cy="45%"
            outerRadius={140}
            innerRadius={60}>

            {brandIndex.map((e,i)=>
              <Cell key={i}
                fill={COLORS[i%COLORS.length]}/>
            )}

          </Pie>

          <Tooltip formatter={formatCurrency}/>

          <Legend verticalAlign="bottom" height={100}/>

        </PieChart>

      </ResponsiveContainer>

    </ChartCard>

  )

}


// ===============================
// UI
// ===============================

function ChartCard({title,children}){

  return(

    <div style={cardStyle}>
      <h2>{title}</h2>
      {children}
    </div>

  )

}


function MetricsRow({metrics}){

  return(

    <div style={{display:"flex",gap:20,marginBottom:30}}>

      <Card title="Total Lots" value={metrics.total_lots}/>
      <Card title="Average Price" value={formatCurrency(metrics.avg_price)}/>
      <Card title="Total Value" value={formatCurrency(metrics.total_value)}/>
      <Card title="Top Brand" value={metrics.top_brand}/>

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


function StatCard({title,value}){

  return(
    <div style={{
      background:"white",
      padding:20,
      borderRadius:10,
      boxShadow:"0 2px 6px rgba(0,0,0,0.1)",
      minWidth:200
    }}>
      <div style={{color:"#666"}}>{title}</div>
      <div style={{
        fontSize:24,
        fontWeight:"bold"
      }}>
        {value}
      </div>
    </div>
  )

}


function GradeBadge({grade}){

  const colors={
    "A+":"#16a34a",
    "A":"#22c55e",
    "B":"#f59e0b",
    "C":"#ef4444"
  }

  return(
    <span style={{
      background:colors[grade] || "#6b7280",
      color:"white",
      padding:"4px 8px",
      borderRadius:"6px",
      fontWeight:"bold"
    }}>
      {grade}
    </span>
  )

}


function Header({lastUpdated}){

  return(

    <div style={{marginBottom:20}}>
      <h1>Watch Demand Index</h1>
      {lastUpdated &&
        <p style={{color:"#666"}}>
          Last updated: {lastUpdated.toLocaleString()}
        </p>
      }
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
// ARBITRAGE PAGE COMPONENT
// ===============================

function SourceBadge({priority}) {

  const colors = {
    1:"#16a34a",  // best
    2:"#22c55e",
    3:"#eab308",
    4:"#f97316",
    5:"#6b7280"
  }

  return (
    <span style={{
      background:colors[priority] || "#6b7280",
      color:"white",
      padding:"4px 8px",
      borderRadius:"6px",
      fontWeight:"bold",
      minWidth:"28px",
      display:"inline-block",
      textAlign:"center"
    }}>
      #{priority}
    </span>
  )
}

function ArbitragePage() {

  const [data, setData] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const [sortBy, setSortBy] = useState("profit_percent")
  const [minProfit, setMinProfit] = useState(5)

  useEffect(() => {

    async function load() {

      try {

        const res = await fetch(`${API_BASE}/arbitrage`)

        if (!res.ok)
          throw new Error("Failed to load arbitrage data")

        const json = await res.json()

        setData(json)

      } catch (err) {

        setError(err.message)

      } finally {

        setLoading(false)

      }

    }

    load()

  }, [])


  if (loading)
    return <ChartCard title="Dealer Arbitrage Finder">Loading...</ChartCard>

  if (error)
    return <ChartCard title="Dealer Arbitrage Finder">Error: {error}</ChartCard>


  // FILTER
  const filtered = data
    .filter(d => d.profit_percent >= minProfit)
    .sort((a, b) => b[sortBy] - a[sortBy])


  return (

    <>

      {/* SUMMARY */}
      <ChartCard title="Top Dealer Opportunities">

        <div style={{display:"flex",gap:20}}>

          <StatCard
            title="Total Opportunities"
            value={filtered.length}
          />

          <StatCard
            title="Best Profit"
            value={
              filtered.length
                ? filtered[0].profit_percent.toFixed(1) + "%"
                : "-"
            }
          />

          <StatCard
            title="Best Absolute Profit"
            value={
              filtered.length
                ? formatCurrency(filtered[0].absolute_profit)
                : "-"
            }
          />

        </div>

      </ChartCard>


      {/* CONTROLS */}
      <ChartCard title="Filters">

        <div style={{display:"flex",gap:20}}>

          <div>
            Minimum Profit %
            <br/>
            <input
              type="number"
              value={minProfit}
              onChange={(e)=>setMinProfit(Number(e.target.value))}
              style={inputStyle}
            />
          </div>

          <div>
            Sort By
            <br/>
            <select
              value={sortBy}
              onChange={(e)=>setSortBy(e.target.value)}
              style={inputStyle}
            >
              <option value="profit_percent">Profit %</option>
              <option value="absolute_profit">Absolute Profit</option>
              <option value="dealer_price">Dealer Price</option>
            </select>
          </div>

        </div>

      </ChartCard>


      {/* TABLE */}
      <ChartCard title="Live Arbitrage Feed">

        <table style={tableStyle}>

          <thead>
            <tr>
              <th style={thStyle}>Priority</th>
              <th style={thStyle}>Source</th>
              <th style={thStyle}>Seller</th>
              <th style={thStyle}>Brand</th>
              <th style={thStyle}>Reference</th>
              <th style={thStyle}>Dealer Price</th>
              <th style={thStyle}>Market Price</th>
              <th style={thStyle}>Profit %</th>
              <th style={thStyle}>Grade</th>
            </tr>
          </thead>

          <tbody>
            {filtered.map((row,i)=>(
              <tr key={i}>

                <td style={tdStyle}>
                  <SourceBadge
                    priority={row.source_priority}
                    source={row.source}
                  />
                </td>

                <td style={tdStyle}>
                  {row.source || "-"}
                </td>

                <td style={tdStyle}>
                  {row.seller}
                </td>

                <td style={tdStyle}>
                  {row.brand}
                </td>

                <td style={tdStyle}>
                  {row.reference}
                </td>

                <td style={tdStyle}>
                  {formatCurrency(row.dealer_price)}
                </td>

                <td style={tdStyle}>
                  {formatCurrency(row.median_price)}
                </td>

                <td style={tdStyle}>
                  <b style={{color:"#16a34a"}}>
                    {row.profit_percent}%
                  </b>
                </td>

                <td style={tdStyle}>
                  {row.opportunity_grade}
                </td>

              </tr>
            ))}
          </tbody>

        </table>

      </ChartCard>

    </>

  )

}


// ===============================
// STYLES
// ===============================

const containerStyle={
  padding:30,
  background:"#f3f4f6",
  minHeight:"100vh",
  color:"#111",
  width:"100%",
  maxWidth:"1400px",
  margin:"0 auto"
}

const cardStyle={
  background:"white",
  padding:20,
  borderRadius:10,
  marginBottom:30,
  boxShadow:"0 2px 6px rgba(0,0,0,0.1)"
}

const metricCardStyle={
  background:"white",
  padding:15,
  borderRadius:10,
  minWidth:180,
  boxShadow:"0 2px 6px rgba(0,0,0,0.1)"
}

const metricValueStyle={
  fontSize:20,
  fontWeight:"bold"
}

const dropdownStyle={
  padding:10,
  fontSize:16
}

const buttonStyle={
  marginTop:10,
  padding:"8px 16px",
  background:"#2563eb",
  color:"white",
  border:"none",
  borderRadius:6,
  cursor:"pointer"
}

const scoreCardStyle={
  background:"#2563eb",
  color:"white",
  padding:15,
  borderRadius:10,
  minWidth:120,
  textAlign:"center"
}

const scoreValueStyle={
  fontSize:28,
  fontWeight:"bold"
}

const tableStyle={
  width:"100%",
  borderCollapse:"collapse",
  marginTop:"10px"
}

const thStyle={
  border:"1px solid #e5e7eb",
  padding:"10px",
  textAlign:"left",
  background:"#f9fafb",
  fontWeight:"600"
}

const tdStyle={
  border:"1px solid #e5e7eb",
  padding:"10px"
}

const inputStyle={
  padding:"8px",
  fontSize:"14px",
  borderRadius:"6px",
  border:"1px solid #ccc",
  marginTop:"5px"
}


// ===============================

export default App