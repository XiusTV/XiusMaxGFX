--[[
    Xius Max Graphics - Config.lua
    Presets and pick-and-choose graphics features for modern and Forever.
]]

local ADDON, NS = ...

NS.VERSION = "1.6.7"

-- graphicsQuality CVar is 0-9; Options slider shows CVar+1 (1-10).
NS.PROFILE_QUALITY_UI = {
    defaults = 5,
    balance = 7,
    ultimate = 10,
}
NS.PROFILE_QUALITY = {
    defaults = 4,
    balance = 6,
    ultimate = 9,
}

-- Menu rows shared by modern and Forever.
-- Particle Density Ultra=5, Spell Density Everything=2, Secondary Lighting Ultra=graphicsLightMode 3.
NS.MENU_GRAPHICS = {
    defaults = {
        graphicsShadowQuality = 2,
        graphicsLiquidDetail = 1,
        graphicsPBRLiquidDetail = 1,
        graphicsParticleDensity = 2,
        graphicsSSAO = 1,
        graphicsDepthEffects = 1,
        graphicsComputeEffects = 1,
        graphicsTextureResolution = 1,
        graphicsProjectedTextures = 1,
        graphicsSpellDensity = 1,
        graphicsLightMode = 1,
        graphicsViewDistance = 4,
        graphicsEnvironmentDetail = 4,
        graphicsGroundClutter = 4,
        raidGraphicsShadowQuality = 2,
        raidGraphicsParticleDensity = 2,
        raidGraphicsSSAO = 1,
        raidGraphicsDepthEffects = 1,
        raidGraphicsComputeEffects = 1,
        raidGraphicsViewDistance = 4,
        raidGraphicsEnvironmentDetail = 4,
        raidGraphicsGroundClutter = 4,
        raidGraphicsProjectedTextures = 1,
        raidGraphicsSpellDensity = 1,
        raidGraphicsLightMode = 1,
        spellClutter = 60,
        spellVisualDensityFilterSetting = 2,
        giQuality = 1,
        RAIDgiQuality = 1,
        projectedTextures = 1,
        RAIDprojectedTextures = 1,
        shadowMode = 1,
        shadowTextureSize = 1024,
        RAIDshadowMode = 1,
        RAIDshadowTextureSize = 1024,
        SSAO = 1,
        RAIDSSAO = 1,
        waterDetail = 1,
        RAIDWaterDetail = 1,
        refraction = 1,
        RAIDrefraction = 1,
        rippleDetail = 0,
        particleDensity = 50,
        particleMTDensity = 50,
        RAIDparticleDensity = 50,
        RAIDparticleMTDensity = 50,
        weatherDensity = 1,
        RAIDweatherDensity = 1,
        volumeFog = 1,
        volumeFogLevel = 1,
        RAIDVolumeFogLevel = 1,
        sunShafts = 1,
        RAIDsunShafts = 1,
        farclip = 4000,
        horizonClip = 4000,
        horizonStart = 1200,
        RAIDfarclip = 4000,
        RAIDhorizonStart = 1200,
        terrainLodDist = 400,
        lodObjectCullDist = 30,
        RAIDterrainLodDist = 400,
        RAIDlodObjectCullDist = 30,
        groundEffectDensity = 64,
        groundEffectDist = 140,
        groundEffectFade = 70,
        RAIDgroundEffectDensity = 64,
        RAIDgroundEffectDist = 140,
        physicsLevel = 1,
        ffxGlow = 1,
        ResampleAlwaysSharpen = 0,
        ResampleQuality = 1,
        ResampleSharpness = 0,
        textureFilteringMode = 2,
        ffxAntiAliasingMode = 2,
        MSAAQuality = 0,
        specular = 1,
        componentSpecular = 1,
        cameraDistanceMaxZoomFactor = 1.9,
        clusteredShading = 0,
        RAIDclusteredShading = 0,
        maxLightCount = 8,
        entityLodDist = 5,
        RAIDentityLodDist = 5,
        entityShadowFadeScale = 20,
        wmoLodDist = 300,
        lodObjectFadeScale = 100,
        lodObjectCullSize = 15,
        doodadLodScale = 100,
        componentTextureLevel = 1,
        worldBaseMip = 1,
        ffxDeath = 1,
    },
    balance = {
        graphicsShadowQuality = 3,
        graphicsLiquidDetail = 2,
        graphicsPBRLiquidDetail = 2,
        graphicsParticleDensity = 3,
        graphicsSSAO = 2,
        graphicsDepthEffects = 2,
        graphicsComputeEffects = 2,
        graphicsTextureResolution = 2,
        graphicsProjectedTextures = 1,
        graphicsSpellDensity = 1,
        graphicsLightMode = 2,
        graphicsViewDistance = 6,
        graphicsEnvironmentDetail = 6,
        graphicsGroundClutter = 6,
        raidGraphicsShadowQuality = 3,
        raidGraphicsParticleDensity = 3,
        raidGraphicsSSAO = 1,
        raidGraphicsDepthEffects = 2,
        raidGraphicsComputeEffects = 2,
        raidGraphicsViewDistance = 6,
        raidGraphicsEnvironmentDetail = 6,
        raidGraphicsGroundClutter = 6,
        raidGraphicsProjectedTextures = 1,
        raidGraphicsSpellDensity = 1,
        raidGraphicsLightMode = 2,
        spellClutter = 40,
        spellVisualDensityFilterSetting = 3,
        giQuality = 2,
        RAIDgiQuality = 2,
        projectedTextures = 1,
        RAIDprojectedTextures = 1,
        shadowMode = 2,
        shadowTextureSize = 1024,
        RAIDshadowMode = 1,
        RAIDshadowTextureSize = 1024,
        SSAO = 2,
        RAIDSSAO = 1,
        waterDetail = 2,
        RAIDWaterDetail = 2,
        refraction = 1,
        RAIDrefraction = 1,
        rippleDetail = 1,
        particleDensity = 80,
        particleMTDensity = 80,
        RAIDparticleDensity = 60,
        RAIDparticleMTDensity = 60,
        weatherDensity = 2,
        RAIDweatherDensity = 2,
        volumeFog = 1,
        volumeFogLevel = 1,
        RAIDVolumeFogLevel = 1,
        sunShafts = 1,
        RAIDsunShafts = 1,
        farclip = 7000,
        horizonClip = 7000,
        horizonStart = 1800,
        RAIDfarclip = 6000,
        RAIDhorizonStart = 1600,
        terrainLodDist = 500,
        lodObjectCullDist = 50,
        RAIDterrainLodDist = 500,
        RAIDlodObjectCullDist = 50,
        groundEffectDensity = 128,
        groundEffectDist = 260,
        groundEffectFade = 180,
        RAIDgroundEffectDensity = 96,
        RAIDgroundEffectDist = 220,
        physicsLevel = 1,
        ffxGlow = 0,
        ResampleAlwaysSharpen = 1,
        ResampleQuality = 2,
        ResampleSharpness = 0.55,
        textureFilteringMode = 4,
        ffxAntiAliasingMode = 2,
        MSAAQuality = 0,
        specular = 1,
        componentSpecular = 1,
        cameraDistanceMaxZoomFactor = 2.2,
        clusteredShading = 1,
        RAIDclusteredShading = 1,
        maxLightCount = 16,
        entityLodDist = 8,
        RAIDentityLodDist = 8,
        entityShadowFadeScale = 30,
        wmoLodDist = 400,
        lodObjectFadeScale = 120,
        lodObjectCullSize = 12,
        doodadLodScale = 120,
        componentTextureLevel = 0,
        worldBaseMip = 0,
        ffxDeath = 0,
    },
    ultimate = {
        graphicsShadowQuality = 5,
        graphicsLiquidDetail = 3,
        graphicsPBRLiquidDetail = 3,
        graphicsParticleDensity = 5,
        graphicsSSAO = 4,
        graphicsDepthEffects = 3,
        graphicsComputeEffects = 4,
        graphicsTextureResolution = 2,
        graphicsProjectedTextures = 1,
        graphicsSpellDensity = 2,
        graphicsLightMode = 3,
        graphicsViewDistance = 9,
        graphicsEnvironmentDetail = 9,
        graphicsGroundClutter = 9,
        raidGraphicsShadowQuality = 5,
        raidGraphicsParticleDensity = 5,
        raidGraphicsSSAO = 4,
        raidGraphicsDepthEffects = 3,
        raidGraphicsComputeEffects = 4,
        raidGraphicsViewDistance = 9,
        raidGraphicsEnvironmentDetail = 9,
        raidGraphicsGroundClutter = 9,
        raidGraphicsProjectedTextures = 1,
        raidGraphicsSpellDensity = 2,
        raidGraphicsLightMode = 3,
        spellClutter = 0,
        spellVisualDensityFilterSetting = 4,
        giQuality = 4,
        RAIDgiQuality = 4,
        projectedTextures = 1,
        RAIDprojectedTextures = 1,
        shadowMode = 4,
        shadowTextureSize = 2048,
        RAIDshadowMode = 4,
        RAIDshadowTextureSize = 2048,
        SSAO = 4,
        RAIDSSAO = 4,
        waterDetail = 3,
        RAIDWaterDetail = 3,
        refraction = 2,
        RAIDrefraction = 2,
        rippleDetail = 2,
        particleDensity = 100,
        particleMTDensity = 100,
        RAIDparticleDensity = 100,
        RAIDparticleMTDensity = 100,
        weatherDensity = 3,
        RAIDweatherDensity = 3,
        volumeFog = 1,
        volumeFogLevel = 2,
        RAIDVolumeFogLevel = 2,
        sunShafts = 2,
        RAIDsunShafts = 2,
        farclip = 10000,
        horizonClip = 10000,
        horizonStart = 3000,
        RAIDfarclip = 10000,
        RAIDhorizonStart = 3000,
        terrainLodDist = 650,
        lodObjectCullDist = 100,
        RAIDterrainLodDist = 650,
        RAIDlodObjectCullDist = 100,
        groundEffectDensity = 256,
        groundEffectDist = 500,
        groundEffectFade = 370,
        RAIDgroundEffectDensity = 256,
        RAIDgroundEffectDist = 500,
        physicsLevel = 2,
        ffxGlow = 0,
        ResampleAlwaysSharpen = 1,
        ResampleQuality = 3,
        ResampleSharpness = 0.7,
        textureFilteringMode = 5,
        ffxAntiAliasingMode = 4,
        MSAAQuality = 0,
        specular = 1,
        componentSpecular = 1,
        cameraDistanceMaxZoomFactor = 2.6,
        clusteredShading = 1,
        RAIDclusteredShading = 1,
        maxLightCount = 32,
        entityLodDist = 10,
        RAIDentityLodDist = 10,
        entityShadowFadeScale = 50,
        wmoLodDist = 450,
        lodObjectFadeScale = 160,
        lodObjectCullSize = 8,
        doodadLodScale = 160,
        componentTextureLevel = 0,
        worldBaseMip = 0,
        ffxDeath = 0,
    },
}

