--[[
    Xius Max Graphics - Core.lua
    Applies graphics presets and pick-and-choose CVars.
]]

local ADDON, NS = ...

local GetCVarFunc = (C_CVar and C_CVar.GetCVar) or GetCVar
local SetCVarFunc = (C_CVar and C_CVar.SetCVar) or SetCVar
local GetCVarInfoFunc = C_CVar and C_CVar.GetCVarInfo
local InCombatLockdown = InCombatLockdown
local tonumber = tonumber
local tostring = tostring
local pairs = pairs
local pcall = pcall

local pendingApply = false
local initialApplyDone = false
local reapplyTimer
local reloadPending = false
local reloadAsked
local outlineSuppressor
local outlineAccum = 0
local OUTLINE_STEP = 0.5
local applyingProtect = false
local missingCVars = {}
local unwritableOutline = {}

local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

local function InCombat()
    return InCombatLockdown ~= nil and InCombatLockdown()
end

local function SafeRegister(frame, event)
    pcall(frame.RegisterEvent, frame, event)
end

local function SafeUnregister(frame, event)
    pcall(frame.UnregisterEvent, frame, event)
end

-- Sparkles exist only while outline mode is disabled (0).
-- Turning them off means outline mode High (2) plus the loot-sparkle flag off.
-- Forever applies that change after a full game exit, not a UI reload.
local OUTLINE_ON = {
    outlineModeShowLootEffectWhenDisabled = 1,
    graphicsOutlineMode = 0,
    OutlineEngineMode = 0,
    raidGraphicsOutlineMode = 0,
    RAIDOutlineEngineMode = 0,
    Outline = 0,
    ShowQuestObjectHighlightEffect = 1,
}

local OUTLINE_OFF = {
    outlineModeShowLootEffectWhenDisabled = 0,
    graphicsOutlineMode = 2,
    OutlineEngineMode = 2,
    raidGraphicsOutlineMode = 2,
    RAIDOutlineEngineMode = 2,
    Outline = 2,
    ShowQuestObjectHighlightEffect = 0,
}

local PROTECT_WATCH = {
    graphicsOutlineMode = true,
    OutlineEngineMode = true,
    outlineModeShowLootEffectWhenDisabled = true,
    raidGraphicsOutlineMode = true,
    RAIDOutlineEngineMode = true,
    Outline = true,
    ShowQuestObjectHighlightEffect = true,
    SoftTargetIconGameObject = true,
    SoftTargetIconInteract = true,
}
for k in pairs(PROTECT_WATCH) do
    PROTECT_WATCH[string.lower(k)] = true
end

local INTENSITY_ORDER = { "off", "balance", "ultimate" }

local function CVarGet(name)
    if not GetCVarFunc or missingCVars[name] then
        return nil
    end
    local ok, value = pcall(GetCVarFunc, name)
    if ok then
        return value
    end
    return nil
end

local function CVarExists(name)
    if missingCVars[name] then
        return false
    end
    if GetCVarInfoFunc then
        local ok, value, defaultValue = pcall(GetCVarInfoFunc, name)
        if not ok or IsSecret(value) or IsSecret(defaultValue) then
            return true
        end
        return defaultValue ~= nil or value ~= nil
    end
    local current = CVarGet(name)
    return current ~= nil and not IsSecret(current)
end

local function CVarSet(name, value)
    if missingCVars[name] or not SetCVarFunc then
        return false
    end
    value = tostring(value)
    -- SetCVar returns true, false, or nil. Nil means a secure CVar refused the write.
    local ok, result = pcall(SetCVarFunc, name, value)
    if ok and result == true then
        return true
    end
    if not InCombat() and not CVarExists(name) then
        missingCVars[name] = true
    end
    return false
end

local function ValuesMatch(a, b)
    if IsSecret(a) or IsSecret(b) or a == nil then
        return false
    end
    local na, nb = tonumber(a), tonumber(b)
    if na and nb then
        local delta = na - nb
        if delta < 0 then
            delta = -delta
        end
        return delta < 0.001
    end
    return tostring(a) == tostring(b)
