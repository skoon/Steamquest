# Implementation Plan — "The Golden Gear" (Godot 4.7.1)

## Environment & defaults chosen

- **Engine**: Godot 4.7.1 stable (found at `D:\Games\Godot\Godot_v4.7.1-stable_win64.exe\`), Forward+ renderer. Project root = `D:\source\Steamquest` (the existing `assets/` folder stays untouched).
- **Language**: fully typed GDScript 2.0. No placeholders/TODOs.
- **Tests**: a small self-contained headless test runner (`res://tests/run_tests.gd`, `extends SceneTree`) instead of GUT, so nothing has to be downloaded. Run with:
  `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd` — exits non-zero on any failure.
- **Art**: environment, hazards, doors, Golden Gear etc. are primitives + `StandardMaterial3D`. **Characters are billboarded `AnimatedSprite3D`s** using `assets/sprites` (Technician = `player_woman_athletic` (carries a wrench), Skitterer = `enemy_steam_spider`, Bruiser = `enemy_diver_brute`, Arc Turret = `decor/tesla_coil`). Tileable floor/wall pngs are used as textures on the procedural floors/walls; a few decor pngs (boiler tanks etc.) are billboard props.
- **Level construction**: rooms are built at runtime by a `FoundryBuilder` from a typed layout config (`RoomDef` resources), rather than hand-writing thousands of lines of `.tscn` geometry. Navigation mesh is baked at runtime after geometry is built. Doors, terminals, pedestals, enemies and hazards are real `.tscn` scenes instanced by the builder.

## Architecture

Logic that needs testing is kept in plain, side-effect-free classes; nodes only call into them.

| Layer | Files | Responsibility |
|---|---|---|
| Pure logic | `scripts/resources/gear_item.gd`, `scripts/logic/friction_model.gd`, `scripts/logic/damage_calc.gd`, `scripts/logic/steam_pressure.gd` | All math: friction/wear accumulation, penalty multipliers, jam/shatter, damage + knockback, pressure spend/regen |
| Config | `scripts/config/*.gd` resources (`TechnicianStats`, `EnemyStats`, `RoomDef`) + `.tres` instances in `data/` | Tunable numbers (prefer configuration over hardcoding) |
| State | `scripts/autoload/game_state.gd` (autoload `GameState`) | Rumors found, socketed gears, Golden Gear status, unlocked doors; emits the global signals |
| Scenes | player, enemies, world pieces, HUD | Behaviour + presentation |

### Signals (HUD only listens, never polls scenes)
`health_changed(current, max)`, `pressure_changed(current, max)`, `friction_updated(total_friction, worst_wear_pct)`, `gears_changed(gears)`, `rumor_discovered(rumor_id)`, `golden_gear_acquired()`, `door_unlocked(door_id)`, `player_died()`, `victory()`. Emitted via `GameState` so the HUD has no reference to 3D nodes.

### Physics layers (named in `project.godot`)
1 Environment/Walls · 2 Player · 3 Enemies · 4 PlayerHitboxes/Projectiles · 5 Interactables. Enemy projectiles/slam hitboxes use mask 2 (Player) + 1 (walls).

## Wear & Friction model (concrete rules)

- Technician rig has **3 sockets**: `DRIVE` (movement/dash), `ARM` (wrench/rivet gun), `PUMP` (steam regen). Each holds a `GearItem`.
- `GearItem`: `gear_name`, `friction_rate`, `wear_rate`, `durability` (0–100), `max_durability`, `friction` (current, 0–`MAX_FRICTION`), `is_golden_gear`, plus `state` (OK / JAMMED / SHATTERED).
- `apply_work(work: float)`: `friction += friction_rate * work` (clamped), `durability -= wear_rate * work * (1 + friction)` — friction accelerates wear.
- **Penalty multiplier** per socket: `1.0 / (1.0 + friction)` (≥ ~0.4 at max friction). DRIVE → move speed, ARM → attack speed, PUMP → steam regen.
- **Jam**: below 25% durability, each work tick has a deterministic-seedable chance to jam (socket gives 0 output until bashed free via the utility vent). **Shatter** at 0 durability — socket is empty until a scavenged gear is picked up.
- Friction passively cools slowly when idle.
- **Lubricant Vent / Overclock** (utility, cooldown): resets friction on all non-golden gears to 0, un-jams, grants 4 s of +35% move/attack speed.
- **Golden Gear**: `friction_rate = 0`, `wear_rate = 0`, never jams/shatters. Acquiring it socketing into ARM, sets `GameState.golden_gear_acquired = true`, which **disables all friction penalties globally**, permanently applies a mild overclock, and unlocks the Master Clock Vault elevator.
- Enemies have a chance to drop **scrap gears** (random rates within config ranges); picking one up auto-replaces the most worn/broken socket.

## Gameplay systems

- **Camera rig**: `Node3D` pivot lerps to player; child yaw node (45° + 90° steps, smooth tween on `Q`/`E`), pitch -35.264°, orthogonal `Camera3D` with scroll-wheel zoom between configured min/max `size`.
- **Technician** (`CharacterBody3D`): camera-relative WASD; steam dash (Space) costs pressure, brief i-frames; aim = mouse ray ∩ `Plane(Vector3.UP, global_position.y)`; body yaw snaps to aim.
  - Wrench (LMB): `Area3D` arc hitbox enabled for a short window, damage + knockback, also bashes `JammedValve`s.
  - Rivet gun (RMB): spawns `rivet.tscn` `Area3D` projectile, costs pressure.
  - Health, pressure, gear work applied per action (move distance → DRIVE, swings/shots → ARM, regen → PUMP).
- **Enemies** (`CharacterBody3D` + `NavigationAgent3D`, shared `enemy_base.gd`, configurable `EnemyStats`):
  - *Scrap Skitterer*: fast, low HP, rush + contact bite with cooldown.
  - *Piston Bruiser*: slow, high HP, approaches; at range telegraphs (glowing red ground ring grows ~1 s) then AoE slam.
  - *Arc Turret*: stationary, rotates toward player with line-of-sight check, fires timed lightning bolts.
  - Hit flash, knockback, death spark burst, possible scrap-gear drop.
- **World pieces**: `rumor_terminal.tscn` (interact → log popup + tracker), `steam_door.tscn` (locked until condition: valve bashed / rumor read / golden gear), `jammed_valve.tscn`, `golden_gear_pedestal.tscn`, `rotating_cog.tscn` (decor + optional damage hazard), `furnace.tscn` (flickering `OmniLight3D` + burn zone), `steam_vent.tscn` (`GPUParticles3D`, periodic damage burst), `elevator.tscn` (victory trigger), `gear_pickup.tscn`.
- **Level flow**: Boiler Room (tutorial, terminals explain controls/lore) → valve-locked door → Gear Cutting Floor (skitterers, cogs) → rumor-locked door → Smelting Vats (bruisers, turrets, furnaces) → Golden Gear pedestal → elevator door unlocks → Master Clock Vault → victory screen. Death → restart prompt.
- **Atmosphere**: `WorldEnvironment` with warm ambient, glow, volumetric fog; furnace flicker script; steam & spark particles.
- **HUD** (`CanvasLayer`): health bar, steam pressure gauge (radial dial drawn via `_draw`), friction/wear indicator, gear socket maintenance panel (toggle `G`, shows each socket's gear, friction, wear %, state), rumor/blueprint log popup (toggle `Tab`, and auto-opens on terminal read), interaction prompt, death/victory overlays.

## Input map (`project.godot`)
Spec actions: `move_up/down/left/right` (WASD), `attack_primary` (LMB), `attack_secondary` (RMB), `interact` (E... conflicts with camera — see below), `rotate_cam_left` (Q), `rotate_cam_right` (E).
Since `E` is camera-right, **`interact` = F**. Additional actions I'm adding: `dash` (Space), `ability_utility` (R), `toggle_log` (Tab), `toggle_maintenance` (G), `zoom_in/zoom_out` (wheel).

## File layout
```
project.godot, icon.svg
scripts/autoload/game_state.gd
scripts/resources/gear_item.gd
scripts/logic/{friction_model,damage_calc,steam_pressure}.gd
scripts/config/{technician_stats,enemy_stats,room_def}.gd
data/*.tres   (stats configs, starting gears, golden gear)
scenes/player/{technician.tscn,technician.gd,camera_rig.gd,rivet.tscn,rivet.gd}
scenes/enemies/{enemy_base.gd,scrap_skitterer.*,piston_bruiser.*,arc_turret.*,lightning_bolt.*}
scenes/world/{foundry_level.tscn,foundry_builder.gd,rumor_terminal.*,golden_gear_pedestal.*,rotating_cog.*,steam_door.*,jammed_valve.*,furnace.*,steam_vent.*,elevator.*,gear_pickup.*}
scenes/ui/{hud.tscn,hud.gd,pressure_gauge.gd}
tests/{run_tests.gd,test_case.gd,test_gear_item.gd,test_friction_model.gd,test_damage_calc.gd,test_steam_pressure.gd,test_game_state.gd}
```

## Verification
1. Headless unit tests pass (gear math, penalties, jam/shatter, golden-gear immunity, damage/knockback, pressure, GameState signals/rumors).
   `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd`
2. Integration smoke test plays the level headless end to end (movement wear, enemy aggro/attacks, wrench, rivets, valve, rumor door, scrap pickup, Golden Gear, vault, elevator victory).
   `Godot_v4.7.1-stable_win64_console.exe --headless --path . res://tests/integration/smoke_test.tscn`
3. Screenshot tool for visual checks: `Godot_v4.7.1-stable_win64.exe --path . res://tests/integration/capture_screenshots.tscn -- <out_dir>`
4. Hand off for an in-editor playtest (game feel can't be judged headlessly).

## Decisions (approved)
1. Pixel sprites used as billboarded characters.
2. `interact` on F because `E` is camera rotation per spec.
3. Custom headless test runner (no GUT download).

---

# Phase 2: Room dressing and procedural sound (approved)

## Room dressing
- `RoomDef` gains `dressing_theme` (BOILER / CUTTING / SMELTING / VAULT), `dressing_seed`, `clutter_density` and `grime_density`, which are set per room in `foundry_level.tscn`.
- `scripts/logic/dressing_layout.gd` (`DressingLayout`, pure and unit-tested) plans the clutter:
  - **Large props** sit in a band 0.6–2.2 m from the walls and face into the room.
  - **Wall fixtures** sit on the wall surface.
  - **Floor scatter** (no collision) can go anywhere.
  - Nothing overlaps, and nothing enters an exclusion circle.
- `scenes/world/foundry_props.gd` (`FoundryProps`) holds the per-theme catalogs and builds every prop from primitive meshes. Blocking props add Environment-layer colliders, so the navmesh routes around them.
- `scripts/core/grime_textures.gd` (`GrimeTextures`) generates decal textures from noise: oil, soot, puddles, scorch, and rust or soot streaks.
- **Builder integration:** `FoundryBuilder._build_dressing` runs before the nav bake.
  - **Exclusions:** each direct child of the `keep_clear_roots` containers (Doors, Interactables, Hazards, Props, Enemies), the player start, door lanes and pillars. *Deviation from the plan:* I used container roots instead of a `keep_clear` group, so no scene scripts needed editing.
  - **Cutaway:** wall fixtures and streak decals hide with their wall when it's cut away.
  - **Scorch:** marks are added under every furnace mouth and vat.

## Sound
- `scripts/audio/synth.gd` (`Synth`, pure and unit-tested) provides noise, sine and saw sweeps, inharmonic bells, RBJ biquads, envelopes, mixing, normalize, seamless crossfaded loops, and 16-bit WAV encoding.
- `scripts/audio/sound_recipes.gd` (`SoundRecipes`) has one recipe per id. The `SOUNDS` table holds each id's volume, bus, loop flag and peak.
- `scripts/audio/sound_library.gd` (`SoundLibrary`) checks for `res://assets/audio/<id>.ogg|.wav` and uses that file instead of the synth if it exists. Overrides for looping ids are forced to loop.
- **Autoload `Audio`** (`scripts/autoload/audio.gd`):
  - holds pooled 3D and UI players;
  - provides `play_at`, `play_ui`, `make_loop_player`, `stop_all`;
  - emits `sound_played(id)`.
  - Synthesis (about 1.7 s) runs on a WorkerThreadPool task while the level loads; the first request for a sound waits for it.
  - *Deviation from the plan:* buses (SFX with light reverb, Ambience, UI) and a Master hard limiter are created in code rather than in a `default_bus_layout.tres`. Existing buses with those names are kept.
- **Listener:** `AudioListener3D` sits on the camera rig's yaw node at the follow pivot. Distances are measured from the Technician, and panning turns with the camera.
- **Hooks:** wrench (whoosh, BONG on enemy hits, clang on valves), rivets, dash, vent, player hurt, enemy footsteps (`EnemyBase.step_sounds` on walk frames, throttled), bruiser slam, turret charge/zap, enemy death, vent loop / warning whistle / burst, furnace loop, doors, valve, terminals, pickups, Golden Gear chime.
- **Ambience:** `scenes/world/ambience.gd` plays a looping rumble plus random distant whistles and clanks.

## Phase 2 verification
- Unit tests: `test_dressing_layout`, `test_grime_textures`, `test_foundry_props`, `test_synth`, `test_sound_library`.
- Smoke test: every room is dressed (at least 8 props), and the key sounds fire during the play-through.
- Sound export tool: `Godot_console.exe --headless --path . --script res://tests/integration/export_sounds.gd -- <out_dir>`
- Screenshots of all four rooms.

---

# Phase 3, batch 1: campaign framework + levels 1–3 (approved, built)

**Deviations from the plan as written:**
- SteamDoor ALL_OF/ITEM logic is unit-tested through static `all_unlocked` / `count_unlocked` helpers; the instanced doors are covered by `campaign_smoke_test`.
- The Workshop Backroom in level 3 uses the existing CUTTING dressing theme rather than SHOWROOM.
- Levels register with GameState in the root's `_enter_tree` (not `_ready`), and `level_started` is emitted deferred, so doors read the fresh or restored state; otherwise doors opened in a failed attempt stayed open after restarting.

Built from [level_design.md](level_design.md). After this batch the game plays end to end: title screen → 1 Guild Dispatch Yard → 2 Pneumatic Tramline → 3 Clockmakers' Row → the Great Foundry finale. Levels 4–12 slot in later by adding entries to the campaign list.

## 1. Campaign framework

**Level list**
- `scripts/config/level_info.gd` (`LevelInfo` resource): `title`, `act_name`, `scene_path`.
- `scripts/config/campaign_def.gd` (`CampaignDef` resource): `levels: Array[LevelInfo]`.
- `data/campaign.tres`: the four levels above, in order.

**Progress logic** in `scripts/logic/campaign_progress.gd` (`CampaignProgress`), pure and unit-tested:
- Level index arithmetic: `next_index`, `is_final`, `index_of_scene`.
- Snapshots: rig to and from a Dictionary, keeping each gear's name, rates, durability, friction and jam/shatter state. Discovered rumors to and from a Dictionary (id, title, body, hint), so the log survives a reload.
- Save files: `save(path)` and `load(path)` read and write JSON. The path is injected so tests can use `user://`.

**`GameState` additions** (existing behaviour unchanged):
- **State:** `level_index`, a per-level `items` set (for the wind-up key) and `checkpoint: Dictionary`.
- **`begin_level(index)`:**
  - Called by the level root on load. It clears doors and items, snapshots the rig and rumors as the checkpoint, and writes the save to `user://campaign_save.json`.
  - Health and steam refill without extra work, because the Technician is rebuilt with every scene.
- **`complete_level()`:** emits `level_completed`, then changes scene to the next level. The rig and rumor log stay in memory, so gears carry their wear forward.
- **`restart_level()`:** restores the checkpoint, then reloads the current scene. Death therefore puts gears back the way they were when you entered.
- **`new_campaign()` / `continue_campaign()`:** used by the title screen. Winning the finale deletes the save.
- **Running a level scene directly** (from the editor or a test) looks the level up in the campaign by its scene path, so every level is still runnable on its own.

**Level root:** `scenes/world/foundry_level.gd` becomes the shared root script for every level. It already builds the level and adds ambience. It now also calls `begin_level`, and its restart calls `GameState.restart_level()`.

**Elevator:** `elevator.gd` gains `exit_mode`:
- `VICTORY`, the current behaviour, used by the finale.
- `NEXT_LEVEL`, which is always active. Its lamp is lit, and stepping on it plays a new `lift_rise` sound, fades out and calls `complete_level()`.

**Title screen:** `scenes/ui/title_screen.tscn` becomes the new main scene. It has New Game, Continue (only shown if a save exists) and Quit, built in code like the HUD.

**HUD:**
- A level-intro card ("Act I · Level 2 / Pneumatic Tramline") fades in on level start.
- The death overlay reads "Press Enter to restart this level".
- The victory overlay offers "Press Enter to return to the title".

## 2. New doors and items
- **`SteamDoor` gains two conditions:**
  - `ALL_OF` (`required_unlock_ids`): opens once every listed id is unlocked. Two valves each unlock their own id.
  - `ITEM` (`required_item_id`): opens from the lock panel if you carry the item. The prompt is "[F] Wind the clockwork door".
- **`scenes/world/key_pickup.gd/.tscn`** (`KeyPickup`): uses the `wind_up_key.png` sprite, spins and bobs like a gear pickup, and adds its `item_id` to `GameState.items`.

## 3. Hazard: tram crossing (level 2)
- **Timing logic:** `scripts/logic/hazard_cycle.gd` (`HazardCycle`, pure and tested) maps time to IDLE / WARNING / ACTIVE with a phase offset. `steam_vent.gd` is left as it is.
- **`scenes/world/tram_crossing.gd/.tscn`** (`TramCrossing`):
  - **Track and car:** rails and sleepers across the room (along Z), and a tram car built from boxes and brass trim that runs the length of the track each cycle.
  - **Warning:** lamps on both walls flash and a bell rings during WARNING.
  - **Danger:** the car's Area3D hits the Technician and enemies for heavy damage and a sideways knockback, once per pass per body.
  - **Navigation:** the track is ordinary floor, so enemies can wander onto it and get hit.
  - **Exports:** `interval`, `warning_time`, `pass_time`, `damage`, `knockback`, `phase_offset`, `track_length`.

## 4. New enemies
**Clockwork Hound** (`scenes/enemies/clockwork_hound.gd/.tscn`, `data/enemies/clockwork_hound_stats.tres`, `enemy_clockwork_hound` sprites):
- **Chase:** fast and fairly fragile.
- **Circle:** within about 6 m it stops rushing and circles the Technician at about 4 m. Each hound in a pack takes a different orbit slot, using its index among the aggro hounds, so a pack spreads around you.
- **Lunge:** when its cooldown is ready and it's roughly beside or behind your aim, it lunges and bites, reusing the skitterer's lunge pattern.
- **Logic:** slot angles and flank checks live in `scripts/logic/pack_tactics.gd` (`PackTactics`, pure and tested).

**Brass Sentry** (`scenes/enemies/brass_sentry.gd/.tscn`, `data/enemies/brass_sentry_stats.tres`, `enemy_brass_sentry` sprites):
- **Movement:** slow and armoured. It turns toward you at a limited rate (exported `turn_speed`), which is what lets you dash around it.
- **Shield:** it blocks any hit arriving within ±60° of its facing. Blocked hits deal no damage, throw sparks, play `sentry_shield` (a short high clang, so it's clearly not the BONG) and post the notice "Its shield turns the blow. Get behind it."
- **How the hit direction is known:** it comes from the knockback vector that every hit already carries, so the wrench, rivets and trams all work without touching the Technician.
- **Attack:** a telegraphed bayonet thrust in a short line in front of it.
- **Logic:** `DamageCalc.is_blocked_by_shield(facing, incoming, arc_degrees)`, pure and tested.

**Sounds:** new recipes in `SoundRecipes`: `hound_step`, `hound_lunge`, `sentry_step`, `sentry_shield`, `sentry_thrust`, `tram_bell`, `tram_rush`, `key_pickup`, `lift_rise`. All can be replaced by a file the same way as the existing sounds.

## 5. Dressing themes
- **`RoomDef.DressingTheme`** gains YARD, TRAM and SHOWROOM.
- **`FoundryProps`** gets a catalog for each:
  - **YARD:** crates, mail sacks, a hand cart, lamp posts, a dispatch desk, pallets, rope coils; scatter of straw and letters.
  - **TRAM:** benches, a ticket booth, signal lamps, timetable boards, pipe runs, rail sleepers; scatter of tickets and grit.
  - **SHOWROOM:** display cases with gear exhibits, pedestals with clocks, wall clocks and placards, and furniture from the existing decor sprites (sofa, armchair, cabinet, bookcase, grandfather clock) as billboard props; scatter of glass shards and fallen cogs.
- **Grime is lighter in the showroom:** dust and broken glass, not soot.

## 6. The levels
Each level is a `.tscn` laid out like `foundry_level.tscn`: a `FoundryBuilder` with `RoomDef`s, and Doors, Interactables, Hazards, Props and Enemies containers. Rooms run west to east.

**Level 1: Guild Dispatch Yard** (`scenes/levels/level_01_dispatch_yard.tscn`)
- **Rooms:** Loading Yard (stone slab, brick) → Guild Office (wood planks, wood panel) → Tram Platform (stone, cellar brick).
- **Story and tutorial terminals:**
  - the briefing, which is the current "Dispatch #1" text and controls hint, moved here;
  - a valve memo;
  - a rivets-and-vent primer;
  - a missing-persons notice.
- **Enemies:** two skitterers in the yard and three in the office, plus a scrap-gear cache.
- **Gates:** a valve door between the yard and the office; an open door to the platform. The exit elevator is on the platform.

**Level 2: Pneumatic Tramline** (`scenes/levels/level_02_tramline.tscn`)
- **Rooms:** Station Concourse → Tram Tunnel (long, with two tram crossings at different offsets) → Signal Hall → Freight Lift.
- **Enemies:**
  - a lone hound in the concourse, so you meet the circling behaviour safely;
  - a pack of three in the tunnel, which the trams can thin out;
  - skitterers and one arc turret in the signal hall.
- **Gate:** the Freight Lift door is `ALL_OF`, needing the concourse valve and the signal-hall valve.
- **Story:** two terminals.

**Level 3: Clockmakers' Row** (`scenes/levels/level_03_clockmakers_row.tscn`)
- **Rooms:** Showroom Foyer (checker marble, striped wallpaper) → Gallery of Clocks → Workshop Backroom (parquet, wood panel) → Service Lift.
- **Enemies:**
  - one sentry alone in the foyer, to teach getting behind it;
  - two sentries and two hounds in the gallery;
  - a sentry pair and a bruiser guarding the wind-up key in the backroom.
- **Gate:** the backroom → lift door is `ITEM` (winding key).
- **Story:** advertising placards for "Hargreaves' Perpetual Engine".

**Finale** (`foundry_level.tscn`):
- Its arrival terminal is rewritten as "Dispatch #4: The Great Foundry", without the controls hint, which now lives in level 1.
- Its elevator stays on `VICTORY`.
- Adding new enemy types to the finale waits for batch 4, as planned.

## Tests
- **New unit tests:**
  - `test_campaign_progress`: index arithmetic, rig and rumor snapshot round trips (including jammed and shattered gears), save/load round trip through `user://`, and a missing save reporting cleanly.
  - `test_hazard_cycle`: phase boundaries and offsets.
  - `test_pack_tactics`: distinct orbit slots, flank detection.
  - `DamageCalc` shield-block cases.
  - `test_game_state` additions: begin, complete and restart restore the checkpoint; items reset per level.
  - `SteamDoor` `ALL_OF` and `ITEM` conditions, tested on instanced nodes.
- **Extended automatically:** `test_foundry_props` covers the three new themes, and the sound library tests cover the new ids.
- **New `tests/integration/campaign_smoke_test.gd/.tscn`**, which plays levels 1–3 headless:
  - **Each level builds and dresses:** at least 8 props per room.
  - **Level 1:** its valve gate.
  - **Level 2:** a tram hits the Technician during its pass and not outside it; both valves are required.
  - **Level 3:** a frontal wrench hit on a sentry does no damage while a hit from behind does; the key opens the door.
  - **Hounds:** a hound pack takes distinct flanking positions.
  - **Exits:** the elevator loads the next level, gear wear carries over and health refills; death restores the checkpoint rig; level 3's exit loads the finale.
- **Existing smoke test:** still runs the finale directly and must still pass.
- **Screenshots:** `capture_screenshots` takes an optional level scene argument, so I can shoot the new rooms.

## Verification
1. Import (new class names), then run the unit tests, both smoke tests and the sound export.
2. Take windowed screenshots of every new room, review them, and send them to Scott.
3. Not verifiable by me: how the hound and sentry fights feel, tram timing, and the sound of the new effects. Those are for Scott's playtest.


# Phase 3, batch 2: levels 4–6 (approved, built)

**Deviations from the plan as written:**
- No farm-tileset atlas sprites were used. The garden props (planters, trellises, water tanks, produce crates) and the CART-style ore car are procedural meshes, because slicing exact regions out of the farm sheets would have been guesswork.
- 10 new sounds rather than 9: `humid_hiss` was added for entering a humid zone. The Warden's `warden_roar` plays when it starts a slam combo.
- The Warden's 1.4× size comes from a larger sprite and collider in `cistern_warden.tscn` (an inherited Piston Bruiser scene), not from scaling the node.
- Room darkness in level 6 comes from low room light energies in the level data plus `dark_level` dimming the ambient light and sun.

## Context
Batch 1 built the campaign framework and Act I's first three levels. This batch adds the last Act I level (the Flooded Cisterns) and the first two Act II levels (the Steam Gardens and the Coal Seam), following `level_design.md`. Each level introduces one new idea, reuses the batch 1 framework, and ends at an exit lift. After it, the campaign reads: levels 1–6, then the Great Foundry.

## Defaults I picked (tell me to change any)
- **Water is a slow tide.** Each pool rises and falls on a smooth cycle of about 14 s, not on a switch.
- **Deep water:**
  - slows the Technician to 60%;
  - doubles DRIVE wear per metre;
  - slows enemies too;
  - turns off any Arc Turret standing in it.
- **Pump order is fixed per level.** A terminal gives the order. A wrong valve resets the sequence and forces one full flood cycle in the pump hall.
- **The Cistern Warden** is a Piston Bruiser variant built from its own stats file, about 1.4× the size. It slams three times in a row with shorter telegraphs between slams. For now there's no boss health bar; that comes with the level 12 boss.
- **Humid zones double wear on every socket** while you stand in them. A visible mist marks each zone.
- **Nests:**
  - each one spawns until it's destroyed, capped at 3 living spawns;
  - a nest takes wrench and rivet hits (HP 90);
  - each destroyed nest counts toward the exit door, reusing batch 1's ALL_OF door.
- **Darkness is level-wide in level 6:**
  - near-zero ambient light and very dim room lights;
  - the Technician carries a lantern light about 6 m across;
  - wall lanterns light permanently (for that attempt) when you press F or hit them.
- **Ore carts** reuse `TramCrossing` with a new `style` setting (CART): a smaller, faster car, lower damage, and a rumble instead of a bell.
- **Winch defence:**
  - bash the seized winch free (3 hits), then stay within 6 m while it winds for 40 s;
  - progress pauses (it doesn't drain) while you're away;
  - enemies come in waves from fixed spawn points while it winds;
  - the lift door opens when winding finishes.

## Level by level

### Level 4: Flooded Cisterns (Act I)
- **Rooms:**
  - Intake Gallery (16×14): stone, grate;
  - Settling Tanks (24×18): two tidal pools and the Warden;
  - Pump Hall (20×18): three pump valves and the order terminal;
  - Outflow Lift (12×12).
- **Enemies:** skitterers and a bruiser at the intake; two Arc Turrets standing in the tank pools; the Cistern Warden in the Settling Tanks; hounds in the Pump Hall.
- **Gate:** turn three pump valves in the order the terminal gives.
- **Pickups:** a guaranteed scrap-gear cache in the Pump Hall.
- **Story:** two rumor logs: the cistern keeper's flood log, and a work order for "Hargreaves' sealed project".

### Level 5: Steam Gardens (Act II opens)
- **Rooms:**
  - Greenhouse Atrium (18×16): one humid zone;
  - Hydroponic Rows (26×16): two humid zones, planters, and 2 nests;
  - Pump Shed (16×14): 1 nest;
  - Garden Lift (12×12).
- **Enemies:** skitterers and hounds coming out of the nests, plus one sentry guarding the shed.
- **Gate:** destroy all 3 nests.
- **Story:** the canteen menu from the night it went quiet, and a gardener's note about automatons "tending the rows with no one to feed".

### Level 6: Coal Seam & Mine Lift
- **Rooms:**
  - Lamp Room (14×14): the lantern tutorial terminal;
  - Coal Face (24×16): an ore cart crossing and wall lanterns;
  - Cart Junction (20×16): two ore cart crossings;
  - Winch House (18×18): the winch defence;
  - Mine Lift (12×12).
- **Enemies:** skitterers in the dark, hounds at the junction, and waves at the winch (skitterers, hounds, then a bruiser).
- **Gate:** free and wind the winch.
- **Story:** a shift roster with every name crossed out, and the first hint that "the Gear" is guarded on purpose.

## New code

**Pure logic** (`scripts/logic/`, each fully unit-tested):
- `TideCycle`:
  - `level_at(t)`, a smooth 0..1 level;
  - `is_deep(t, threshold)`;
  - `forced_flood(until)` support.
- `SequenceLock`: `press(id)` returns PROGRESS, WRONG or SOLVED; `reset()`; `progress()`.
- `SpawnSchedule`: `should_spawn(time_since_last, alive)`, using an interval and a max-alive cap.
- `HoldProgress`: `tick(delta, in_range) -> progress`, with a rate; it pauses when you're out of range and completes at 1.

**World scenes** (`scenes/world/`):
- `water_pool`: an Area3D plus a translucent water plane driven by TideCycle. In deep water it slows bodies inside it, adds DRIVE work, and disables turrets. `flood_for(seconds)` forces a flood.
- `pump_valve` and `pump_sequence`:
  - pump valves are F-interact valves that report to a `PumpSequence` node holding the SequenceLock;
  - when solved, the sequence calls `GameState.unlock_door`;
  - a wrong valve floods the linked pools.
- `humid_zone`: an Area3D with mist particles. It sets a wear multiplier on the rig while the Technician is inside it.
- `enemy_nest`:
  - a destructible mound (sprite and mesh) with HP;
  - it spawns enemy scenes from a list on a SpawnSchedule, but only while the Technician is within aggro range;
  - destroying it unlocks its `unlock_id`.
- `wall_lantern_switch`: lit with F or the wrench; when lit it adds an OmniLight.
- `winch`: bash it free, then a HoldProgress wind. It shows a Label3D meter and spawns waves from its child Marker3D spawn points; when finished it unlocks a door.
- `tram_crossing`: add `style` (TRAM or CART). The CART style is a smaller car built from an ore-cart atlas region of the farm tileset, with its own sounds.

**Small changes to existing code:**
- `FrictionModel`: add `wear_multiplier` (default 1.0), applied in `apply_work`. Add `slow_multiplier` hooks for the Technician and `EnemyBase` (a speed factor the pools set and clear).
- `ArcTurret`: add `disabled` (no shots, a dimmed sprite) for flooded turrets.
- `PistonBruiser`: add `combo_slams` (default 1) and `combo_gap`. The Warden sets 3.
- `Technician`: add an optional lantern light (`set_lantern(enabled)`). Levels switch it on through a new level-root export, `dark_level`.
- Level root (`foundry_level.gd`): add `dark_level`, which dims the environment and room lights and turns on the lantern.
- `RoomDef.DressingTheme`: add CISTERN, GARDEN and MINE. Each gets a catalog and grime mix in `foundry_props.gd`:
  - cistern: pump engines, valve manifolds, puddles, buckets, chains;
  - garden: planters, trellises, watering pipes, crates of produce, and silos and water towers from the farm tileset;
  - mine: coal piles, slag, timber props, rail ends, pick racks, mine carts.
- **New data:**
  - `data/enemies/cistern_warden_stats.tres` and `scenes/enemies/cistern_warden.tscn`;
  - three level scenes in `scenes/levels/`;
  - `data/campaign.tres` gains levels 4–6 before the finale;
  - the finale arrival log is renumbered to "Dispatch #7".

**New sounds** (all synthesized, about 9): water_slosh, pump_clunk, sequence_wrong, warden_roar, nest_pulse, nest_break, cart_rumble, winch_crank, lantern_light.

## Tests
- **Unit tests:**
  - TideCycle;
  - SequenceLock: right order, wrong order resets, solved stays solved;
  - SpawnSchedule;
  - HoldProgress;
  - FrictionModel wear_multiplier;
  - `test_foundry_props` covers the three new themes;
  - campaign order covers six levels plus the finale.
- **`campaign_smoke_test`:**
  - Extended to levels 4–6. Each level gets the nav and dressing checks.
  - Level 4: deep water slows the Technician and switches a turret off; a wrong pump order floods the hall, and the right order opens the door.
  - Level 5: a humid zone wears gears faster; a nest spawns no more than its cap; destroying all three nests opens the door.
  - Level 6: the lantern is on; an ore cart hits on the rails; the winch only winds while you're nearby, and finishing it opens the lift door.
  - Exit chain: 1 → 2 → … → 6 → finale.

## Verification
1. Import, then run the unit tests, both smoke tests and the sound export.
2. Capture screenshots of every new room with the level argument, review them (especially that the darkness is readable), and send them.
3. Left for your playtest: tide timing, Warden difficulty, how tense the winch defence is, and whether the darkness is atmospheric or just annoying.


# Phase 3, batch 3: levels 7–9 (approved, built)

**Deviations from the plan as written:**
- **Tesla Drone reach:** the drone's collision column runs from 0.6 m to 2.5 m and stays fixed while only its sprite bobs, so rivets (fired at chest height) can hit it. The wrench can therefore reach a drone at any time if you get close, not only when it swoops. In practice it keeps 6–8 m away, so the rivet gun is still the answer. A coil-stunned drone sinks to the floor.
- **One fall zone per level:** a single large catch volume below the whole level, not one under each railing gap. The behaviour is the same.
- **No wind streak particles:** gusts are shown by the windsock (hangs limp, snaps taut on the warning, streams during the gust) plus the whistle and gust sounds.
- **Tesla coils are rivet-only.** They sit on the environment layer, which the wrench doesn't hit.
- **Plates:** the Switch Room sections are single plate banks wired to the router (live or dead), not swept patterns. The sweeping banks are in the Insulator Gallery and the Coil Hall.
- **Extra pure-logic helper:** `RailingLayout` splits a deck edge into railing spans around its gaps (unit-tested).
- **Bug fixed along the way:** pushes (wind, propeller wash) were building up in the Technician's velocity from frame to frame. `technician.gd` now strips last frame's push back out, the way it already did for knockback, and a smoke check confirms the Technician stops drifting after a gust.


## Context
Batches 1 and 2 built levels 1–6. This batch finishes Act II with the Airship Mooring Tower and the Blueprint Archive, and opens Act III with the Tesla Generator Hall. It also adds the third new enemy, the Tesla Drone. After it the campaign runs levels 1–9, then the Great Foundry.

## Defaults I picked (tell me to change any)
- **Open-air decks (level 7):**
  - instead of walls, a deck room gets a waist-high brass railing that blocks movement, with a few marked gaps;
  - through a gap is a long drop;
  - an automaton that falls is destroyed;
  - if you fall, you lose 30 hull and are winched back up to the entrance of the room you fell from, rather than dying outright.
- **Wind gusts:**
  - on a cycle (about 9 s), a windsock and a whistle warn you for 1.5 s;
  - then a 2 s gust pushes everyone on the deck one way, toward the edges;
  - you can lean into it, and dashing beats it;
  - enemies near a gap get blown off, which is the reward for timing your fights.
- **Propellers:** spinning hazards at deck level that hurt and shove whatever touches them, built like the hazard cogs. They use the `propeller` sprite on a hub.
- **Tesla Drone:**
  - it flies, hovering about 2 m up and gliding over low clutter, so it doesn't follow the floor routes the walkers use;
  - it keeps 6–8 m away and circles you;
  - it telegraphs a 0.6 s charge, then fires an arc bolt (the existing turret bolt);
  - it has low HP (35), so two or three rivets kill it, and the wrench only reaches it when it swoops low after firing.
- **The level 7 gate:** pull two gangway levers at opposite ends of the deck to lower the gangway (an ALL_OF door).
- **Sight-cone stealth (level 8):**
  - patrolling Brass Sentries walk set routes with a lantern cone (about 8 m long, 50° wide) drawn on the floor;
  - they only spot you inside the cone with a clear line of sight, not by plain distance like everything else;
  - being spotted rings an alarm bell that wakes every dormant Arc Turret in that room;
  - the alarm clears 20 s after no sentry can see you, and the turrets go dormant again;
  - you can sneak past, or fight it out.
- **Blueprint pages:**
  - three pages placed around the archive, picked up like the winding key;
  - the exit opens when all three are collected (an ALL_OF door; each page unlocks its own id).
- **Electrified floor (level 9):**
  - floor plate banks that sweep live in a pattern, row by row, with a 0.8 s blue flicker warning;
  - a live plate hurts the Technician (12 per 0.5 s), and automatons too.
- **Power routing:**
  - three junction switches, each turning between 3 positions with F;
  - the switch positions decide which of three plate sections the surplus current feeds;
  - the exit door opens only when no section on the exit path is live (one correct combination, hinted by a terminal);
  - a wrong combination makes a different section live.
- **Coil overload:** a rivet fired into a Tesla coil overloads it. It discharges an arc that stuns drones within 6 m for 3 s (they drop and the wrench can reach them) and damages turrets. Each coil recharges in 12 s.
- **Gear cache:** a guaranteed cache in level 8, per the brainstorm.

## Level by level

### Level 7: Airship Mooring Tower (Act II)
- **Rooms:**
  - Stair Landing (14×14, indoors): stone and brick;
  - Cargo Deck (26×18, open air): two railing gaps on each long side, and two propellers;
  - Mooring Gantry (20×16, open air): the moored airship sprite, a third propeller, and the two gangway levers;
  - Gangway Lift (12×12).
- **Enemies:** hounds on the landing; drones and skitterers on the Cargo Deck; drones and a sentry on the gantry.
- **Gate:** pull both gangway levers.
- **Story:** the harbourmaster's log of the last airship to leave, and a crate manifest addressed to "the Master, deep works".

### Level 8: The Blueprint Archive (Act II)
- **Rooms:**
  - Reading Room (16×16): parquet, bookcases, and one patrolling sentry;
  - Map Stacks (24×18): two patrolling sentries and two dormant turrets;
  - Drafting Office (18×16): a sentry and a turret;
  - Archive Lift (12×12).
- **Pickups:** three blueprint pages, one per working room, and a scrap-gear cache.
- **Gate:** collect all three pages.
- **Story beat, the big one:** the Master's last order to the automatons, *guard the Gear*, recovered from a phonograph cylinder in the drafting office.

### Level 9: Tesla Generator Hall (Act III opens)
- **Rooms:**
  - Insulator Gallery (16×14);
  - Coil Hall (26×18): plate banks, two coils, drones;
  - Switch Room (16×14): three junction switches and the routing terminal;
  - Generator Lift (12×12).
- **Enemies:** drones and turrets, with skitterers early on.
- **Gate:** route the power so no section on the exit path is live.
- **Twist:** rivet a coil to stun nearby drones.

## New code

**Pure logic** (`scripts/logic/`, each fully unit-tested):
- `SightCone.can_see(origin, facing, target, range, half_angle)`: geometry only, height ignored; the node adds the line-of-sight ray.
- `AlarmState`: `spot(time)`, `tick(time, seen)`, `is_raised()`, with a quiet period before it clears.
- `PatrolRoute`: loops through points; `next_target(position, arrive_distance)`.
- `GustCycle`: wraps HazardCycle and adds a push direction; `force_at(time)`.
- `PlatePattern`: which plate rows are live or warning at time t for a sweep, with direction and offset.
- `PowerRouting`: maps 3 switch positions (0..2 each) to the live section, and `is_safe(positions)` for the exit.

**World scenes** (`scenes/world/`):
- `wind_zone`: an Area3D over the deck that drives a GustCycle. During a gust it adds a push velocity to the Technician and to enemies. It has a windsock and streaming particle effects, and plays `wind_gust`.
- `fall_zone`: an Area3D under each railing gap. It destroys enemies, and for the Technician applies the fall damage and the respawn at the room entrance.
- `propeller`: a spinning hub with blades, a damage and push area, and the propeller sprite.
- `gangway_lever`: an F-interact lever that unlocks its id.
- Blueprint pages: `key_pickup` gains `unlock_id`, which is also sent to `GameState.unlock_door` on pickup, plus an optional sprite override (a paper sheet).
- `alarm_bell`: a per-room node holding an AlarmState. It rings `alarm_bell` and wakes or sleeps the turrets listed for it.
- `electric_plates`: a bank of floor plates driven by a PlatePattern, with an optional `power_section` that PowerRouting can make live.
- `junction_switch` and `power_router`: switches report to the router, which sets which plate sections are live and unlocks the exit when safe.
- `tesla_coil`: the `tesla_coil` sprite on a plinth. `receive_projectile_hit` overloads it, stunning drones nearby; it then recharges.

**Enemy changes and additions:**
- **New `TeslaDrone`** (`scenes/enemies/tesla_drone.gd/.tscn` and `data/enemies/tesla_drone_stats.tres`): uses the `enemy_tesla_drone` sprites. It hovers, steers directly rather than following floor routes, orbits at range, fires a telegraphed arc bolt, and has a `stun(seconds)`.
- `BrassSentry`: optional `patrol_points` and `sight_cone` mode. A patrolling sentry walks its route until it sees you in its cone, then rings its room's alarm, and its lantern cone shows on the floor. Level 3 sentries are unchanged.
- `ArcTurret`: add `dormant` (asleep until an alarm wakes it). It reuses the `disabled` look from batch 2.
- `EnemyBase`: add `apply_push(velocity)` for wind and propellers, and `fall()`, which destroys the automaton.

**Builder changes:**
- `RoomDef` gains `open_air` and `railing_gaps` (a list of gaps along the two long sides). For open-air rooms, `FoundryBuilder` builds a railing instead of a wall, leaves the gaps open, skips the ceiling pipes and wall-mounted dressing, and drops the floor's outer lip so the edge reads as a drop.
- The level root gains a `sky_color` override for open-air levels.

**New data:**
- `RoomDef.DressingTheme` gains:
  - TOWER: cargo nets, crates, mooring bollards, rope coils, sandbags;
  - ARCHIVE: bookcase and desk sprites, drafting tables, map cabinets, paper stacks;
  - GENERATOR: transformers, insulator stacks, cable reels, cable runs, coil sprites as decor.
- Three level scenes; `data/campaign.tres` gains levels 7–9; the finale log is renumbered to "Dispatch #10".

**New sounds** (about 9): wind_gust, wind_warning, propeller_whirr, drone_hum, drone_zap, alarm_bell, plate_crackle, switch_clunk, coil_overload. Page pickup reuses `key_pickup`.

## Tests
- **Unit tests:**
  - SightCone, AlarmState, PatrolRoute, GustCycle, PlatePattern and PowerRouting;
  - the three new themes in `test_foundry_props`;
  - campaign order covers nine levels plus the finale.
- **`campaign_smoke_test`, extended to levels 7–9:**
  - Level 7: a gust pushes the Technician; a skitterer pushed through a railing gap falls and dies; a fall costs 30 hull and returns you to the room entrance; a propeller hurts; both levers open the gangway; a rivet kills a drone.
  - Level 8: a sentry doesn't spot you behind it or out of its cone, but does inside it; spotting raises the alarm and wakes the room's turrets; the alarm clears after the quiet period; three pages open the exit.
  - Level 9: a plate row hurts only while live; a wrong routing makes a different section live; the safe combination opens the exit; a rivet into a coil stuns a nearby drone.
  - Exit chain: 1 → … → 9 → finale.

## Verification
1. Import, then run the unit tests, both smoke tests and the sound export.
2. Capture screenshots of every new room, especially the open decks and the sight cones, review them, and send them.
3. Left for your playtest: gust strength, whether falling feels fair, how hard the drones are, how readable and fair the stealth is, and how long the plate sweeps take.


# Phase 3, batch 4: levels 10–12 + finale changes (built under the "finish batch 4" goal)

Scott set the goal "finish batch 4", so this plan is written down and built straight away instead of waiting for a separate approval. The defaults below are the ones to push back on after playtesting.

**Built.** 189 unit tests pass; the campaign smoke test runs levels 1–12 into the finale; the finale smoke test passes with the extra enemies; 67 sounds export.

**Deviations from the plan as written:**
- **Walker plating:** the half-damage plating applies from phase 2 onward (the plan lists it under phase 2). In phase 1 the Walker takes normal damage, so the opening isn't a slog.
- **The Walker tramples automatons:** it doesn't collide with other automatons, so its own adds can't stop a charge. It still collides with walls and the Technician.
- **Breath numbers:** the plan gave no damage figure. The cone is 9 m long and ±14° wide, and deals 18 damage every 0.4 s to anyone it sweeps over.
- **Room pressure starts at 25%**, not zero, so the first warning comes about 30 s into the level rather than 47 s.
- **Level 10 enemies:** the line's skitterers, two skitterers in the Parts Store, two bruisers and a turret. I first built a hound, a sentry and a drone in place of the second bruiser, and corrected it at verification.
- **Engine shutdown crash:** one of four campaign smoke runs segfaulted while Godot was shutting down, after every check had passed and the "PASSED" line was printed. The other three exited cleanly. The existing "ObjectDB instances leaked at exit" warning appears on every run.

## Context
Batches 1–3 built levels 1–9. This batch finishes Act III: the Automaton Assembly Line, the Pressure Exchange and the Engine Yard boss fight against the Steam Walker. It also makes the finale changes from `level_design.md`. After it the campaign runs levels 1–12, then the Great Foundry.

## Defaults I picked (tell me to change any)
- **Conveyors (level 10):** belts push everything standing on them (the Technician and automatons) at about 3 m/s along the belt. Walking against a belt is slow but possible.
- **Stamping presses:** each press works on a beat (HazardCycle): a hiss and a shaking head as a warning, then the head slams down. Anyone under it takes 35 damage and is thrown clear. Automatons die under it, the same as under a tram.
- **The production line:** a spawner at the end of the line turns out a skitterer every few seconds, up to 4 alive at once, until all three drive governors are smashed. Each governor (a spinning flyball governor) takes three wrench blows. Smashing all three jams the line, which stops it spawning and unlocks the lift.
- **Gear workbench:** one use. F fully repairs the most-worn gear in the rig: durability is restored, friction cleared, and a jam or shatter fixed.
- **Room pressure (level 11):** a level-wide pressure that climbs about 1.6% per second, shown as a ROOM PRESSURE bar on the HUD only in levels that have it.
  - Bashing a relief valve with the wrench bleeds off 30%; each valve then needs 6 s to reseal.
  - Above 75% a klaxon warns you, and the pipe routes marked on the floor start to steam.
  - At 100% every marked route bursts for 1.5 s: 25 damage plus a shove to anyone standing on one. Pressure then drops back to 40%.
- **Pressure Exchange gate:** the Main Relief Stack in the last room, a seized valve that takes three blows (the existing JammedValve). The level is a gauntlet of every enemy type, with a guaranteed scrap-gear cache.
- **Steam Walker (level 12):** 700 HP, slow, `steam_walker` sprite at about 4.5 m tall, and a boss health bar on the HUD.
  - **Phase 1 (above 66%):** stomps with the bruiser's red ring, scaled up to a 4.5 m radius.
  - **Phase 2 (66% to 33%):** alternates stomps with a steam breath, a 1 s wind-up and then a cone that sweeps 120° over 1.6 s, damaging anyone inside. It then overheats for 4 s and exposes its boiler valve. Three wrench blows on the valve stagger it for 4 s, and it takes double damage while staggered. Outside a stagger its plating halves the damage it takes.
  - **Phase 3 (below 33%):** every 12 s it calls in two skitterers and a hound from the yard edges, up to 4 alive at once. It also charges: a red lane telegraphs for 1.2 s, then it rams in a straight line, dealing 35 damage and a big knockback.
  - **On death** it drops the Foundry Seal (a key item). The Foundry Gate is an ITEM door that takes the seal.
- **Finale:** the tutorial terminal already moved to level 1 in batch 1, and the elevator victory already ends the campaign. This batch adds hounds, sentries and drones to the Great Foundry, and renumbers its arrival log to Dispatch #13, mentioning the seal.

## Level by level
### Level 10: Automaton Assembly Line (Act III)
- Rooms: Parts Store (14×14), Line Floor (30×16: two conveyors, three presses, the line spawner, three governors), Inspection Bay (16×14: the gear workbench), Line Lift (12×12).
- Enemies: skitterers from the line, two bruisers, a turret.
- Story: an output ledger counting "guards produced", and the foreman's note about the line building guards instead of workers.

### Level 11: Pressure Exchange (Act III)
- Rooms: Gauge Gallery (16×14), Relief Stacks (24×18), Manifold Hall (22×16), Exchange Lift (12×12).
- Five relief valves, four marked burst routes, a scrap-gear cache, and every enemy type.
- Story: the pressure clerk's last entries, and the Master's order to divert everything to the Gear vault.

### Level 12: The Overseer's Engine Yard (Act III, boss)
- Rooms: Yard Gate (14×14, terminals), Engine Yard (34×24, the Steam Walker), Foundry Gate (12×12, seal door and lift).
- Story: the Overseer's commission plate, and the last Guild dispatch before the finale.

## New code
- **Pure logic, unit-tested:**
  - `RoomPressure`: rise, bleed, warning and burst, with the reset after a burst.
  - `HitCounter`: the governors and the boiler valve.
  - `BossPhases`: phase from health ratio.
  - `GearItem.repair_fully()`.
- **World scenes:**
  - `conveyor`, `stamping_press`, `drive_governor`, `assembly_line` and `gear_workbench`;
  - `pressure_system`, `relief_valve` and `burst_route`;
  - `KeyPickup` gains a Foundry Seal look.
- **Enemy:** `steam_walker`, with its stats.
- **HUD:** a ROOM PRESSURE bar and a boss bar, driven by new GameState signals.
- **Sounds (about 11):** conveyor_rattle, press_hiss, press_slam, governor_break, workbench_repair, relief_vent, pressure_klaxon, pipe_burst, walker_stomp, walker_breath, walker_charge.
- **Dressing themes:** ASSEMBLY, EXCHANGE and ENGINE_YARD.

## Tests
- Unit tests for the new logic, the three new themes, and a campaign of 12 levels plus the finale.
- `campaign_smoke_test` extended through levels 10–12:
  - **Level 10:** a conveyor carries the Technician, a press hurts on its beat, the line spawns until all three governors are smashed and then the lift opens, and the workbench repairs a worn gear once.
  - **Level 11:** pressure climbs and shows on the HUD, a relief valve bleeds it, a burst hurts someone on a marked route, and the Main Relief Stack opens the lift.
  - **Level 12:** the Walker changes phase as it is damaged, its stomp hurts, a breath followed by three valve blows staggers it, phase 3 calls in adds, and its death drops the seal, which opens the gate.
- The exit chain runs 1 → … → 12 → finale. The finale smoke test still passes with the extra enemies.

## Verification
Import; run the unit tests, both smoke tests and the sound export; capture and review screenshots of every new room and send them. Left for your playtest: belt speed, press timing, how fast the pressure climbs, and the Walker's difficulty.

# Phase 4: 3D models replace the 2D sprites (branch `3dmodels`, approved, built)

## Context
`assets/models/` holds five GLB packs. Each pack is one scene with many models laid side by side as named root nodes (for example `steampunk_props.glb` has 20 roots: `boiler_tank`, `tesla_coil`, `propeller`, `steam_walker`...). The characters and enemies are rigged as **node hierarchies, not skeletons** (`<name>_Rig_pelvis / _Rig_leg_l / _Rig_arm_r / _Rig_head`...; the hound has four legs, a tail and a jaw; the spider has eight legs). Their only animation is a 9.5 s "Showcase" clip in which almost every track has two keys, so it is effectively a static pose with a little torso breathing. There are no walk, attack or death clips.

## What gets replaced
| Today (2D) | Becomes (3D model) | File |
| --- | --- | --- |
| Technician `player_woman_athletic` sprite | `player_woman_athletic` | players_female |
| Scrap Skitterer `enemy_steam_spider` | `enemy_steam_spider` | enemies |
| Piston Bruiser and Cistern Warden `enemy_diver_brute` | `enemy_diver_brute` (Warden keeps its tint and larger scale) | enemies |
| Clockwork Hound | `enemy_clockwork_hound` | enemies |
| Brass Sentry | `enemy_brass_sentry` | enemies |
| Tesla Drone | `enemy_tesla_drone` | enemies |
| Arc Turret (`tesla_coil.png`) | `tesla_coil` | props |
| Steam Walker boss (`steam_walker.png`) | `steam_walker` | props |
| Level DecorProps: boiler tank, grandfather clock, airship, gear stack, automaton head | same names | props / furniture_doors |
| FoundryProps furniture: sofa, armchair, cabinet, bookcase, clock, desk | `furniture_*` | furniture_doors |
| KeyPickup winding key | `wind_up_key` | props |
| Propeller blades | `propeller` (spins on its own axis) | props |
| World Tesla Coil | `tesla_coil` | props |

**Not changing:** floor and wall tile textures (there are no models for them), the HUD, and the loading-screen gear (a 2D UI image).

## Approach
1. **`ModelLibrary`** (`scripts/core/model_library.gd`, static): loads each GLB once, caches it, and returns a fresh copy of one named root with its root translation zeroed, optionally scaled so its height (from the merged mesh AABB) matches a target height and its feet sit on y = 0. It asserts loudly when a model name is missing.
2. **`CharacterModel`** (`scripts/core/character_model.gd`, `extends Node3D`) replaces `CharacterSprite` with the same public API that the gameplay code already calls: `play_locomotion()`, `play_attack()`, `play_death()`, `flash_hit()`, `play(&"idle")`, `animation`, `frame`, the `frame_changed` signal (footstep sounds keep working), `speed_scale` and a `modulate` property (tints apply through a `material_overlay`). Animations are procedural on the rig nodes, found by name suffix: legs swing (bipeds alternate two legs, the hound swings diagonal pairs, the spider ripples its eight legs), arms counter-swing, the right arm chops for the attack, a small bob and breathing sway for idle, and the death topples the model over. The model yaws to face its world move direction (and for the Technician, its aim direction).
3. **`EnemyBase.sprite`** stays as the property name so subclasses and the smoke tests keep working, but it becomes a `Node3D` and uses `modulate` through `CharacterModel`. The Brass Sentry model yaws to its `facing`, so its real back is visible; the glowing back boiler and floor arc stay because they still help the readability that playtest feedback asked for. The Steam Walker and Arc Turret get a static-model variant (`StaticModel` with `modulate` and hit flash) in place of their `Sprite3D`.
4. **Decor:** `DecorProp` gets a `model_file` / `model_name` / `model_height` (the texture export goes away), and the 12 level scenes swap their decor entries. `FoundryProps._sprite_prop` becomes `_model_prop`.
5. **Shading:** models are lit by the scene's lights (sprites were unshaded), which suits the dark lantern levels; models cast real shadows, so the blob shadow stays only under flying things such as the drone.
6. The old PNGs stay in `assets/sprites` (I won't delete anything); only references change.

## Defaults I picked (tell me to change any)
- Technician stays `player_woman_athletic` (the other 17 outfits are unused for now).
- Procedural animation in code, rather than authoring clips in Blender.
- Sizes match today's sprites on screen (Technician about 1.8 m, hound about 0.9 m, Walker about 4.5 m).
- Doors keep their current procedural 3D look. The six door models could replace the `SteamDoor` frame and leaf as a follow-up.

## Tests
- Unit tests: `ModelLibrary` (every model name the game uses exists, fitting to a height, feet on the floor, cache reuse) and `CharacterModel` (rig parts found for each enemy type, state changes idle → walk → attack → idle, death is one-shot, `frame_changed` fires during walk, facing yaw follows velocity, modulate and flash).
- Existing smoke tests updated where they read sprite properties (for example the drone hover check) and run again for all 13 levels.

## Verification
Import the GLBs headless; run the unit tests, the smoke test and the campaign smoke test; capture screenshots of a room from each act plus the Walker fight, and send them. Left for your playtest: how the procedural animation feels and whether any model needs a size tweak.

## Found during the build
The GLB materials carry names (SP_MAT_BRASS, SP_MAT_IRON, 42 in all) but no base colours, so everything imported white. `ModelPalette` (`scripts/core/model_palette.gd`) gives each named material a colour and roughness when a pack is first loaded, and asserts if a pack uses a material it has no colour for. If the GLBs are re-exported with colours, the palette can be removed.