NS.FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
NS.WHITE = "Interface\\Buttons\\WHITE8X8"
NS.COLOR = {
    gold = { 1, 0.847, 0, 1 },
    goldLine = { 0.72, 0.57, 0, 1 },
    goldLineDim = { 0.34, 0.27, 0.01, 1 },
    buttonEdge = { 0.56, 0.42, 0.24, 1 },
    dash = { 0.88, 0.66, 0, 1 },
    muted = { 0.62, 0.60, 0.56, 1 },
    good = { 0.45, 0.85, 0.50, 1 },
    warn = { 1, 0.55, 0.20, 1 },
    sparkle = { 1.0, 0.88, 0.35, 1 },
}
NS.BACKDROP_MENU = {
    bgFile = NS.WHITE,
    edgeFile = NS.WHITE,
    tile = false,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}
NS.BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

NS.FEATURES = {
    {
        key = "maxGrass",
        label = "Maximum grass & clutter",
        tip = "Ground clutter density and distance beyond the slider.",
        category = "world",
        ultimate = {
            graphicsGroundClutter = 9,
            raidGraphicsGroundClutter = 9,
            groundEffectDensity = 256,
            groundEffectDist = 500,
            groundEffectFade = 370,
            RAIDgroundEffectDensity = 256,
            RAIDgroundEffectDist = 500,
        },
        balance = {
            graphicsGroundClutter = 6,
            raidGraphicsGroundClutter = 6,
            groundEffectDensity = 128,
            groundEffectDist = 260,
            groundEffectFade = 180,
            RAIDgroundEffectDensity = 96,
            RAIDgroundEffectDist = 220,
        },
    },
    {
        key = "maxViewDistance",
        label = "Maximum view distance",
        tip = "How far terrain and objects draw.",
        category = "world",
        ultimate = {
            graphicsViewDistance = 9,
            raidGraphicsViewDistance = 9,
            farclip = 10000,
            horizonClip = 10000,
            horizonStart = 3000,
            RAIDfarclip = 10000,
            RAIDhorizonStart = 3000,
        },
        balance = {
            graphicsViewDistance = 6,
            raidGraphicsViewDistance = 6,
            farclip = 7000,
            horizonClip = 7000,
            horizonStart = 1800,
            RAIDfarclip = 6000,
            RAIDhorizonStart = 1600,
        },
    },
    {
        key = "maxObjectDetail",
        label = "Maximum object & terrain detail",
        tip = "Terrain and object LOD distances.",
        category = "world",
        ultimate = {
            graphicsEnvironmentDetail = 9,
            raidGraphicsEnvironmentDetail = 9,
            terrainLodDist = 650,
            lodObjectCullDist = 100,
            entityLodDist = 10,
            wmoLodDist = 450,
            lodObjectFadeScale = 160,
            lodObjectCullSize = 8,
            doodadLodScale = 160,
            RAIDterrainLodDist = 650,
            RAIDlodObjectCullDist = 100,
            RAIDentityLodDist = 10,
        },
        balance = {
            graphicsEnvironmentDetail = 6,
            raidGraphicsEnvironmentDetail = 6,
            terrainLodDist = 500,
            lodObjectCullDist = 50,
            entityLodDist = 8,
            wmoLodDist = 400,
            lodObjectFadeScale = 120,
            lodObjectCullSize = 12,
            doodadLodScale = 120,
            RAIDterrainLodDist = 500,
            RAIDlodObjectCullDist = 50,
            RAIDentityLodDist = 8,
        },
    },
    {
        key = "maxShadows",
        label = "Maximum shadows",
        tip = "Shadow mode and texture quality. Heavy on FPS.",
        category = "lighting",
        ultimate = {
            shadowMode = 4,
            shadowTextureSize = 2048,
            graphicsShadowQuality = 5,
            raidGraphicsShadowQuality = 5,
            RAIDshadowMode = 4,
            RAIDshadowTextureSize = 2048,
        },
        balance = {
            shadowMode = 2,
            shadowTextureSize = 1024,
            graphicsShadowQuality = 3,
            raidGraphicsShadowQuality = 3,
            RAIDshadowMode = 1,
            RAIDshadowTextureSize = 1024,
        },
    },
    {
        key = "maxSSAO",
        label = "Maximum SSAO / ambient occlusion",
        tip = "Contact shadows where objects meet the ground.",
        category = "lighting",
        ultimate = {
            SSAO = 4,
            graphicsSSAO = 4,
            RAIDSSAO = 4,
            raidGraphicsSSAO = 4,
        },
        balance = {
            SSAO = 2,
            graphicsSSAO = 2,
            RAIDSSAO = 1,
            raidGraphicsSSAO = 1,
        },
    },
    {
        key = "volumeFog",
        label = "Volumetric fog (on)",
        tip = "Volumetric fog for atmosphere.",
        category = "lighting",
        ultimate = {
            volumeFog = 1,
            volumeFogLevel = 2,
            RAIDVolumeFogLevel = 2,
        },
        balance = {
            volumeFog = 1,
            volumeFogLevel = 1,
            RAIDVolumeFogLevel = 1,
        },
    },
    {
        key = "sunShafts",
        label = "God rays / sun shafts",
        tip = "Light shafts through trees and windows.",
        category = "lighting",
        ultimate = {
            sunShafts = 2,
            RAIDsunShafts = 2,
        },
        balance = {
            sunShafts = 1,
            RAIDsunShafts = 1,
        },
    },
    {
        key = "maxParticles",
        label = "Maximum particles & weather",
        tip = "Spell particles and weather density.",
        category = "effects",
        ultimate = {
            graphicsParticleDensity = 5,
            raidGraphicsParticleDensity = 5,
            particleDensity = 100,
            particleMTDensity = 100,
            weatherDensity = 3,
            RAIDparticleDensity = 100,
            RAIDparticleMTDensity = 100,
            RAIDweatherDensity = 3,
        },
        balance = {
            graphicsParticleDensity = 3,
            raidGraphicsParticleDensity = 3,
            particleDensity = 80,
            particleMTDensity = 80,
            weatherDensity = 2,
            RAIDparticleDensity = 60,
            RAIDparticleMTDensity = 60,
            RAIDweatherDensity = 2,
        },
    },
    {
        key = "maxWater",
        label = "Maximum water detail",
        tip = "Liquid detail and refraction.",
        category = "effects",
        ultimate = {
            graphicsLiquidDetail = 3,
            graphicsPBRLiquidDetail = 3,
            waterDetail = 3,
            refraction = 2,
            rippleDetail = 2,
            RAIDWaterDetail = 3,
            RAIDrefraction = 2,
        },
        balance = {
            graphicsLiquidDetail = 2,
            graphicsPBRLiquidDetail = 2,
            waterDetail = 2,
            refraction = 1,
            rippleDetail = 1,
            RAIDWaterDetail = 2,
            RAIDrefraction = 1,
        },
    },
    {
        key = "projectedTextures",
        label = "Projected textures",
        tip = "Ground spell markers and projected textures.",
        category = "effects",
        ultimate = {
            graphicsProjectedTextures = 1,
            raidGraphicsProjectedTextures = 1,
            projectedTextures = 1,
            RAIDprojectedTextures = 1,
        },
        balance = {
            graphicsProjectedTextures = 1,
            raidGraphicsProjectedTextures = 1,
            projectedTextures = 1,
            RAIDprojectedTextures = 1,
        },
    },
    {
        key = "crispImage",
        label = "Crystal-clear image (no bloom + sharpen)",
        tip = "Disables bloom and enables resample sharpening.",
        category = "image",
        ultimate = {
            ffxGlow = 0,
            ResampleAlwaysSharpen = 1,
            ResampleQuality = 3,
            ResampleSharpness = 0.7,
        },
        balance = {
            ffxGlow = 0,
            ResampleAlwaysSharpen = 1,
            ResampleQuality = 2,
            ResampleSharpness = 0.55,
        },
    },
    {
        key = "extendedCamera",
        label = "Extended camera zoom",
        tip = "How far the camera can zoom out.",
        category = "image",
        ultimate = { cameraDistanceMaxZoomFactor = 2.6 },
        balance = { cameraDistanceMaxZoomFactor = 2.2 },
    },
    {
        key = "colorfulDeath",
        label = "Colorful death screen",
        tip = "Keeps the world in color when you die.",
        category = "image",
        ultimate = { ffxDeath = 0 },
        balance = { ffxDeath = 0 },
    },
}