end

function NS.SetCVarIfChanged(name, value)
    if value == nil or missingCVars[name] then
        return false
    end
    local current = CVarGet(name)
    if current == nil then
        if not InCombat() and not CVarExists(name) then
            missingCVars[name] = true
        end
        return false
    end
    if ValuesMatch(current, value) then
        return false
    end
    return CVarSet(name, value)
end

function NS.ForceCVarNow(name, value)
    if value == nil or missingCVars[name] then
        return false
    end
    if CVarGet(name) == nil and not InCombat() and not CVarExists(name) then
        missingCVars[name] = true
        return false
    end
    return CVarSet(name, value)
end

function NS.ApplyCVarBundle(bundle, skipMap)
    if not bundle then
        return false
    end
    local sliders = NS.SLIDER_CVARS
    local wroteSlider = false
    -- Pass 1: Write menu slider CVars (graphics* / raidGraphics*) first so their
    -- engine callbacks run before raw beyond-the-slider CVars are applied.
    if sliders then
        for name, value in pairs(bundle) do
            if sliders[name] and not (skipMap and skipMap[name]) then
                if NS.SetCVarIfChanged(name, value) then
                    wroteSlider = true
                end
            end
        end
    end
    -- Pass 2: Write raw engine CVars (groundEffectDensity, farclip, wmoLodDist, etc.)
    -- after the menu sliders so the slider callbacks cannot clobber them.
    for name, value in pairs(bundle) do
        if not (sliders and sliders[name]) and not (skipMap and skipMap[name]) then
            NS.SetCVarIfChanged(name, value)
        end
    end
    return wroteSlider
end

function NS.ApplyMenuGraphics(profile, skipFeatures)
    return NS.ApplyCVarBundle(NS.MENU_GRAPHICS[profile], skipFeatures and NS.FEATURE_CVARS or nil)
end

function NS.ApplyGraphicsQuality(profile)
    local quality = NS.PROFILE_QUALITY[profile]
    if not quality then
        return false
    end
    local wrote = false
    local function WriteQuality(name)
        if missingCVars[name] or ValuesMatch(CVarGet(name), quality) then
            return
        end
        if NS.ForceCVarNow(name, quality) then
            wrote = true
        end
    end
    WriteQuality("graphicsQuality")
    WriteQuality("RAIDgraphicsQuality")
    return wrote
end

function NS.ApplySoftTargetIcons()
    local db = NS.db
    if not db then
        return
    end
    if InCombat() then
        pendingApply = true
        return
    end
    NS.SetCVarIfChanged("SoftTargetIconGameObject", db.showSoftTargetObjectIcons and 1 or 0)
    NS.SetCVarIfChanged("SoftTargetIconInteract", db.showSoftTargetInteractIcons and 1 or 0)
end

function NS.ApplySoftTargetCVars()
    local db = NS.db
    if not db or not db.enabled then
        return
    end
    if InCombat() then
        pendingApply = true
        return
    end
    if db.herbSparkles or db.oreSparkles or db.questObjectSparkles then
        -- In front of the camera only, gather range. A wide arc was locking onto quest givers.
        local range = db.questObjectSparkles and 28 or 20
        local arc = db.questObjectSparkles and 2 or 1
        NS.SetCVarIfChanged("SoftTargetInteract", 3)
        NS.SetCVarIfChanged("SoftTargetInteractRange", range)
        NS.SetCVarIfChanged("SoftTargetInteractArc", arc)
        NS.SetCVarIfChanged("SoftTargetInteractOnlyInRange", 1)
    end
    NS.ApplySoftTargetIcons()
end

function NS.ApplyGathering()
    NS.ApplySoftTargetCVars()
    if NS.Sparkles and NS.Sparkles.Refresh then
        NS.Sparkles.Refresh()
    end
