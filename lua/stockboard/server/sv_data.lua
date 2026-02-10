-- lua/stockboard/server/sv_data.lua

StockBoard.Prices = StockBoard.Prices or {}
StockBoard.Portfolios = StockBoard.Portfolios or {}
StockBoard.PlayerStats = StockBoard.PlayerStats or {}

local DATA_DIR = "stockboard"
local PATH_PRICES = DATA_DIR .. "/prices.json"
local PATH_PORTFOLIOS = DATA_DIR .. "/portfolios.json"
local PATH_STATS = DATA_DIR .. "/stats.json"

function StockBoard.InitData()
    if not file.IsDir(DATA_DIR, "DATA") then
        file.CreateDir(DATA_DIR)
    end
    
    -- 1. Prices
    if file.Exists(PATH_PRICES, "DATA") then
        local content = file.Read(PATH_PRICES, "DATA")
        StockBoard.Prices = util.JSONToTable(content) or {}
    end
    
    -- Initialiser les stocks manquants
    for _, stock in ipairs(StockBoard.Config.Stocks) do
        if not StockBoard.Prices[stock.id] then
            StockBoard.Prices[stock.id] = {
                current = stock.basePrice,
                history = {},
                lastChange = 0
            }
            -- Remplir un faux historique initial
            for i=1, StockBoard.Config.PriceHistoryLength do
                table.insert(StockBoard.Prices[stock.id].history, stock.basePrice)
            end
        end
    end
    
    -- 2. Portfolios
    if file.Exists(PATH_PORTFOLIOS, "DATA") then
        local content = file.Read(PATH_PORTFOLIOS, "DATA")
        StockBoard.Portfolios = util.JSONToTable(content) or {}
    end
    
    -- 3. Stats
    if file.Exists(PATH_STATS, "DATA") then
        local content = file.Read(PATH_STATS, "DATA")
        StockBoard.PlayerStats = util.JSONToTable(content) or {}
    end
end

function StockBoard.SavePrices()
    file.Write(PATH_PRICES, util.TableToJSON(StockBoard.Prices))
end

function StockBoard.SavePortfolios()
    file.Write(PATH_PORTFOLIOS, util.TableToJSON(StockBoard.Portfolios))
end

function StockBoard.SaveStats()
    file.Write(PATH_STATS, util.TableToJSON(StockBoard.PlayerStats))
end

function StockBoard.GetPlayerStats(steamid)
    if not StockBoard.PlayerStats[steamid] then
        StockBoard.PlayerStats[steamid] = {
            totalInvested = 0,
            totalProfit = 0,
            trades = 0,
            biggestTrade = 0,
            name = "Unknown"
        }
    end
    return StockBoard.PlayerStats[steamid]
end

function StockBoard.RecordTrade(ply, profit)
    local steamid = ply:SteamID()
    local stats = StockBoard.GetPlayerStats(steamid)
    
    stats.name = ply:Nick()
    stats.trades = stats.trades + 1
    
    if profit then
        stats.totalProfit = stats.totalProfit + profit
        if profit > stats.biggestTrade then
            stats.biggestTrade = profit
        end
    end

    StockBoard.SaveStats()
    StockBoard.SendPlayerStats(ply)
end

function StockBoard.GetLeaderboard(category, limit)
    local entries = {}
    
    -- Si category == "portfolioValue", on doit calculer la valeur actuelle
    if category == "portfolioValue" then
        for steamid, port in pairs(StockBoard.Portfolios) do
            local total = 0
            for stockId, data in pairs(port) do
                local currentPrice = StockBoard.Prices[stockId] and StockBoard.Prices[stockId].current or 0
                total = total + (data.shares * currentPrice)
            end
            
            -- Recup nom depuis stats
            local name = (StockBoard.PlayerStats[steamid] and StockBoard.PlayerStats[steamid].name) or steamid
            
            if total > 0 then
                table.insert(entries, { steamid = steamid, name = name, value = total })
            end
        end
    else
        -- Categories classiques depuis stats (totalProfit, trades)
        for steamid, stats in pairs(StockBoard.PlayerStats) do
            local val = stats[category] or 0
            if val != 0 then -- On affiche meme les negatifs pour le profit
                 table.insert(entries, { steamid = steamid, name = stats.name, value = val })
            end
        end
    end
    
    table.sort(entries, function(a, b) return a.value > b.value end)
    
    local top = {}
    for i = 1, math.min(limit, #entries) do
        top[i] = entries[i]
        top[i].rank = i
    end
    
    return top, entries
end

hook.Add("PlayerInitialSpawn", "StockBoard_TrackName", function(ply)
    timer.Simple(2, function()
        if not IsValid(ply) then return end
        local stats = StockBoard.GetPlayerStats(ply:SteamID())
        stats.name = ply:Nick()
        StockBoard.SaveStats()
    end)
end)

StockBoard.InitData()