NS.RELOAD_OPTIONS = {
    showSoftTargetObjectIcons = "Show soft-target object/gather icons",
    showSoftTargetInteractIcons = "Show soft-target NPC/quest giver icons",
}

NS.FEATURE_BY_KEY = {}
NS.FEATURE_CVARS = {}
for i = 1, #NS.FEATURES do
    NS.FEATURE_BY_KEY[NS.FEATURES[i].key] = NS.FEATURES[i]
end

-- OFF restores the Defaults preset for that row, so unchecking a MAX upgrade actually drops it.
local defaultsMenu = NS.MENU_GRAPHICS.defaults
for i = 1, #NS.FEATURES do
    local feature = NS.FEATURES[i]
    local off = {}
    local function Collect(bundle)
        if not bundle then
            return
        end
        for name in pairs(bundle) do
            NS.FEATURE_CVARS[name] = true
            if defaultsMenu[name] ~= nil then
                off[name] = defaultsMenu[name]
            end
        end
    end
    Collect(feature.ultimate)
    Collect(feature.balance)
    feature.off = off
end

-- These rows are the effect itself. OFF means off, not the Defaults level.
NS.FEATURE_BY_KEY.volumeFog.off = {
    volumeFog = 0,
    volumeFogLevel = 0,
    RAIDVolumeFogLevel = 0,
}
NS.FEATURE_BY_KEY.sunShafts.off = {
    sunShafts = 0,
    RAIDsunShafts = 0,
}
NS.FEATURE_BY_KEY.projectedTextures.off = {
    graphicsProjectedTextures = 0,
    raidGraphicsProjectedTextures = 0,
    projectedTextures = 0,
    RAIDprojectedTextures = 0,
}