end

function NS.SyncOutlineSuppressor()
    local db = NS.db
    -- Graphics quality turns outline mode off, and disabled outline mode is the
    -- quest-giver sparkle. Hold High outline mode and the loot-sparkle flag off.
    local want = db and db.enabled and not db.questItemSparkles
    if want then
        if not outlineSuppressor then
            outlineSuppressor = CreateFrame("Frame")
            outlineSuppressor:SetScript("OnUpdate", function(_, elapsed)
                outlineAccum = outlineAccum + elapsed
                if outlineAccum < OUTLINE_STEP then
                    return
                end
                outlineAccum = 0
                if InCombat() then
                    return
                end
                for name, value in pairs(OUTLINE_OFF) do
                    if not missingCVars[name] and not unwritableOutline[name] then
                        local live = CVarGet(name)
                        if live == nil then
                            if not CVarExists(name) then
                                missingCVars[name] = true
                            else
                                unwritableOutline[name] = true
                            end
                        elseif not IsSecret(live) and not ValuesMatch(live, value) then
                            if not CVarSet(name, value) or not ValuesMatch(CVarGet(name), value) then
                                unwritableOutline[name] = true
                            end
                        end
                    end
                end
            end)
        end
        outlineAccum = 0
        outlineSuppressor:Show()
    elseif outlineSuppressor then
        outlineSuppressor:Hide()
    end
end

function NS.ApplySparkleCVars()
    local db = NS.db
    if not db then
        return
    end
    if InCombat() then
        pendingApply = true
        NS.SyncOutlineSuppressor()
        return
    end
    local bundle = (db.enabled and db.questItemSparkles) and OUTLINE_ON or OUTLINE_OFF
    NS.ApplyCVarBundle(bundle)
    NS.SyncOutlineSuppressor()
end

function NS.ApplyFeature(def)
    if not def then
        return false
    end
    if InCombat() then
        pendingApply = true
        return false
    end
    local intensity = NS.GetFeatureIntensity(def.key)
    if intensity == "off" then
        return NS.ApplyCVarBundle(def.off)
    end
    return NS.ApplyCVarBundle(def[intensity] or def.ultimate)
end

function NS.ApplyAllFeatures()
    local list = NS.FEATURES
    local wroteSlider = false
    for i = 1, #list do
        if NS.ApplyFeature(list[i]) then
            wroteSlider = true
        end
    end
    return wroteSlider
end

local function CancelReapplyTimer()
    if reapplyTimer then
        reapplyTimer:Cancel()
        reapplyTimer = nil
    end
end

function NS.ApplyAll(full)
    local db = NS.db
    if not db or not db.enabled then
        CancelReapplyTimer()
        NS.SyncOutlineSuppressor()
        if NS.Sparkles and NS.Sparkles.Refresh then
            NS.Sparkles.Refresh()
        end
        return false
    end
    if InCombat() then
        pendingApply = true
        return false
    end
    local profile = db.profile
    if profile ~= "defaults" and profile ~= "balance" and profile ~= "ultimate" and profile ~= "custom" then
        profile = "ultimate"
        db.profile = profile
    end
    local base = db.baseProfile
    if base ~= "defaults" and base ~= "balance" and base ~= "ultimate" then
        base = (profile ~= "custom") and profile or "ultimate"
        db.baseProfile = base
    end
    local useFeatureBundles = (profile == "custom" or profile == "defaults")
    -- Quality first. Writing it or menu sliders can reset raw CVars a moment later, so reapply.
    local wroteMaster = false
    if profile ~= "custom" or full then
        if NS.ApplyGraphicsQuality(base) then
            wroteMaster = true
        end
        -- Skip feature-owned CVars when ApplyAllFeatures is about to write their final values.
        if NS.ApplyMenuGraphics(base, useFeatureBundles) then
            wroteMaster = true
        end
    end
    -- Defaults still runs each feature's off bundle. Fog and sun shafts are on in
    -- the menu baseline and off only in those bundles. Projected textures stay on.
    if useFeatureBundles then
        if NS.ApplyAllFeatures() then
            wroteMaster = true
        end
    end
    NS.ApplySparkleCVars()
    NS.ApplySoftTargetCVars()
    if NS.Sparkles and NS.Sparkles.Refresh then
        NS.Sparkles.Refresh()
    end
    initialApplyDone = true
    return wroteMaster
