import { useCallback, useEffect, useMemo, useState } from "react"

const ACCESS_TOKEN_KEY = "wdi.accessToken"
const REFRESH_TOKEN_KEY = "wdi.refreshToken"

const RUNTIME_API_BASE = window.__APP_CONFIG__?.VITE_API_BASE_URL
const API_BASE = (
  RUNTIME_API_BASE ||
  import.meta.env.VITE_API_BASE_URL ||
  (import.meta.env.DEV
    ? "http://127.0.0.1:8000"
    : "")
).replace(/\/$/, "")

class ApiError extends Error {
  constructor(message, status, payload) {
    super(message)
    this.name = "ApiError"
    this.status = status
    this.payload = payload
  }
}

async function apiRequest(path, options = {}) {
  if (!API_BASE) {
    throw new Error("VITE_API_BASE_URL is not configured for this deployment")
  }

  const token = localStorage.getItem(ACCESS_TOKEN_KEY)
  const headers = new Headers(options.headers || {})

  if (!headers.has("Content-Type") && options.body) {
    headers.set("Content-Type", "application/json")
  }
  if (token) {
    headers.set("Authorization", `Bearer ${token}`)
  }

  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers,
  })

  let payload = null
  const contentType = response.headers.get("content-type") || ""
  if (contentType.includes("application/json")) {
    payload = await response.json()
  } else {
    payload = await response.text()
  }

  if (!response.ok) {
    const message =
      (payload && typeof payload === "object" && payload.detail) ||
      `Request failed with status ${response.status}`
    throw new ApiError(message, response.status, payload)
  }

  return payload
}

function persistSession(authPayload) {
  localStorage.setItem(ACCESS_TOKEN_KEY, authPayload.access_token)
  localStorage.setItem(REFRESH_TOKEN_KEY, authPayload.refresh_token)
}

function clearSession() {
  localStorage.removeItem(ACCESS_TOKEN_KEY)
  localStorage.removeItem(REFRESH_TOKEN_KEY)
}

function formatCurrency(value) {
  if (value === null || value === undefined) return "-"
  return new Intl.NumberFormat("en-CH", {
    style: "currency",
    currency: "CHF",
    maximumFractionDigits: 0,
  }).format(value)
}

function formatDateTime(value) {
  if (!value) return "-"
  return new Date(value).toLocaleString()
}

function formatPercent(value) {
  if (value === null || value === undefined) return "-"
  return `${Number(value).toFixed(1)}%`
}

function normalizeBrandRows(rows) {
  return rows.map((row) => ({
    ...row,
    demand_score: Number(row.demand_score || 0),
    avg_price: Number(row.avg_price || 0),
    total_value: Number(row.total_value || 0),
    lot_count: Number(row.lot_count || 0),
  }))
}

const METRIC_TOOLTIPS = {
  totalLots:
    "Counts the auction lots currently included in the live dataset. More lots usually means broader market coverage and a stronger sample.",
  averagePrice:
    "Shows the mean hammer-price level across tracked lots. Use it as a quick read on where the current market sits, not as a guaranteed buy price.",
  totalValue:
    "Adds up the value of all priced lots in the feed. This helps dealers gauge how much capital is moving through the tracked auction slice.",
  topBrand:
    "Identifies the brand with the highest lot volume in the current auction feed. It is a signal for where attention and liquidity are clustering.",
}

const PANEL_TOOLTIPS = {
  brandDemandIndex:
    "Ranks brands by the platform's current demand score so dealers can spot where sell-through energy is strongest before buying inventory.",
  accountAndBilling:
    "Summarizes the tenant's subscription state and access entitlements so teams can see which datasets and workflows should be available.",
  auctionFeed:
    "Shows the latest auction lots flowing into the system. Dealers can use it to monitor comparable sales, brand activity, and reference frequency.",
  watchlist:
    "Stores the references your team wants to monitor repeatedly. It becomes the operating queue for sourcing, pricing, and alert workflows.",
  arbitrageFeed:
    "Highlights listings where the observed dealer ask appears below the modelled market level, helping surface potential margin opportunities.",
}

