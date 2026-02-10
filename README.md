# Stock Board

A real-time stock market simulation addon for **Garry's Mod DarkRP** servers. Players buy and sell shares of fictional companies, track prices with interactive charts, climb investor ranks, and compete on leaderboards.

---

## Features

- **8 fictional companies** with unique icons, colors, base prices, and volatility
- **Real-time price fluctuations** with configurable tick intervals
- **Buy & sell shares** using DarkRP money with transaction fees
- **Modern DHTML UI** built with TailwindCSS and FontAwesome (4 tabs: Market, Portfolio, Charts, Stats)
- **Interactive charts** with sparklines on market cards and a full-size chart view
- **Portfolio tracking** with weighted average prices, return calculations, and total value
- **Investor ranks** (Intern to Wolf of Wall Street) based on realized profit
- **Market events** (Tech Breakthrough, Market Crash, etc.) that shift prices temporarily
- **Leaderboards** ranked by total profit or trade count
- **Anti-abuse protections**: input validation, per-stock cooldowns, transaction fees, mean reversion, price clamping
- **Permission system**: group whitelist, job blacklist
- **Fully configurable**: theme colors, UI text, stocks, events, ranks, and more
- **Data persistence**: prices, portfolios, and stats survive server restarts (JSON files)

---

## Installation

1. Download or clone this repository
2. Place the `stock-board` folder into your server's `addons` directory:
   ```
   garrysmod/addons/stock-board/
   ```
3. Restart your server (or change map)
4. The addon loads automatically — no extra steps required

### Requirements

- **Garry's Mod** dedicated server or listen server
- **DarkRP** gamemode (uses `ply:canAfford()`, `ply:addMoney()`)

---

## Usage

### Opening the menu

Players can open the Stock Board using any of these chat commands:

| Command | Description |
|---------|-------------|
| `!stocks` | Open the stock board |
| `/stocks` | Open the stock board |
| `!bourse` | French alias |
| `/bourse` | French alias |
| `!sb` | Short alias |
| `/sb` | Short alias |

Or via console: `stockboard_menu`

### Buying shares

1. Open the Stock Board
2. On the **Market** tab, find the company you want to invest in
3. Click **BUY** on the stock card
4. Use the quantity buttons (-10, -1, +1, +10) to set the amount
5. Review the total cost (including fees) and click **CONFIRM PURCHASE**

The amount (price x quantity + fees) is deducted from your DarkRP wallet.

### Selling shares

1. Open the Stock Board
2. Click **SELL** on a stock card (only available if you own shares)
3. Set the quantity (limited to the shares you own)
4. Review the revenue (minus fees) and click **CONFIRM SALE**

The SELL button is disabled (greyed out) for stocks you don't own.

### Viewing your portfolio

Switch to the **Portfolio** tab to see:
- All your holdings with current value, average buy price, and return percentage
- Total portfolio value

### Charts

Click on any stock card or switch to the **Charts** tab to see a full-size price history chart. Use the sidebar to switch between companies.

### Stats & Ranks

The **Stats** tab shows:
- Total invested, realized profit, trade count, and best trade
- Your current rank and progress toward the next one
- Leaderboards (filter by Profit or Trades)

---

## Configuration

All settings are in a single file:

```
lua/stockboard/shared/sh_config.lua
```

After editing, restart the server or change map to apply changes.

### General

| Setting | Default | Description |
|---------|---------|-------------|
| `CurrencySymbol` | `$` | Symbol shown in the UI |
| `CurrencyName` | `dollars` | Currency name |

### Market

| Setting | Default | Description |
|---------|---------|-------------|
| `TickInterval` | `30` | Seconds between each price fluctuation |
| `PriceHistoryLength` | `60` | Number of price history data points to keep |
| `PriceMin` | `5` | Absolute minimum price (hard floor) |
| `PriceMax` | `10000` | Absolute maximum price (hard ceiling) |
| `MeanReversionForce` | `2` | Pull strength toward base price. Prevents prices drifting too far. `0` = disabled |

### Trading

| Setting | Default | Description |
|---------|---------|-------------|
| `TransactionFee` | `0.05` | 5% fee per trade (anti wash-trading) |
| `MinShares` | `1` | Minimum shares per transaction |
| `MaxShares` | `100` | Maximum shares per transaction |
| `TradeCooldown` | `10` | Seconds between any trade (global) |
| `TradeStockCooldown` | `30` | Seconds between trades on the same stock (anti pump & dump) |

