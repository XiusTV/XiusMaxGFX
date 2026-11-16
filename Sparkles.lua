--[[
    Xius Max Graphics - Sparkles.lua
    Soft-target glints for herbs, ore, and optional quest objects.
]]

local ADDON, NS = ...

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

NS.Sparkles = NS.Sparkles or {}

local sparkles = NS.Sparkles
local NUM_GLINTS = 2
local STEP = 1 / 12

local pcall = pcall
local type = type
local GetTime = GetTime
local sin = math.sin
local cos = math.cos
local PI2 = math.pi * 2
local strfind = string.find
local strlower = string.lower
local strsub = string.sub
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitName = UnitName
local UnitCanAttack = UnitCanAttack
local UnitIsUnit = UnitIsUnit
local UnitIsInInteractRange = UnitIsInInteractRange
local CheckInteractDistance = CheckInteractDistance
local InCombatLockdown = InCombatLockdown

local holder
local glints
local shown = false
local lastGuid
local lastAllowed = false
local colorMode = -1
local accum = 0
local attachedPlate
local ticker
local pendingReparent = false
local raisedNameplate = false
local eventsRegistered = false

local ORE_WORDS = {
    "vein", "deposit", "seam", "outcrop",
    "copper", "tin", "silver", "iron", "gold", "mithril", "truesilver", "thorium",
    "cobalt", "saronite", "titanium", "obsidium", "elementium", "pyrite",
    "kyparite", "trillium", "leystone", "felslate", "empyrium", "monelite",
    "platinum", "osmenite", "laestrite", "phaedrum", "sinvyr", "elethium",
    "serevite", "draconium", "khaz'gorite", "bismuth", "aqirite", "ironclaw",
}

local HERB_WORDS = {
    "peacebloom", "silverleaf", "earthroot", "mageroyal", "briarthorn", "stranglekelp",
    "bruiseweed", "steelbloom", "gravemoss", "kingsblood", "liferoot", "fadeleaf",
    "goldthorn", "wintersbite", "firebloom", "lotus", "arthas", "sungrass",
    "blindweed", "mushroom", "gromsblood", "sansam", "dreamfoil", "silversage",
    "plaguebloom", "icecap", "whisker", "felweed", "ragveil", "terocone",
    "netherbloom", "flamecap", "bloodthistle", "hochenblume", "saxifrage",
    "writhebark", "mycobloom", "luredrop", "orbinid", "arathor",
}

local function IsSecret(value)
    if value == nil then
        return false
    end
    if NS.CanRead then
        return not NS.CanRead(value)
    end
    return issecretvalue ~= nil and issecretvalue(value)
end

local function IsSecretTable(value)
    return issecrettable ~= nil and issecrettable(value)
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

local function Wanted()
    local db = NS.db
    return db and db.enabled and (db.herbSparkles or db.oreSparkles or db.questObjectSparkles)
end

local function SafeExists(unit)
    local ok, exists = pcall(UnitExists, unit)
    if not ok or IsSecret(exists) then
        return false
    end
    return exists and true or false
end

local function SafeString(fn, unit)
    if not fn then
        return nil
    end
    local ok, value = pcall(fn, unit)
    if not ok or IsSecret(value) or type(value) ~= "string" or value == "" then
        return nil
    end
    return value
end

local function Has(text, word)
    return text ~= nil and strfind(text, word, 1, true) ~= nil
end

local function HasAny(text, list)
    if not text then
        return false
    end
    for i = 1, #list do
        local word = list[i]
        local start = 1
        local step = #word
        while true do
            local found = strfind(text, word, start, true)
            if not found then
                break
            end
            local prev = found > 1 and strsub(text, found - 1, found - 1) or ""
            local prevOk = prev == "" or strfind(prev, "%a") == nil
            if prevOk then
                local nextc = strsub(text, found + step, found + step)
                local nextOk = nextc == "" or strfind(nextc, "%a") == nil
                -- Short names must be a whole word so "gold" does not match "golden".
                if nextOk or step >= 6 then
                    return true
                end
            end
            start = found + 1
        end
    end
    return false
end

local tipParts = {}

local function ReadTooltipLines(data)
    local lines = data.lines
    if IsSecret(lines) or IsSecretTable(lines) or type(lines) ~= "table" then
        return nil
    end
    local count = 0
    for i = 1, #lines do
        local line = lines[i]
        if not IsSecret(line) and not IsSecretTable(line) and line then
            local left = line.leftText
            if not IsSecret(left) and type(left) == "string" and left ~= "" then
                count = count + 1
                tipParts[count] = strlower(left)
            end
        end
    end
    for i = count + 1, #tipParts do
        tipParts[i] = nil
    end
    if count == 0 then
        return nil
    end
    return table.concat(tipParts, " ")
end

