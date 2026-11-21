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

NS.VERSION = "1.7.0"

function NS.CanRead(value)
    if value == nil then
        return false
    end
    if issecretvalue then
        local ok, secret = pcall(issecretvalue, value)
        if ok and secret then
            return false
        end
    end
    if canaccessvalue then
        local ok, allowed = pcall(canaccessvalue, value)
        if ok and not allowed then
            return false
        end
    end
    return true
end

-- graphicsQuality CVar is 0-9; Options slider shows CVar+1 (1-10).
NS.PROFILE_QUALITY_UI = {
    potato = 1,
    low = 3,
    defaults = 5,
    balance = 7,
    ultimate = 10,
}
NS.PROFILE_QUALITY = {
    potato = 0,
    low = 2,
    defaults = 4,
    balance = 6,
    ultimate = 9,
}

-- Forever 1.60.1 rejects out-of-bounds CVar writes and keeps the old value instead of clamping.
-- When a retail ceiling is rejected by the engine, Core.lua immediately falls back to these
-- measured Forever maximums so the setting still reaches Forever's true limit.
NS.FALLBACK_CVARS = {
    farclip = 7000,
    RAIDfarclip = 7000,
    horizonClip = 7000,
    RAIDhorizonClip = 7000,
    groundEffectDist = 300,
    RAIDgroundEffectDist = 300,
    groundEffectFade = 300,
    doodadLodScale = 100,
    SSAO = 3,
    RAIDSSAO = 3,
    volumeFogLevel = 3,
    RAIDVolumeFogLevel = 3,
    shadowMode = 2,
    RAIDshadowMode = 2,
    ffxAntiAliasingMode = 2,
    cameraDistanceMaxZoomFactor = 2.6,
    spellClutter = 1,
}

-- Explicitly reset bloom/post-process CVars that can clip bright outdoor zones (e.g. Mount Hyjal)
-- to yellow/green/white, without touching user display calibration (Gamma, Brightness, Contrast).
NS.SAFE_LIGHTING_RESET = {
    ffxGlow = 0,
    graphicsBloom = 0,
    raidGraphicsBloom = 0,
    bloomUserMult = 0,
    graphicsBloomUserMult = 0,
    raidGraphicsBloomUserMult = 0,
    specular = 1,
    componentSpecular = 1,
}