### Market Pressure

| Setting | Default | Description |
|---------|---------|-------------|
| `PressurePerShare` | `0.05` | % price impact per share traded. 100 shares = 5% instant price move |

### Events

| Setting | Default | Description |
|---------|---------|-------------|
| `EventChance` | `8` | % chance of a market event per tick (0-100) |
| `EventDuration` | `10` | Event duration in ticks (10 ticks x 30s = 5 minutes) |

### Stocks

Each stock has the following properties:

| Property | Description |
|----------|-------------|
| `id` | Unique identifier (used internally and as sector for events) |
| `name` | Display name |
| `icon` | FontAwesome icon class |
| `color` | Hex color (without `#`) |
| `basePrice` | Starting price and mean reversion target |
| `volatility` | % random price swing per tick (higher = riskier) |

**Default stocks:**

| ID | Name | Base Price | Volatility |
|----|------|-----------|------------|
| `wood` | Darkwood Ind. | $50 | 3% |
| `nrg` | Nova Energy | $120 | 4% |
| `arms` | Ironclad Arms | $300 | 6% |
| `med` | Medica Corp | $200 | 2% |
| `tech` | Nexus Tech | $500 | 8% |
| `mine` | Lunar Mining | $150 | 5% |
| `ship` | Oceanic Trade | $80 | 3% |
| `bank` | Shadow Finance | $1000 | 7% |

### Events

Each event targets a stock sector (or `all`) and applies a price modifier for the event duration:

```lua
StockBoard.Config.Events = {
    { text = "Health Scandal!",      sector = "med",  modifier = 0.85 },  -- -15%
    { text = "Tech Breakthrough!",   sector = "tech", modifier = 1.15 },  -- +15%
    { text = "Gang Wars!",           sector = "arms", modifier = 1.20 },  -- +20%
    { text = "Forest Fire!",         sector = "wood", modifier = 0.80 },  -- -20%
    { text = "Market Crash!",        sector = "all",  modifier = 0.90 },  -- -10%
    { text = "Economic Boom!",       sector = "all",  modifier = 1.10 },  -- +10%
    { text = "New Mine Discovered!", sector = "mine", modifier = 1.25 },  -- +25%
    { text = "Massive Blackout!",    sector = "nrg",  modifier = 0.85 },  -- -15%
}
```

### Ranks

Ranks are based on total realized profit (only positive profit counts toward progression):

| Rank | Profit Threshold |
|------|-----------------|
| Intern | $0 |
| Trader | $5,000 |
| Broker | $25,000 |
| Analyst | $100,000 |
| Whale | $500,000 |
| Tycoon | $2,000,000 |
| Wolf of Wall Street | $10,000,000 |

### Permissions

| Setting | Default | Description |
|---------|---------|-------------|
| `AllowedGroups` | `{}` | UserGroups allowed to trade. Empty = everyone |
| `BlacklistedJobs` | `{}` | DarkRP jobs that cannot trade |
| `ImmuneGroups` | `{"superadmin"}` | UserGroups with special access |
| `AdminBypass` | `false` | Disabled for market integrity |

### Logging

| Setting | Default | Description |
|---------|---------|-------------|
| `LogToConsole` | `true` | Print trade events to server console |
| `LogPrefix` | `[StockBoard]` | Prefix for console log messages |

### Chat Commands

```lua
StockBoard.Config.ChatCommands = { "!stocks", "/stocks", "!bourse", "/bourse", "!sb", "/sb" }
```

Add or remove commands as needed.

---

## UI Customization

### Theme Colors

All UI colors are configurable via `StockBoard.Config.Theme`. Values are hex color codes **without** the `#`:

```lua
StockBoard.Config.Theme = {
    BgPage      = "020408",     -- Main background
    BgCard      = "0f172a",     -- Card background
    BgCardHover = "1e293b",     -- Card hover
    Border      = "1e293b",     -- Borders
    BorderHover = "334155",     -- Border hover
    Accent      = "58c6fc",     -- Main accent color (light blue)
    AccentHover = "38a6dc",     -- Accent hover
    AccentLight = "88d6fd",     -- Light accent
    TextTitle   = "58c6fc",     -- Title color
    TextPrimary = "f1f5f9",     -- Primary text
    TextSecondary = "94a3b8",   -- Secondary text
    Success     = "58c6fc",     -- Success notifications
    Danger      = "ef4444",     -- Error / danger
    Info        = "3b82f6",     -- Info
    Warning     = "f59e0b",     -- Warnings
}
```

