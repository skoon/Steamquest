# Task Checklist — The Golden Gear

- [x] Locate Godot 4.7.1 install
- [x] Write implementation_plan.md
- [x] Plan approved by Scott (sprites as billboarded characters)
- [x] project.godot (input map, physics layer names, autoload, main scene)
- [x] Pure logic: GearItem, FrictionModel, DamageCalc, SteamPressure, ScrapGearTable
- [x] Config resources + data/*.tres
- [x] GameState autoload + signals
- [x] Unit test runner + tests (61 passing)
- [x] Camera rig
- [x] Technician controller (move, dash, aim, wrench, rivet gun, overclock vent)
- [x] Enemies: base, Skitterer, Bruiser, Arc Turret
- [x] World pieces: terminal, doors, valve, pedestal, cog, furnace, vent, elevator, gear pickup, vats, decor props
- [x] Foundry builder + foundry_level.tscn (4 rooms, nav bake, environment, wall cutaway)
- [x] HUD (bars, gauge, friction, maintenance panel, rumor log, overlays)
- [x] Headless boot check with zero errors
- [x] Integration smoke test (32 checks: full play-through to victory)
- [x] Windowed screenshot check of all four rooms
- [x] Final test run
- [ ] In-editor playtest by Scott (game feel / balance)

## Phase 2: room dressing and sound
- [x] Plan approved (synthesized sounds, swappable via assets/audio overrides)
- [x] DressingLayout planner + RoomDef dressing settings
- [x] FoundryProps catalogs (boiler, cutting, smelting, vault) + grime decals
- [x] Builder integration (exclusions, nav bake, cutaway for wall fixtures, scorch marks)
- [x] Synth + SoundRecipes + SoundLibrary (override files)
- [x] Audio autoload (pools, buses, listener on camera rig, threaded synthesis)
- [x] Gameplay sound hooks + ambience
- [x] Unit tests (106 passing) + smoke test sound/dressing checks
- [x] Screenshots + sound export check
- [x] Listening/playtest by Scott (sounds approved)

## Phase 3: campaign (brainstorm round)
- [x] Brainstorm 12 levels before the Great Foundry finale (see level_design.md)
- [x] Decisions: gears carry over, health/steam refill; death restarts the current level; add hound, sentry, drone and steam walker enemies
- [x] Scott picks the first batch (framework + levels 1–3)
- [x] Batch 1: campaign framework + levels 1–3
  - [x] LevelInfo / CampaignDef / data/campaign.tres, CampaignProgress save (user://campaign_save.json), GameState checkpoints
  - [x] Elevator NEXT_LEVEL mode, title screen (main scene), HUD level card
  - [x] SteamDoor ALL_OF + ITEM, KeyPickup, TramCrossing + HazardCycle
  - [x] Clockwork Hound (pack flanking) and Brass Sentry (frontal shield)
  - [x] 9 new sounds; YARD / TRAM / SHOWROOM dressing themes
  - [x] Levels 1–3 built; finale arrival log rewritten
  - [x] Unit tests (145 passing), campaign_smoke_test, capture_screenshots level argument
  - [ ] Scott playtests levels 1–3
    - [x] Feedback: sentry blocks rivets and its back is unreadable. Rivet on the shield now staggers it (shield drops ~1.3 s); a glowing back boiler and brighter floor arc show facing; first sentry seen per level posts a how-to notice; foyer sentry moved deeper; level 3 terminal texts updated
- [x] Batch 2: levels 4–6
  - [x] TideCycle / SequenceLock / SpawnSchedule / HoldProgress logic
  - [x] Water pools, pump valves + sequence, humid zones, enemy nests, wall lanterns, winch, ore-cart style
  - [x] Cistern Warden (3-slam bruiser); turret shorting; rig wear multiplier; terrain slow; lantern + dark levels
  - [x] 10 new sounds; CISTERN / GARDEN / MINE dressing themes
  - [x] Levels 4–6 built and added to the campaign; finale log renumbered
  - [x] Unit tests (165 passing), campaign smoke test runs levels 1–6 to the finale
  - [ ] Scott playtests levels 4–6
- [ ] Batch 3: levels 7–9 (plan written, awaiting approval)
- [ ] Batch 4: levels 10–12 + finale changes
