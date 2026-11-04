--[[
    Xius Max Graphics - Options.lua
    Movable /xmg window plus the same controls in Esc > Options > AddOns.
]]

local ADDON, NS = ...

NS.Options = NS.Options or {}

local COLOR = NS.COLOR
local TEMPLATE = NS.BACKDROP_TEMPLATE
local PANEL_MIN_W = 380
local PANEL_MIN_H = 420
local PANEL_MAX_W = 560
local PANEL_MAX_H = 720
local LEFT = 16
local refreshers = {}
local layoutHooks = {}
local panel
local scrollChild
local blizzardChild
local blizzardBuilt = false

local BG_STEPPER = { 0.08, 0.08, 0.08, 1 }
local BORDER_STEPPER = { COLOR.buttonEdge[1], COLOR.buttonEdge[2], COLOR.buttonEdge[3], 0.7 }
local BG_ARROW = { 0.10, 0.10, 0.10, 1 }
local BORDER_ARROW = { COLOR.buttonEdge[1], COLOR.buttonEdge[2], COLOR.buttonEdge[3], 0.9 }

local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

local function Clamp(val, low, high)
    if val < low then
        return low
    elseif val > high then
        return high
    end
    return val
end

local function IntensityLabel(intensity)
    if intensity == "ultimate" then
        return "MAX"
    elseif intensity == "balance" then
        return "BAL"
    end
    return "OFF"
end

local function IntensityColor(intensity)
    if intensity == "ultimate" then
        return COLOR.good
    elseif intensity == "balance" then
        return COLOR.warn
    end
    return COLOR.muted
end

local function SectionHeader(parent, text, y)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    NS.SetFont(fs, 12)
    fs:SetTextColor(COLOR.gold[1], COLOR.gold[2], COLOR.gold[3])
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", LEFT, y)
    fs:SetText(text)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture(NS.WHITE)
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 8, 0)
    line:SetPoint("RIGHT", parent, "RIGHT", -LEFT, 0)
    line:SetVertexColor(COLOR.goldLine[1], COLOR.goldLine[2], COLOR.goldLine[3], 0.45)
    return y - 22
end

local function TipScripts(frame, title, tip)
    frame:SetScript("OnEnter", function(self)
        if not GameTooltip then
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 0.82, 0)
        if tip then
            GameTooltip:AddLine(tip, 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)
end

local function LabelWidget(cb, label)
    local text = cb.Text
    if not text then
        text = cb:CreateFontString(nil, "OVERLAY")
        text:SetPoint("LEFT", cb, "RIGHT", 4, 1)
    end
    NS.SetFont(text, 12)
    text:SetTextColor(1, 1, 1)
    text:SetText(label)
    return text
end

