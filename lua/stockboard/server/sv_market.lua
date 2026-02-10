-- lua/stockboard/server/sv_market.lua

StockBoard.ActiveEvent = nil

-- Main tick timer
timer.Create("StockBoard_MarketTick", StockBoard.Config.TickInterval, 0, function()
    StockBoard.TickMarket()
end)

function StockBoard.TickMarket()
    -- 1. Event management
    if StockBoard.ActiveEvent then
        StockBoard.ActiveEvent.ticksRemaining = StockBoard.ActiveEvent.ticksRemaining - 1
        if StockBoard.ActiveEvent.ticksRemaining <= 0 then
            StockBoard.ActiveEvent = nil
            StockBoard.NotifyAll("Market is stabilizing...", "info")
        end
    else
        -- Chance to spawn new event
        if math.random(100) <= StockBoard.Config.EventChance then
            local events = StockBoard.Config.Events
            local ev = events[math.random(#events)]

            StockBoard.ActiveEvent = {
                text = ev.text,
                icon = ev.icon,
                sector = ev.sector,
                modifier = ev.modifier,
                ticksRemaining = StockBoard.Config.EventDuration
            }

            -- Broadcast event start
            local type = (ev.modifier >= 1) and "success" or "error"
            StockBoard.NotifyAll(string.format(StockBoard.Lang.EventStart, ev.text), type)

            net.Start("StockBoard_MarketEvent")
                net.WriteTable({
                    text = ev.text,
                    icon = ev.icon,
                    sector = ev.sector,
                    type = (ev.modifier >= 1) and "positive" or "negative"
                })
            net.Broadcast()
        end
    end

    -- 2. Price fluctuation
    for _, stock in ipairs(StockBoard.Config.Stocks) do
        local data = StockBoard.Prices[stock.id]
        local current = data.current

        -- Base random variation
        local volatility = stock.volatility
        local changePercent = math.Rand(-volatility, volatility)

        -- Mean reversion: pull price back toward base price
        -- The further the price deviates, the stronger the pull
        local deviation = (current - stock.basePrice) / stock.basePrice
        local reversion = -deviation * StockBoard.Config.MeanReversionForce
        changePercent = changePercent + reversion

        -- Event influence
        if StockBoard.ActiveEvent then
            if StockBoard.ActiveEvent.sector == "all" or StockBoard.ActiveEvent.sector == stock.id then
                local mod = (StockBoard.ActiveEvent.modifier - 1) * 100
                changePercent = changePercent + mod
            end
        end

        -- Calculate new price
        local newPrice = current * (1 + (changePercent / 100))

        -- Clamp within bounds
        newPrice = math.Clamp(newPrice, StockBoard.Config.PriceMin, StockBoard.Config.PriceMax)
        newPrice = math.Round(newPrice, 2)

        -- Update data
        data.lastChange = math.Round(((newPrice - current) / current) * 100, 2)
        data.current = newPrice

        table.insert(data.history, newPrice)
        if #data.history > StockBoard.Config.PriceHistoryLength then
            table.remove(data.history, 1)
        end
    end

    StockBoard.SavePrices()

    -- 3. Broadcast price update
    local updates = {}
    for id, data in pairs(StockBoard.Prices) do
        updates[id] = { c = data.current, l = data.lastChange }
    end

    net.Start("StockBoard_PriceTick")
        net.WriteTable(updates)
    net.Broadcast()
end

-- Player trade pressure on market (called by sv_trading)
function StockBoard.ApplyBuyPressure(stockId, quantity)
    local impact = quantity * StockBoard.Config.PressurePerShare
    local data = StockBoard.Prices[stockId]
    if not data then return end

    data.current = data.current * (1 + (impact / 100))
    data.current = math.Clamp(data.current, StockBoard.Config.PriceMin, StockBoard.Config.PriceMax)
    data.current = math.Round(data.current, 2)
end

function StockBoard.ApplySellPressure(stockId, quantity)
    local impact = quantity * StockBoard.Config.PressurePerShare
    local data = StockBoard.Prices[stockId]
    if not data then return end

    data.current = data.current * (1 - (impact / 100))
    data.current = math.Clamp(data.current, StockBoard.Config.PriceMin, StockBoard.Config.PriceMax)
    data.current = math.Round(data.current, 2)
end
