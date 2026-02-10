-- lua/autorun/stockboard_init.lua

StockBoard = StockBoard or {}

-- Shared (charge des deux cotes)
include("stockboard/shared/sh_config.lua")

if SERVER then
    -- Envoyer les fichiers client
    AddCSLuaFile("stockboard/shared/sh_config.lua")
    AddCSLuaFile("stockboard/client/cl_fonts.lua")
    AddCSLuaFile("stockboard/client/cl_notifications.lua")
    AddCSLuaFile("stockboard/client/cl_menu.lua")

    -- Charger les fichiers serveur
    include("stockboard/server/sv_network.lua")
    include("stockboard/server/sv_data.lua")
    include("stockboard/server/sv_market.lua")
    include("stockboard/server/sv_trading.lua")

    print("[StockBoard] Server loaded!")
end

if CLIENT then
    include("stockboard/client/cl_fonts.lua")
    include("stockboard/client/cl_notifications.lua")
    include("stockboard/client/cl_menu.lua")

    print("[StockBoard] Client loaded!")
end