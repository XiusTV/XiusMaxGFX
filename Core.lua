local addonName, ns = ...
local ADDON, NS = addonName, ns

local XiusCore = _G.XiusCore or _G.XiusCoreSettingsLib
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
local settleTimer
local reloadPending = false
local reloadAsked
local OUTLINE_FAST = 0.5
local LOGIN_SETTLE_SECONDS = 4.35
local applyingProtect = false
local missingCVars = {}
local unwritableOutline = {}
local rejectedMaxCVars = {}

local function IsSecret(value)
    if value == nil then
        return false
    end
    if NS.CanRead then
        return not NS.CanRead(value)
    end
    if issecretvalue then
        local ok, secret = pcall(issecretvalue, value)
        if not ok or secret then
            return true
        end
    end
    if canaccessvalue then
        local ok, allowed = pcall(canaccessvalue, value)
        if not ok or not allowed then
            return true
        end
    end
    return false
end

local function InCombat()
    if type(InCombatLockdown) ~= "function" then
        return false
    end
    local ok, locked = pcall(InCombatLockdown)
    if not ok or IsSecret(locked) then
        return true
    end
    return locked and true or false
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

local OUTLINE_WATCH = {}
for k in pairs(OUTLINE_OFF) do
    OUTLINE_WATCH[k] = true
    OUTLINE_WATCH[string.lower(k)] = true
end

local PROTECT_WATCH = {
    SoftTargetIconGameObject = true,
    SoftTargetIconInteract = true,
}
for k in pairs(OUTLINE_WATCH) do
    PROTECT_WATCH[k] = true
end
for k in pairs(PROTECT_WATCH) do
    PROTECT_WATCH[string.lower(k)] = true
end

local function CVarGet(name)
    if not GetCVarFunc or missingCVars[name] then
        return nil, "missing"
    end
    local ok, value = pcall(GetCVarFunc, name)
    if not ok or value == nil then
        return nil, "missing"
    end
    if IsSecret(value) then
        return nil, "secret"
    end
    return value, "ok"
end

local function CVarExists(name)
    if missingCVars[name] then
        return false
    end
    if GetCVarInfoFunc then
        local ok, value, defaultValue = pcall(GetCVarInfoFunc, name)
        if not ok then
            return false
        end
        if IsSecret(value) or IsSecret(defaultValue) then
            return true
        end
        return defaultValue ~= nil or value ~= nil
    end
    local _, status = CVarGet(name)
    return status == "ok" or status == "secret"
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
    if IsSecret(a) or IsSecret(b) or a == nil or b == nil then
        return false
    end
    local na, nb = tonumber(a), tonumber(b)
    if IsSecret(na) or IsSecret(nb) then
        return false
    end
    if na and nb then
        local delta = na - nb
        if IsSecret(delta) then
            return false
        end
        if delta < 0 then
            delta = -delta
        end
        return delta < 0.001
    end
    return tostring(a) == tostring(b)
end

local function ResolveTargetValue(name, value)
    local fallback = NS.FALLBACK_CVARS and NS.FALLBACK_CVARS[name]
    if fallback ~= nil and rejectedMaxCVars[name] then
        local nv, nf = tonumber(value), tonumber(fallback)
        if nv and nf and nv > nf then
            return fallback
        end
    end
    return value
end

function NS.SetCVarIfChanged(name, value)
    if value == nil or IsSecret(value) or missingCVars[name] then
        return false
    end
    value = ResolveTargetValue(name, value)
    local current, status = CVarGet(name)
    if InCombat() then
        if status ~= "ok" or not ValuesMatch(current, value) then
            pendingApply = true
        end
        return false
    end
    if status == "secret" then
        return CVarSet(name, value)
    end
    if status ~= "ok" then
        if not CVarExists(name) then
            missingCVars[name] = true
        end
        return false
    end
    if ValuesMatch(current, value) then
        return false
    end
    local wrote = CVarSet(name, value)
    -- Forever 1.60.1 rejects out-of-bounds CVar values and keeps the old value.
    -- Read back the live value; if the engine refused a higher value, apply the Forever ceiling.
    local fallback = NS.FALLBACK_CVARS and NS.FALLBACK_CVARS[name]
    if fallback ~= nil and not ValuesMatch(value, fallback) then
        local nv, nf = tonumber(value), tonumber(fallback)
        if nv and nf and nv > nf then
            local after, afterStatus = CVarGet(name)
            if afterStatus == "ok" and not ValuesMatch(after, value) then
                rejectedMaxCVars[name] = true
                if not ValuesMatch(after, fallback) then
                    wrote = CVarSet(name, fallback) or wrote
                end
            end
        end
    end
    return wrote
