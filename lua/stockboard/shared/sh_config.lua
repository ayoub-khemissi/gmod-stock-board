-- lua/stockboard/shared/sh_config.lua

StockBoard = StockBoard or {}
StockBoard.Config = StockBoard.Config or {}

-- 1. General Config
StockBoard.Config.CurrencySymbol = "$"
StockBoard.Config.CurrencyName = "dollars"

StockBoard.Config.TickInterval = 30       -- Seconds between each price fluctuation
StockBoard.Config.PriceHistoryLength = 60 -- How many history data points to keep
StockBoard.Config.TransactionFee = 0.05   -- 5% fee per trade (anti wash-trading)
StockBoard.Config.MinShares = 1           -- Min shares per transaction
StockBoard.Config.MaxShares = 100         -- Max shares per transaction
StockBoard.Config.TradeCooldown = 10      -- Seconds between any trade (global)
StockBoard.Config.TradeStockCooldown = 30 -- Seconds between trades on the SAME stock (anti pump&dump)
StockBoard.Config.EventChance = 8         -- % chance of event per tick (0-100)
StockBoard.Config.EventDuration = 10      -- Event duration (in ticks)
StockBoard.Config.PressurePerShare = 0.05 -- % price impact per share traded (buy/sell pressure)
StockBoard.Config.MeanReversionForce = 2  -- Pull strength toward base price (0 = disabled)

StockBoard.Config.PriceMin = 5
StockBoard.Config.PriceMax = 10000

-- 2. Stocks (Entreprises)
StockBoard.Config.Stocks = {
    { id = "wood",  name = "Darkwood Ind.",   icon = "fa-tree",             color = "22c55e", basePrice = 50,  volatility = 3 },
    { id = "nrg",   name = "Nova Energy",     icon = "fa-bolt",             color = "eab308", basePrice = 120, volatility = 4 },
    { id = "arms",  name = "Ironclad Arms",   icon = "fa-gun",              color = "ef4444", basePrice = 300, volatility = 6 },
    { id = "med",   name = "Medica Corp",     icon = "fa-heart-pulse",      color = "ec4899", basePrice = 200, volatility = 2 },
    { id = "tech",  name = "Nexus Tech",      icon = "fa-microchip",        color = "3b82f6", basePrice = 500, volatility = 8 },
    { id = "mine",  name = "Lunar Mining",    icon = "fa-gem",              color = "a855f7", basePrice = 150, volatility = 5 },
    { id = "ship",  name = "Oceanic Trade",   icon = "fa-ship",             color = "06b6d4", basePrice = 80,  volatility = 3 },
    { id = "bank",  name = "Shadow Finance",  icon = "fa-building-columns", color = "64748b", basePrice = 1000, volatility = 7 },
}

-- 3. Events
-- modifier: price multiplier (e.g. 1.10 = +10%, 0.85 = -15%)
-- sector: stock id or "all"
StockBoard.Config.Events = {
    { text = "Health Scandal!",         icon = "fa-biohazard",          sector = "med",  modifier = 0.85 },
    { text = "Tech Breakthrough!",      icon = "fa-rocket",             sector = "tech", modifier = 1.15 },
    { text = "Gang Wars!",              icon = "fa-person-rifle",       sector = "arms", modifier = 1.20 },
    { text = "Forest Fire!",            icon = "fa-fire",               sector = "wood", modifier = 0.80 },
    { text = "Market Crash!",           icon = "fa-chart-line-down",    sector = "all",  modifier = 0.90 },
    { text = "Economic Boom!",          icon = "fa-money-bill-trend-up",sector = "all",  modifier = 1.10 },
    { text = "New Mine Discovered!",    icon = "fa-gem",                sector = "mine", modifier = 1.25 },
    { text = "Massive Blackout!",       icon = "fa-plug-circle-xmark",  sector = "nrg",  modifier = 0.85 },
}