local function CreateCheck(parent, label, key, y, tip)
    if NS.RELOAD_OPTIONS and NS.RELOAD_OPTIONS[key] then
        label = label .. " (requires reload)"
    end
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", LEFT - 4, y)
    LabelWidget(cb, label)

    cb:SetScript("OnClick", function(self)
        NS.ToggleFeature(key, self:GetChecked() and true or false)
    end)
    TipScripts(cb, label, tip)

    refreshers[#refreshers + 1] = function()
        cb:SetChecked(NS.db[key] and true or false)
    end
    return y - 26
end

local function MakeArrowButton(parent, glyph)
    local b = CreateFrame("Button", nil, parent, TEMPLATE)
    b:SetSize(20, 20)
    NS.ApplyBackdrop(b, NS.BACKDROP_MENU, BG_ARROW, BORDER_ARROW)
    local fs = b:CreateFontString(nil, "OVERLAY")
    NS.SetFont(fs, 12)
    fs:SetPoint("CENTER", 0, 0)
    fs:SetTextColor(COLOR.gold[1], COLOR.gold[2], COLOR.gold[3])
    fs:SetText(glyph)
    b:SetScript("OnEnter", function(self)
        if self.SetBackdropColor then
            self:SetBackdropColor(0.18, 0.16, 0.10, 1)
            self:SetBackdropBorderColor(COLOR.gold[1], COLOR.gold[2], COLOR.gold[3], 1)
        end
    end)
    b:SetScript("OnLeave", function(self)
        if self.SetBackdropColor then
            self:SetBackdropColor(0.10, 0.10, 0.10, 1)
            self:SetBackdropBorderColor(COLOR.buttonEdge[1], COLOR.buttonEdge[2], COLOR.buttonEdge[3], 0.9)
        end
    end)
    return b
end

local function CreateFeatureRow(parent, feature, y)
    local key = feature.key
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", LEFT - 4, y)

    local featureText = LabelWidget(cb, feature.label)

    local stepper = CreateFrame("Frame", nil, parent, TEMPLATE)
    stepper:SetSize(78, 20)
    stepper:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -LEFT, y - 2)
    NS.ApplyBackdrop(stepper, NS.BACKDROP_MENU, BG_STEPPER, BORDER_STEPPER)

    local left = MakeArrowButton(stepper, "<")
    left:SetPoint("LEFT", stepper, "LEFT", 1, 0)

    local right = MakeArrowButton(stepper, ">")
    right:SetPoint("RIGHT", stepper, "RIGHT", -1, 0)

    featureText:SetPoint("RIGHT", stepper, "LEFT", -6, 0)
    featureText:SetJustifyH("LEFT")
    featureText:SetWordWrap(false)

    local valueBtn = CreateFrame("Button", nil, stepper)
    valueBtn:SetPoint("LEFT", left, "RIGHT", 1, 0)
    valueBtn:SetPoint("RIGHT", right, "LEFT", -1, 0)
    valueBtn:SetHeight(18)
    valueBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local valueText = valueBtn:CreateFontString(nil, "OVERLAY")
    NS.SetFont(valueText, 10)
    valueText:SetPoint("CENTER", 0, 0)

    local function RefreshStepper()
        local intensity = NS.GetFeatureIntensity(key)
        valueText:SetText(IntensityLabel(intensity))
        local c = IntensityColor(intensity)
        valueText:SetTextColor(c[1], c[2], c[3])
    end

    local function Step(dir)
        NS.CycleFeatureIntensity(key, dir)
    end

    left:SetScript("OnClick", function()
        Step(-1)
    end)
    right:SetScript("OnClick", function()
        Step(1)
    end)
    valueBtn:SetScript("OnClick", function(_, button)
        Step(button == "RightButton" and -1 or 1)
    end)

    cb:SetScript("OnClick", function(self)
        NS.ToggleFeature(key, self:GetChecked() and true or false)
    end)

    TipScripts(cb, feature.label, feature.tip)
    TipScripts(left, "Lower", "Step down: MAX -> BAL -> OFF")
    TipScripts(right, "Higher", "Step up: OFF -> BAL -> MAX")
    TipScripts(valueBtn, "Intensity", "Use the arrows or click to set MAX, BAL, or OFF for this upgrade only.")

    refreshers[#refreshers + 1] = function()
        cb:SetChecked(NS.db[key] and true or false)
        RefreshStepper()
    end
    return y - 28
end

local function CreateButton(parent, label, width, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    return b
end

local function BuildSettingsContent(parent)
    local y = -8

    y = SectionHeader(parent, "Presets", y)

    local profileLabel = parent:CreateFontString(nil, "OVERLAY")
    NS.SetFont(profileLabel, 11)
    profileLabel:SetTextColor(COLOR.muted[1], COLOR.muted[2], COLOR.muted[3])
    profileLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", LEFT, y)
    refreshers[#refreshers + 1] = function()
        local qProfile = NS.db.profile
        if not (NS.PROFILE_QUALITY_UI and NS.PROFILE_QUALITY_UI[qProfile]) then
            qProfile = NS.db.baseProfile
        end
        local q = NS.PROFILE_QUALITY_UI and NS.PROFILE_QUALITY_UI[qProfile]
        local text = "Active profile: " .. NS.ProfileDisplayName()
        if q then
            text = text .. "  |  Base Quality " .. tostring(q)
        end
        profileLabel:SetText(text)
    end
    y = y - 20

    local ultimate = CreateButton(parent, "Ultimate", 118, function()
        NS.SetProfile("ultimate")
    end)
    local balance = CreateButton(parent, "Balance", 118, function()
        NS.SetProfile("balance")
    end)
    local reset = CreateButton(parent, "Defaults", 118, function()
        NS.SetProfile("defaults")
    end)
    local presetButtons = { ultimate, balance, reset }
    ultimate:SetPoint("TOPLEFT", parent, "TOPLEFT", LEFT, y)
    balance:SetPoint("LEFT", ultimate, "RIGHT", 6, 0)
    reset:SetPoint("LEFT", balance, "RIGHT", 6, 0)
    layoutHooks[#layoutHooks + 1] = function()
        local width = parent:GetWidth()
        if IsSecret(width) or type(width) ~= "number" or width < 100 then
            return
        end
        local buttonWidth = Clamp(math.floor((width - (LEFT * 2) - 12) / 3), 72, 118)
        for i = 1, #presetButtons do
            presetButtons[i]:SetWidth(buttonWidth)
        end
    end
    y = y - 34

    y = SectionHeader(parent, "General", y)
    y = CreateCheck(parent, "Enable graphics upgrades", "enabled", y,
        "Master switch. When off, the addon stops applying CVars.")
    y = CreateCheck(parent, "Keep loot / soft-target icons sticky", "protect", y,
        "Only re-locks loot sparkles and soft-target icons. Does not fight your Graphics menu.")
    y = CreateCheck(parent, "Chat messages", "chatMessages", y,
        "Show status messages in chat when presets are applied.")
    y = y - 6

    y = SectionHeader(parent, "World detail", y)
    for i = 1, #NS.FEATURES do
        local f = NS.FEATURES[i]
        if f.category == "world" then
            y = CreateFeatureRow(parent, f, y)
        end
    end
    y = y - 4

    y = SectionHeader(parent, "Lighting & fog", y)
    for i = 1, #NS.FEATURES do
        local f = NS.FEATURES[i]
        if f.category == "lighting" then
            y = CreateFeatureRow(parent, f, y)
        end
    end
    y = y - 4

    y = SectionHeader(parent, "Effects & water", y)
    for i = 1, #NS.FEATURES do
        local f = NS.FEATURES[i]
        if f.category == "effects" then
            y = CreateFeatureRow(parent, f, y)
        end
    end
    y = y - 4

    y = SectionHeader(parent, "Image clarity", y)
    for i = 1, #NS.FEATURES do
        local f = NS.FEATURES[i]
        if f.category == "image" then
            y = CreateFeatureRow(parent, f, y)
        end
    end
    y = y - 4

    y = SectionHeader(parent, "Loot & gathering sparkles", y)
    y = CreateCheck(parent, "Quest item loot sparkles", "questItemSparkles", y,
        "Sparkles on quest loot and quest givers. Leave this off to hide them. Fully exit the game afterward. A UI reload will not remove the sparkles.")
    y = CreateCheck(parent, "Herb sparkles (soft target)", "herbSparkles", y,
        "Golden glints on the nearest herb within soft-target range. Does not sparkle NPCs or quest givers.")
    y = CreateCheck(parent, "Ore vein sparkles (soft target)", "oreSparkles", y,
        "Golden glints on the nearest ore vein within soft-target range. Does not sparkle NPCs or quest givers.")
    y = CreateCheck(parent, "Quest object sparkles (soft target)", "questObjectSparkles", y,
        "Extra sparkles on nearby quest objects (chests, wanted posters). Does not sparkle quest-giver NPCs.")
    y = CreateCheck(parent, "Show soft-target object/gather icons", "showSoftTargetObjectIcons", y,
        "Floating 2D icons over quest objects, ground loot, herb nodes, and ore veins. You will be asked to reload as soon as you change this.")
    y = CreateCheck(parent, "Show soft-target NPC/quest giver icons", "showSoftTargetInteractIcons", y,
        "Overhead icons on NPCs and quest givers. Ultimate, Balance, and Defaults turn this off. You will be asked to reload as soon as you change this.")

    local note = parent:CreateFontString(nil, "OVERLAY")
    NS.SetFont(note, 10)
    note:SetTextColor(COLOR.muted[1], COLOR.muted[2], COLOR.muted[3])
    note:SetPoint("TOPLEFT", parent, "TOPLEFT", LEFT, y - 4)
    note:SetPoint("RIGHT", parent, "RIGHT", -LEFT, 0)
    note:SetJustifyH("LEFT")
    note:SetWordWrap(true)
    note:SetText("Tip: Ultimate = max graphics. Balance = high quality with less cost. Defaults = the graphics menu baseline. Use < > for MAX/BAL/OFF. Type /xmg for a movable window.")
    y = y - 56

    parent:SetHeight(math.abs(y) + 20)
    return math.abs(y) + 20
end

local function SavePanelLayout()
    if not panel or not NS.db then
        return
    end
    local point, _, relativePoint, x, y = panel:GetPoint(1)
    if IsSecret(point) or IsSecret(relativePoint) or IsSecret(x) or IsSecret(y) then
        return
    end
    NS.db.panelPoint = { point or "CENTER", relativePoint or "CENTER", x or 0, y or 40 }
    local w, h = panel:GetWidth(), panel:GetHeight()
    if not IsSecret(w) and type(w) == "number" then
        NS.db.panelWidth = Clamp( math.floor(w + 0.5), PANEL_MIN_W, PANEL_MAX_W )
    end
    if not IsSecret(h) and type(h) == "number" then
        NS.db.panelHeight = Clamp( math.floor(h + 0.5), PANEL_MIN_H, PANEL_MAX_H )
    end
end

local function BuildPanel()
    panel = CreateFrame("Frame", "XiusMaxGraphicsOptions", UIParent, TEMPLATE)
    panel:SetFrameStrata("DIALOG")
    local width = Clamp(tonumber(NS.db.panelWidth) or 440, PANEL_MIN_W, PANEL_MAX_W)
    local height = Clamp(tonumber(NS.db.panelHeight) or 560, PANEL_MIN_H, PANEL_MAX_H)
    panel:SetSize(width, height)
    local pp = NS.db.panelPoint
    if type(pp) ~= "table" or type(pp[1]) ~= "string" or type(pp[2]) ~= "string" then
        pp = { "CENTER", "CENTER", 0, 40 }
    end
    panel:SetPoint(pp[1], UIParent, pp[2], tonumber(pp[3]) or 0, tonumber(pp[4]) or 40)
    panel:SetMovable(true)
    panel:SetResizable(true)
    if panel.SetResizeBounds then
        panel:SetResizeBounds(PANEL_MIN_W, PANEL_MIN_H, PANEL_MAX_W, PANEL_MAX_H)
    elseif panel.SetMinResize then
        panel:SetMinResize(PANEL_MIN_W, PANEL_MIN_H)
        panel:SetMaxResize(PANEL_MAX_W, PANEL_MAX_H)
    end
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePanelLayout()
    end)
    NS.CreateWindowBackground(panel)
    panel:Hide()
    panel:SetScript("OnHide", function()
        NS.PromptReload()
    end)
    tinsert(UISpecialFrames, "XiusMaxGraphicsOptions")

    local titleBar = NS.CreateTitleBar(panel, 26)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        panel:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
        panel:StopMovingOrSizing()
        SavePanelLayout()
    end)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    NS.SetFont(title, 13)
    title:SetTextColor(COLOR.gold[1], COLOR.gold[2], COLOR.gold[3])
    title:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    title:SetText("Xius Max Graphics")

    local ver = titleBar:CreateFontString(nil, "OVERLAY")
    NS.SetFont(ver, 10)
    ver:SetTextColor(COLOR.muted[1], COLOR.muted[2], COLOR.muted[3])
    ver:SetPoint("LEFT", title, "RIGHT", 8, 0)
    ver:SetText("v" .. NS.VERSION)

    local close = CreateFrame("Button", nil, titleBar)
    close:SetSize(18, 18)
    close:SetPoint("RIGHT", titleBar, "RIGHT", -5, 0)
    local x = close:CreateFontString(nil, "OVERLAY")
    NS.SetFont(x, 12)
    x:SetTextColor(COLOR.dash[1], COLOR.dash[2], COLOR.dash[3])
    x:SetPoint("CENTER", 0, 0)
    x:SetText("X")
    close:SetScript("OnEnter", function()
        x:SetTextColor(1, 0.92, 0.5)
    end)
    close:SetScript("OnLeave", function()
        x:SetTextColor(COLOR.dash[1], COLOR.dash[2], COLOR.dash[3])
    end)
    close:SetScript("OnClick", function()
        panel:Hide()
    end)

    local scroll = CreateFrame("ScrollFrame", "XiusMaxGraphicsScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -32)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 12)

    scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(width - 40, 800)
    scroll:SetScrollChild(scrollChild)

    panel:SetScript("OnSizeChanged", function(self, w)
        if not IsSecret(w) and type(w) == "number" and w > 80 then
            scrollChild:SetWidth(w - 40)
            for i = 1, #layoutHooks do
                layoutHooks[i]()
            end
        end
    end)

    local grip = CreateFrame("Button", nil, panel)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
    local gripTex = grip:CreateTexture(nil, "OVERLAY")
    gripTex:SetAllPoints()
    gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetScript("OnMouseDown", function()
        gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        panel:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function()
        gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        panel:StopMovingOrSizing()
        SavePanelLayout()
        local w = panel:GetWidth()
        if not IsSecret(w) and type(w) == "number" then
            scrollChild:SetWidth(w - 40)
        end
        NS.Options.Refresh()
    end)
    grip:SetScript("OnEnter", function()
        gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    end)
    grip:SetScript("OnLeave", function()
        gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)

    BuildSettingsContent(scrollChild)
end

function NS.Options.Refresh()
    if not NS.db or #refreshers == 0 then
        return
    end
    for i = 1, #refreshers do
        refreshers[i]()
    end
    for i = 1, #layoutHooks do
        layoutHooks[i]()
    end
end

function NS.Options.Toggle()
    if not NS.db then
        NS.InitDB()
    end
    if not NS.db then
        return
    end
    if not panel then
        BuildPanel()
    end
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
        NS.Options.Refresh()
    end
end

function NS.Options.Show()
    if not NS.db then
        NS.InitDB()
    end
    if not NS.db then
        return
    end
    if not panel then
        BuildPanel()
    end
    panel:Show()
    NS.Options.Refresh()
end

function NS.Options.RegisterSettings()
    if NS.settingsRegistered then
        return
    end
    local settingsPanel = CreateFrame("Frame", "XiusMaxGraphicsSettingsPanel")
    settingsPanel.name = "Xius Max Graphics"
    settingsPanel:Hide()

    local function EnsureBlizzardContent()
        if blizzardBuilt then
            return
        end
        blizzardBuilt = true

        local title = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -8)
        title:SetText("Xius Max Graphics")

        local ver = settingsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        ver:SetPoint("LEFT", title, "RIGHT", 8, 0)
        ver:SetTextColor(COLOR.muted[1], COLOR.muted[2], COLOR.muted[3])
        ver:SetText("v" .. NS.VERSION)

        local scroll = CreateFrame("ScrollFrame", "XiusMaxGraphicsSettingsScroll", settingsPanel, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 4, -32)
        scroll:SetPoint("BOTTOMRIGHT", settingsPanel, "BOTTOMRIGHT", -26, 4)

        blizzardChild = CreateFrame("Frame", nil, scroll)
        blizzardChild:SetSize(580, 900)
        scroll:SetScrollChild(blizzardChild)
        BuildSettingsContent(blizzardChild)
    end

    local function FitChild()
        EnsureBlizzardContent()
        if blizzardChild then
            local width = settingsPanel:GetWidth()
            if not IsSecret(width) and type(width) == "number" and width > 80 then
                blizzardChild:SetWidth(math.max(360, width - 36))
            end
        end
        NS.Options.Refresh()
    end
    settingsPanel:SetScript("OnShow", FitChild)
    settingsPanel:SetScript("OnSizeChanged", function()
        if not blizzardBuilt then
            return
        end
        FitChild()
    end)
    settingsPanel:SetScript("OnHide", function()
        NS.PromptReload()
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, settingsPanel, "Xius Max Graphics")
        if ok and category then
            if category.SetID then
                pcall(category.SetID, category, "XiusMaxGraphics")
            end
            local listed = pcall(Settings.RegisterAddOnCategory, category)
            if listed then
                NS.settingsRegistered = true
                return
            end
        end
    end
    if InterfaceOptions_AddCategory then
        local listed = pcall(InterfaceOptions_AddCategory, settingsPanel)
        if listed then
            NS.settingsRegistered = true
        end
    end
end