end

local reapplyLeft = 0

local function ScheduleReapply()
    reapplyLeft = 2
    CancelReapplyTimer()
    if not (C_Timer and C_Timer.NewTimer) then
        return
    end
    local function Fire()
        reapplyTimer = nil
        local wroteMaster = NS.ApplyAll(true)
        if wroteMaster and reapplyLeft > 0 then
            reapplyLeft = reapplyLeft - 1
            reapplyTimer = C_Timer.NewTimer(0.35, Fire)
        else
            reapplyLeft = 0
        end
    end
    reapplyTimer = C_Timer.NewTimer(0.4, Fire)
end

function NS.ApplySettings(silent)
    if NS.ApplyAll(true) then
        ScheduleReapply()
    end
    if NS.Options and NS.Options.Refresh then
        NS.Options.Refresh()
    end
    if not silent then
        NS.Print(NS.PresetChatName() .. " Graphics Applied")
    end
end

function NS.SnapshotPresetToCustom()
    local db = NS.db
    if not db or db.profile == "custom" then
        return
    end
    local fallback = (db.baseProfile == "balance" or db.profile == "balance") and "balance" or "ultimate"
    local list = NS.FEATURES
    for i = 1, #list do
        local k = list[i].key
        local cur = NS.GetFeatureIntensity(k)
        db[k] = cur ~= "off"
        db.intensity[k] = (cur == "off") and fallback or cur
    end
    db.profile = "custom"
end

function NS.ApplySingleFeature(key)
    local feature = NS.FEATURE_BY_KEY[key]
    if not feature then
        return
    end
    if not initialApplyDone or pendingApply then
        NS.ApplySettings(true)
        return
    end
    if NS.db and NS.db.enabled then
        if NS.ApplyFeature(feature) and C_Timer and C_Timer.After then
            -- Re-assert raw CVars after the engine's slider callback settles.
            C_Timer.After(0.2, function()
                if NS.db and NS.db.enabled and not InCombat() then
                    NS.ApplyFeature(feature)
                end
            end)
        end
    end
    if NS.Options and NS.Options.Refresh then
        NS.Options.Refresh()
    end
end

function NS.SetProfile(profile, silent)
    if profile ~= "defaults" and profile ~= "balance" and profile ~= "ultimate" then
        profile = "ultimate"
    end
    NS.db.profile = profile
    NS.db.baseProfile = profile
    NS.db.enabled = true
    local hadInteractIcons = NS.db.showSoftTargetInteractIcons
    NS.db.showSoftTargetInteractIcons = false
    local list = NS.FEATURES
    for i = 1, #list do
        local key = list[i].key
        if profile == "defaults" then
            NS.db[key] = key == "projectedTextures"
            NS.db.intensity[key] = "ultimate"
        else
            NS.db[key] = true
            NS.db.intensity[key] = profile
        end
    end
    if NS.ApplyAll(true) then
        ScheduleReapply()
    end
    if NS.Options and NS.Options.Refresh then
        NS.Options.Refresh()
    end
    if not silent then
        NS.Print(NS.PresetChatName(profile) .. " Graphics Applied")
    end
    if hadInteractIcons then
        NS.SyncReloadFlag()
        NS.PromptReload()
    end
end

