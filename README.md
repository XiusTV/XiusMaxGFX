# Xius Max Graphics

Pick-and-choose graphics upgrades for **modern World of Warcraft** and **World of Warcraft Forever**. Ultimate, Balance, Low, Potato, and Defaults push (or pull) view distance, grass, shadows, water, particles, and image clarity past the normal graphics menu. Each upgrade can be set on its own. Optional loot and gathering sparkles sit on top of that.

Settings open in [Xius Core](https://github.com/XiusTV/XiusCore). This addon does not build its own window.

**Current version: 1.7.0** (requires Xius Core)

## Features

### Presets

- **Ultimate:** Top graphics-menu quality, with grass, view distance, shadows, water, particles, and sharpening pushed further.
- **Balance:** High quality with a lighter cost. Raid shadows and ambient occlusion stay lower than the open world.
- **Defaults:** The normal graphics-menu baseline. Projected textures (ground spell markers) stay on.
- **Low:** Light FPS-friendly profile with safe indoor/dungeon lighting kept intact.
- **Potato:** Minimum everything for weak PCs, without pitch-black interiors or broken night lighting.
- **Custom:** Change any single row or fine-tune slider and the addon keeps your mix. Each row is **OFF**, **LOW**, **BAL**, or **MAX**.

Turning the addon off stops it from writing settings. It does not put your old graphics back.

### World, light, and image

- **World:** Grass and clutter, view distance, object and terrain detail, with fine-tune sliders for farclip, terrain LOD, horizon, and ground clutter.
- **Lighting:** Shadows, SSAO, volumetric fog, and god rays. Safe lighting reset keeps bloom/`ffxGlow` from clipping bright outdoor zones (for example Mount Hyjal).
- **Effects:** Particles and weather, water detail, projected textures, and anti-aliasing.
- **Image:** Bloom off with Forever-aware sharpening, extended camera zoom, and a color death screen.
- **Screen tint:** Optional color filters (sepia, warm, cold, night, emerald, dusk) with strength control.

Heavy rows (shadows, view distance, grass) cost FPS. Balance / Low / Potato exist for that.

### Loot and gathering sparkles

- **Quest item loot sparkles:** Sparkles on quest loot and quest givers. Fully exit the game and start it again after changing this. A UI reload will not show or hide them.
- **Herb and ore glints:** Golden glints on the nearest herb or vein in front of the camera. These do not sparkle NPCs or quest givers.
- **Quest object sparkles:** Extra glints on nearby quest objects such as chests and wanted posters.
- **Soft-target icons:** Optional floating icons on gather nodes, and separate overhead icons on NPCs and quest givers. Changing either icon option asks you to reload. Ultimate, Balance, and Defaults turn the NPC icons off.
- **Keep icons sticky:** Re-locks loot sparkles and soft-target icons if something else changes them. It does not fight the Graphics menu.

## Controls & Slash Commands

| Command / Input | Action |
| --- | --- |
| `/xmg` or `/xiusmax` | Open or close Max Graphics in Xius Core |
| `/xmg on` / `/xmg off` | Turn upgrades on or off |
| `/xmg ultimate` or `/xmg max` | Apply the Ultimate preset |
| `/xmg balance` | Apply the Balance preset |
| `/xmg low` | Apply the Low preset |
| `/xmg potato` | Apply the Potato preset |
| `/xmg defaults` or `/xmg reset` | Apply the Defaults preset |
| `/xmg protect` | Toggle sticky loot and soft-target icons |
| `/xmg sparkles` or `/xmg loot` | Toggle quest item loot sparkles |
| `/xius graphics` | Open Max Graphics from Xius Core |
| Left-click the addon compartment icon | Open Max Graphics |
| Right-click the addon compartment icon | Toggle the addon on or off |

## Configuration

Open the page with `/xmg`, `/xiusmax`, or `/xius graphics`. Xius Core has to be installed and enabled.

- **Presets:** Ultimate, Balance, Defaults, Low, and Potato.
- **Rows:** OFF / LOW / BAL / MAX for each graphics upgrade.
- **Fine-tuning:** Sliders for view distance, terrain, horizon, clutter, water, camera zoom, and tint strength.
- **Sparkles:** Quest loot, herbs, ore, quest objects, and the two soft-target icon options.
- **Actions:** Restart Graphics Engine after heavy CVar changes when the client needs a nudge.

Choices are saved for the account in `XiusMaxGraphicsDB`.

## Changelog highlights since 1.6.8

- Version **1.7.0** with Potato / Low presets and richer Custom fine-tuning.
- Forever-safe CVar fallbacks when the engine rejects out-of-bounds retail ceilings.
- Bloom / lighting safety reset to stop outdoor yellow/white clip artifacts.
- Screen tint filters with preview art (`Media/tint-preview.tga`).
- Secret-value / Midnight-safe reads for combat and unit APIs.
- Dedicated Forever TOC (`XiusMaxGraphics_Forever.toc`, Interface 16001) plus camelot load support.
- Standalone Options/Shell windows removed — settings live only in Xius Core.
- Branded TOC title and expanded Interface list for modern + Forever clients.

## More From Xius

### Xius Core - [GitHub](https://github.com/XiusTV/XiusCore) · [CurseForge](https://www.curseforge.com/wow/addons/xius-core)

The settings and quality-of-life hub for the Xius addons. One window holds Quality of Life, General, and every other Xius addon you have installed.

### Xius Threat Meter - [GitHub](https://github.com/XiusTV/XiusThreatMeter) · [CurseForge](https://www.curseforge.com/wow/addons/xius-threat-meter)

A threat meter. Shows who is on the enemy's threat table, how much threat each player and pet has, and warns you before you pull aggro.

### Xius XP & Reputation Tracker - [GitHub](https://github.com/XiusTV/XiusXPTracker) · [CurseForge](https://www.curseforge.com/wow/addons/xius-xp-and-reputation-tracker)

A HUD card for level, XP, rested XP, watched faction, session rates, gold, and time-to-level.

### Xius Marks Bar - [GitHub](https://github.com/XiusTV/XiusMarksBar) · [CurseForge](https://www.curseforge.com/wow/addons/xius-marks-bar)

A raid marking bar. Click the flag for world markers or the star for target markers. Includes 5 / 10 / 20 pull timers, ready check, and role check.

### Xius Kill Streak - [GitHub](https://github.com/XiusTV/XiusKillStreak) · [CurseForge](https://www.curseforge.com/wow/addons/xius-kill-streak)

A ten-tier kill streak announcer for mobs and enemy players. Each tier shows a banner, plays a call, and keeps a counter for the streak and the time left.

Their settings open from the Xius Core window.

## License

Released under the [GNU General Public License v3.0](LICENSE).

## Development & AI Disclosure

This addon was built and refactored with the assistance of AI development tools (Cursor / LLMs) for code generation, UI layout structure, and graphics-setting layout, with manual architecture, in-game verification, and maintenance by Xius.