local function TooltipText(unit)
    if not (C_TooltipInfo and C_TooltipInfo.GetUnit) then
        return nil
    end
    local ok, data = pcall(C_TooltipInfo.GetUnit, unit)
    if not ok or IsSecret(data) or IsSecretTable(data) or data == nil then
        return nil
    end
    local readOk, blob = pcall(ReadTooltipLines, data)
    if readOk then
        return blob
    end
    return nil
end

local function Classify(unit)
    local tip = TooltipText(unit)
    if Has(tip, "herbalism") or Has(tip, "herb") then
        return "herb"
    end
    if Has(tip, "mining") then
        return "ore"
    end
    if Has(tip, "quest") then
        return "quest"
    end

    local name = SafeString(UnitName, unit)
    if name then
        name = strlower(name)
        if HasAny(name, ORE_WORDS) then
            return "ore"
        end
        if HasAny(name, HERB_WORDS) then
            return "herb"
        end
    end

    return "object"
end

local function KindAllowed(kind)
    local db = NS.db
    if not db then
        return false
    end
    if kind == "herb" then
        return db.herbSparkles and true or false
    end
    if kind == "ore" then
        return db.oreSparkles and true or false
    end
    if kind == "quest" or kind == "object" then
        return db.questObjectSparkles and true or false
    end
    return false
end

local function ReadableBoolean(value)
    if IsSecret(value) then
        return nil
    end
    return value and true or false
end

local function InRange()
    if UnitIsInInteractRange then
        local ok, value = pcall(UnitIsInInteractRange, "softinteract")
        if ok then
            local readable = ReadableBoolean(value)
            if readable ~= nil then
                return readable
            end
            return true
        end
    end
    if not CheckInteractDistance then
        return true
    end
    local ok, value = pcall(CheckInteractDistance, "softinteract", 3)
    if ok then
        local readable = ReadableBoolean(value)
        if readable ~= nil then
            return readable
        end
    end
    return true
end

local function CanUse()
    if not UnitCanAttack then
        return true
    end
    local ok, can = pcall(UnitCanAttack, "player", "softinteract")
    if not ok or IsSecret(can) then
        return true
    end
    return can ~= true
end

local function EnsureHolder()
    if holder then
        return
    end
    holder = CreateFrame("Frame", nil, UIParent)
    holder:SetSize(32, 32)
    holder:SetFrameStrata("HIGH")
    holder:Hide()

    glints = {}
    local slice = PI2 / NUM_GLINTS
    for i = 1, NUM_GLINTS do
        local g = holder:CreateTexture(nil, "OVERLAY")
        g:SetTexture("Interface\\Cooldown\\star4")
        g:SetBlendMode("ADD")
        g:SetSize(12, 12)
        g:SetPoint("CENTER", holder, "CENTER", 0, 0)
        g.angle = (i - 1) * slice
        g.radius = (i == 1) and 10 or 16
        g.speed = 1.4 + i * 0.25
        glints[i] = g
    end
end

local function GlintOnUpdate(self, elapsed)
    if IsSecret(elapsed) then
        return
    end
    accum = accum + (elapsed or 0)
    if accum < STEP then
        return
    end
    accum = 0
    local t = GetTime()
    if IsSecret(t) then
        return
    end
    for i = 1, NUM_GLINTS do
        local g = glints[i]
        local angle = g.angle + t * g.speed
        local pulse = 0.7 + 0.3 * sin(t * 6 + g.angle)
        if IsSecret(angle) or IsSecret(pulse) then
            return
        end
        g:SetPoint("CENTER", self, "CENTER", cos(angle) * g.radius, sin(angle) * g.radius * pulse)
        g:SetAlpha(0.4 + 0.6 * pulse)
    end
end

local function SetColor(mode)
    if colorMode == mode or not glints then
        return
    end
    colorMode = mode
    local r, g, b, a
    if mode == 1 then
        r, g, b, a = NS.COLOR.sparkle[1], NS.COLOR.sparkle[2], NS.COLOR.sparkle[3], 1
    elseif mode == 2 then
        r, g, b, a = 0.75, 0.65, 0.25, 0.55
    else
        r, g, b, a = 0.55, 0.55, 0.55, 0.8
    end
    for i = 1, NUM_GLINTS do
        glints[i]:SetVertexColor(r, g, b, a)
    end
end

local function ReleaseHolder()
    if not holder then
        return
    end
    holder:SetScript("OnUpdate", nil)
    if InCombat() then
        pendingReparent = true
        return
    end
    holder:Hide()
    pcall(holder.ClearAllPoints, holder)
    pcall(holder.SetParent, holder, UIParent)
    pendingReparent = false
end

local function GetPlateUnitFrame(plate)
    return plate.UnitFrame
end

