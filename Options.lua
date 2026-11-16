--[[
    Xius Max Graphics - Options.lua
    Opens the Xius Core settings window. This file does not build one.
    The page is registered by Libs/SettingsGlue.lua.
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

NS.Options = NS.Options or {}

local function SettingsLib()
    return _G.XiusCoreSettingsLib
end

function NS.OpenGraphicsOptions()
    local Lib = SettingsLib()
    if not Lib then
        return
    end
    if not NS.db and NS.InitDB then
        NS.InitDB()
    end
    if type(Lib.OpenModule) == "function" then
        Lib:OpenModule("Graphics")
        return
    end
    if type(Lib.Open) == "function" then
        Lib:Open("Graphics")
    end
end

function NS.ToggleGraphicsOptions()
    local Lib = SettingsLib()
    if not Lib then
        return
    end
    if not NS.db and NS.InitDB then
        NS.InitDB()
    end
    if type(Lib.Toggle) == "function" then
        Lib:Toggle("Graphics")
        return
    end
    NS.OpenGraphicsOptions()
end

function NS.Options.Show()
    NS.OpenGraphicsOptions()
end

function NS.Options.Toggle()
    NS.ToggleGraphicsOptions()
end

function NS.ToggleOptions()
    NS.ToggleGraphicsOptions()
end

NS.OpenOptions = NS.Options.Show

function NS.Options.Refresh()
    local Lib = SettingsLib()
    if Lib and Lib.RefreshPage and Lib.frame and Lib.frame:IsShown() and Lib.page == "Graphics" and Lib.mode ~= "profiles" then
        Lib:RefreshPage()
    end
end

function NS.Options.RegisterSettings()
    if NS.RegisterSettingsModule then
        NS.RegisterSettingsModule()
    end
end