function NS.ToggleEnabled()
    NS.db.enabled = not NS.db.enabled
    NS.SyncProtectWatch()
    NS.SyncOutlineSuppressor()
    if NS.db.enabled then
        if NS.ApplyAll(true) then
            ScheduleReapply()
        end
        NS.Print("On.")
    else
        pendingApply = false
        CancelReapplyTimer()
        if NS.Sparkles and NS.Sparkles.Refresh then
            NS.Sparkles.Refresh()
        end
        NS.Print("Off. Game graphics stay as they are.")
    end
    if NS.Options and NS.Options.Refresh then
        NS.Options.Refresh()
    end
end

function NS.ToggleFeature(key, enabled)
    local feature = NS.FEATURE_BY_KEY[key]
    if feature == nil
        and key ~= "questItemSparkles"
        and key ~= "herbSparkles"
        and key ~= "oreSparkles"
        and key ~= "questObjectSparkles"
        and key ~= "showSoftTargetObjectIcons"
        and key ~= "showSoftTargetInteractIcons"
        and key ~= "protect"
        and key ~= "enabled"
        and key ~= "chatMessages" then
        return
    end
    local checked = enabled and true or false
    if feature then
        NS.SnapshotPresetToCustom()
        NS.db[key] = checked
        if checked and (not NS.db.intensity[key] or NS.db.intensity[key] == "off") then
            NS.db.intensity[key] = (NS.db.baseProfile == "balance") and "balance" or "ultimate"
        elseif not checked then
            NS.db.intensity[key] = "off"
        end
        NS.ApplySingleFeature(key)
        return
    end
    NS.db[key] = checked
    if key == "protect" or key == "enabled" then
        NS.SyncProtectWatch()
        NS.SyncOutlineSuppressor()
        if key == "enabled" then
            if checked then
                NS.ApplySettings(true)
            else
                pendingApply = false
                CancelReapplyTimer()
                if NS.Sparkles and NS.Sparkles.Refresh then
                    NS.Sparkles.Refresh()
                end
            end
        end
        NS.RefreshOptions()
        return
    end
    if key == "chatMessages" then
        NS.RefreshOptions()
        return
    end
    if key == "questItemSparkles" or key == "herbSparkles" or key == "oreSparkles"
        or key == "questObjectSparkles" or key == "showSoftTargetObjectIcons"
        or key == "showSoftTargetInteractIcons" then
        if key == "questItemSparkles" then
            NS.ApplySparkleCVars()
            NS.Print(checked
                and "Quest sparkles on. Fully exit the game and start it again. A UI reload will not show them."
                or "Quest sparkles off. Fully exit the game and start it again. A UI reload will not remove them.")
        end
        NS.ApplyGathering()
        NS.RefreshOptions()
        if NS.RELOAD_OPTIONS and NS.RELOAD_OPTIONS[key] then
            NS.SyncReloadFlag()
            NS.PromptReload()
        end
        return
    end
end

function NS.CycleFeatureIntensity(key, direction)
    local feature = NS.FEATURE_BY_KEY[key]
    if not feature then
        return
    end
    local cur = NS.GetFeatureIntensity(key)
    local idx = 1
    for i = 1, #INTENSITY_ORDER do
        if INTENSITY_ORDER[i] == cur then
            idx = i
            break
        end
    end
    idx = idx + (direction or 1)
    if idx < 1 then
        idx = #INTENSITY_ORDER
    elseif idx > #INTENSITY_ORDER then
        idx = 1
    end
    local nextIntensity = INTENSITY_ORDER[idx]
    NS.SnapshotPresetToCustom()
    NS.db.intensity[key] = nextIntensity
    NS.db[key] = nextIntensity ~= "off"
    NS.ApplySingleFeature(key)
    return nextIntensity
end

function NS.CaptureReloadBaseline()
    NS.reloadBaseline = {}
    if not NS.db or not NS.RELOAD_OPTIONS then
        return
    end
    for key in pairs(NS.RELOAD_OPTIONS) do
        NS.reloadBaseline[key] = NS.db[key] and true or false
    end
    reloadPending = false
end