end

function NS.GetCVarNumber(name, fallback)
    if NS.db and NS.db.profile == "custom" and type(NS.db.customCVars) == "table" and NS.db.customCVars[name] ~= nil then
        local saved = tonumber(NS.db.customCVars[name])
        if saved then
            return saved
        end
    end
    local val, status = CVarGet(name)
    if status == "ok" then
        local n = tonumber(val)
        if n and not IsSecret(n) then
            return n
        end
    end
    local base = (NS.db and (NS.MENU_GRAPHICS[NS.db.profile] or NS.MENU_GRAPHICS[NS.db.baseProfile])) or NS.MENU_GRAPHICS.ultimate
    if base and base[name] ~= nil then
        return tonumber(base[name]) or fallback
    end
    return fallback
end

function NS.SetCustomCVar(name, value, raidName)
    if not NS.db then
        NS.InitDB()
    end
    if not NS.db then
        return
    end
    local n = tonumber(value)
    if n == nil then
        return
    end
    NS.SnapshotPresetToCustom()
    NS.db.customCVars = NS.db.customCVars or {}
    NS.db.customCVars[name] = n
    if raidName then
        NS.db.customCVars[raidName] = n
    end
    if NS.db.enabled then
        NS.SetCVarIfChanged(name, n)
        if raidName then
            NS.SetCVarIfChanged(raidName, n)
        end
    end
    NS.RefreshOptions()
end

function NS.ApplyCustomCVars()
    local db = NS.db
    if not db or db.profile ~= "custom" or type(db.customCVars) ~= "table" then
        return
    end
    -- Never let saved custom CVars re-enable bloom / glow that SAFE_LIGHTING_RESET
    -- is meant to kill (Mount Hyjal outdoor clipping artifacts).
    local lighting = NS.SAFE_LIGHTING_RESET
    for name, val in pairs(db.customCVars) do
        if lighting and lighting[name] ~= nil then
            db.customCVars[name] = nil
        else
            NS.SetCVarIfChanged(name, val)
        end
    end
end

local bundlePlan = {}

