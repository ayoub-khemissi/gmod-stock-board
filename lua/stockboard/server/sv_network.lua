-- lua/stockboard/server/sv_network.lua

util.AddNetworkString("StockBoard_Notify")
util.AddNetworkString("StockBoard_RequestData")
util.AddNetworkString("StockBoard_SendMarket")
util.AddNetworkString("StockBoard_SendPortfolio")
util.AddNetworkString("StockBoard_PriceTick")
util.AddNetworkString("StockBoard_MarketEvent")
util.AddNetworkString("StockBoard_Buy")
util.AddNetworkString("StockBoard_Sell")
util.AddNetworkString("StockBoard_RequestLeaderboard")
util.AddNetworkString("StockBoard_SendLeaderboard")
util.AddNetworkString("StockBoard_SendPlayerStats")

-- Helpers
function StockBoard.NotifyPlayer(ply, msg, notifType)
    net.Start("StockBoard_Notify")
        net.WriteString(msg)
        net.WriteString(notifType or "info")
    net.Send(ply)
end

function StockBoard.NotifyAll(msg, notifType)
    net.Start("StockBoard_Notify")
        net.WriteString(msg)
        net.WriteString(notifType or "info")
    net.Broadcast()
end

function StockBoard.Log(msg)
    if StockBoard.Config.LogToConsole then
        print(StockBoard.Config.LogPrefix .. " " .. msg)
    end
end

-- Valid stock IDs lookup table (built from config)
local validStockIds = {}
for _, stock in ipairs(StockBoard.Config.Stocks) do
    validStockIds[stock.id] = true
end

local function IsValidStockId(id)
    return type(id) == "string" and validStockIds[id] == true
end

-- Validate and sanitize shares count (positive integer, within bounds)
local function SanitizeShares(shares)
    if type(shares) ~= "number" then return nil end
    shares = math.floor(shares) -- Force integer
    if shares < 1 then return nil end
    if shares > StockBoard.Config.MaxShares then return nil end
    return shares
end

-- Senders
function StockBoard.SendMarket(ply)
    local marketData = {}
    for id, data in pairs(StockBoard.Prices) do
        marketData[id] = {
            current = data.current,
            lastChange = data.lastChange,
            history = data.history
        }
    end

    -- Also send active event if any
    local activeEvent = nil
    if StockBoard.ActiveEvent then
        activeEvent = {
            text = StockBoard.ActiveEvent.text,
            icon = StockBoard.ActiveEvent.icon,
            sector = StockBoard.ActiveEvent.sector,
            type = (StockBoard.ActiveEvent.modifier >= 1) and "positive" or "negative"
        }
    end

    net.Start("StockBoard_SendMarket")
        net.WriteTable(marketData)
        net.WriteTable(activeEvent or {})
    net.Send(ply)
end

function StockBoard.SendPortfolio(ply)
    local steamid = ply:SteamID()
    local port = StockBoard.Portfolios[steamid] or {}

    net.Start("StockBoard_SendPortfolio")
        net.WriteTable(port)
    net.Send(ply)
end

function StockBoard.SendPlayerStats(ply)
    local stats = StockBoard.GetPlayerStats(ply:SteamID())
    -- Inject current wallet balance for UI calculations
    local wallet = 0
    if ply.getDarkRPVar then wallet = ply:getDarkRPVar("money") or 0
    elseif ply.getDarkRPvar then wallet = ply:getDarkRPvar("money") or 0
    elseif ply.GetMoney then wallet = ply:GetMoney() or 0
    end

    -- Copy to avoid saving wallet to persistent stats
    local data = table.Copy(stats)
    data.wallet = wallet

    net.Start("StockBoard_SendPlayerStats")
        net.WriteTable(data)
    net.Send(ply)
end

function StockBoard.SendLeaderboard(ply, category)
    local top, all = StockBoard.GetLeaderboard(category, 10)

    local myRank, myValue = 0, 0
    local sid = ply:SteamID()

    for i, e in ipairs(all) do
        if e.steamid == sid then
            myRank = i
            myValue = e.value
            break
        end
    end

    net.Start("StockBoard_SendLeaderboard")
        net.WriteString(category)
        net.WriteTable(top)
        net.WriteUInt(myRank, 16)
        net.WriteDouble(myValue)
    net.Send(ply)
end

-- Receivers (with input validation)
net.Receive("StockBoard_RequestData", function(len, ply)
    StockBoard.SendMarket(ply)
    StockBoard.SendPortfolio(ply)
    StockBoard.SendPlayerStats(ply)
end)

net.Receive("StockBoard_Buy", function(len, ply)
    local stockId = net.ReadString()
    local shares = net.ReadInt(32)

    if not IsValidStockId(stockId) then
        StockBoard.Log("BLOCKED: Invalid stock ID '" .. tostring(stockId) .. "' from " .. ply:Nick())
        return
    end

    shares = SanitizeShares(shares)
    if not shares then
        StockBoard.Log("BLOCKED: Invalid shares value from " .. ply:Nick())
        return
    end

    StockBoard.BuyStock(ply, stockId, shares)
end)

net.Receive("StockBoard_Sell", function(len, ply)
    local stockId = net.ReadString()
    local shares = net.ReadInt(32)

    if not IsValidStockId(stockId) then
        StockBoard.Log("BLOCKED: Invalid stock ID '" .. tostring(stockId) .. "' from " .. ply:Nick())
        return
    end

    shares = SanitizeShares(shares)
    if not shares then
        StockBoard.Log("BLOCKED: Invalid shares value from " .. ply:Nick())
        return
    end

    StockBoard.SellStock(ply, stockId, shares)
end)

net.Receive("StockBoard_RequestLeaderboard", function(len, ply)
    local cat = net.ReadString()
    -- Only allow known categories
    if cat ~= "totalProfit" and cat ~= "trades" then return end
    StockBoard.SendLeaderboard(ply, cat)
end)