const TABLE_TOOLTIPS = {
  brandIndex: {
    brand: "The watch brand being scored for this daily index snapshot.",
    date: "The day the index snapshot was calculated. Use it to judge freshness and compare movement over time.",
    lots: "How many lots contributed to this brand's score on that day. Higher counts usually mean a more representative read.",
    averagePrice: "Average realized price for the lots included in this brand snapshot.",
    totalValue: "Combined value of the lots included in the brand snapshot.",
    demandScore:
      "A normalized demand indicator. Higher scores suggest stronger dealer interest, depth, or market absorption relative to peers.",
  },
  billing: {
    plan: "Your active subscription tier, which controls access to premium analytics and protected endpoints.",
    status:
      "The current account state. Active means the tenant should have access, while other states may limit billing-backed features.",
    subscription:
      "The linked billing subscription identifier. This helps operators confirm whether the tenant is connected to a live Stripe subscription.",
    periodEnd:
      "When the current billing period ends. Teams use this to anticipate renewals, downgrades, or access changes.",
  },
  auctionFeed: {
    auction: "The auction house or source where the lot was observed.",
    lot: "The lot number inside the source auction, useful for finding the original listing again.",
    brand: "The brand assigned to the lot.",
    reference: "The reference code, which is often the most actionable identifier for sourcing and pricing.",
    model: "The watch model name, when available from the source.",
    price:
      "The observed lot price in the feed. Treat it as a comparable signal rather than a guaranteed executable market price.",
    filterBrand:
      "Limit the feed to one brand so you can review comparables and recent activity without cross-brand noise.",
  },
  arbitrage: {
    source: "The marketplace or source where the opportunity was captured.",
    seller: "The seller or dealer attached to the listing, when the source provides it.",
    brand: "The watch brand for the potential opportunity.",
    reference: "The reference used to match the listing against market pricing.",
    dealerPrice: "The observed asking price from the source listing.",
    marketPrice: "The modelled or median market price used as the comparison anchor.",
    profit:
      "Estimated upside between the observed listing and the modelled market price. It is directional and should be validated before buying.",
    grade:
      "A simplified opportunity score derived from the expected spread. Higher grades indicate stronger potential margin at face value.",
  },
}