function NS.SyncReloadFlag()
    local baseline = NS.reloadBaseline
    if not baseline or not NS.db or not NS.RELOAD_OPTIONS then
        reloadPending = false
        return
    end
    local pending = false
    for key in pairs(NS.RELOAD_OPTIONS) do
        if (NS.db[key] and true or false) ~= baseline[key] then
            pending = true
            break
        end
    end
    reloadPending = pending
end

local function ReloadSignature()
    if not NS.db or not NS.RELOAD_OPTIONS then
        return ""
    end
    local parts = {}
    for key in pairs(NS.RELOAD_OPTIONS) do
        parts[#parts + 1] = key .. "=" .. (NS.db[key] and "1" or "0")
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

function NS.PromptReload()
    NS.SyncReloadFlag()
    if not reloadPending then
        reloadAsked = nil
        return
    end
    local signature = ReloadSignature()
    if signature == reloadAsked then
        return
    end
    local dialogInfo = StaticPopupDialogs and StaticPopupDialogs["XIUSMAXGRAPHICS_RELOAD"]
    if not dialogInfo or not StaticPopup_Show then
        return
    end
    local lines = {}
    local baseline = NS.reloadBaseline or {}
    for key, label in pairs(NS.RELOAD_OPTIONS) do
        local now = NS.db[key] and true or false
        if now ~= baseline[key] then
            lines[#lines + 1] = label .. " (" .. (now and "on" or "off") .. ")"
        end
    end
    table.sort(lines)
    local body = "A UI reload is required before this change finishes."
    if #lines > 0 then
        body = body .. "\n\n" .. table.concat(lines, "\n")
    end
    body = body .. "\n\nReload now?"
    dialogInfo.text = body
    reloadAsked = signature
    if StaticPopup_Visible and StaticPopup_Visible("XIUSMAXGRAPHICS_RELOAD") then
        if StaticPopup_FindVisible then
            local dialog = StaticPopup_FindVisible("XIUSMAXGRAPHICS_RELOAD")
            if dialog then
                local textRegion = (dialog.GetTextFontString and dialog:GetTextFontString()) or dialog.text or dialog.Text
                if textRegion and textRegion.SetText then
                    textRegion:SetText(body)
                end
            end
        end
        return
    end
    StaticPopup_Show("XIUSMAXGRAPHICS_RELOAD")
end

function NS.ToggleOptions()
    if NS.Options and NS.Options.Toggle then
        NS.Options.Toggle()
    end
end

function NS.RefreshOptions()
    if NS.Options and NS.Options.Refresh then
        NS.Options.Refresh()
    end
end

SLASH_XIUSMAXGRAPHICS1 = "/xmg"
SLASH_XIUSMAXGRAPHICS2 = "/xiusmax"
SlashCmdList.XIUSMAXGRAPHICS = function(msg)
    if not NS.db then
        NS.InitDB()
    end
    if not NS.db then
        return
    end
    msg = string.lower(strtrim(msg or ""))
    if msg == "on" or msg == "enable" then
        NS.db.enabled = true
        NS.SyncProtectWatch()
        if NS.ApplyAll(true) then
            ScheduleReapply()
        end
        NS.Print("On.")
        NS.RefreshOptions()
    elseif msg == "off" or msg == "disable" then
        NS.db.enabled = false
        pendingApply = false
        CancelReapplyTimer()
        NS.SyncProtectWatch()
        NS.SyncOutlineSuppressor()
        if NS.Sparkles and NS.Sparkles.Refresh then
            NS.Sparkles.Refresh()
        end
        NS.Print("Off.")
        NS.RefreshOptions()
    elseif msg == "ultimate" or msg == "max" then
        NS.SetProfile("ultimate")
    elseif msg == "balance" or msg == "balanced" then
        NS.SetProfile("balance")
    elseif msg == "defaults" or msg == "default" or msg == "reset" then
        NS.SetProfile("defaults")
    elseif msg == "protect" then
        NS.db.protect = not NS.db.protect
        NS.SyncProtectWatch()
        NS.Print("Protect icons: " .. (NS.db.protect and "ON" or "OFF"))
        NS.RefreshOptions()
    elseif msg == "sparkles" or msg == "loot" then
        NS.ToggleFeature("questItemSparkles", not NS.db.questItemSparkles)
    else
        NS.ToggleOptions()
    end
end

StaticPopupDialogs["XIUSMAXGRAPHICS_RELOAD"] = {
    text = "One or more Xius Max Graphics options need a UI reload to finish applying.\n\nReload now?",
    button1 = "Reload",
    button2 = "Later",
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function XiusMaxGraphics_OnAddonCompartmentClick(_, buttonName)
    if buttonName == "RightButton" then
        if not NS.db then
            NS.InitDB()
        end
        if NS.db then
            NS.ToggleEnabled()
        end
        return
    end
    NS.ToggleOptions()
end

function XiusMaxGraphics_OnAddonCompartmentEnter(_, menuButtonFrame)
    if not GameTooltip or not menuButtonFrame then
        return
    end
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_LEFT")
    GameTooltip:SetText("Xius Max Graphics", 1, 0.82, 0)
    if NS.db then
        local status = NS.db.enabled and NS.ProfileDisplayName() or "OFF"
        GameTooltip:AddLine("Status: " .. status, 1, 1, 1)
    end
    GameTooltip:AddLine("Left-Click: Open options", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Right-Click: Toggle on/off", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function XiusMaxGraphics_OnAddonCompartmentLeave()
    if GameTooltip then
        GameTooltip:Hide()
    end
end

local events = CreateFrame("Frame")
SafeRegister(events, "ADDON_LOADED")
SafeRegister(events, "PLAYER_LOGIN")
SafeRegister(events, "PLAYER_ENTERING_WORLD")
SafeRegister(events, "PLAYER_REGEN_ENABLED")

function NS.SyncProtectWatch()
    if NS.db and NS.db.enabled and NS.db.protect then
        SafeRegister(events, "CVAR_UPDATE")
    else
        SafeUnregister(events, "CVAR_UPDATE")
    end
end

events:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if not IsSecret(arg1) and arg1 == ADDON then
            NS.InitDB()
            SafeUnregister(events, "ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        if not NS.db then
            NS.InitDB()
        end
        NS.SyncProtectWatch()
        if NS.db and NS.db.enabled then
            if NS.ApplyAll(true) then
                ScheduleReapply()
            end
        else
            NS.SyncOutlineSuppressor()
        end
        if NS.Options and NS.Options.RegisterSettings then
            NS.Options.RegisterSettings()
        end
        NS.CaptureReloadBaseline()
        NS.Print("Loaded v" .. NS.VERSION .. ". Type |cffffd100/xmg|r for options.")
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin = not IsSecret(arg1) and arg1
        local isReloadingUi = not IsSecret(arg2) and arg2
        if (isInitialLogin or isReloadingUi) and NS.db and NS.db.enabled then
            NS.ApplyAll(true)
            ScheduleReapply()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingApply then
            pendingApply = false
            if NS.ApplyAll(true) then
                ScheduleReapply()
            end
        end
        if NS.Sparkles and NS.Sparkles.OnCombatEnd then
            NS.Sparkles.OnCombatEnd()
        end
    elseif event == "CVAR_UPDATE" then
        if not NS.db or not NS.db.enabled or not NS.db.protect then
            return
        end
        if IsSecret(arg1) or type(arg1) ~= "string" then
            return
        end
        if applyingProtect or not (PROTECT_WATCH[arg1] or PROTECT_WATCH[string.lower(arg1)]) then
            return
        end
        if InCombat() then
            pendingApply = true
            return
        end
        applyingProtect = true
        NS.ApplySparkleCVars()
        NS.ApplySoftTargetIcons()
        applyingProtect = false
    end
end)
