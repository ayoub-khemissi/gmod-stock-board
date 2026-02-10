-- lua/stockboard/server/sv_trading.lua

-- Cooldowns: per-player AND per-stock to prevent cross-market manipulation
-- Format: StockBoard.Cooldowns[steamid] = { global = timestamp, [stockId] = timestamp }
StockBoard.Cooldowns = StockBoard.Cooldowns or {}

local CFG = StockBoard.Config

local function CheckCooldown(ply, stockId)
    -- Admin bypass removed for market integrity
    local steamid = ply:SteamID()
    local cd = StockBoard.Cooldowns[steamid]
    if not cd then return true end

    local now = os.time()

    -- Global cooldown (any trade)
    if cd.global and (now - cd.global) < CFG.TradeCooldown then
        return false
    end

    -- Per-stock cooldown (same stock traded twice)
    if stockId and cd[stockId] and (now - cd[stockId]) < CFG.TradeStockCooldown then
        return false
    end

    return true
end

local function SetCooldown(ply, stockId)
    local steamid = ply:SteamID()
    StockBoard.Cooldowns[steamid] = StockBoard.Cooldowns[steamid] or {}
    local now = os.time()
    StockBoard.Cooldowns[steamid].global = now
    if stockId then
        StockBoard.Cooldowns[steamid][stockId] = now
    end
end

function StockBoard.BuyStock(ply, stockId, shares)
    if not IsValid(ply) then return end

    -- 1. Validations
    if not CheckCooldown(ply, stockId) then
        StockBoard.NotifyPlayer(ply, StockBoard.Lang.ErrCooldown, "error")
        return
    end

    -- Server-side shares validation (defense in depth)
    if not shares or shares < CFG.MinShares or shares > CFG.MaxShares then
        StockBoard.NotifyPlayer(ply, string.format(StockBoard.Lang.ErrLimitReached, CFG.MinShares, CFG.MaxShares), "error")
        return
    end

    local stockData = StockBoard.Prices[stockId]
    if not stockData then return end

    -- 2. Price calculation
    local pricePerShare = stockData.current
    local subTotal = pricePerShare * shares
    local fees = subTotal * CFG.TransactionFee
    local totalCost = math.ceil(subTotal + fees) -- Round up to prevent float exploits

    -- 3. Money check
    StockBoard.Log("Player " .. ply:Nick() .. " trying to buy " .. shares .. " of " .. stockId .. " for " .. totalCost)

    if ply.canAfford then
        if not ply:canAfford(totalCost) then
            StockBoard.NotifyPlayer(ply, StockBoard.Lang.ErrCannotAfford, "error")
            return
        end
    else
        StockBoard.Log("ERROR: ply:canAfford not found! Is DarkRP installed?")
        StockBoard.NotifyPlayer(ply, "System Error: Money system not found (console for details)", "error")
        return
    end

    -- 4. Execution
    if ply.addMoney then
        ply:addMoney(-totalCost)
    else
        StockBoard.Log("ERROR: ply:addMoney not found!")
        StockBoard.NotifyPlayer(ply, "System Error: Money system not found", "error")
        return
    end

    local steamid = ply:SteamID()
    StockBoard.Portfolios[steamid] = StockBoard.Portfolios[steamid] or {}
    local port = StockBoard.Portfolios[steamid]

    if not port[stockId] then
        port[stockId] = { shares = 0, avgPrice = 0 }
    end

    -- Weighted average update
    local oldVal = port[stockId].shares * port[stockId].avgPrice
    local newVal = shares * pricePerShare
    local newShares = port[stockId].shares + shares
    port[stockId].avgPrice = (oldVal + newVal) / newShares
    port[stockId].shares = newShares

    -- 5. Finalization
    SetCooldown(ply, stockId)
    StockBoard.SavePortfolios()

    -- Stats: record investment amount
    local stats = StockBoard.GetPlayerStats(steamid)
    stats.totalInvested = stats.totalInvested + totalCost
    StockBoard.RecordTrade(ply, nil) -- Just increment trade counter

    -- Market impact
    StockBoard.ApplyBuyPressure(stockId, shares)

    -- Notifications & update
    StockBoard.NotifyPlayer(ply, string.format(StockBoard.Lang.Bought, shares, stockId, CFG.CurrencySymbol..math.Round(totalCost)), "success")
    StockBoard.SendPortfolio(ply)
    StockBoard.SendPlayerStats(ply)
end

function StockBoard.SellStock(ply, stockId, shares)
    if not IsValid(ply) then return end

    if not CheckCooldown(ply, stockId) then
        StockBoard.NotifyPlayer(ply, StockBoard.Lang.ErrCooldown, "error")
        return
    end

    -- Server-side shares validation (defense in depth)
    if not shares or shares < CFG.MinShares or shares > CFG.MaxShares then
        StockBoard.NotifyPlayer(ply, string.format(StockBoard.Lang.ErrLimitReached, CFG.MinShares, CFG.MaxShares), "error")
        return
    end

    local steamid = ply:SteamID()
    local port = StockBoard.Portfolios[steamid]

    if not port or not port[stockId] or port[stockId].shares < shares then
        StockBoard.NotifyPlayer(ply, StockBoard.Lang.ErrNotEnough, "error")
        return
    end

    local stockData = StockBoard.Prices[stockId]
    if not stockData then return end

    local pricePerShare = stockData.current
    local subTotal = pricePerShare * shares
    local fees = subTotal * CFG.TransactionFee
    local totalRevenue = math.floor(subTotal - fees) -- Round down to prevent float exploits

    -- Profit calculation
    local buyCost = port[stockId].avgPrice * shares
    local profit = totalRevenue - buyCost

    -- Execution
    StockBoard.Log("Player " .. ply:Nick() .. " selling " .. shares .. " of " .. stockId .. " for " .. totalRevenue)

    if ply.addMoney then
        ply:addMoney(totalRevenue)
    else
        StockBoard.Log("ERROR: ply:addMoney not found!")
        StockBoard.NotifyPlayer(ply, "System Error: Money system not found", "error")
        return
    end

    port[stockId].shares = port[stockId].shares - shares
    if port[stockId].shares <= 0 then
        port[stockId] = nil
    end

    SetCooldown(ply, stockId)
    StockBoard.SavePortfolios()
    StockBoard.RecordTrade(ply, profit)

    -- Market impact
    StockBoard.ApplySellPressure(stockId, shares)

    StockBoard.NotifyPlayer(ply, string.format(StockBoard.Lang.Sold, shares, stockId, CFG.CurrencySymbol..math.Round(totalRevenue), CFG.CurrencySymbol..math.Round(profit)), "success")
    StockBoard.SendPortfolio(ply)
    StockBoard.SendPlayerStats(ply)
end