function App() {
  const [authMode, setAuthMode] = useState("login")
  const [authForm, setAuthForm] = useState({
    company_name: "",
    email: "",
    password: "",
    plan_tier: "starter",
  })
  const [authLoading, setAuthLoading] = useState(false)
  const [authError, setAuthError] = useState("")

  const [user, setUser] = useState(null)
  const [dashboardState, setDashboardState] = useState({
    loading: true,
    error: "",
    metrics: null,
    brandIndex: [],
    auctionLots: [],
    watchlist: [],
    arbitrage: [],
    billing: null,
    arbitrageLocked: false,
  })
  const [watchlistForm, setWatchlistForm] = useState({
    reference_code: "",
    brand: "",
    notes: "",
  })
  const [watchlistSaving, setWatchlistSaving] = useState(false)
  const [watchlistError, setWatchlistError] = useState("")
  const [selectedBrand, setSelectedBrand] = useState("ALL")

  const loadDashboard = useCallback(async function loadDashboard() {
    setDashboardState((current) => ({ ...current, loading: true, error: "" }))
    try {
      const [metrics, brandIndex, auctionLots, watchlist, billing, arbitrageResult] = await Promise.all([
        apiRequest("/metrics"),
        apiRequest("/brand-index"),
        apiRequest("/auction_lots"),
        apiRequest("/watchlist"),
        apiRequest("/billing/status"),
        apiRequest("/arbitrage")
          .then((rows) => ({ rows, locked: false }))
          .catch((error) => {
            if (error instanceof ApiError && error.status === 403) {
              return { rows: [], locked: true }
            }
            throw error
          }),
      ])

      setDashboardState({
        loading: false,
        error: "",
        metrics,
        brandIndex: normalizeBrandRows(brandIndex),
        auctionLots,
        watchlist,
        arbitrage: arbitrageResult.rows,
        billing,
        arbitrageLocked: arbitrageResult.locked,
      })
    } catch (error) {
      setDashboardState((current) => ({
        ...current,
        loading: false,
        error: error instanceof Error ? error.message : "Failed to load dashboard",
      }))
    }
  }, [])

  const hydrateSession = useCallback(async function hydrateSession() {
    setDashboardState((current) => ({ ...current, loading: true, error: "" }))
    try {
      const currentUser = await apiRequest("/auth/me")
      setUser(currentUser)
      await loadDashboard()
    } catch (error) {
      clearSession()
      setUser(null)
      setDashboardState((current) => ({
        ...current,
        loading: false,
        error: error instanceof Error ? error.message : "Unable to restore session",
      }))
    }
  }, [loadDashboard])

  useEffect(() => {
    const existingToken = localStorage.getItem(ACCESS_TOKEN_KEY)
    if (!existingToken) {
      setDashboardState((current) => ({ ...current, loading: false }))
      return
    }

    hydrateSession()
  }, [hydrateSession])

  async function handleAuthSubmit(event) {
    event.preventDefault()
    setAuthLoading(true)
    setAuthError("")

    const path = authMode === "login" ? "/auth/login" : "/auth/register"
    const body =
      authMode === "login"
        ? {
            email: authForm.email,
            password: authForm.password,
          }
        : authForm

    try {
      const payload = await apiRequest(path, {
        method: "POST",
        body: JSON.stringify(body),
      })
      persistSession(payload)
      const currentUser = await apiRequest("/auth/me")
      setUser(currentUser)
      await loadDashboard()
    } catch (error) {
      setAuthError(error instanceof Error ? error.message : "Authentication failed")
    } finally {
      setAuthLoading(false)
    }
  }

  async function handleLogout() {
    const refreshToken = localStorage.getItem(REFRESH_TOKEN_KEY)
    clearSession()
    setUser(null)
    setDashboardState((current) => ({
      ...current,
      loading: false,
      error: "",
      watchlist: [],
      arbitrage: [],
      brandIndex: [],
      auctionLots: [],
      metrics: null,
      billing: null,
      arbitrageLocked: false,
    }))

    if (!refreshToken) return
    try {
      await fetch(`${API_BASE}/auth/logout`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refresh_token: refreshToken }),
      })
    } catch {
      // Local session is already cleared, so logout can remain best-effort.
    }
  }

  async function handleWatchlistSubmit(event) {
    event.preventDefault()
    setWatchlistSaving(true)
    setWatchlistError("")

    try {
      await apiRequest("/watchlist", {
        method: "POST",
        body: JSON.stringify(watchlistForm),
      })
      setWatchlistForm({ reference_code: "", brand: "", notes: "" })
      await loadDashboard()
    } catch (error) {
      setWatchlistError(error instanceof Error ? error.message : "Unable to save watchlist item")
    } finally {
      setWatchlistSaving(false)
    }
  }

  async function handleDeleteWatchlist(itemId) {
    try {
      await apiRequest(`/watchlist/${itemId}`, { method: "DELETE" })
      await loadDashboard()
    } catch (error) {
      setWatchlistError(error instanceof Error ? error.message : "Unable to remove watchlist item")
    }
  }

  const filteredLots = useMemo(() => {
    if (selectedBrand === "ALL") return dashboardState.auctionLots
    return dashboardState.auctionLots.filter((row) => row.brand === selectedBrand)
  }, [dashboardState.auctionLots, selectedBrand])

  const brandOptions = useMemo(
    () => ["ALL", ...dashboardState.brandIndex.map((row) => row.brand)],
    [dashboardState.brandIndex],
  )

  const topBrands = useMemo(
    () => [...dashboardState.brandIndex].sort((a, b) => b.demand_score - a.demand_score).slice(0, 5),
    [dashboardState.brandIndex],
  )

  if (!user) {
    return (
      <div className="app-shell">
        <section className="hero-panel">
          <div className="hero-copy">
            <span className="eyebrow">Watch Demand Index</span>
            <h1>Turn watch market noise into dealer-grade conviction.</h1>
            <p>
              This baseline now supports authentication, plan-aware API access, watchlists, billing status,
              and a live dashboard backed by the FastAPI service.
            </p>
            <div className="hero-meta">
              <div>
                <strong>API</strong>
                <span>{API_BASE}</span>
              </div>
              <div>
                <strong>Status</strong>
                <span>Starter platform under active hardening</span>
              </div>
            </div>
          </div>

          <form className="auth-card" onSubmit={handleAuthSubmit}>
            <div className="auth-toggle">
              <button
                type="button"
                className={authMode === "login" ? "active" : ""}
                onClick={() => setAuthMode("login")}
              >
                Sign in
              </button>
              <button
                type="button"
                className={authMode === "register" ? "active" : ""}
                onClick={() => setAuthMode("register")}
              >
                Create account
              </button>
            </div>

            {authMode === "register" && (
              <>
                <label>
                  Company name
                  <input
                    value={authForm.company_name}
                    onChange={(event) =>
                      setAuthForm((current) => ({ ...current, company_name: event.target.value }))
                    }
                    placeholder="Crown & Co"
                    required
                  />
                </label>

                <label>
                  Plan tier
                  <select
                    value={authForm.plan_tier}
                    onChange={(event) =>
                      setAuthForm((current) => ({ ...current, plan_tier: event.target.value }))
                    }
                  >
                    <option value="starter">Starter</option>
                    <option value="pro">Pro</option>
                    <option value="enterprise">Enterprise</option>
                  </select>
                </label>
              </>
            )}

            <label>
              Email
              <input
                type="email"
                value={authForm.email}
                onChange={(event) => setAuthForm((current) => ({ ...current, email: event.target.value }))}
                placeholder="dealer@example.com"
                required
              />
            </label>

            <label>
              Password
              <input
                type="password"
                value={authForm.password}
                onChange={(event) =>
                  setAuthForm((current) => ({ ...current, password: event.target.value }))
                }
                placeholder="••••••••"
                required
              />
            </label>

            {authError && <p className="error-banner">{authError}</p>}

            <button type="submit" className="primary-button" disabled={authLoading}>
              {authLoading ? "Working..." : authMode === "login" ? "Sign in" : "Create account"}
            </button>
          </form>
        </section>
      </div>
    )
  }

  return (
    <div className="app-shell">
      <header className="topbar">
        <div>
          <span className="eyebrow">Authenticated workspace</span>
          <h1>Dealer intelligence console</h1>
        </div>
        <div className="topbar-actions">
          <div className="identity-card">
            <strong>{user.email}</strong>
            <span>{user.role} for tenant {user.tenant_id}</span>
          </div>
          <button type="button" className="ghost-button" onClick={loadDashboard}>
            Refresh
          </button>
          <button type="button" className="ghost-button" onClick={handleLogout}>
            Sign out
          </button>
        </div>
      </header>

      {dashboardState.error && <p className="error-banner">{dashboardState.error}</p>}
      {watchlistError && <p className="error-banner">{watchlistError}</p>}

      {dashboardState.loading ? (
        <section className="loading-card">Loading dashboard data...</section>
      ) : (
        <>
          <section className="stats-grid">
            <MetricCard
              label="Total auction lots"
              value={dashboardState.metrics?.total_lots ?? 0}
              tooltip={METRIC_TOOLTIPS.totalLots}
            />
            <MetricCard
              label="Average auction price"
              value={formatCurrency(dashboardState.metrics?.avg_price)}
              tooltip={METRIC_TOOLTIPS.averagePrice}
            />
            <MetricCard
              label="Total auction value"
              value={formatCurrency(dashboardState.metrics?.total_value)}
              tooltip={METRIC_TOOLTIPS.totalValue}
            />
            <MetricCard
              label="Top auction brand"
              value={dashboardState.metrics?.top_brand || "-"}
              tooltip={METRIC_TOOLTIPS.topBrand}
            />
          </section>

          <section className="content-grid">
            <Panel
              title="Brand demand index"
              subtitle="API-aligned ranking from the live brand index endpoint"
              tooltip={PANEL_TOOLTIPS.brandDemandIndex}
            >
              <div className="brand-highlight-row">
                {topBrands.map((row) => (
                  <div className="brand-score-card" key={`${row.brand}-${row.date}`}>
                    <span>{row.brand}</span>
                    <strong>{row.demand_score.toFixed(1)}</strong>
                    <small>{row.lot_count} lots</small>
                  </div>
                ))}
              </div>

              <div className="table-wrap">
                <table>
                  <thead>
                    <tr>
                      <TableHeader label="Brand" tooltip={TABLE_TOOLTIPS.brandIndex.brand} />
                      <TableHeader label="Date" tooltip={TABLE_TOOLTIPS.brandIndex.date} />
                      <TableHeader label="Lots" tooltip={TABLE_TOOLTIPS.brandIndex.lots} />
                      <TableHeader label="Average price" tooltip={TABLE_TOOLTIPS.brandIndex.averagePrice} />
                      <TableHeader label="Total value" tooltip={TABLE_TOOLTIPS.brandIndex.totalValue} />
                      <TableHeader label="Demand score" tooltip={TABLE_TOOLTIPS.brandIndex.demandScore} />
                    </tr>
                  </thead>
                  <tbody>
                    {dashboardState.brandIndex.slice(0, 12).map((row) => (
                      <tr key={`${row.brand}-${row.date}`}>
                        <td>{row.brand}</td>
                        <td>{row.date}</td>
                        <td>{row.lot_count}</td>
                        <td>{formatCurrency(row.avg_price)}</td>
                        <td>{formatCurrency(row.total_value)}</td>
                        <td>{row.demand_score.toFixed(1)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </Panel>

            <Panel
              title="Account and billing"
              subtitle="Current tenant entitlement surface from the billing API"
              tooltip={PANEL_TOOLTIPS.accountAndBilling}
            >
              <dl className="definition-list">
                <div>
                  <dt>
                    <TooltipText text="Plan" tooltip={TABLE_TOOLTIPS.billing.plan} />
                  </dt>
                  <dd>{dashboardState.billing?.plan || "-"}</dd>
                </div>
                <div>
                  <dt>
                    <TooltipText text="Status" tooltip={TABLE_TOOLTIPS.billing.status} />
                  </dt>
                  <dd>{dashboardState.billing?.status || "-"}</dd>
                </div>
                <div>
                  <dt>
                    <TooltipText text="Subscription" tooltip={TABLE_TOOLTIPS.billing.subscription} />
                  </dt>
                  <dd>{dashboardState.billing?.stripe_subscription_id || "Not connected"}</dd>
                </div>
                <div>
                  <dt>
                    <TooltipText text="Period end" tooltip={TABLE_TOOLTIPS.billing.periodEnd} />
                  </dt>
                  <dd>{formatDateTime(dashboardState.billing?.current_period_end)}</dd>
                </div>
              </dl>
            </Panel>

            <Panel
              title="Auction feed"
              subtitle="Latest auction lots from the API"
              tooltip={PANEL_TOOLTIPS.auctionFeed}
            >
              <div className="toolbar">
                <label>
                  <TooltipText text="Filter brand" tooltip={TABLE_TOOLTIPS.auctionFeed.filterBrand} />
                  <select value={selectedBrand} onChange={(event) => setSelectedBrand(event.target.value)}>
                    {brandOptions.map((brand) => (
                      <option key={brand} value={brand}>
                        {brand}
                      </option>
                    ))}
                  </select>
                </label>
              </div>
              <div className="table-wrap">
                <table>
                  <thead>
                    <tr>
                      <TableHeader label="Auction" tooltip={TABLE_TOOLTIPS.auctionFeed.auction} />
                      <TableHeader label="Lot" tooltip={TABLE_TOOLTIPS.auctionFeed.lot} />
                      <TableHeader label="Brand" tooltip={TABLE_TOOLTIPS.auctionFeed.brand} />
                      <TableHeader label="Reference" tooltip={TABLE_TOOLTIPS.auctionFeed.reference} />
                      <TableHeader label="Model" tooltip={TABLE_TOOLTIPS.auctionFeed.model} />
                      <TableHeader label="Price" tooltip={TABLE_TOOLTIPS.auctionFeed.price} />
                    </tr>
                  </thead>
                  <tbody>
                    {filteredLots.slice(0, 20).map((row) => (
                      <tr key={`${row.auction_id}-${row.lot}`}>
                        <td>{row.auction_house}</td>
                        <td>{row.lot}</td>
                        <td>{row.brand}</td>
                        <td>{row.reference_code || "-"}</td>
                        <td>{row.model || "-"}</td>
                        <td>{formatCurrency(row.price)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </Panel>

            <Panel
              title="Watchlist"
              subtitle="Tenant-specific watchlist persisted through the protected API"
              tooltip={PANEL_TOOLTIPS.watchlist}
            >
              <form className="watchlist-form" onSubmit={handleWatchlistSubmit}>
                <input
                  placeholder="Reference code"
                  value={watchlistForm.reference_code}
                  onChange={(event) =>
                    setWatchlistForm((current) => ({ ...current, reference_code: event.target.value }))
                  }
                  required
                />
                <input
                  placeholder="Brand"
                  value={watchlistForm.brand}
                  onChange={(event) => setWatchlistForm((current) => ({ ...current, brand: event.target.value }))}
                />
                <input
                  placeholder="Notes"
                  value={watchlistForm.notes}
                  onChange={(event) => setWatchlistForm((current) => ({ ...current, notes: event.target.value }))}
                />
                <button type="submit" className="primary-button" disabled={watchlistSaving}>
                  {watchlistSaving ? "Saving..." : "Add watch"}
                </button>
              </form>

              <div className="watchlist-items">
                {dashboardState.watchlist.length === 0 ? (
                  <p className="muted-copy">No watchlist items yet.</p>
                ) : (
                  dashboardState.watchlist.map((item) => (
                    <div className="watchlist-item" key={item.item_id}>
                      <div>
                        <strong>{item.reference_code}</strong>
                        <p>{item.brand || "Unknown brand"}</p>
                        <small>{item.notes || "No notes yet"}</small>
                      </div>
                      <button
                        type="button"
                        className="ghost-button"
                        onClick={() => handleDeleteWatchlist(item.item_id)}
                      >
                        Remove
                      </button>
                    </div>
                  ))
                )}
              </div>
            </Panel>

            <Panel
              title="Arbitrage feed"
              tooltip={PANEL_TOOLTIPS.arbitrageFeed}
              subtitle={
                dashboardState.arbitrageLocked
                  ? "Locked behind Pro or Enterprise plans"
                  : "Live opportunities from the arbitrage endpoint"
              }
            >
              {dashboardState.arbitrageLocked ? (
                <div className="callout-card">
                  <strong>Upgrade required</strong>
                  <p>
                    The API correctly restricts arbitrage access to `pro` and `enterprise` tenants. This surface now
                    reflects that entitlement instead of failing the whole page.
                  </p>
                </div>
              ) : (
                <div className="table-wrap">
                  <table>
                    <thead>
                      <tr>
                        <TableHeader label="Source" tooltip={TABLE_TOOLTIPS.arbitrage.source} />
                        <TableHeader label="Seller" tooltip={TABLE_TOOLTIPS.arbitrage.seller} />
                        <TableHeader label="Brand" tooltip={TABLE_TOOLTIPS.arbitrage.brand} />
                        <TableHeader label="Reference" tooltip={TABLE_TOOLTIPS.arbitrage.reference} />
                        <TableHeader label="Dealer price" tooltip={TABLE_TOOLTIPS.arbitrage.dealerPrice} />
                        <TableHeader label="Market price" tooltip={TABLE_TOOLTIPS.arbitrage.marketPrice} />
                        <TableHeader label="Profit" tooltip={TABLE_TOOLTIPS.arbitrage.profit} />
                        <TableHeader label="Grade" tooltip={TABLE_TOOLTIPS.arbitrage.grade} />
                      </tr>
                    </thead>
                    <tbody>
                      {dashboardState.arbitrage.slice(0, 15).map((row, index) => (
                        <tr key={`${row.reference}-${row.seller}-${index}`}>
                          <td>{row.source}</td>
                          <td>{row.seller}</td>
                          <td>{row.brand}</td>
                          <td>{row.reference}</td>
                          <td>{formatCurrency(row.dealer_price)}</td>
                          <td>{formatCurrency(row.median_price)}</td>
                          <td>{formatPercent(row.profit_percent)}</td>
                          <td>{row.opportunity_grade}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </Panel>
          </section>
        </>
      )}
    </div>
  )
}

function InfoTooltip({ label, text }) {
  return (
    <span className="tooltip-anchor" tabIndex={0} title={text} aria-label={`${label}: ${text}`}>
      <span className="tooltip-dot" aria-hidden="true">
        i
      </span>
      <span className="tooltip-bubble" role="tooltip">
        {text}
      </span>
    </span>
  )
}

function TooltipText({ text, tooltip }) {
  return (
    <span className="tooltip-label">
      <span>{text}</span>
      {tooltip ? <InfoTooltip label={text} text={tooltip} /> : null}
    </span>
  )
}

function TableHeader({ label, tooltip }) {
  return (
    <th>
      <TooltipText text={label} tooltip={tooltip} />
    </th>
  )
}

function MetricCard({ label, value, tooltip }) {
  return (
    <article className="metric-card">
      <span>
        <TooltipText text={label} tooltip={tooltip} />
      </span>
      <strong>{value}</strong>
    </article>
  )
}

function Panel({ title, subtitle, tooltip, children }) {
  return (
    <section className="panel">
      <div className="panel-header">
        <h2>
          <TooltipText text={title} tooltip={tooltip} />
        </h2>
        <p>{subtitle}</p>
      </div>
      {children}
    </section>
  )
}

export default App