-- Menu rows shared by Forever (priority) and modern clients.
-- Note on Low & Potato lighting: graphicsLightMode, giQuality, specular, componentSpecular,
-- maxLightCount, and ffxGlow stay at the safe baseline (1 / 8) so interiors, caves, and night
-- zones never turn pitch black or suffer broken lighting.
NS.MENU_GRAPHICS = {
    potato = {
        graphicsShadowQuality = 0,
        graphicsLiquidDetail = 0,
        graphicsPBRLiquidDetail = 0,
        graphicsParticleDensity = 0,
        graphicsSSAO = 0,
        graphicsDepthEffects = 0,
        graphicsComputeEffects = 0,
        graphicsTextureResolution = 0,
        graphicsProjectedTextures = 0,
        graphicsSpellDensity = 0,
        graphicsLightMode = 1,
        graphicsViewDistance = 0,
        graphicsEnvironmentDetail = 0,
        graphicsGroundClutter = 0,
        raidGraphicsShadowQuality = 0,
        raidGraphicsLiquidDetail = 0,
        raidGraphicsPBRLiquidDetail = 0,
        raidGraphicsParticleDensity = 0,
        raidGraphicsSSAO = 0,
        raidGraphicsDepthEffects = 0,
        raidGraphicsComputeEffects = 0,
        raidGraphicsTextureResolution = 0,
        raidGraphicsViewDistance = 0,
        raidGraphicsEnvironmentDetail = 0,
        raidGraphicsGroundClutter = 0,
        raidGraphicsProjectedTextures = 0,
        raidGraphicsSpellDensity = 0,
        raidGraphicsLightMode = 1,
        spellClutter = 1,
        spellVisualDensityFilterSetting = 1,
        giQuality = 1,
        RAIDgiQuality = 1,
        projectedTextures = 0,
        RAIDprojectedTextures = 0,
        shadowMode = 0,
        shadowSoft = 0,
        shadowTextureSize = 1024,
        RAIDshadowMode = 0,
        RAIDshadowTextureSize = 1024,
        SSAO = 0,
        RAIDSSAO = 0,
        waterDetail = 0,
        RAIDWaterDetail = 0,
        pbrLiquidDetail = 0,
        RAIDpbrLiquidDetail = 0,
        reflectionMode = 0,
        refraction = 0,
        RAIDrefraction = 0,
        rippleDetail = 0,
        RAIDrippleDetail = 0,
        particleDensity = 10,
        particleMTDensity = 10,
        RAIDparticleDensity = 10,
        RAIDparticleMTDensity = 10,
        DepthBasedOpacity = 0,
        weatherDensity = 0,
        RAIDweatherDensity = 0,
        skyCloudLod = 0,
        volumeFog = 0,
        volumeFogLevel = 0,
        RAIDVolumeFogLevel = 0,
        sunShafts = 0,
        RAIDsunShafts = 0,
        farclip = 185,
        horizonClip = 185,
        horizonStart = 185,
        RAIDfarclip = 185,
        RAIDhorizonClip = 185,
        RAIDhorizonStart = 185,
        terrainLodDist = 50,
        lodObjectCullDist = 15,
        RAIDterrainLodDist = 50,
        RAIDlodObjectCullDist = 15,
        groundEffectDensity = 16,
        groundEffectDist = 0,
        groundEffectFade = 15,
        RAIDgroundEffectDensity = 16,
        RAIDgroundEffectDist = 0,
        physicsLevel = 0,
        ffxGlow = 0,
        ResampleAlwaysSharpen = 0,
        ResampleQuality = 0,
        ResampleSharpness = 0.5,
        textureFilteringMode = 0,
        ffxAntiAliasingMode = 0,
        MSAAQuality = 0,
        specular = 1,
        componentSpecular = 1,
        cameraDistanceMaxZoomFactor = 4.0,
        clusteredShading = 0,
        RAIDclusteredShading = 0,
        maxLightCount = 8,
        entityLodDist = 1,
        RAIDentityLodDist = 1,
        entityShadowFadeScale = 10,
        RAIDentityShadowFadeScale = 10,
        wmoLodDist = 50,
        RAIDwmoLodDist = 50,
        lodObjectFadeScale = 50,
        lodObjectCullSize = 30,
        RAIDlodObjectCullSize = 30,
        doodadLodScale = 0,
        componentTextureLevel = 1,
        worldBaseMip = 1,
        ffxDeath = 0,
    },
    low = {
        graphicsShadowQuality = 1,
        graphicsLiquidDetail = 1,
        graphicsPBRLiquidDetail = 1,
        graphicsParticleDensity = 1,
        graphicsSSAO = 0,
        graphicsDepthEffects = 1,
        graphicsComputeEffects = 0,
        graphicsTextureResolution = 1,
        graphicsProjectedTextures = 1,
        graphicsSpellDensity = 1,
        graphicsLightMode = 1,
        graphicsViewDistance = 2,
        graphicsEnvironmentDetail = 2,
        graphicsGroundClutter = 2,
        raidGraphicsShadowQuality = 1,
        raidGraphicsLiquidDetail = 1,
        raidGraphicsPBRLiquidDetail = 1,
        raidGraphicsParticleDensity = 1,
        raidGraphicsSSAO = 0,
        raidGraphicsDepthEffects = 1,
        raidGraphicsComputeEffects = 0,
        raidGraphicsTextureResolution = 1,
        raidGraphicsViewDistance = 2,
        raidGraphicsEnvironmentDetail = 2,
        raidGraphicsGroundClutter = 2,
        raidGraphicsProjectedTextures = 1,
        raidGraphicsSpellDensity = 1,
        raidGraphicsLightMode = 1,
        spellClutter = 1,
        spellVisualDensityFilterSetting = 1,
        giQuality = 1,
        RAIDgiQuality = 1,
        projectedTextures = 1,
        RAIDprojectedTextures = 1,
        shadowMode = 0,
        shadowSoft = 0,
        shadowTextureSize = 1024,
        RAIDshadowMode = 0,
        RAIDshadowTextureSize = 1024,
        SSAO = 0,
        RAIDSSAO = 0,
        waterDetail = 1,
        RAIDWaterDetail = 1,
        pbrLiquidDetail = 1,
        RAIDpbrLiquidDetail = 1,
        reflectionMode = 0,
        refraction = 0,
        RAIDrefraction = 0,
        rippleDetail = 0,
        RAIDrippleDetail = 0,
        particleDensity = 25,
        particleMTDensity = 20,
        RAIDparticleDensity = 25,
        RAIDparticleMTDensity = 20,
        DepthBasedOpacity = 0,
        weatherDensity = 1,
        RAIDweatherDensity = 1,
        skyCloudLod = 1,
        volumeFog = 0,
        volumeFogLevel = 0,
        RAIDVolumeFogLevel = 0,
        sunShafts = 0,
        RAIDsunShafts = 0,
        farclip = 1300,
        horizonClip = 1300,
        horizonStart = 600,
        RAIDfarclip = 1300,
        RAIDhorizonClip = 1300,
        RAIDhorizonStart = 600,
        terrainLodDist = 200,
        lodObjectCullDist = 20,
        RAIDterrainLodDist = 200,
        RAIDlodObjectCullDist = 20,
        groundEffectDensity = 32,
        groundEffectDist = 60,
        groundEffectFade = 40,
        RAIDgroundEffectDensity = 32,
        RAIDgroundEffectDist = 60,
        physicsLevel = 1,
        ffxGlow = 0,
        ResampleAlwaysSharpen = 0,
        ResampleQuality = 1,
        ResampleSharpness = 0.5,
        textureFilteringMode = 1,
        ffxAntiAliasingMode = 0,
        MSAAQuality = 0,
        specular = 1,
        componentSpecular = 1,
        cameraDistanceMaxZoomFactor = 4.0,
        clusteredShading = 0,
        RAIDclusteredShading = 0,
        maxLightCount = 8,
        entityLodDist = 5,
        RAIDentityLodDist = 5,
        entityShadowFadeScale = 15,
        RAIDentityShadowFadeScale = 15,
        wmoLodDist = 200,
        RAIDwmoLodDist = 200,
        lodObjectFadeScale = 80,
        lodObjectCullSize = 20,
        RAIDlodObjectCullSize = 20,
        doodadLodScale = 50,
        componentTextureLevel = 1,
        worldBaseMip = 1,
        ffxDeath = 0,
    },
    defaults = {
        graphicsShadowQuality = 2,
        graphicsLiquidDetail = 1,
        graphicsPBRLiquidDetail = 1,
        graphicsParticleDensity = 2,
        graphicsSSAO = 1,
        graphicsDepthEffects = 1,
        graphicsComputeEffects = 0,
        graphicsTextureResolution = 1,
        graphicsProjectedTextures = 1,
        graphicsSpellDensity = 1,
        graphicsLightMode = 1,
        graphicsViewDistance = 4,
        graphicsEnvironmentDetail = 4,
        graphicsGroundClutter = 4,
        raidGraphicsShadowQuality = 2,
        raidGraphicsLiquidDetail = 1,
        raidGraphicsPBRLiquidDetail = 1,
        raidGraphicsParticleDensity = 2,
        raidGraphicsSSAO = 1,
        raidGraphicsDepthEffects = 1,
        raidGraphicsComputeEffects = 0,
        raidGraphicsTextureResolution = 1,
        raidGraphicsViewDistance = 4,
        raidGraphicsEnvironmentDetail = 4,
        raidGraphicsGroundClutter = 4,
        raidGraphicsProjectedTextures = 1,
        raidGraphicsSpellDensity = 1,
        raidGraphicsLightMode = 1,
        spellClutter = 0,
        spellVisualDensityFilterSetting = 2,
        giQuality = 1,
        RAIDgiQuality = 1,
        projectedTextures = 1,
        RAIDprojectedTextures = 1,
        shadowMode = 1,
        shadowSoft = 0,
        shadowTextureSize = 1024,
        RAIDshadowMode = 1,
        RAIDshadowTextureSize = 1024,
        SSAO = 1,
        RAIDSSAO = 1,
        waterDetail = 1,
        RAIDWaterDetail = 1,
        pbrLiquidDetail = 1,
        RAIDpbrLiquidDetail = 1,
        reflectionMode = 0,
        refraction = 1,
        RAIDrefraction = 1,
        rippleDetail = 0,
        RAIDrippleDetail = 0,
        particleDensity = 50,
        particleMTDensity = 50,
        RAIDparticleDensity = 50,
        RAIDparticleMTDensity = 50,
        DepthBasedOpacity = 0,
        weatherDensity = 1,
        RAIDweatherDensity = 1,
        skyCloudLod = 2,
        volumeFog = 0,
        volumeFogLevel = 0,
        RAIDVolumeFogLevel = 0,
        sunShafts = 0,
        RAIDsunShafts = 0,
        farclip = 2600,
        horizonClip = 2600,
        horizonStart = 1200,
        RAIDfarclip = 2600,
        RAIDhorizonClip = 2600,
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
        ffxGlow = 0,
        ResampleAlwaysSharpen = 0,
        ResampleQuality = 1,
        ResampleSharpness = 0.5,
        textureFilteringMode = 2,
        ffxAntiAliasingMode = 2,
        MSAAQuality = 0,
        specular = 1,
        componentSpecular = 1,
        cameraDistanceMaxZoomFactor = 4.0,
        clusteredShading = 0,
        RAIDclusteredShading = 0,
        maxLightCount = 8,
        entityLodDist = 5,
        RAIDentityLodDist = 5,
        entityShadowFadeScale = 20,
        RAIDentityShadowFadeScale = 20,
        wmoLodDist = 300,
        RAIDwmoLodDist = 300,
        lodObjectFadeScale = 100,
        lodObjectCullSize = 15,
        RAIDlodObjectCullSize = 15,
        doodadLodScale = 75,
        componentTextureLevel = 1,
        worldBaseMip = 1,
        ffxDeath = 0,
    },
    balance = {
        graphicsShadowQuality = 3,
        graphicsLiquidDetail = 2,
        graphicsPBRLiquidDetail = 2,
        graphicsParticleDensity = 3,
        graphicsSSAO = 2,
        graphicsDepthEffects = 2,
        graphicsComputeEffects = 0,
        graphicsTextureResolution = 2,
        graphicsProjectedTextures = 1,
        graphicsSpellDensity = 1,
        graphicsLightMode = 1,
        graphicsViewDistance = 6,
        graphicsEnvironmentDetail = 6,
        graphicsGroundClutter = 6,
        raidGraphicsShadowQuality = 3,
        raidGraphicsLiquidDetail = 2,
        raidGraphicsPBRLiquidDetail = 2,
        raidGraphicsParticleDensity = 3,
        raidGraphicsSSAO = 1,
        raidGraphicsDepthEffects = 2,
        raidGraphicsComputeEffects = 0,
        raidGraphicsTextureResolution = 2,
        raidGraphicsViewDistance = 6,
        raidGraphicsEnvironmentDetail = 6,
        raidGraphicsGroundClutter = 6,
        raidGraphicsProjectedTextures = 1,
        raidGraphicsSpellDensity = 1,
        raidGraphicsLightMode = 1,
        spellClutter = 0,
        spellVisualDensityFilterSetting = 3,
        giQuality = 1,
        RAIDgiQuality = 1,
        projectedTextures = 1,
        RAIDprojectedTextures = 1,
        shadowMode = 2,
        shadowSoft = 1,
        shadowTextureSize = 1024,
        RAIDshadowMode = 1,
        RAIDshadowTextureSize = 1024,
        SSAO = 2,
        RAIDSSAO = 1,
        waterDetail = 2,
        RAIDWaterDetail = 2,
        pbrLiquidDetail = 2,
        RAIDpbrLiquidDetail = 2,
        reflectionMode = 2,
        refraction = 1,
        RAIDrefraction = 1,
        rippleDetail = 1,
        RAIDrippleDetail = 1,
        particleDensity = 80,
        particleMTDensity = 80,
        RAIDparticleDensity = 60,
        RAIDparticleMTDensity = 60,
        DepthBasedOpacity = 1,
        weatherDensity = 2,
        RAIDweatherDensity = 2,
        skyCloudLod = 3,
        volumeFog = 0,
        volumeFogLevel = 0,
        RAIDVolumeFogLevel = 0,
        sunShafts = 0,
        RAIDsunShafts = 0,
        farclip = 5000,
        horizonClip = 5000,
        horizonStart = 1800,
        RAIDfarclip = 5000,
        RAIDhorizonClip = 5000,
        RAIDhorizonStart = 1600,
        terrainLodDist = 600,
        lodObjectCullDist = 50,
        RAIDterrainLodDist = 500,
        RAIDlodObjectCullDist = 50,
        groundEffectDensity = 128,
        groundEffectDist = 220,
        groundEffectFade = 180,
        RAIDgroundEffectDensity = 96,
        RAIDgroundEffectDist = 200,
        physicsLevel = 1,
        ffxGlow = 0,
        ResampleAlwaysSharpen = 1,
        ResampleQuality = 2,
        -- On Forever 1.60.1, ResampleSharpness is sharpening reduction (0 = sharpest, 2 = softest).
        ResampleSharpness = 0.15,
        textureFilteringMode = 4,
        ffxAntiAliasingMode = 2,
        MSAAQuality = 0,
        specular = 1,
        componentSpecular = 1,
        cameraDistanceMaxZoomFactor = 4.0,
        clusteredShading = 0,
        RAIDclusteredShading = 0,
        maxLightCount = 8,
        entityLodDist = 20,
        RAIDentityLodDist = 15,
        entityShadowFadeScale = 30,
        RAIDentityShadowFadeScale = 30,
        wmoLodDist = 500,
        RAIDwmoLodDist = 400,
        lodObjectFadeScale = 120,
        lodObjectCullSize = 12,
        RAIDlodObjectCullSize = 12,
        doodadLodScale = 100,
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
        graphicsComputeEffects = 0,
        graphicsTextureResolution = 2,
        graphicsProjectedTextures = 1,
        graphicsSpellDensity = 2,
        graphicsLightMode = 1,
        graphicsViewDistance = 9,
        graphicsEnvironmentDetail = 9,
        graphicsGroundClutter = 9,
        raidGraphicsShadowQuality = 5,
        raidGraphicsLiquidDetail = 3,
        raidGraphicsPBRLiquidDetail = 3,
        raidGraphicsParticleDensity = 5,
        raidGraphicsSSAO = 4,
        raidGraphicsDepthEffects = 3,
        raidGraphicsComputeEffects = 0,
        raidGraphicsTextureResolution = 2,
        raidGraphicsViewDistance = 9,
        raidGraphicsEnvironmentDetail = 9,
        raidGraphicsGroundClutter = 9,
        raidGraphicsProjectedTextures = 1,
        raidGraphicsSpellDensity = 2,
        raidGraphicsLightMode = 1,
        spellClutter = 0,
        spellVisualDensityFilterSetting = 4,
        giQuality = 1,
        RAIDgiQuality = 1,
        projectedTextures = 1,
        RAIDprojectedTextures = 1,
        shadowMode = 4,
        shadowSoft = 1,
        shadowTextureSize = 2048,
        RAIDshadowMode = 4,
        RAIDshadowTextureSize = 2048,
        SSAO = 4,
        RAIDSSAO = 4,
        waterDetail = 3,
        RAIDWaterDetail = 3,
        pbrLiquidDetail = 3,
        RAIDpbrLiquidDetail = 3,
        reflectionMode = 3,
        refraction = 2,
        RAIDrefraction = 2,
        rippleDetail = 2,
        RAIDrippleDetail = 2,
        particleDensity = 100,
        particleMTDensity = 100,
        RAIDparticleDensity = 100,
        RAIDparticleMTDensity = 100,
        DepthBasedOpacity = 1,
        weatherDensity = 3,
        RAIDweatherDensity = 3,
        skyCloudLod = 3,
        volumeFog = 0,
        volumeFogLevel = 0,
        RAIDVolumeFogLevel = 0,
        sunShafts = 0,
        RAIDsunShafts = 0,
        farclip = 10000,
        horizonClip = 10000,
        horizonStart = 3000,
        RAIDfarclip = 10000,
        RAIDhorizonClip = 10000,
        RAIDhorizonStart = 3000,
        terrainLodDist = 1000,
        lodObjectCullDist = 100,
        RAIDterrainLodDist = 1000,
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
        -- 0 is maximum sharpness on Forever 1.60.1 (0.15 keeps crisp edges without ringing artifacts).
        ResampleSharpness = 0.15,
        textureFilteringMode = 5,
        ffxAntiAliasingMode = 4,
        MSAAQuality = 0,
        specular = 1,
        componentSpecular = 1,
        cameraDistanceMaxZoomFactor = 4.0,
        clusteredShading = 0,
        RAIDclusteredShading = 0,
        maxLightCount = 8,
        entityLodDist = 50,
        RAIDentityLodDist = 50,
        entityShadowFadeScale = 50,
        RAIDentityShadowFadeScale = 50,
        wmoLodDist = 1000,
        RAIDwmoLodDist = 1000,
        lodObjectFadeScale = 160,
        lodObjectCullSize = 8,
        RAIDlodObjectCullSize = 8,
        doodadLodScale = 160,
        componentTextureLevel = 0,
        worldBaseMip = 0,
        ffxDeath = 0,
    },
}