local function Attach()
    if not holder or not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then
        return false
    end
    local ok, plate = pcall(C_NamePlate.GetNamePlateForUnit, "softinteract")
    if not ok or IsSecret(plate) or plate == nil then
        return false
    end
    -- The nameplate base frame rejects addon anchors. Use its unit frame.
    local hostOk, host = pcall(GetPlateUnitFrame, plate)
    if not hostOk or IsSecret(host) or host == nil then
        return false
    end
    if attachedPlate == host and not pendingReparent then
        return true
    end
    if not pcall(holder.SetParent, holder, host) then
        return false
    end
    holder:ClearAllPoints()
    if not pcall(holder.SetPoint, holder, "CENTER", host, "CENTER", 0, 8) then
        pcall(holder.SetParent, holder, UIParent)
        attachedPlate = nil
        pendingReparent = false
        return false
    end
    attachedPlate = host
    pendingReparent = false
    return true
end

local function DropNameplateCVar()
    if not raisedNameplate or InCombat() then
        return
    end
    NS.SetCVarIfChanged("SoftTargetNameplateInteract", 0)
    raisedNameplate = false
end

local function Hide()
    if not shown and not pendingReparent and not raisedNameplate then
        return
    end
    local wasShown = shown
    shown = false
    colorMode = -1
    attachedPlate = nil
    if holder and (wasShown or pendingReparent) then
        ReleaseHolder()
    end
    if not pendingReparent then
        DropNameplateCVar()
    end
end

local function Show()
    EnsureHolder()
    if not raisedNameplate then
        NS.SetCVarIfChanged("SoftTargetNameplateInteract", 1)
        raisedNameplate = true
    end
    if not Attach() then
        return
    end
    shown = true
    if CanUse() then
        SetColor(InRange() and 1 or 2)
    else
        SetColor(0)
    end
    if holder:GetScript("OnUpdate") ~= GlintOnUpdate then
        holder:SetScript("OnUpdate", GlintOnUpdate)
    end
    holder:Show()
end

local function StopTicker()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

local function Evaluate()
    if pendingReparent and not InCombat() then
        ReleaseHolder()
    end
    if not Wanted() then
        lastGuid = nil
        lastAllowed = false
        Hide()
        StopTicker()
        return
    end
    if InCombat() then
        Hide()
        return
    end
    if not SafeExists("softinteract") then
        lastGuid = nil
        lastAllowed = false
        Hide()
        return
    end
    -- Quest givers and other NPCs can be the soft-interact target. Never sparkle them.
    local guid = SafeString(UnitGUID, "softinteract")
    if not guid or strsub(guid, 1, 10) ~= "GameObject" then
        lastGuid = nil
        lastAllowed = false
        Hide()
        return
    end

    if guid == lastGuid then
        if not lastAllowed then
            return
        end
        if shown then
            if CanUse() then
                SetColor(InRange() and 1 or 2)
            else
                SetColor(0)
            end
            Attach()
        else
            Show()
        end
        return
    end

    lastGuid = guid
    lastAllowed = KindAllowed(Classify("softinteract"))
    if lastAllowed then
        Show()
    else
        Hide()
    end
end

local function EnsureTicker()
    if ticker or not Wanted() or not (C_Timer and C_Timer.NewTicker) then
        return
    end
    ticker = C_Timer.NewTicker(2, Evaluate)
end

local events = CreateFrame("Frame")

local function SyncEvents()
    local want = Wanted()
    if want and not eventsRegistered then
        SafeRegister(events, "PLAYER_SOFT_INTERACT_CHANGED")
        SafeRegister(events, "NAME_PLATE_UNIT_ADDED")
        SafeRegister(events, "PLAYER_REGEN_DISABLED")
        SafeRegister(events, "PLAYER_ENTERING_WORLD")
        eventsRegistered = true
    elseif not want and eventsRegistered then
        SafeUnregister(events, "PLAYER_SOFT_INTERACT_CHANGED")
        SafeUnregister(events, "NAME_PLATE_UNIT_ADDED")
        SafeUnregister(events, "PLAYER_REGEN_DISABLED")
        SafeUnregister(events, "PLAYER_ENTERING_WORLD")
        eventsRegistered = false
    end
end

function sparkles.Refresh()
    lastGuid = nil
    lastAllowed = false
    SyncEvents()
    EnsureTicker()
    Evaluate()
end

function sparkles.OnCombatEnd()
    SyncEvents()
    EnsureTicker()
    Evaluate()
end

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        lastGuid = nil
        lastAllowed = false
        EnsureTicker()
    elseif event == "PLAYER_REGEN_DISABLED" then
        Hide()
        return
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        if not lastAllowed then
            return
        end
        if UnitIsUnit and not IsSecret(arg1) and type(arg1) == "string" then
            local ok, same = pcall(UnitIsUnit, arg1, "softinteract")
            if not (ok and not IsSecret(same) and same) then
                return
            end
        end
    end
    Evaluate()
end)