### HUD Colors

Toast notifications use Lua `Color()` objects in `StockBoard.Colors`. Update these to match your theme:

```lua
StockBoard.Colors = {
    Bg            = Color(2, 4, 8),
    Card          = Color(15, 23, 42),
    Border        = Color(30, 41, 59),
    Accent        = Color(88, 198, 252),
    AccentDark    = Color(56, 166, 220),
    Danger        = Color(239, 68, 68),
    Success       = Color(88, 198, 252),
    TextPrimary   = Color(241, 245, 249),
    TextSecondary = Color(148, 163, 184),
    Black         = Color(0, 0, 0),
    White         = Color(255, 255, 255),
}
```

### UI Text / Translation

All visible text in the menu is in `StockBoard.Config.UI`. Change the values to translate or rephrase:

```lua
StockBoard.Config.UI = {
    Title       = "STOCK BOARD",
    Subtitle    = "REAL-TIME MARKET",
    TabMarket   = "Market",
    TabPortfolio= "Portfolio",
    TabCharts   = "Charts",
    TabStats    = "Stats",
    -- ... see sh_config.lua for the full list
}
```

Notification messages are in `StockBoard.Lang` with `%s` placeholders for dynamic values.

---

## Anti-Abuse & Security

The addon includes several layers of protection against market manipulation:

- **Input validation**: stock IDs and share counts are validated server-side at the network layer. Negative, zero, or out-of-range values are blocked and logged.
- **Per-stock cooldowns**: players must wait 30 seconds before trading the same stock again, preventing rapid pump & dump cycles.
- **Global cooldown**: 10 seconds between any trade to limit bot/macro abuse.
- **Transaction fees**: 5% fee per trade makes wash-trading (buy-sell-buy cycles) unprofitable. Round-trip cost is ~10%.
- **Mean reversion**: prices naturally gravitate back toward their base price, preventing infinite drift.
- **Price clamping**: hard floor ($5) and ceiling ($10,000) on all prices, including after player pressure.
- **Market pressure clamping**: buy/sell pressure respects price bounds.
- **Server-side enforcement**: all limits (MaxShares, money checks, share ownership) are validated server-side. Client-side limits are cosmetic only.
- **No admin bypass on trading**: disabled by default to preserve market integrity.

---

## File Structure

```
stock-board/
├── addon.json                              -- Workshop metadata
├── README.md                               -- This file
└── lua/
    ├── autorun/
    │   └── stockboard_init.lua            -- Loader
    └── stockboard/
        ├── shared/
        │   └── sh_config.lua              -- All configuration
        ├── server/
        │   ├── sv_network.lua             -- Net strings, senders, input validation
        │   ├── sv_data.lua                -- Data persistence & player stats
        │   ├── sv_trading.lua             -- Buy/sell logic, cooldowns
        │   └── sv_market.lua              -- Price ticks, events, pressure
        └── client/
            ├── cl_fonts.lua               -- HUD fonts
            ├── cl_notifications.lua       -- Toast notifications (HUD)
            └── cl_menu.lua                -- Main DHTML menu
```

---

## Data Storage

All data is saved to:
```
garrysmod/data/stockboard/prices.json
garrysmod/data/stockboard/portfolios.json
garrysmod/data/stockboard/stats.json
```

These files are automatically created and updated. All data persists across server restarts.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Menu doesn't open | Check console for Lua errors. Ensure DarkRP is the active gamemode |
| "You cannot afford this transaction" | You don't have enough DarkRP money (including the 5% fee) |
| SELL button is greyed out | You don't own any shares of that stock |
| "Please wait before trading again" | Wait for the cooldown to expire (10s global, 30s per stock) |
| Prices don't update | Check that the server tick timer is running (`StockBoard_MarketTick`) |
| UI looks broken | The DHTML panel needs internet access for TailwindCSS and FontAwesome CDNs |
| Wallet not detected | Ensure DarkRP is installed. The addon tries `getDarkRPVar("money")`, `getDarkRPvar("money")`, and `GetMoney()` |