NS.DEFAULTS = {
    enabled = true,
    protect = false,
    profile = "ultimate",
    baseProfile = "ultimate",
    panelPoint = { "CENTER", "CENTER", 0, 40 },
    panelWidth = 440,
    panelHeight = 560,
    intensity = {},
    questItemSparkles = true,
    herbSparkles = true,
    oreSparkles = true,
    questObjectSparkles = false,
    showSoftTargetObjectIcons = false,
    showSoftTargetInteractIcons = false,
    chatMessages = true,
}

for i = 1, #NS.FEATURES do
    local key = NS.FEATURES[i].key
    NS.DEFAULTS[key] = true
    NS.DEFAULTS.intensity[key] = "ultimate"
end

function NS.InitDB()
    if type(XiusMaxGraphicsDB) ~= "table" then
        XiusMaxGraphicsDB = {}
    end
    local db = XiusMaxGraphicsDB
    for k, v in pairs(NS.DEFAULTS) do
        if db[k] == nil then
            if type(v) == "table" then
                local copy = {}
                for ck, cv in pairs(v) do
                    copy[ck] = cv
                end
                db[k] = copy
            else
                db[k] = v
            end
        end
    end
    if type(db.intensity) ~= "table" then
        db.intensity = {}
    end
    if db.profile ~= "ultimate" and db.profile ~= "balance" and db.profile ~= "defaults" and db.profile ~= "custom" then
        db.profile = "ultimate"
    end
    if db.baseProfile ~= "ultimate" and db.baseProfile ~= "balance" and db.baseProfile ~= "defaults" then
        if db.profile == "ultimate" or db.profile == "balance" or db.profile == "defaults" then
            db.baseProfile = db.profile
        else
            db.baseProfile = "ultimate"
        end
    end
    local defaultIntensity = (db.profile == "balance" or db.baseProfile == "balance") and "balance" or "ultimate"
    for i = 1, #NS.FEATURES do
        local key = NS.FEATURES[i].key
        if db[key] == nil then
            db[key] = db.profile ~= "defaults" or key == "projectedTextures"
        else
            db[key] = db[key] and true or false
        end
        local intensity = db.intensity[key]
        if intensity ~= "ultimate" and intensity ~= "balance" and intensity ~= "off" then
            db.intensity[key] = defaultIntensity
        end
        if db.profile == "ultimate" or db.profile == "balance" then
            db[key] = true
            db.intensity[key] = db.profile
        end
    end
    if db.profile == "defaults" then
        db.projectedTextures = true
        db.intensity.projectedTextures = "ultimate"
    end
    if type(db.panelPoint) ~= "table" or type(db.panelPoint[1]) ~= "string" or type(db.panelPoint[2]) ~= "string" then
        db.panelPoint = { "CENTER", "CENTER", 0, 40 }
    end
    db.enabled = db.enabled ~= false
    db.protect = db.protect and true or false
    db.questItemSparkles = db.questItemSparkles ~= false
    db.herbSparkles = db.herbSparkles ~= false
    db.oreSparkles = db.oreSparkles ~= false
    db.questObjectSparkles = db.questObjectSparkles and true or false
    db.showSoftTargetObjectIcons = db.showSoftTargetObjectIcons and true or false
    db.showSoftTargetInteractIcons = db.showSoftTargetInteractIcons and true or false
    db.chatMessages = db.chatMessages ~= false
    NS.db = db
