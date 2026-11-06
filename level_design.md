# Level Design: The Golden Gear campaign

## Context
The game currently has one level, the Hargreaves Foundry: Boiler Room → Gear Cutting Floor → Smelting Vats → Golden Gear → Master Clock Vault. Scott wants that to become the **final level**, with at least 10 levels before it that build toward the Golden Gear.

**This round is brainstorm only**, by Scott's choice. No code changes. Once this plan is approved, I'll save it as `level_design.md` in the project root and add a "Phase 3: campaign" entry to `task.md`. Scott will trim or reorder the list before anything is built.

**Decisions already made:**
- **Carry-over between levels:** gears (with their wear and friction) carry over; health and steam refill.
- **On death:** restart the current level, with gears as they were when you entered it.
- **Enemies:** add the four unused enemy sprite sets in `assets/sprites/enemies`: clockwork hound, brass sentry, tesla drone, steam walker.

## Story arc
The existing lore: the Hargreaves Automaton & Clockwork Foundry went silent in one night eleven years ago. The automatons kept working; the workers never came home. The guild sends the Technician to find the frictionless cog that Master Hargreaves hid in the core.

The campaign is the journey **from the guild city down to the foundry's heart**, in three acts:
- **Act I, The City Above (levels 1–4):** reach the foundry.
- **Act II, The Outer Works (levels 5–8):** the support works that fed and powered it. This act is also where you learn what happened that night.
- **Act III, The Deep Foundry (levels 9–12):** the machinery that never stopped. It ends with a boss guarding the foundry gates.
- **Finale (level 13):** the existing Great Foundry level.

Rumor terminals carry the story. Each level has 2–3 logs, and together they reveal the mystery piece by piece: Hargreaves didn't lose control of the automatons. He ordered them to guard the Gear, and they're still following that order.

## Rules every level follows
- **Teaches one new thing.** Each level adds one mechanic, enemy or hazard, then combines it with what came before.
- **Has a gate.** It ends in a locked exit (door, lift, tram or gangway) opened by a level-specific task. Most gates reuse the existing valve-bashing or terminal-reading locks.
- **Leaves by elevator.** Reusing `elevator.tscn`, each exit takes the Technician to the next level instead of declaring victory.
- **Uses existing art.** Floor, wall, decor, door and enemy sprites from `assets/sprites`; the farm and city tilesets where they fit.
- **Wears down your gears.** Because gears carry over, levels 4, 8 and 11 each have a guaranteed scrap-gear cache, and level 10 adds a gear workbench.

## The levels

### Act I: The City Above
**1. Guild Dispatch Yard** (new tutorial)
- **Look:** wood planks and stone slab floors, brick walls, crates, brass lanterns, a guild office with desks.
- **Teaches:** movement, wrench, rivets, dash and the vent, using the tutorial terminals that currently sit in the Boiler Room.
- **Enemies:** a few scrap skitterers that escaped the foundry and are scavenging the yard.
- **Gate:** bash the seized valve to pressurize the tram platform.
- **Story:** your guild dispatch, the job briefing, and a missing-persons notice for the foundry workers.

**2. Pneumatic Tramline**
- **Look:** a long, narrow tunnel; iron plate floor, metal walls, rails, signal lamps.
- **New hazard:** tram cars thunder along a crossing track on a timer. A warning bell and lamp sound first; getting caught means heavy damage and knockback, and enemies get hit too.
- **New enemy: Clockwork Hound.** Fast pack hunters in groups of 2–3 that circle and lunge from your flanks, unlike skitterers, which rush straight in.
- **Gate:** restart the line by bashing two valves at opposite ends of the station.