local function BundlePlan(bundle)
    local plan = bundlePlan[bundle]
    if plan then
        return plan
    end
    local sliders, raw = {}, {}
    local sliderSet = NS.SLIDER_CVARS
    for name in pairs(bundle) do
        if sliderSet and sliderSet[name] then
            sliders[#sliders + 1] = name
        else
            raw[#raw + 1] = name
        end
    end
    plan = { sliders, raw }
    bundlePlan[bundle] = plan
    return plan
end

function NS.ApplyCVarBundle(bundle, skipMap)
    if not bundle then
        return false
    end
    -- Pass 1 writes menu slider CVars so their engine callbacks run before
    -- pass 2 writes the raw CVars those callbacks would otherwise reset.
    local plan = BundlePlan(bundle)
    local sliderNames, rawNames = plan[1], plan[2]
    local wroteSlider = false
    for i = 1, #sliderNames do
        local name = sliderNames[i]
        if not (skipMap and skipMap[name]) and NS.SetCVarIfChanged(name, bundle[name]) then
            wroteSlider = true
        end
    end
    for i = 1, #rawNames do
        local name = rawNames[i]
        if not (skipMap and skipMap[name]) then
            NS.SetCVarIfChanged(name, bundle[name])
        end
    end
    return wroteSlider
end

function NS.ApplyMenuGraphics(profile, skipFeatures)
    return NS.ApplyCVarBundle(NS.MENU_GRAPHICS[profile], skipFeatures and NS.FEATURE_CVARS or nil)
end

function NS.ApplyGraphicsQuality(profile)
    local quality = NS.PROFILE_QUALITY[profile]
    if quality == nil then
        return false
    end
    local wrote = false
    if NS.SetCVarIfChanged("graphicsQuality", quality) then
        wrote = true
    end
    if NS.SetCVarIfChanged("RAIDgraphicsQuality", quality) then
        wrote = true
    end
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
    if not db then
        return
    end
    if InCombat() then
        pendingApply = true
        return
    end
    local want = db.enabled and (db.herbSparkles or db.oreSparkles or db.questObjectSparkles)
    if want then
        -- In front of the camera only, gather range. A wide arc was locking onto quest givers.
        local range = db.questObjectSparkles and 28 or 20
        local arc = db.questObjectSparkles and 2 or 1
        NS.SetCVarIfChanged("SoftTargetInteract", 3)
        NS.SetCVarIfChanged("SoftTargetInteractRange", range)
        NS.SetCVarIfChanged("SoftTargetInteractArc", arc)
        NS.SetCVarIfChanged("SoftTargetInteractOnlyInRange", 1)
    else
        -- Mode 3 is this addon's gather targeting. Put it back when sparkles are off.
        local current, status = CVarGet("SoftTargetInteract")
        if status == "ok" and ValuesMatch(current, 3) then
            NS.SetCVarIfChanged("SoftTargetInteract", 1)
        end
    end
    if db.enabled then
        NS.ApplySoftTargetIcons()
    end
end

function NS.ApplyGathering()
    NS.ApplySoftTargetCVars()
    if NS.Sparkles and NS.Sparkles.Refresh then
        NS.Sparkles.Refresh()
    end
end

local outlineTicker
local outlineQuiet = 0
local outlineNames = {}
for name in pairs(OUTLINE_OFF) do
    outlineNames[#outlineNames + 1] = name
end

local function StopOutlineTicker()
    if outlineTicker then
        outlineTicker:Cancel()
        outlineTicker = nil
    end
end

local function StartOutlineTicker()
    if outlineTicker or not (C_Timer and C_Timer.NewTicker) then
        return
    end
    outlineTicker = C_Timer.NewTicker(OUTLINE_FAST, function()
        NS.PulseOutline()
    end)
end

function NS.PulseOutline()
    if InCombat() then
        return
    end
    local busy = false
    for i = 1, #outlineNames do
        local name = outlineNames[i]
        if not missingCVars[name] and not unwritableOutline[name] then
            local value = OUTLINE_OFF[name]
            local live, status = CVarGet(name)
            if status == "secret" then
                -- Leave this CVar alone until its value can be read.
            elseif status ~= "ok" then
                if not CVarExists(name) then
                    missingCVars[name] = true
                else
                    unwritableOutline[name] = true
                end
            elseif not ValuesMatch(live, value) then
                busy = true
                if not CVarSet(name, value) then
                    unwritableOutline[name] = true
                else
                    local after, afterStatus = CVarGet(name)
                    if afterStatus == "ok" and not ValuesMatch(after, value) then
                        unwritableOutline[name] = true
                    end
                end
            end
        end
    end
    if not outlineTicker then
        return
    end
    if busy then
        outlineQuiet = 0
    else
        outlineQuiet = outlineQuiet + 1
        if outlineQuiet >= 4 then
            StopOutlineTicker()
        end
    end
end

function NS.SyncOutlineSuppressor()
    local db = NS.db
    -- Graphics quality turns outline mode off, and disabled outline mode is the
    -- quest-giver sparkle. Hold High outline mode and the loot-sparkle flag off.
    local want = db and db.enabled and not db.questItemSparkles
    if want then
        outlineQuiet = 0
        StartOutlineTicker()
        NS.PulseOutline()
    else
        StopOutlineTicker()
    end
    if NS.SyncProtectWatch then
        NS.SyncProtectWatch()
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
        local offBundle = (NS.GetFeatureOffBundle and NS.GetFeatureOffBundle(def)) or def.off
        return NS.ApplyCVarBundle(offBundle)
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

local tintLayer
local tintTexture

function NS.ApplyTint()
    local db = NS.db
    local tints = NS.TINTS
    local tintIndex = db and tonumber(db.tint) or 0
    local strength = db and tonumber(db.tintStrength) or 0
    local entry = (db and db.enabled and tints and tintIndex > 0 and strength > 0) and tints[tintIndex] or nil
    local color = entry and entry.color or nil
    if not color then
        if tintLayer then
            tintLayer:Hide()
        end
        return
    end
    if not tintLayer then
        local parent = WorldFrame or UIParent
        tintLayer = CreateFrame("Frame", nil, parent)
        tintLayer:SetAllPoints()
        tintLayer:SetFrameStrata("BACKGROUND")
        tintTexture = tintLayer:CreateTexture(nil, "BACKGROUND")
        tintTexture:SetAllPoints()
        tintTexture:SetBlendMode("MOD")
    end
    local factor = math.max(0, math.min(1, strength / 100))
    local r = 1 - factor * (1 - color[1])
    local g = 1 - factor * (1 - color[2])
    local b = 1 - factor * (1 - color[3])
    tintTexture:SetColorTexture(r, g, b, 1)
    tintLayer:Show()
end

function NS.SetTint(tintIndex, silent)
    if not NS.db then
        NS.InitDB()
    end
    if not NS.db then
        return
    end
    local idx = math.floor((tonumber(tintIndex) or 0) + 0.5)
    local tints = NS.TINTS or {}
    if idx < 0 or idx > #tints then
        idx = 0
    end
    NS.db.tint = idx
    if idx > 0 and (tonumber(NS.db.tintStrength) or 0) <= 0 then
        NS.db.tintStrength = 50
    end
    NS.ApplyTint()
    NS.RefreshOptions()
    if not silent then
        if idx == 0 then
            NS.Print("Color tint disabled (default).")
        else
            NS.Print("Color tint: " .. (tints[idx] and tints[idx].name or tostring(idx)) .. " (" .. tostring(NS.db.tintStrength or 50) .. "%)")
        end
    end
end

function NS.SetTintStrength(strength)
    if not NS.db then
        NS.InitDB()
    end
    if not NS.db then
        return
    end
    local n = math.floor(((tonumber(strength) or 0) / 5) + 0.5) * 5
    NS.db.tintStrength = math.max(0, math.min(100, n))
    NS.ApplyTint()
    NS.RefreshOptions()
end

function NS.ResetTint(silent)
    if not NS.db then
        NS.InitDB()
    end
    if not NS.db then
        return
    end
    NS.db.tint = 0
    NS.db.tintStrength = 50
    NS.ApplyTint()
    NS.RefreshOptions()
    if not silent then
        NS.Print("Color tint reset to default (None).")
    end
end

local function CancelReapplyTimer()
    if reapplyTimer then
        reapplyTimer:Cancel()
        reapplyTimer = nil
    end
end

local function CancelSettleTimer()
    if settleTimer then
        settleTimer:Cancel()
        settleTimer = nil
    end
end

function NS.ApplyAll(full)
    local db = NS.db
    if not db or not db.enabled then
        CancelReapplyTimer()
        CancelSettleTimer()
        -- Clear bloom/glow left behind so outdoor clipping does not persist after disable.
        if not InCombat() and NS.SAFE_LIGHTING_RESET then
            NS.ApplyCVarBundle(NS.SAFE_LIGHTING_RESET)
        end
        NS.ApplyTint()
        NS.SyncOutlineSuppressor()
        NS.ApplySoftTargetCVars()
        if NS.Sparkles and NS.Sparkles.Refresh then
            NS.Sparkles.Refresh()
        end
        return false
    end
    NS.ApplyTint()
    if InCombat() then
        pendingApply = true
        return false
    end
    local profile = db.profile
    if not (NS.VALID_PROFILES and NS.VALID_PROFILES[profile]) then
        profile = "ultimate"
        db.profile = profile
    end
    local base = db.baseProfile
    if not (NS.VALID_BASE_PROFILES and NS.VALID_BASE_PROFILES[base]) then
        base = (profile ~= "custom" and NS.VALID_BASE_PROFILES and NS.VALID_BASE_PROFILES[profile]) and profile or "ultimate"
        db.baseProfile = base
    end
    local useFeatureBundles = (profile == "custom" or profile == "defaults")
    -- Quality first. Writing it or menu sliders can reset raw CVars a moment later, so reapply.
    local wroteMaster = false
    if profile ~= "custom" or full then
        local targetProfile = (profile ~= "custom") and profile or base
        if NS.ApplyGraphicsQuality(targetProfile) then
            wroteMaster = true
        end
        -- Skip feature-owned CVars when ApplyAllFeatures is about to write their final values.
        if NS.ApplyMenuGraphics(targetProfile, useFeatureBundles) then
            wroteMaster = true
        end
    end
    -- Defaults still runs each feature's off bundle. Fog and sun shafts are on in
    -- the menu baseline and off only in those bundles. Projected textures stay on.
    if useFeatureBundles then
        if NS.ApplyAllFeatures() then
            wroteMaster = true
        end
        NS.ApplyCustomCVars()
    end
    if NS.SAFE_LIGHTING_RESET then
        NS.ApplyCVarBundle(NS.SAFE_LIGHTING_RESET)
    end
    -- Bloom multipliers stay at 0 via SAFE_LIGHTING_RESET. Feature bundles already
    -- write the user's sunShafts intensity — do not force the checkbox off here.
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

-- Forever continues loading server/default CVars up to ~4 seconds after login.
-- Schedule a final settle pass at 4.35s so the client does not undo raw CVars.
local function ScheduleLoginSettle()
    CancelSettleTimer()
    if not (C_Timer and C_Timer.NewTimer) then
        return
    end
    settleTimer = C_Timer.NewTimer(LOGIN_SETTLE_SECONDS, function()
        settleTimer = nil
        if NS.db and NS.db.enabled then
            if NS.ApplyAll(true) then
                ScheduleReapply()
            end
            if NS.Options and NS.Options.Refresh then
                NS.Options.Refresh()
            end
        end
    end)
end

function NS.ApplySettings(a, b)
    local silent = a
    if a == NS then
        silent = b
        if NS.InitDB then
            NS.InitDB()
        end
    end
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
    local fallback = "ultimate"
    if db.baseProfile == "balance" or db.profile == "balance" then
        fallback = "balance"
    elseif db.baseProfile == "low" or db.profile == "low" then
        fallback = "low"
    end
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
    if NS.db and type(NS.db.customCVars) == "table" and feature.ultimate then
        for name in pairs(feature.ultimate) do
            NS.db.customCVars[name] = nil
        end
    end
    if not initialApplyDone or pendingApply then
        NS.ApplySettings(true)
        return
    end
    if NS.db and NS.db.enabled then
        if NS.ApplyFeature(feature) then
            if NS.SAFE_LIGHTING_RESET then
                NS.ApplyCVarBundle(NS.SAFE_LIGHTING_RESET)
            end
            if C_Timer and C_Timer.After then
                -- Re-assert raw CVars after the engine's slider callback settles.
                C_Timer.After(0.2, function()
                    if NS.db and NS.db.enabled and not InCombat() then
                        NS.ApplyFeature(feature)
                        if NS.SAFE_LIGHTING_RESET then
                            NS.ApplyCVarBundle(NS.SAFE_LIGHTING_RESET)
                        end
                    end
                end)
            end
        end
    end
    if NS.Options and NS.Options.Refresh then
        NS.Options.Refresh()
    end
end

function NS.SetProfile(profile, silent)
    if not (NS.VALID_BASE_PROFILES and NS.VALID_BASE_PROFILES[profile]) then
        profile = "ultimate"
    end
    NS.db.profile = profile
    NS.db.baseProfile = profile
    NS.db.enabled = true
    NS.db.customCVars = {}
    if profile == "defaults" or profile == "potato" then
        NS.db.tint = 0
    end
    local hadInteractIcons = NS.db.showSoftTargetInteractIcons
    NS.db.showSoftTargetInteractIcons = false
    local list = NS.FEATURES
    for i = 1, #list do
        local key = list[i].key
        if NS.ALWAYS_MAX_FEATURES and NS.ALWAYS_MAX_FEATURES[key] then
            NS.db[key] = true
            NS.db.intensity[key] = "ultimate"
        elseif profile == "potato" then
            NS.db[key] = false
            NS.db.intensity[key] = "off"
        elseif profile == "defaults" then
            NS.db[key] = key == "projectedTextures"
            NS.db.intensity[key] = "ultimate"
        elseif profile == "low" then
            if key == "projectedTextures" then
                NS.db[key] = true
                NS.db.intensity[key] = "ultimate"
            elseif NS.LOW_OFF_FEATURES and NS.LOW_OFF_FEATURES[key] then
                NS.db[key] = false
                NS.db.intensity[key] = "off"
            else
                NS.db[key] = true
                NS.db.intensity[key] = "low"
            end
        else
            if key == "volumeFog" or key == "sunShafts" then
                NS.db[key] = false
                NS.db.intensity[key] = "off"
            else
                NS.db[key] = true
                NS.db.intensity[key] = profile
            end
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

function NS.RestartGraphics()
    if ConsoleExec then
        pcall(ConsoleExec, "gxRestart")
        NS.Print("Graphics engine restarted.")
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
        CancelSettleTimer()
        if not InCombat() and NS.SAFE_LIGHTING_RESET then
            NS.ApplyCVarBundle(NS.SAFE_LIGHTING_RESET)
        end
        NS.ApplyTint()
        if NS.Sparkles and NS.Sparkles.Refresh then
            NS.Sparkles.Refresh()
        end
        NS.Print("Off. Bloom/glow reset; other graphics stay as last applied.")
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
            if NS.db.baseProfile == "balance" then
                NS.db.intensity[key] = "balance"
            elseif NS.db.baseProfile == "low" then
                NS.db.intensity[key] = "low"
            else
                NS.db.intensity[key] = "ultimate"
            end
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
                CancelSettleTimer()
                NS.ApplyTint()
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

function NS.CaptureReloadBaseline()
    NS.reloadBaseline = NS.reloadBaseline or {}
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

local reloadParts = {}
local reloadLines = {}

local function ReloadSignature()
    if not NS.db or not NS.RELOAD_OPTIONS then
        return ""
    end
    local count = 0
    for key in pairs(NS.RELOAD_OPTIONS) do
        count = count + 1
        reloadParts[count] = key .. "=" .. (NS.db[key] and "1" or "0")
    end
    for i = count + 1, #reloadParts do
        reloadParts[i] = nil
    end
    table.sort(reloadParts)
    return table.concat(reloadParts, "|")
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
    local count = 0
    local baseline = NS.reloadBaseline or {}
    for key, label in pairs(NS.RELOAD_OPTIONS) do
        local now = NS.db[key] and true or false
        if now ~= baseline[key] then
            count = count + 1
            reloadLines[count] = label .. " (" .. (now and "on" or "off") .. ")"
        end
    end
    for i = count + 1, #reloadLines do
        reloadLines[i] = nil
    end
    table.sort(reloadLines)
    local body = "A UI reload is required before this change finishes."
    if count > 0 then
        body = body .. "\n\n" .. table.concat(reloadLines, "\n")
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
        CancelSettleTimer()
        NS.ApplyTint()
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
    elseif msg == "low" then
        NS.SetProfile("low")
    elseif msg == "potato" or msg == "min" then
        NS.SetProfile("potato")
    elseif msg == "restart" or msg == "gxrestart" then
        NS.RestartGraphics()
    elseif string.sub(msg, 1, 4) == "tint" then
        local arg = strtrim(string.sub(msg, 5))
        if arg == "" or arg == "off" or arg == "none" or arg == "default" or arg == "reset" or arg == "0" then
            NS.ResetTint()
        else
            local found = tonumber(arg)
            if not found and NS.TINTS then
                for i = 1, #NS.TINTS do
                    if string.lower(NS.TINTS[i].name) == arg then
                        found = i
                        break
                    end
                end
            end
            if found then
                NS.SetTint(found)
            else
                NS.Print("Tint options: off, sepia, warm, cold, night, emerald, dusk.")
            end
        end
    elseif msg == "protect" then
        NS.db.protect = not NS.db.protect
        NS.SyncProtectWatch()
        NS.Print("Protect icons: " .. (NS.db.protect and "ON" or "OFF"))
        NS.RefreshOptions()
    elseif msg == "sparkles" or msg == "loot" then
        NS.ToggleFeature("questItemSparkles", not NS.db.questItemSparkles)
    elseif msg == "general" then
        NS.OpenGraphicsOptions("general")
    elseif msg == "world" or msg == "terrain" then
        NS.OpenGraphicsOptions("world")
    elseif msg == "lighting" or msg == "effects" or msg == "shadows" then
        NS.OpenGraphicsOptions("lighting")
    elseif msg == "camera" then
        NS.OpenGraphicsOptions("camera")
    else
        local Lib = _G.XiusCoreSettingsLib
        if Lib and type(Lib.Toggle) == "function" then
            Lib:Toggle("Graphics")
        elseif NS.ToggleOptions then
            NS.ToggleOptions()
        end
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
    if NS.OpenGraphicsOptions then
        NS.OpenGraphicsOptions()
    elseif NS.ToggleOptions then
        NS.ToggleOptions()
    end
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
SafeRegister(events, "VARIABLES_LOADED")
SafeRegister(events, "PLAYER_ENTERING_WORLD")
SafeRegister(events, "PLAYER_REGEN_ENABLED")

function NS.SyncProtectWatch()
    local db = NS.db
    if db and db.enabled and (db.protect or not db.questItemSparkles) then
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
        if NS.Options and NS.Options.RegisterSettings then
            NS.Options.RegisterSettings()
        end
        NS.CaptureReloadBaseline()
        ScheduleLoginSettle()
        NS.Print("Loaded v" .. NS.VERSION .. ". Type |cffffd100/xmg|r for options.")
    elseif event == "VARIABLES_LOADED" then
        if NS.db and NS.db.enabled then
            if NS.ApplyAll(true) then
                ScheduleReapply()
            end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin = not IsSecret(arg1) and arg1
        local isReloadingUi = not IsSecret(arg2) and arg2
        if (isInitialLogin or isReloadingUi) and NS.db then
            if NS.ApplyAll(true) then
                ScheduleReapply()
            end
            ScheduleLoginSettle()
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
        local db = NS.db
        if not db or not db.enabled or applyingProtect then
            return
        end
        if IsSecret(arg1) or type(arg1) ~= "string" then
            return
        end
        local lower = string.lower(arg1)
        local isOutline = OUTLINE_WATCH[arg1] or OUTLINE_WATCH[lower]
        if db.protect and (PROTECT_WATCH[arg1] or PROTECT_WATCH[lower]) then
            if InCombat() then
                pendingApply = true
                return
            end
            applyingProtect = true
            NS.ApplySparkleCVars()
            NS.ApplySoftTargetIcons()
            applyingProtect = false
        elseif not db.questItemSparkles and isOutline then
            if InCombat() then
                pendingApply = true
                return
            end
            applyingProtect = true
            NS.SyncOutlineSuppressor()
            applyingProtect = false
        end
    end
end)
