--[[
    Xius Max Graphics settings page.
    Widgets come only from XiusCoreSettingsLib. This file does not build a window.
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

local function SettingsLib()
    return _G.XiusCoreSettingsLib
end

local SECTIONS = {
    { id = "world", title = "World detail" },
    { id = "lighting", title = "Lighting & fog" },
    { id = "effects", title = "Effects & water" },
    { id = "image", title = "Image clarity" },
}

local INTENSITY = {
    { value = "off", text = "OFF" },
    { value = "balance", text = "BAL" },
    { value = "ultimate", text = "MAX" },
}

local function CopySetting(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, inner in pairs(value) do
        copy[key] = CopySetting(inner)
    end
    return copy
end

local function ResetSavedSettings()
    if NS.InitDB and not NS.db then
        NS.InitDB()
    end
    local db = NS.db
    if type(db) ~= "table" or type(NS.DEFAULTS) ~= "table" then
        return
    end
    for key, value in pairs(NS.DEFAULTS) do
        db[key] = CopySetting(value)
    end
    if NS.InitDB then
        NS.InitDB()
    end
    if NS.ApplySettings then
        NS.ApplySettings(true)
    end
    if NS.SyncReloadFlag then
        NS.SyncReloadFlag()
    end
    if NS.PromptReload then
        NS.PromptReload()
    end
    if NS.Options and NS.Options.Refresh then
        NS.Options.Refresh()
    end
    if NS.Print then
        NS.Print("Defaults restored.")
    end
end

local function DisplayLabel(key, label)
    if NS.RELOAD_OPTIONS and NS.RELOAD_OPTIONS[key] then
        return label .. " (requires reload)"
    end
    return label
end

local function ProfileText()
    local db = NS.db or {}
    local qProfile = db.profile
    if not (NS.PROFILE_QUALITY_UI and NS.PROFILE_QUALITY_UI[qProfile]) then
        qProfile = db.baseProfile
    end
    local q = NS.PROFILE_QUALITY_UI and NS.PROFILE_QUALITY_UI[qProfile]
    local text = "Active profile: " .. (NS.ProfileDisplayName and NS.ProfileDisplayName() or tostring(qProfile or ""))
    if q then
        text = text .. "  |  Base Quality " .. tostring(q)
    end
    return text
end

local function Checked(key)
    return NS.db and NS.db[key] and true or false
end

local function SetChecked(key, value)
    if NS.ToggleFeature then
        NS.ToggleFeature(key, value)
    elseif NS.db then
        NS.db[key] = value and true or false
        if NS.Options and NS.Options.Refresh then
            NS.Options.Refresh()
        end
    end
end

local function SetIntensity(key, value)
    if value == "off" then
        SetChecked(key, false)
        return
    end
    if value ~= "ultimate" and value ~= "balance" then
        return
    end
    if NS.SnapshotPresetToCustom then
        NS.SnapshotPresetToCustom()
    end
    if NS.db then
        NS.db[key] = true
        NS.db.intensity = NS.db.intensity or {}
        NS.db.intensity[key] = value
    end
    if NS.ApplySingleFeature then
        NS.ApplySingleFeature(key)
    elseif NS.Options and NS.Options.Refresh then
        NS.Options.Refresh()
    end
end

function NS.RegisterSettingsModule()
    if NS._graphicsModuleRegistered then
        return
    end
    local Lib = SettingsLib()
    if not Lib or not Lib.RegisterModule then
        return
    end
    if NS.InitDB and not NS.db then
        NS.InitDB()
    end

    Lib:RegisterModule({
        id = "Graphics",
        title = "Xius Max Graphics",
        menuTitle = "Max Graphics",
        group = "Utilities & System",
        order = 50,
        defaults = NS.DEFAULTS,
        getDB = function()
            if not NS.db and NS.InitDB then
                NS.InitDB()
            end
            return NS.db
        end,
        onResetDefaults = ResetSavedSettings,
        onUnlock = function()
        end,
        buildContent = function(_, api)
            if NS.InitDB and not NS.db then
                NS.InitDB()
            end
            if not NS.db then
                api:AddNote("Max Graphics is still loading. Close this window and open it again.")
                return
            end

            api:AddSection("Presets")
            api:AddNote(ProfileText)
            api:AddButtonGroup({
                align = "CENTER",
                spacing = 10,
                width = 120,
                height = 24,
                buttons = {
                    { text = "Ultimate", width = 120, height = 24, onClick = function()
                        if NS.SetProfile then
                            NS.SetProfile("ultimate")
                        end
                    end },
                    { text = "Balance", width = 120, height = 24, onClick = function()
                        if NS.SetProfile then
                            NS.SetProfile("balance")
                        end
                    end },
                    { text = "Defaults", width = 120, height = 24, onClick = function()
                        if NS.SetProfile then
                            NS.SetProfile("defaults")
                        end
                    end },
                },
            })

            api:AddSection("General")
            api:AddCheckbox("Enable graphics upgrades", function()
                return Checked("enabled")
            end, function(value)
                SetChecked("enabled", value)
            end, "Master switch. When off, the addon stops applying CVars.")
            api:AddCheckbox("Keep loot / soft-target icons sticky", function()
                return Checked("protect")
            end, function(value)
                SetChecked("protect", value)
            end, "Only re-locks loot sparkles and soft-target icons. Does not fight your Graphics menu.")
            api:AddCheckbox("Chat messages", function()
                return Checked("chatMessages")
            end, function(value)
                SetChecked("chatMessages", value)
            end, "Show status messages in chat when presets are applied.")

            local shown = {}
            local features = NS.FEATURES or {}
            for s = 1, #SECTIONS do
                local section = SECTIONS[s]
                local any = false
                for i = 1, #features do
                    if features[i].category == section.id then
                        any = true
                        break
                    end
                end
                if any then
                    api:AddSection(section.title)
                    for i = 1, #features do
                        local feature = features[i]
                        if feature.category == section.id then
                            local key = feature.key
                            api:AddDropdown(feature.label, INTENSITY, function()
                                if NS.GetFeatureIntensity then
                                    return NS.GetFeatureIntensity(key)
                                end
                                return "off"
                            end, function(value)
                                SetIntensity(key, value)
                            end, feature.tip)
                            shown[key] = true
                        end
                    end
                end
            end

            local leftover = false
            for i = 1, #features do
                if not shown[features[i].key] then
                    leftover = true
                    break
                end
            end
            if leftover then
                api:AddSection("Features")
                for i = 1, #features do
                    local feature = features[i]
                    if not shown[feature.key] then
                        local key = feature.key
                        api:AddDropdown(feature.label, INTENSITY, function()
                            if NS.GetFeatureIntensity then
                                return NS.GetFeatureIntensity(key)
                            end
                            return "off"
                        end, function(value)
                            SetIntensity(key, value)
                        end, feature.tip)
                    end
                end
            end

            api:AddSection("Loot & gathering sparkles")
            api:AddCheckbox(DisplayLabel("questItemSparkles", "Quest item loot sparkles"), function()
                return Checked("questItemSparkles")
            end, function(value)
                SetChecked("questItemSparkles", value)
            end, "Sparkles on quest loot and quest givers. Leave this off to hide them. Fully exit the game afterward. A UI reload will not remove the sparkles.")
            api:AddCheckbox("Herb sparkles (soft target)", function()
                return Checked("herbSparkles")
            end, function(value)
                SetChecked("herbSparkles", value)
            end, "Golden glints on the nearest herb within soft-target range. Does not sparkle NPCs or quest givers.")
            api:AddCheckbox("Ore vein sparkles (soft target)", function()
                return Checked("oreSparkles")
            end, function(value)
                SetChecked("oreSparkles", value)
            end, "Golden glints on the nearest ore vein within soft-target range. Does not sparkle NPCs or quest givers.")
            api:AddCheckbox("Quest object sparkles (soft target)", function()
                return Checked("questObjectSparkles")
            end, function(value)
                SetChecked("questObjectSparkles", value)
            end, "Extra sparkles on nearby quest objects (chests, wanted posters). Does not sparkle quest-giver NPCs.")
            api:AddCheckbox(DisplayLabel("showSoftTargetObjectIcons", "Show soft-target object/gather icons"), function()
                return Checked("showSoftTargetObjectIcons")
            end, function(value)
                SetChecked("showSoftTargetObjectIcons", value)
            end, "Floating 2D icons over quest objects, ground loot, herb nodes, and ore veins. You will be asked to reload as soon as you change this.")
            api:AddCheckbox(DisplayLabel("showSoftTargetInteractIcons", "Show soft-target NPC/quest giver icons"), function()
                return Checked("showSoftTargetInteractIcons")
            end, function(value)
                SetChecked("showSoftTargetInteractIcons", value)
            end, "Overhead icons on NPCs and quest givers. Ultimate, Balance, and Defaults turn this off. You will be asked to reload as soon as you change this.")
            api:AddNote("Tip: Ultimate = max graphics. Balance = high quality with less cost. Defaults = the graphics menu baseline. Choose OFF, BAL, or MAX on each row. Type /xmg to open this window.")
        end,
    })

    NS._graphicsModuleRegistered = true
end

NS.RegisterSettingsModule()