**3. Clockmakers' Row** (the foundry's showroom)
- **Look:** a refined contrast to the industrial levels: checker-marble floor, striped wallpaper, grandfather clocks, sofas, cabinets and display cases.
- **New enemy: Brass Sentry.** An automaton soldier with a shielded front: hits from the front just clang off. You have to get behind it, by dashing past or drawing it toward hazards.
- **Gate:** find the wind-up key (`wind_up_key` sprite) and wind the clockwork showroom door.
- **Story:** advertising placards for "Hargreaves' Perpetual Engine", which promise motion without friction.

**4. Flooded Cisterns** (pumping station)
- **Look:** stone and grate floors, cellar brick, big pump engines, standing water.
- **New hazard: water.**
  - The water level rises and falls on a slow cycle. Deep water slows you down and adds DRIVE wear.
  - Arc turrets standing in water short out; that's a reward for timing your approach.
- **Mini-boss: The Cistern Warden,** an elite Piston Bruiser (diver brute) with a longer slam combo.
- **Gate:** start three pump valves in the order written on a terminal. A wrong order floods the room for one cycle.

### Act II: The Outer Works
**5. Steam Gardens** (the hydroponic farm that fed the workers)
- **Look:** the farm tileset; greenhouses, sprinkler vents, overgrown planters.
- **New hazard: humid zones.** Gears wear faster inside them, which makes the lubricant vent and gear management matter.
- **New object: nests.** Skitterer and hound nests keep spawning enemies until you smash them.
- **Gate:** clear every nest.

**6. Coal Seam & Mine Lift**
- **Look:** dark, with only lanterns and the coal glow; mine rails, coal and slag piles.
- **New mechanic: darkness.** You carry a brass lantern with a small light radius. Wall lanterns you light with the wrench stay lit, and they double as checkpoints for the eye.
- **Hazard:** runaway ore carts on rails.
- **Gate:** fix the lift's winch: bash it free and then defend it while it winds up. This is the game's first "hold the point" moment.

**7. Airship Mooring Tower**
- **Look:** open-air deck at the top of the tower, with the `airship` and `propeller` sprites, railings and sky.
- **New hazard: wind.** Periodic gusts push everyone toward the deck edges, and the hazard works in your favour too: knock enemies off with the wrench.
- **Spinning propellers** act as cog-style hazards.
- **New enemy: Tesla Drone.** It flies over obstacles, keeps its distance and fires arcs. The rivet gun becomes essential.
- **Gate:** lower the gangway down to the foundry's outer wall.

**8. The Blueprint Archive**
- **Look:** a library and drafting office; parquet and dark wood, bookcases, desks, wallpaper.
- **New mechanic: soft stealth.** Brass sentries patrol with lantern sight cones. Being spotted rings an alarm that wakes the room's arc turrets. You can sneak, or fight it out.
- **Gate:** collect three blueprint pages, which assemble the access code for the deep foundry.
- **Story beat, the big one:** the night it went silent, Hargreaves gave the automatons one order: *guard the Gear*.

### Act III: The Deep Foundry
**9. Tesla Generator Hall**
- **Look:** metal plates, glowing coils (`tesla_coil` sprite), cable runs.
- **New hazard: conductive floor plates** that electrify in sweeping patterns.
- **Gate puzzle:** rotate three junction switches to route power away from the exit door. A wrong routing electrifies a different section.
- **Twist:** a rivet shot into a coil overloads it and stuns nearby drones.

**10. Automaton Assembly Line**
- **Look:** a long factory floor of conveyors, stamping presses and half-built automatons.
- **New hazards:**
  - conveyors carry you and enemies along;
  - stamping presses crush on a beat.
- **The line keeps producing skitterers** until you jam it. The twist is that this time *you* break the machine: bash three drive governors.
- **New object: gear workbench.** Use it once to fully repair one socketed gear.

**11. Pressure Exchange**
- **Look:** pipe galleries, giant gauges, relief stacks.
- **New mechanic: room pressure.** A room-wide gauge (shown on the HUD) keeps climbing. Bash relief valves to bleed it off; if it peaks, pipes burst along marked routes.
- **The level is a gauntlet:** every enemy type mixed together while you keep the pressure down.