end

function NS.SetFont(fs, size, flags)
    fs:SetFont(NS.FONT, size or 12, flags or "")
end

function NS.ApplyBackdrop(frame, backdrop, bgColor, edgeColor)
    if not frame.SetBackdrop then
        return
    end
    frame:SetBackdrop(backdrop or NS.BACKDROP_MENU)
    if bgColor then
        frame:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 1)
    end
    if edgeColor then
        frame:SetBackdropBorderColor(edgeColor[1], edgeColor[2], edgeColor[3], edgeColor[4] or 1)
    end
end

function NS.CreateWindowBackground(frame)
    NS.ApplyBackdrop(frame, NS.BACKDROP_MENU, { 0.05, 0.05, 0.05, 0.96 }, {
        NS.COLOR.buttonEdge[1], NS.COLOR.buttonEdge[2], NS.COLOR.buttonEdge[3], 0.9,
    })
end

function NS.CreateTitleBar(parent, height)
    local bar = CreateFrame("Frame", nil, parent, NS.BACKDROP_TEMPLATE)
    bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 1, -1)
    bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -1, -1)
    bar:SetHeight(height or 26)
    NS.ApplyBackdrop(bar, NS.BACKDROP_MENU, { 0.10, 0.09, 0.06, 1 }, {
        NS.COLOR.goldLineDim[1], NS.COLOR.goldLineDim[2], NS.COLOR.goldLineDim[3], 1,
    })
    return bar
