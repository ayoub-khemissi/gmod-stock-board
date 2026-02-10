-- lua/stockboard/client/cl_notifications.lua

StockBoard.Notifications = StockBoard.Notifications or {}

local NOTIF_W, NOTIF_H = 340, 44
local MARGIN = 5
local FADE_IN, SHOW, FADE_OUT = 0.25, 4.5, 0.4
local MAX = 5

local typeColors = {
    info    = StockBoard.Colors.Info,
    error   = StockBoard.Colors.Danger,
    success = StockBoard.Colors.Success,
}

function StockBoard.AddNotification(msg, t)
    table.insert(StockBoard.Notifications, 1, {
        message = msg,
        type = t or "info",
        start = CurTime()
    })
    while #StockBoard.Notifications > MAX do
        table.remove(StockBoard.Notifications)
    end
end

hook.Add("HUDPaint", "StockBoard_Notifications", function()
    local scrW = ScrW()
    local now = CurTime()
    local rm = {}

    for i, n in ipairs(StockBoard.Notifications) do
        local el = now - n.start
        local life = FADE_IN + SHOW + FADE_OUT
        if el > life then table.insert(rm, i) continue end

        -- Calcul opacite
        local a = 1
        if el < FADE_IN then a = el / FADE_IN
        elseif el > FADE_IN + SHOW then a = 1 - (el - FADE_IN - SHOW) / FADE_OUT end
        a = math.Clamp(a, 0, 1)

        -- Slide-in
        local slide = el < FADE_IN and (1 - a) * 50 or 0
        local x = scrW - NOTIF_W - 12 + slide
        local y = 12 + (i - 1) * (NOTIF_H + MARGIN)
        local accent = typeColors[n.type] or typeColors.info

        -- Shadow
        draw.RoundedBox(8, x + 1, y + 2, NOTIF_W, NOTIF_H,
            ColorAlpha(StockBoard.Colors.Black, a * 40))
        -- Background
        draw.RoundedBox(8, x, y, NOTIF_W, NOTIF_H,
            ColorAlpha(StockBoard.Colors.Card, a * 240))
        -- Barre accent gauche
        draw.RoundedBoxEx(8, x, y, 3, NOTIF_H,
            ColorAlpha(accent, a * 255), true, false, true, false)
        -- Texte
        draw.SimpleText(n.message, "SB_Notif", x + 14, y + NOTIF_H / 2,
            ColorAlpha(StockBoard.Colors.TextPrimary, a * 255),
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    for i = #rm, 1, -1 do table.remove(StockBoard.Notifications, rm[i]) end
end)

net.Receive("StockBoard_Notify", function()
    StockBoard.AddNotification(net.ReadString(), net.ReadString())
end)