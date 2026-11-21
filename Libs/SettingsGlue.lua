local addonName, ns = ...
local NS = ns

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

local function SettingsLib()
    return _G.XiusCoreSettingsLib
end

NS.Options = NS.Options or {}

function NS.OpenGraphicsOptions(subTab)
    local Lib = SettingsLib()
    if not Lib then
        return
    end
    if not NS.db and NS.InitDB then
        NS.InitDB()
    end
    if type(Lib.OpenModule) == "function" then
        Lib:OpenModule("Graphics", subTab)
        return
    end
    if type(Lib.Open) == "function" then
        Lib:Open("Graphics", subTab)
    end
end

function NS.ToggleGraphicsOptions(subTab)
    local Lib = SettingsLib()
    if not Lib then
        return
    end
    if not NS.db and NS.InitDB then
        NS.InitDB()
    end
    if type(Lib.Toggle) == "function" then
        Lib:Toggle("Graphics", subTab)
        return
    end
    NS.OpenGraphicsOptions(subTab)
end

function NS.Options.Show(subTab)
    NS.OpenGraphicsOptions(subTab)
end

function NS.Options.Toggle(subTab)
    NS.ToggleGraphicsOptions(subTab)
end

function NS.ToggleOptions(subTab)
    NS.ToggleGraphicsOptions(subTab)
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

do
    local core = _G.XiusCore
    if core and core.RegisterModule then
        if NS.InitDB and not NS.db then
            NS.InitDB()
        end
        core:RegisterModule("Graphics", NS)
    end
end

local INTENSITY = {
    { value = "off", text = "OFF" },
    { value = "low", text = "LOW" },
    { value = "balance", text = "BAL" },
    { value = "ultimate", text = "MAX" },
}

local AA_MODES = {
    { value = 0, text = "Off" },
    { value = 1, text = "Low (FXAA)" },
    { value = 2, text = "Medium (CMAA)" },
    { value = 4, text = "Max (CMAA 2 / Advanced)" },
}

local TINT_PREVIEW_TEX = "Interface\\AddOns\\XiusMaxGraphics\\Media\\tint-preview"

local TINT_NAMES = {
    [0] = "None",
    [1] = "Sepia",
    [2] = "Warm",
    [3] = "Cold",
    [4] = "Night",
    [5] = "Emerald",
    [6] = "Dusk",
}

local SUB_TABS = {
    { id = "general", text = "General", width = 96 },
    { id = "world", text = "World & Terrain", width = 132 },
    { id = "lighting", text = "Lighting & Effects", width = 142 },
    { id = "camera", text = "Camera & Sparkles", width = 142 },
}