end

function NS.Print(msg)
    if NS.db and NS.db.chatMessages == false then
        return
    end
    print("|cffd4a85a[Xius Max Graphics]|r " .. tostring(msg))
end

function NS.GetFeatureIntensity(key)
    local db = NS.db
    if not db or not db[key] then
        return "off"
    end
    if db.profile == "ultimate" or db.profile == "balance" then
        return db.profile
    end
    if db.profile == "defaults" then
        if key == "projectedTextures" then
            return "ultimate"
        end
        return "off"
    end
    local intensity = db.intensity and db.intensity[key]
    if intensity == "off" then
        return "off"
    end
    if intensity == "ultimate" or intensity == "balance" then
        return intensity
    end
    return (db.baseProfile == "balance") and "balance" or "ultimate"
end

function NS.ProfileDisplayName(profile)
    profile = profile or (NS.db and NS.db.profile) or "custom"
    if profile == "ultimate" then
        return "ULTIMATE"
    elseif profile == "balance" then
        return "BALANCE"
    elseif profile == "defaults" then
        return "DEFAULTS"
    elseif profile == "custom" then
        return "CUSTOM"
    end
    return string.upper(tostring(profile))
end

function NS.PresetChatName(profile)
    profile = profile or (NS.db and NS.db.profile) or "custom"
    if profile == "ultimate" then
        return "Ultimate"
    elseif profile == "balance" then
        return "Balance"
    elseif profile == "defaults" then
        return "Defaults"
    end
    return NS.ProfileDisplayName(profile)
end