NS.COLOR = {
    sparkle = { 1.0, 0.88, 0.35, 1 },
}

-- World color tint overlays (MOD blend on WorldFrame, no CVars touched).
-- 0 = None / Disabled (default).
NS.TINTS = {
    [1] = { name = "Sepia", color = { 1, 0.82, 0.58 } },
    [2] = { name = "Warm", color = { 1, 0.88, 0.72 } },
    [3] = { name = "Cold", color = { 0.75, 0.88, 1 } },
    [4] = { name = "Night", color = { 0.55, 0.68, 1 } },
    [5] = { name = "Emerald", color = { 0.7, 1, 0.78 } },
    [6] = { name = "Dusk", color = { 1, 0.72, 0.88 } },
}

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
            groundEffectDist = 220,
            groundEffectFade = 180,
            RAIDgroundEffectDensity = 96,
            RAIDgroundEffectDist = 200,
        },
        low = {
            graphicsGroundClutter = 2,
            raidGraphicsGroundClutter = 2,
            groundEffectDensity = 32,
            groundEffectDist = 60,
            groundEffectFade = 40,
            RAIDgroundEffectDensity = 32,
            RAIDgroundEffectDist = 60,
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
            RAIDhorizonClip = 10000,
            RAIDhorizonStart = 3000,
        },
        balance = {
            graphicsViewDistance = 6,
            raidGraphicsViewDistance = 6,
            farclip = 5000,
            horizonClip = 5000,
            horizonStart = 1800,
            RAIDfarclip = 5000,
            RAIDhorizonClip = 5000,
            RAIDhorizonStart = 1600,
        },
        low = {
            graphicsViewDistance = 2,
            raidGraphicsViewDistance = 2,
            farclip = 1300,
            horizonClip = 1300,
            horizonStart = 600,
            RAIDfarclip = 1300,
            RAIDhorizonClip = 1300,
            RAIDhorizonStart = 600,
        },
    },
    {
        key = "maxObjectDetail",
        label = "Maximum object & terrain detail",
        tip = "Terrain, building, creature, and sky LOD distances.",
        category = "world",
        ultimate = {
            graphicsEnvironmentDetail = 9,
            raidGraphicsEnvironmentDetail = 9,
            terrainLodDist = 1000,
            lodObjectCullDist = 100,
            entityLodDist = 50,
            wmoLodDist = 1000,
            RAIDwmoLodDist = 1000,
            lodObjectFadeScale = 160,
            lodObjectCullSize = 8,
            RAIDlodObjectCullSize = 8,
            doodadLodScale = 160,
            skyCloudLod = 3,
            RAIDterrainLodDist = 1000,
            RAIDlodObjectCullDist = 100,
            RAIDentityLodDist = 50,
        },
        balance = {
            graphicsEnvironmentDetail = 6,
            raidGraphicsEnvironmentDetail = 6,
            terrainLodDist = 600,
            lodObjectCullDist = 50,
            entityLodDist = 20,
            wmoLodDist = 500,
            RAIDwmoLodDist = 400,
            lodObjectFadeScale = 120,
            lodObjectCullSize = 12,
            RAIDlodObjectCullSize = 12,
            doodadLodScale = 100,
            skyCloudLod = 3,
            RAIDterrainLodDist = 500,
            RAIDlodObjectCullDist = 50,
            RAIDentityLodDist = 15,
        },
        low = {
            graphicsEnvironmentDetail = 2,
            raidGraphicsEnvironmentDetail = 2,
            terrainLodDist = 200,
            lodObjectCullDist = 20,
            entityLodDist = 5,
            wmoLodDist = 200,
            RAIDwmoLodDist = 200,
            lodObjectFadeScale = 80,
            lodObjectCullSize = 20,
            RAIDlodObjectCullSize = 20,
            doodadLodScale = 50,
            skyCloudLod = 1,
            RAIDterrainLodDist = 200,
            RAIDlodObjectCullDist = 20,
            RAIDentityLodDist = 5,
        },
    },
    {
        key = "maxShadows",
        label = "Maximum shadows",
        tip = "Soft shadows, shadow mode, and 2048 shadow map resolution. Heavy on FPS.",
        category = "lighting",
        ultimate = {
            shadowMode = 4,
            shadowSoft = 1,
            shadowTextureSize = 2048,
            graphicsShadowQuality = 5,
            raidGraphicsShadowQuality = 5,
            RAIDshadowMode = 4,
            RAIDshadowTextureSize = 2048,
            entityShadowFadeScale = 50,
            RAIDentityShadowFadeScale = 50,
        },
        balance = {
            shadowMode = 2,
            shadowSoft = 1,
            shadowTextureSize = 1024,
            graphicsShadowQuality = 3,
            raidGraphicsShadowQuality = 3,
            RAIDshadowMode = 1,
            RAIDshadowTextureSize = 1024,
            entityShadowFadeScale = 30,
            RAIDentityShadowFadeScale = 30,
        },
        low = {
            shadowMode = 0,
            shadowSoft = 0,
            shadowTextureSize = 1024,
            graphicsShadowQuality = 1,
            raidGraphicsShadowQuality = 1,
            RAIDshadowMode = 0,
            RAIDshadowTextureSize = 1024,
            entityShadowFadeScale = 15,
            RAIDentityShadowFadeScale = 15,
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
        low = {
            SSAO = 0,
            graphicsSSAO = 0,
            RAIDSSAO = 0,
            raidGraphicsSSAO = 0,
        },
    },
    {
        key = "volumeFog",
        label = "Volumetric fog (on)",
        tip = "Volumetric fog for atmosphere (capped at safe lighting level).",
        category = "lighting",
        ultimate = {
            volumeFog = 1,
            volumeFogLevel = 2,
            RAIDVolumeFogLevel = 2,
        },
        balance = {
            volumeFog = 1,
            volumeFogLevel = 2,
            RAIDVolumeFogLevel = 2,
        },
        low = {
            volumeFog = 0,
            volumeFogLevel = 0,
            RAIDVolumeFogLevel = 0,
        },
    },
    {
        key = "sunShafts",
        label = "God rays / sun shafts",
        tip = "Light shafts through trees and windows (capped to prevent bright outdoor bloom clipping).",
        category = "lighting",
        ultimate = {
            sunShafts = 1,
            RAIDsunShafts = 1,
        },
        balance = {
            sunShafts = 1,
            RAIDsunShafts = 1,
        },
        low = {
            sunShafts = 0,
            RAIDsunShafts = 0,
        },
    },
    {
        key = "maxParticles",
        label = "Maximum particles & weather",
        tip = "Spell particles, weather density, physics, and depth-based transparency.",
        category = "effects",
        ultimate = {
            graphicsParticleDensity = 5,
            raidGraphicsParticleDensity = 5,
            particleDensity = 100,
            particleMTDensity = 100,
            DepthBasedOpacity = 1,
            weatherDensity = 3,
            physicsLevel = 2,
            RAIDparticleDensity = 100,
            RAIDparticleMTDensity = 100,
            RAIDweatherDensity = 3,
        },
        balance = {
            graphicsParticleDensity = 3,
            raidGraphicsParticleDensity = 3,
            particleDensity = 80,
            particleMTDensity = 80,
            DepthBasedOpacity = 1,
            weatherDensity = 2,
            physicsLevel = 1,
            RAIDparticleDensity = 60,
            RAIDparticleMTDensity = 60,
            RAIDweatherDensity = 2,
        },
        low = {
            graphicsParticleDensity = 1,
            raidGraphicsParticleDensity = 1,
            particleDensity = 25,
            particleMTDensity = 20,
            DepthBasedOpacity = 0,
            weatherDensity = 1,
            physicsLevel = 1,
            RAIDparticleDensity = 25,
            RAIDparticleMTDensity = 20,
            RAIDweatherDensity = 1,
        },
    },
    {
        key = "maxWater",
        label = "Maximum water detail",
        tip = "Liquid detail, full scenery reflections, ripples, and refraction.",
        category = "effects",
        ultimate = {
            graphicsLiquidDetail = 3,
            raidGraphicsLiquidDetail = 3,
            graphicsPBRLiquidDetail = 3,
            raidGraphicsPBRLiquidDetail = 3,
            pbrLiquidDetail = 3,
            RAIDpbrLiquidDetail = 3,
            waterDetail = 3,
            reflectionMode = 3,
            refraction = 2,
            rippleDetail = 2,
            RAIDrippleDetail = 2,
            RAIDWaterDetail = 3,
            RAIDrefraction = 2,
        },
        balance = {
            graphicsLiquidDetail = 2,
            raidGraphicsLiquidDetail = 2,
            graphicsPBRLiquidDetail = 2,
            raidGraphicsPBRLiquidDetail = 2,
            pbrLiquidDetail = 2,
            RAIDpbrLiquidDetail = 2,
            waterDetail = 2,
            reflectionMode = 2,
            refraction = 1,
            rippleDetail = 1,
            RAIDrippleDetail = 1,
            RAIDWaterDetail = 2,
            RAIDrefraction = 1,
        },
        low = {
            graphicsLiquidDetail = 1,
            raidGraphicsLiquidDetail = 1,
            graphicsPBRLiquidDetail = 1,
            raidGraphicsPBRLiquidDetail = 1,
            pbrLiquidDetail = 1,
            RAIDpbrLiquidDetail = 1,
            waterDetail = 1,
            reflectionMode = 0,
            refraction = 0,
            rippleDetail = 0,
            RAIDrippleDetail = 0,
            RAIDWaterDetail = 1,
            RAIDrefraction = 0,
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
        low = {
            graphicsProjectedTextures = 1,
            raidGraphicsProjectedTextures = 1,
            projectedTextures = 1,
            RAIDprojectedTextures = 1,
        },
    },
    {
        key = "crispImage",
        label = "Crystal-clear image (no bloom + sharpen)",
        tip = "Disables bloom and enables strong resample sharpening (0.15 on Forever).",
        category = "image",
        ultimate = {
            ffxGlow = 0,
            ResampleAlwaysSharpen = 1,
            ResampleQuality = 3,
            ResampleSharpness = 0.15,
        },
        balance = {
            ffxGlow = 0,
            ResampleAlwaysSharpen = 1,
            ResampleQuality = 2,
            -- Forever clamps ResampleSharpness near 0.15 (0 = sharpest).
            ResampleSharpness = 0.15,
        },
        low = {
            ffxGlow = 0,
            ResampleAlwaysSharpen = 0,
            ResampleQuality = 1,
            ResampleSharpness = 0.5,
        },
    },
    {
        key = "extendedCamera",
        label = "Extended camera zoom",
        tip = "How far the camera can zoom out (4.0 on Forever, 2.6 on modern; zero FPS cost).",
        category = "image",
        ultimate = { cameraDistanceMaxZoomFactor = 4.0 },
        balance = { cameraDistanceMaxZoomFactor = 4.0 },
        low = { cameraDistanceMaxZoomFactor = 4.0 },
    },
    {
        key = "colorfulDeath",
        label = "Colorful death screen",
        tip = "Keeps the world in color when you die (zero FPS cost).",
        category = "image",
        ultimate = { ffxDeath = 0 },
        balance = { ffxDeath = 0 },
        low = { ffxDeath = 0 },
    },
}

NS.RELOAD_OPTIONS = {
    showSoftTargetObjectIcons = "Show soft-target object/gather icons",
    showSoftTargetInteractIcons = "Show soft-target NPC/quest giver icons",
}

NS.FEATURE_BY_KEY = {}
NS.FEATURE_CVARS = {}
NS.SLIDER_CVARS = {}

-- Menu slider CVars (graphics* and raidGraphics*) must always be written BEFORE
-- raw engine CVars (groundEffectDensity, farclip, wmoLodDist, etc.), because
-- changing a slider CVar causes the WoW engine to overwrite its child raw CVars.
for _, menuBundle in pairs(NS.MENU_GRAPHICS) do
    for name in pairs(menuBundle) do
        if string.sub(name, 1, 8) == "graphics" or string.sub(name, 1, 12) == "raidGraphics" then
            NS.SLIDER_CVARS[name] = true
        end
    end
end

for i = 1, #NS.FEATURES do
    NS.FEATURE_BY_KEY[NS.FEATURES[i].key] = NS.FEATURES[i]
end

-- Build off bundles for defaults, low, and potato baselines.
local defaultsMenu = NS.MENU_GRAPHICS.defaults
local lowMenu = NS.MENU_GRAPHICS.low
local potatoMenu = NS.MENU_GRAPHICS.potato
for i = 1, #NS.FEATURES do
    local feature = NS.FEATURES[i]
    local off = {}
    local offLow = {}
    local offPotato = {}
    local function Collect(bundle)
        if not bundle then
            return
        end
        for name in pairs(bundle) do
            NS.FEATURE_CVARS[name] = true
            if string.sub(name, 1, 8) == "graphics" or string.sub(name, 1, 12) == "raidGraphics" then
                NS.SLIDER_CVARS[name] = true
            end
            if defaultsMenu[name] ~= nil then
                off[name] = defaultsMenu[name]
            end
            if lowMenu[name] ~= nil then
                offLow[name] = lowMenu[name]
            end
            if potatoMenu[name] ~= nil then
                offPotato[name] = potatoMenu[name]
            end
        end
    end
    Collect(feature.ultimate)
    Collect(feature.balance)
    Collect(feature.low)
    feature.off = off
    feature.offByBase = {
        defaults = off,
        low = offLow,
        potato = offPotato,
    }
    feature.potato = offPotato
end

-- These rows are the effect itself. OFF means off, not the Defaults level.
local volumeFogOff = {
    volumeFog = 0,
    volumeFogLevel = 0,
    RAIDVolumeFogLevel = 0,
}
NS.FEATURE_BY_KEY.volumeFog.off = volumeFogOff
NS.FEATURE_BY_KEY.volumeFog.offByBase = {
    defaults = volumeFogOff,
    low = volumeFogOff,
    potato = volumeFogOff,
}

local sunShaftsOff = {
    sunShafts = 0,
    RAIDsunShafts = 0,
}
NS.FEATURE_BY_KEY.sunShafts.off = sunShaftsOff
NS.FEATURE_BY_KEY.sunShafts.offByBase = {
    defaults = sunShaftsOff,
    low = sunShaftsOff,
    potato = sunShaftsOff,
}

local projectedOff = {
    graphicsProjectedTextures = 0,
    raidGraphicsProjectedTextures = 0,
    projectedTextures = 0,
    RAIDprojectedTextures = 0,
}
NS.FEATURE_BY_KEY.projectedTextures.off = projectedOff
NS.FEATURE_BY_KEY.projectedTextures.offByBase = {
    defaults = projectedOff,
    low = projectedOff,
    potato = projectedOff,
}

local extendedCameraOff = {
    cameraDistanceMaxZoomFactor = 1.9,
}
NS.FEATURE_BY_KEY.extendedCamera.off = extendedCameraOff
NS.FEATURE_BY_KEY.extendedCamera.offByBase = {
    defaults = extendedCameraOff,
    low = extendedCameraOff,
    potato = extendedCameraOff,
}

local colorfulDeathOff = {
    ffxDeath = 1,
}
NS.FEATURE_BY_KEY.colorfulDeath.off = colorfulDeathOff
NS.FEATURE_BY_KEY.colorfulDeath.offByBase = {
    defaults = colorfulDeathOff,
    low = colorfulDeathOff,
    potato = colorfulDeathOff,
}

-- Zero-FPS-cost quality-of-life features that stay MAX across every preset.
NS.ALWAYS_MAX_FEATURES = {
    extendedCamera = true,
    colorfulDeath = true,
}

NS.LOW_OFF_FEATURES = {
    maxSSAO = true,
    volumeFog = true,
    sunShafts = true,
    crispImage = true,
}

NS.VALID_PROFILES = {
    ultimate = true,
    balance = true,
    defaults = true,
    low = true,
    potato = true,
    custom = true,
}

NS.VALID_BASE_PROFILES = {
    ultimate = true,
    balance = true,
    defaults = true,
    low = true,
    potato = true,
}

NS.DEFAULTS = {
    enabled = true,
    protect = false,
    profile = "ultimate",
    baseProfile = "ultimate",
    intensity = {},
    customCVars = {},
    tint = 0,
    tintStrength = 50,
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
        if type(XiusUIDB) == "table" and type(XiusUIDB.graphics) == "table" then
            XiusMaxGraphicsDB = XiusUIDB.graphics
        else
            XiusMaxGraphicsDB = {}
        end
    end
    if type(XiusUIDB) == "table" then
        if next(XiusMaxGraphicsDB) == nil and type(XiusUIDB.graphics) == "table" and next(XiusUIDB.graphics) ~= nil then
            for k, v in pairs(XiusUIDB.graphics) do
                XiusMaxGraphicsDB[k] = v
            end
        end
        XiusUIDB.graphics = XiusMaxGraphicsDB
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
    if type(db.customCVars) ~= "table" then
        db.customCVars = {}
    end
    if not NS.VALID_PROFILES[db.profile] then
        db.profile = "ultimate"
    end
    if not NS.VALID_BASE_PROFILES[db.baseProfile] then
        if NS.VALID_BASE_PROFILES[db.profile] then
            db.baseProfile = db.profile
        else
            db.baseProfile = "ultimate"
        end
    end
    local defaultIntensity = "ultimate"
    if db.profile == "balance" or db.baseProfile == "balance" then
        defaultIntensity = "balance"
    elseif db.profile == "low" or db.baseProfile == "low" then
        defaultIntensity = "low"
    end
    for i = 1, #NS.FEATURES do
        local key = NS.FEATURES[i].key
        if db[key] == nil then
            if db.profile == "potato" then
                db[key] = false
            elseif db.profile == "defaults" then
                db[key] = key == "projectedTextures"
            elseif db.profile == "low" then
                db[key] = not NS.LOW_OFF_FEATURES[key]
            else
                db[key] = true
            end
        else
            db[key] = db[key] and true or false
        end
        local intensity = db.intensity[key]
        if intensity ~= "ultimate" and intensity ~= "balance" and intensity ~= "low" and intensity ~= "off" then
            db.intensity[key] = defaultIntensity
        end
        if NS.ALWAYS_MAX_FEATURES[key] and db.profile ~= "custom" then
            db[key] = true
            db.intensity[key] = "ultimate"
        elseif db.profile == "ultimate" or db.profile == "balance" then
            if key == "volumeFog" or key == "sunShafts" then
                db[key] = false
                db.intensity[key] = "off"
            else
                db[key] = true
                db.intensity[key] = db.profile
            end
        elseif db.profile == "low" then
            if key == "projectedTextures" then
                db[key] = true
                db.intensity[key] = "ultimate"
            elseif NS.LOW_OFF_FEATURES[key] then
                db[key] = false
                db.intensity[key] = "off"
            else
                db[key] = true
                db.intensity[key] = "low"
            end
        elseif db.profile == "potato" then
            db[key] = false
            db.intensity[key] = "off"
        end
    end
    if db.profile == "defaults" then
        db.projectedTextures = true
        db.intensity.projectedTextures = "ultimate"
    end
    local tint = tonumber(db.tint) or 0
    tint = math.floor(tint + 0.5)
    if tint < 0 or tint > #NS.TINTS then
        tint = 0
    end
    db.tint = tint
    local tintStrength = tonumber(db.tintStrength)
    if tintStrength == nil then
        tintStrength = 50
    end
    tintStrength = math.max(0, math.min(100, math.floor(tintStrength / 5 + 0.5) * 5))
    db.tintStrength = tintStrength
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

function NS.Print(msg)
    if NS.db and NS.db.chatMessages == false then
        return
    end
    print("|cffd4a85a[Xius Max Graphics]|r " .. tostring(msg))
end

function NS.GetFeatureOffBundle(feature)
    if not feature then
        return nil
    end
    local base = NS.db and NS.db.baseProfile
    if feature.offByBase and base and feature.offByBase[base] then
        return feature.offByBase[base]
    end
    return feature.off
end

function NS.GetFeatureIntensity(key)
    local db = NS.db
    if not db or not db[key] then
        return "off"
    end
    if db.profile ~= "custom" and NS.ALWAYS_MAX_FEATURES and NS.ALWAYS_MAX_FEATURES[key] then
        return "ultimate"
    end
    if db.profile == "ultimate" or db.profile == "balance" then
        return db.profile
    end
    if db.profile == "potato" then
        return "off"
    end
    if db.profile == "defaults" then
        if key == "projectedTextures" then
            return "ultimate"
        end
        return "off"
    end
    if db.profile == "low" then
        if key == "projectedTextures" then
            return "ultimate"
        end
        if NS.LOW_OFF_FEATURES and NS.LOW_OFF_FEATURES[key] then
            return "off"
        end
        return "low"
    end
    local intensity = db.intensity and db.intensity[key]
    if intensity == "off" then
        return "off"
    end
    if intensity == "ultimate" or intensity == "balance" or intensity == "low" then
        return intensity
    end
    if db.baseProfile == "balance" then
        return "balance"
    elseif db.baseProfile == "low" then
        return "low"
    end
    return "ultimate"
end

function NS.ProfileDisplayName(profile)
    profile = profile or (NS.db and NS.db.profile) or "custom"
    if profile == "ultimate" then
        return "ULTIMATE"
    elseif profile == "balance" then
        return "BALANCE"
    elseif profile == "defaults" then
        return "DEFAULTS"
    elseif profile == "low" then
        return "LOW"
    elseif profile == "potato" then
        return "POTATO"
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
    elseif profile == "low" then
        return "Low"
    elseif profile == "potato" then
        return "Potato"
    end
    return NS.ProfileDisplayName(profile)
end