local function CreateBorder(frame, thickness, outset, r, g, b, a)
    local edges = {}
    local function Edge(point1, x1, y1, point2, x2, y2, horizontal)
        local edge = frame:CreateTexture(nil, "OVERLAY")
        if edge.SetColorTexture then
            edge:SetColorTexture(r, g, b, a)
        else
            edge:SetTexture("Interface\\Buttons\\WHITE8X8")
            edge:SetVertexColor(r, g, b, a)
        end
        edge:SetPoint(point1, x1, y1)
        edge:SetPoint(point2, x2, y2)
        if horizontal then
            edge:SetHeight(thickness)
        else
            edge:SetWidth(thickness)
        end
        edge:Hide()
        edges[#edges + 1] = edge
    end
    Edge("TOPLEFT", -outset, outset, "TOPRIGHT", outset, outset, true)
    Edge("BOTTOMLEFT", -outset, -outset, "BOTTOMRIGHT", outset, -outset, true)
    Edge("TOPLEFT", -outset, outset, "BOTTOMLEFT", -outset, -outset, false)
    Edge("TOPRIGHT", outset, outset, "BOTTOMRIGHT", outset, -outset, false)
    return function(shown)
        for i = 1, #edges do
            edges[i]:SetShown(shown)
        end
    end
end

local function AddTintThumbnailRow(api)
    if not api or not api.parent or not api.rows then
        return
    end
    local rowHeight = 112
    local row = CreateFrame("Frame", nil, api.parent)
    row.rowHeight = rowHeight
    row.searchText = "color tint filter sepia warm cold night emerald dusk none"
    row:SetHeight(rowHeight)

    local divider = row:CreateTexture(nil, "BORDER")
    divider:SetHeight(1)
    divider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 16, 0)
    divider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -16, 0)
    if divider.SetColorTexture then
        divider:SetColorTexture(0.28, 0.24, 0.16, 0.4)
    else
        divider:SetTexture("Interface\\Buttons\\WHITE8X8")
        divider:SetVertexColor(0.28, 0.24, 0.16, 0.4)
    end

    local marker = row:CreateTexture(nil, "ARTWORK")
    if marker.SetColorTexture then
        marker:SetColorTexture(1, 0.82, 0, 1)
    else
        marker:SetTexture("Interface\\Buttons\\WHITE8X8")
        marker:SetVertexColor(1, 0.82, 0, 1)
    end
    marker:SetWidth(2)
    marker:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -6)
    marker:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 8, 6)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    local font, _, flags = label:GetFont()
    if font then
        label:SetFont(font, 12, flags or "")
    end
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 16, -8)
    label:SetJustifyH("LEFT")
    label:SetText("Color tint")

    local tip = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    local subFont, _, subFlags = tip:GetFont()
    if subFont then
        tip:SetFont(subFont, 10, subFlags or "")
    end
    tip:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
    tip:SetJustifyH("LEFT")
    tip:SetTextColor(0.72, 0.72, 0.72)
    tip:SetText("Color laid over the world: sepia, warm, cold, night, emerald or dusk.")

    local reset = CreateFrame("Button", nil, row)
    reset:SetSize(22, 22)
    reset:SetPoint("TOPRIGHT", row, "TOPRIGHT", -24, -10)
    reset:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
    reset:SetDisabledTexture("Interface\\Buttons\\UI-RefreshButton")
    if reset:GetDisabledTexture() then
        reset:GetDisabledTexture():SetDesaturated(true)
        reset:GetDisabledTexture():SetAlpha(0.5)
    end
    reset:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    if reset.SetMotionScriptsWhileDisabled then
        reset:SetMotionScriptsWhileDisabled(true)
    end
    reset:SetScript("OnClick", function()
        if NS.SetTint then
            NS.SetTint(0, true)
        elseif NS.ResetTint then
            NS.ResetTint(true)
        end
        if row.Refresh then
            row:Refresh()
        end
    end)
    reset:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Default: None", 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    reset:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    local thumbnails = {}
    local tints = NS.TINTS or {}
    local maxIndex = #tints
    for value = 0, maxIndex do
        local thumbnail = CreateFrame("Button", nil, row)
        thumbnail:SetSize(72, 40)
        if value == 0 then
            thumbnail:SetPoint("TOPLEFT", tip, "BOTTOMLEFT", 0, -8)
        else
            thumbnail:SetPoint("LEFT", thumbnails[value - 1], "RIGHT", 6, 0)
        end
        local image = thumbnail:CreateTexture(nil, "ARTWORK")
        image:SetAllPoints()
        image:SetTexture(TINT_PREVIEW_TEX)
        image:SetTexCoord(0.05, 0.95, 0, 1)
        local entry = tints[value]
        local color = entry and entry.color
        if color then
            image:SetVertexColor(color[1], color[2], color[3])
        end
        local caption = thumbnail:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        caption:SetPoint("TOP", thumbnail, "BOTTOM", 0, -3)
        caption:SetWidth(72)
        caption:SetWordWrap(false)
        local name = (entry and entry.name) or TINT_NAMES[value] or tostring(value)
        caption:SetText(name)
        thumbnail.caption = caption
        thumbnail.ShowSelected = CreateBorder(thumbnail, 2, 2, 1, 0.82, 0, 1)
        local showHover = CreateBorder(thumbnail, 1, 0, 1, 1, 1, 0.6)
        thumbnail:SetScript("OnEnter", function(self)
            showHover(true)
            if GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(name, 1, 1, 1)
                GameTooltip:Show()
            end
        end)
        thumbnail:SetScript("OnLeave", function()
            showHover(false)
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)
        local pickValue = value
        thumbnail:SetScript("OnClick", function()
            if NS.SetTint then
                NS.SetTint(pickValue, true)
            elseif NS.db then
                NS.db.tint = pickValue
                if pickValue > 0 and (tonumber(NS.db.tintStrength) or 0) <= 0 then
                    NS.db.tintStrength = 50
                end
                if NS.ApplyTint then
                    NS.ApplyTint()
                end
            end
            if row.Refresh then
                row:Refresh()
            end
        end)
        thumbnails[value] = thumbnail
    end

    function row:Refresh()
        local current = (NS.db and tonumber(NS.db.tint)) or 0
        local modified = current ~= 0
        marker:SetShown(modified)
        reset:SetEnabled(modified)
        for value, thumbnail in pairs(thumbnails) do
            local chosen = value == current
            thumbnail.ShowSelected(chosen)
            if thumbnail.caption then
                thumbnail.caption:SetFontObject(chosen and GameFontNormalSmall or GameFontHighlightSmall)
            end
        end
    end

    row:Refresh()
    api.rows[#api.rows + 1] = row
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", api.parent, "TOPLEFT", 0, api.y or 0)
    row:SetPoint("RIGHT", api.parent, "RIGHT", 0, 0)
    api.y = (api.y or 0) - rowHeight
    return row
end

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
    if value ~= "ultimate" and value ~= "balance" and value ~= "low" then
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

local function AddFeatureRow(api, key)
    local feature = NS.FEATURE_BY_KEY and NS.FEATURE_BY_KEY[key]
    if not feature then
        return
    end
    api:AddDropdown(feature.label, INTENSITY, function()
        if NS.GetFeatureIntensity then
            return NS.GetFeatureIntensity(key)
        end
        return "off"
    end, function(value)
        SetIntensity(key, value)
    end, feature.tip)
end

local function ReadCVar(name, fallback)
    if NS.GetCVarNumber then
        return NS.GetCVarNumber(name, fallback)
    end
    return fallback
end

local function WriteCVar(name, value, raidName)
    if NS.SetCustomCVar then
        NS.SetCustomCVar(name, value, raidName)
    end
end

local function BuildGeneralTab(api)
    api:AddSection("Presets")
    api:AddNote(ProfileText)
    api:AddButtonGroup({
        align = "CENTER",
        spacing = 8,
        width = 92,
        height = 24,
        buttons = {
            { text = "Ultimate", width = 92, height = 24, onClick = function()
                if NS.SetProfile then
                    NS.SetProfile("ultimate")
                end
            end },
            { text = "Balance", width = 92, height = 24, onClick = function()
                if NS.SetProfile then
                    NS.SetProfile("balance")
                end
            end },
            { text = "Defaults", width = 92, height = 24, onClick = function()
                if NS.SetProfile then
                    NS.SetProfile("defaults")
                end
            end },
            { text = "Low", width = 92, height = 24, onClick = function()
                if NS.SetProfile then
                    NS.SetProfile("low")
                end
            end },
            { text = "Potato", width = 92, height = 24, onClick = function()
                if NS.SetProfile then
                    NS.SetProfile("potato")
                end
            end },
        },
    })

    api:AddSection("General & Behavior")
    api:AddCheckbox("Enable graphics upgrades (auto-apply on login)", function()
        return Checked("enabled")
    end, function(value)
        SetChecked("enabled", value)
    end, "Master switch. Applies your graphics preset automatically on login and world enter. When off, the addon stops applying CVars.")
    api:AddCheckbox("Keep loot / soft-target icons sticky", function()
        return Checked("protect")
    end, function(value)
        SetChecked("protect", value)
    end, "Only re-locks loot sparkles and soft-target icons if another setting resets them. Does not fight your Graphics menu.")
    api:AddCheckbox("Chat messages", function()
        return Checked("chatMessages")
    end, function(value)
        SetChecked("chatMessages", value)
    end, "Show status messages in chat when presets are applied.")

    api:AddSection("Actions")
    api:AddButtonGroup({
        align = "CENTER",
        spacing = 10,
        width = 180,
        height = 24,
        buttons = {
            { text = "Reapply Current Settings", width = 180, height = 24, onClick = function()
                if NS.ApplySettings then
                    NS.ApplySettings(false)
                end
            end },
            { text = "Restart Graphics Engine", width = 180, height = 24, onClick = function()
                if NS.RestartGraphics then
                    NS.RestartGraphics()
                end
            end },
        },
    })

    api:AddNote("Tip: Ultimate (10) = max graphics. Balance (7) = high quality with less cost. Defaults (5) = baseline. Low (3) = light FPS. Potato (1) = minimum everything with safe lighting. Use the tabs above to customize World & Terrain, Lighting & Effects, or Camera & Sparkles.")
end

local function BuildWorldTab(api)
    api:AddSection("World & Terrain Feature Tiers")
    AddFeatureRow(api, "maxViewDistance")
    AddFeatureRow(api, "maxObjectDetail")
    AddFeatureRow(api, "maxGrass")
    AddFeatureRow(api, "maxWater")

    api:AddSection("Fine-Tuning Sliders")
    api:AddSlider("View distance (farclip)", 185, 10000, 50, function()
        return ReadCVar("farclip", 7000)
    end, function(value)
        WriteCVar("farclip", value, "RAIDfarclip")
    end, "Maximum draw distance for scenery and terrain. Forever supports up to 7000 (10000 on modern).")
    api:AddSlider("Terrain detail (terrainLodDist)", 50, 1000, 10, function()
        return ReadCVar("terrainLodDist", 650)
    end, function(value)
        WriteCVar("terrainLodDist", value, "RAIDterrainLodDist")
    end, "Distance up to which terrain keeps its full geometric detail.")
    api:AddSlider("Horizon start (horizonStart)", 185, 4000, 50, function()
        return ReadCVar("horizonStart", 3000)
    end, function(value)
        WriteCVar("horizonStart", value, "RAIDhorizonStart")
    end, "Distance where distant horizon blending begins.")
    api:AddSlider("Ground clutter distance (groundEffectDist)", 0, 500, 10, function()
        return ReadCVar("groundEffectDist", 300)
    end, function(value)
        WriteCVar("groundEffectDist", value, "RAIDgroundEffectDist")
    end, "Visibility distance of grass and ground clutter (up to 300 on Forever, 500 on modern).")
    api:AddSlider("Water reflections (reflectionMode)", 0, 3, 1, function()
        return ReadCVar("reflectionMode", 3)
    end, function(value)
        WriteCVar("reflectionMode", value)
    end, "What the water reflects on Forever (0 = off, 1 = sky, 2 = terrain, 3 = full scenery).")
end

local function BuildLightingTab(api)
    api:AddSection("Lighting & Shadows")
    AddFeatureRow(api, "maxShadows")
    AddFeatureRow(api, "maxSSAO")
    AddFeatureRow(api, "volumeFog")
    AddFeatureRow(api, "sunShafts")

    api:AddSection("Effects, Weather & Anti-Aliasing")
    AddFeatureRow(api, "maxParticles")
    AddFeatureRow(api, "projectedTextures")
    AddFeatureRow(api, "crispImage")
    AddFeatureRow(api, "colorfulDeath")
    api:AddDropdown("Anti-aliasing mode", AA_MODES, function()
        local val = math.floor(ReadCVar("ffxAntiAliasingMode", 4) + 0.5)
        if val == 0 or val == 1 or val == 2 or val == 4 then
            return val
        end
        return 2
    end, function(value)
        WriteCVar("ffxAntiAliasingMode", value)
    end, "Post-process anti-aliasing mode (ffxAntiAliasingMode).")

    api:AddSection("Screen Tint / Color Filter")
    AddTintThumbnailRow(api)
    api:AddSlider("Tint strength (%)", 0, 100, 5, function()
        return (NS.db and tonumber(NS.db.tintStrength)) or 50
    end, function(value)
        if NS.SetTintStrength then
            NS.SetTintStrength(value)
        elseif NS.db then
            NS.db.tintStrength = tonumber(value) or 50
            if NS.ApplyTint then
                NS.ApplyTint()
            end
        end
    end, "Strength of the active color tint, in %.")
end

local function BuildCameraTab(api)
    api:AddSection("Camera")
    AddFeatureRow(api, "extendedCamera")
    api:AddSlider("Max camera zoom factor", 1.0, 4.0, 0.1, function()
        return ReadCVar("cameraDistanceMaxZoomFactor", 4.0)
    end, function(value)
        WriteCVar("cameraDistanceMaxZoomFactor", value)
    end, "Maximum camera zoom-out multiplier (up to 4.0 on Forever, 2.6 on modern).")

    api:AddSection("Loot & Gathering Sparkles")
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
    end, "Overhead icons on NPCs and quest givers. Presets turn this off. You will be asked to reload as soon as you change this.")
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
        noCache = true,
        hidePageTitle = true,
        activeSubTab = "general",
        subTabs = SUB_TABS,
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
        buildContent = function(_, api, spec)
            if NS.InitDB and not NS.db then
                NS.InitDB()
            end
            if not NS.db then
                api:AddNote("Max Graphics is still loading. Close this window and open it again.")
                return
            end

            local subTab = (spec and spec.activeSubTab) or "general"
            if subTab == "world" then
                BuildWorldTab(api)
            elseif subTab == "lighting" then
                BuildLightingTab(api)
            elseif subTab == "camera" then
                BuildCameraTab(api)
            else
                BuildGeneralTab(api)
            end
        end,
    })

    NS._graphicsModuleRegistered = true
end

NS.RegisterSettingsModule()