**12. The Overseer's Engine Yard** (boss)
- **Boss: the Steam Walker,** a giant boiler-legged walker (`steam_walker` sprite) that guards the gates of the Great Foundry.
- **Phase 1:** stomps that use the bruiser slam telegraph, scaled up.
- **Phase 2:** a sweeping steam breath. It overheats afterwards, which exposes its boiler valve; three wrench BONGs on the valve stagger it.
- **Phase 3:** it calls in skitterers and hounds, and a tram-style charge crosses the yard.
- **Reward:** the Foundry Seal, which opens the Great Foundry's bulkhead.

### Finale
**13. The Great Foundry** (the existing level)
- **Room order:** Boiler Room → Gear Cutting Floor → Smelting Vats → Golden Gear → Master Clock Vault → victory.
- **Changes it needs once the campaign exists:**
  - The tutorial terminal moves to level 1, and the Boiler Room gets a new arrival log.
  - More enemies to match a veteran player, including a few hounds, sentries and drones alongside the originals.
  - The elevator's victory now ends the campaign.

## Difficulty curve
| # | Level | New thing | Enemies |
|---|---|---|---|
| 1 | Guild Dispatch Yard | Controls | Skitterers |
| 2 | Pneumatic Tramline | Tram crossings | + Hounds |
| 3 | Clockmakers' Row | Shielded enemies, key item | + Sentries |
| 4 | Flooded Cisterns | Rising water, valve order | Bruisers, turrets, Warden mini-boss |
| 5 | Steam Gardens | Humid wear zones, nests | Skitterers, hounds |
| 6 | Coal Seam & Mine Lift | Darkness, ore carts, defend the lift | Mixed |
| 7 | Airship Mooring Tower | Wind, edges, propellers | + Tesla drones |
| 8 | Blueprint Archive | Stealth sight cones, collect pages | Sentries, turrets |
| 9 | Tesla Generator Hall | Electrified floors, power routing | Drones, turrets |
| 10 | Assembly Line | Conveyors, presses, workbench | Endless skitterers until jammed |
| 11 | Pressure Exchange | Room pressure meter | Everything |
| 12 | Engine Yard | Steam Walker boss | Boss + adds |
| 13 | The Great Foundry | (finale) | Everything |

**Easiest to cut:** levels 6 and 11, because their mechanics overlap others. Cutting both still leaves 10 levels before the finale.

## What building it will take (for later phases, not this round)
- **Campaign framework:**
  - a `CampaignDef` resource listing the level scenes in order;
  - `GameState` tracks the current level and keeps the rig between levels;
  - a checkpoint copy of the rig is taken when each level starts, and restored on death;
  - progress saved between levels;
  - the elevator gains a "next level" mode;
  - a simple title and level-intro card.
- **Level construction:**
  - each level is a `.tscn` built by the existing `FoundryBuilder` from `RoomDef`s;
  - new dressing themes for each setting (yard, tram, showroom, cistern, garden, mine, tower, archive, generator, assembly, exchange, yard);
  - non-rectangular or outdoor spaces (the tower deck) may need a small extension to the builder.
- **New enemies:** four `EnemyBase` subclasses with `EnemyStats` `.tres` files, sound recipes for each, and the Steam Walker boss.
- **New hazards and objects:** tram, water cycle, humid zone, nest spawner, darkness and lantern, ore cart, wind, propeller, sight cone and alarm, electrified plates and junction switches, conveyor, press, gear workbench, room pressure, key and page pickups.
- **Suggested build order** (three levels per batch, playtesting after each):
  - framework + levels 1–3
  - levels 4–6
  - levels 7–9
  - levels 10–12 + finale changes

## Verification for this round
There's nothing to run: no code changes. Done means `level_design.md` exists in the project root with this content and `task.md` has the Phase 3 entry. After that, Scott trims or reorders the list and picks the first batch.
