--[[
    Hand the graphics engine to Xius Core.
    Xius Core keeps its module table on the XiusUI global.
]]

local _, NS = ...

local XiusCore = _G.XiusCore or _G.XiusUI or _G.XiusCoreSettingsLib
if not XiusCore and C_AddOns and C_AddOns.IsAddOnLoaded then
    local ok, loaded = pcall(C_AddOns.IsAddOnLoaded, "XiusCore")
    XiusCore = ok and loaded and true or false
end
if not XiusCore and IsAddOnLoaded then
    local ok, loaded = pcall(IsAddOnLoaded, "XiusCore")
    XiusCore = ok and loaded and true or false
end
if not XiusCore then
    return
end

if not XiusUI or not XiusUI.RegisterModule then
    return
end

if NS.InitDB and not NS.db then
    NS.InitDB()
end

XiusUI:RegisterModule("Graphics", NS)