-- 4. Ranks (Based on total realized profit)
StockBoard.Config.Ranks = {
    { name = "Intern",              threshold = 0,        icon = "fa-user-graduate" },
    { name = "Trader",              threshold = 5000,     icon = "fa-briefcase" },
    { name = "Broker",              threshold = 25000,    icon = "fa-id-badge" },
    { name = "Analyst",             threshold = 100000,   icon = "fa-chart-pie" },
    { name = "Whale",               threshold = 500000,   icon = "fa-hippo" },
    { name = "Tycoon",              threshold = 2000000,  icon = "fa-city" },
    { name = "Wolf of Wall Street", threshold = 10000000, icon = "fa-wolf-pack-battalion" },
}

-- 5. Permissions
StockBoard.Config.AllowedGroups = {}       -- empty = everyone allowed
StockBoard.Config.BlacklistedJobs = {}
StockBoard.Config.ImmuneGroups = { "superadmin" }
StockBoard.Config.AdminBypass = false -- Disabled for market integrity

-- 6. Chat commands
StockBoard.Config.ChatCommands = { "!stocks", "/stocks", "!bourse", "/bourse", "!sb", "/sb" }

-- 7. Logging
StockBoard.Config.LogToConsole = true
StockBoard.Config.LogPrefix = "[StockBoard]"

-- 8. Theme UI (Hex colors WITHOUT #)
StockBoard.Config.Theme = {
    -- Fond & panneaux (Dark Finance)
    BgPage      = "020408", -- Very dark, near black
    BgCard      = "0f172a", -- Slate 900
    BgCardHover = "1e293b", -- Slate 800
    BgInput     = "0f172a",
    Border      = "1e293b",
    BorderHover = "334155",

    -- Accent (Light Blue Finance)
    Accent      = "58c6fc", -- Requested Light Blue
    AccentHover = "38a6dc", -- Darker
    AccentLight = "88d6fd", -- Lighter

    -- Texte
    TextTitle   = "58c6fc",
    TextPrimary = "f1f5f9", -- Slate 100
    TextSecondary = "94a3b8", -- Slate 400

    -- Statuts
    Success     = "58c6fc",
    Danger      = "ef4444",
    Info        = "3b82f6",
    Warning     = "f59e0b",
}

-- 9. UI Text
StockBoard.Config.UI = {
    Title       = "STOCK BOARD",
    Subtitle    = "REAL-TIME MARKET",

    -- Tabs
    TabMarket   = "Market",
    TabPortfolio= "Portfolio",
    TabCharts   = "Charts",
    TabStats    = "Stats",

    -- Market
    LblPrice    = "Price",
    LblChange   = "24h %",
    BtnBuy      = "BUY",
    BtnSell     = "SELL",
    
    -- Portfolio
    LblShares   = "Shares",
    LblAvgPrice = "Avg Price",
    LblCurrent  = "Current",
    LblReturn   = "Return",
    LblTotalVal = "Total Value",
    EmptyPort   = "You don't own any stocks yet.",

    -- Stats
    StatsTitle  = "My Stats",
    LblInvested = "Total Invested",
    LblProfit   = "Realized Profit",
    LblTrades   = "Trades Count",
    LblBest     = "Best Trade",
    LblRank     = "Current Rank",
}

-- 10. Lang (Notifications)
StockBoard.Lang = {
    ErrNotAllowed   = "You are not allowed to access the stock market!",
    ErrCooldown     = "Please wait before trading again.",
    ErrCannotAfford = "You cannot afford this transaction!",
    ErrNotEnough    = "You don't have enough shares!",
    ErrLimitReached = "Transaction limit reached (Min: %s, Max: %s).",
    
    Bought          = "Bought %s shares of %s for %s.",
    Sold            = "Sold %s shares of %s for %s (Profit: %s).",
    
    EventStart      = "MARKET NEWS: %s",
    PriceUpdate     = "Market prices updated.",
}

-- 11. HUD Colors (Lua)
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