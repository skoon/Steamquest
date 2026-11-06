# Steampunk Sprite Set

289 hand-drawn (scripted) assets — **200×200 px, RGBA PNG**, drawn with the light
coming from the upper left so sprites can be freely rotated/mirrored without
breaking the shading.

- **20 props and sprites** — transparent background
- **5 enemies** — transparent background, each with a 4-frame walk cycle
- **6 player characters** — three male and three female builds, each with a
  4-frame walk cycle
- **12 alternate outfits** — two clothing swaps per build, same body and hitbox
- **side-view walks** — `player_<build>_side_walk_1..4.png`, facing right
- **death animation** — four frames of collapse for every player and enemy
- **idle and attack** — a breathing loop and a weapon swing per character
- **9 seamless tiles** (floors and walls) plus **6 variants** — fully opaque
- **3 stair treads** (opaque) and **2 railing overlays**
- **6 doors and 7 Victorian furniture pieces** — transparent props
- **13 edge/transition tiles** — overlays, plus 3 opaque thresholds

## Props and sprites

| File | Use |
| --- | --- |
| `gear_brass_large.png` | Background machinery, rotating hazard |
| `gear_iron_small.png` | Small mechanism / pickup part |
| `gear_stack.png` | Two meshed gears, decorative prop |
| `pipe_straight.png` | Level tile / wall pipe |
| `pipe_elbow.png` | Level tile / pipe corner |
| `valve_wheel.png` | Interactive valve (open/close puzzle) |
| `pressure_gauge.png` | HUD or machine status dial |
| `boiler_tank.png` | Room prop, destructible boiler |
| `steam_vent.png` | Emitter / steam hazard |
| `tesla_coil.png` | Powered trap or generator |
| `goggles.png` | Player accessory / item icon |
| `top_hat.png` | Player cosmetic / NPC hat |
| `pocket_watch.png` | Timer item / HUD clock |
| `wind_up_key.png` | Quest item / collectible |
| `propeller.png` | Rotating prop (animate via rotation) |
| `airship.png` | Background vehicle / level element |
| `automaton_head.png` | Character portrait / enemy head |
| `clockwork_heart.png` | Health pickup or lore item |
| `steam_walker.png` | Enemy (boiler walker) |
| `brass_lantern.png` | Light source prop, pickup |

## Enemies

Transparent, side-on, art inset a few px so an `Area2D` hitbox fits the body.

| File | Concept |
| --- | --- |
| `enemy_clockwork_hound.png` | Fast melee quadruped — gear joints, teal eye, gear tail |
| `enemy_steam_spider.png` | Eight-legged boiler walker, three eyes, steam vent |
| `enemy_tesla_drone.png` | Floating gyroscope orb, tesla arcs, single lens |
| `enemy_diver_brute.png` | Heavy diving-suit brawler swinging a pipe wrench |
| `enemy_brass_sentry.png` | Upright automaton soldier with a bayonet |

Each one also ships `enemy_<name>_walk_1..4.png`: the hound strides its paws, the
spider lifts alternate leg pairs, the drone hovers up and down, and the two
bipeds march in place. Keep the `Area2D` on the parent so the hitbox never moves
while the frames cycle. Each enemy also has `_idle_1..4`, `_attack_1..4` and a
four-frame death, `enemy_<name>_death_1..4.png`.

## Player characters

Front-facing, feet on y≈194, all six inside the same 200×200 box, so a single
`Sprite2D` can swap bodies without touching its origin or hitbox.

| File | Build | Character |
| --- | --- | --- |
| `player_man_slim.png` | tall, narrow | Engineer — waistcoat, goggles pushed up on the brow, ring spanner |
| `player_man_broad.png` | wide, heavy | Docker — braces, rolled sleeves, pipe wrench |
| `player_man_stout.png` | short, round | Inventor — top hat, moustache, frock coat and cane |
| `player_woman_slim.png` | tall, narrow | Pilot — flight jacket, long red hair, pistol |
| `player_woman_athletic.png` | medium, strong | Mechanic — leather apron, bandana, wrench |
| `player_woman_curvy.png` | short, full | Matron — corseted bustle dress, curls, parasol |

### Alternate outfits

A second outfit for each build: same silhouette, feet line and hand positions,
so a build can be re-dressed without a new hitbox. Use `alt=True` on the
character function to draw one (see `tools/gen_outfits.py`).

| File | Build | Character |
| --- | --- | --- |
| `player_man_slim_detective.png` | slim man | Detective — bowler, navy waistcoat, spanner |
| `player_man_broad_blacksmith.png` | broad man | Blacksmith — leather apron, leather skull cap with goggles |
| `player_man_stout_aristocrat.png` | stout man | Aristocrat — blue frock coat, monocle on a chain, gloves |
| `player_woman_slim_officer.png` | slim woman | Officer — navy uniform, brass buttons, epaulettes, peaked cap |
| `player_woman_athletic_aviator.png` | athletic woman | Aviator — shearling collar, crimson scarf, flight cap and goggles |
| `player_woman_curvy_opera.png` | curvy woman | Opera singer — crimson bustle gown, brass tiara, folding fan |
| `player_man_slim_professor.png` | slim man | Professor — flat cap, spectacles, satchel strap |
| `player_man_broad_fighter.png` | broad man | Pit fighter — bare arms, head strap, bandaged fists, neckerchief |
| `player_man_stout_mayor.png` | stout man | Mayor — cream top hat, gold chain of office, gloves |
| `player_woman_slim_nurse.png` | slim woman | Nurse — white pinafore, cap with a red cross, hand lamp |
| `player_woman_athletic_constable.png` | athletic woman | Constable — navy tunic, custodian helmet, truncheon |
| `player_woman_curvy_widow.png` | curvy woman | Widow — charcoal gown, bonnet, black lace fan |

### Walk cycles

Every build has a four-frame march in place seen from the front,
`player_<build>_walk_1..4.png`, in
the same box on the same feet line, so the idle sprite and the walk frames can
share one `Sprite2D`/`AnimatedSprite2D`. Arms and props are deliberately not
articulated: the hands keep their grip on the spanner, wrench, cane, parasol and
fan, so swapping frames never shifts a weapon. The curvy build animates the
skirt hem instead of the legs (a bustle dress hides them) — run that cycle a
little slower so the sway reads.

In Godot, give it a `SpriteFrames` with the four textures, loop on, ~10 fps. A
walker never stands exactly like the idle sprite, so cross-fade rather than
snap; the drone's frame 1 matches its static pose exactly.

### Side view

A second, profile set: `player_<build>_side_walk_1..4.png`, facing right. It is
separate art rather than a rotation of the front sprite, because a side walk
needs a near and far arm and leg, and a head drawn in profile. Set `flip_h` on
the `Sprite2D` for walking left. The curvy build swings its hem instead of
stepping, as in the front cycle.

### Death

`player_<build>_death_1..4.png` and `enemy_<name>_death_1..4.png`: the character
staggers, buckles and ends as a pile on the floor. Nothing new is drawn — each
frame is the standing sprite rotated about its feet and flattened towards the
ground (`Sprite.collapse()`), so a collapse always matches that character's art
and stays inside the 200×200 box. The drone, which floats, drops out of the air
before it lands. Play once, do not loop, and hold the last frame.

### Idle

`player_<build>_idle_1..4.png` and `enemy_<name>_idle_1..4.png`: a breathing
loop. The boots stay planted — each frame is the standing art squashed a
percent or two about its feet, so only the chest and head move — while the drone
hovers, the bustle dress sways and the spider shuffles a leg pair. Loop at
~6 fps; it is deliberately subtle so it never fights the walk cycle.

### Attack

`player_<build>_attack_1..4.png` and `enemy_<name>_attack_1..4.png`: wind-up,
strike, follow-through, recover. The body leans about its feet towards the
target and a weapon trail is drawn over the strike frames — a swept arc for the
spanner, wrench, cane, parasol and pistol, a thrust streak for the sentry's
bayonet, muzzle streaks for the hound, a discharge for the drone. Play once and
blend into `_idle_1` on the last frame, which is back on the standing stance.

## Level tiles

Opaque and seamless: repeat on a 200 px grid in any direction, no offset needed.

| File | Use |
| --- | --- |
| `floor_wood_planks.png` | Staggered wooden planks |
| `floor_parquet.png` | Basket-weave parquet |
| `floor_checker_marble.png` | Cream / dark marble checker |
| `floor_iron_plate.png` | Riveted plate with diamond tread |
| `floor_grate.png` | Metal grating, dark slots |
| `wall_brick.png` | Brick wall with mortar |
| `wall_wallpaper.png` | Damask wallpaper (half-drop repeat) |
| `wall_wood_panel.png` | Panelled wainscot with gear carving |
| `wall_metal_plate.png` | Riveted steel plates |
| `floor_wood_dark.png` | Variant: narrow dark-stained planks, knots |
| `floor_stone_slab.png` | Variant: worn flagstones, chipped corners |
| `floor_tile_octagon.png` | Variant: Victorian octagon-and-dot tiles |
| `wall_brick_cellar.png` | Variant: sooty quarter-bond brick, spent bricks |
| `wall_plaster.png` | Variant: cracked plaster with lath showing through |
| `wall_wallpaper_striped.png` | Variant: striped paper with gold lozenges |

## Stairs

Each `stair_tread_*` tile is **one step**: tread at the top, brass nosing, then a
shadowed riser. Place them one per row in a vertical run — wood, stone or iron —
and the staircase builds itself; they are seamless sideways, so a run can be any
width. `tools/preview_stairs.png` shows four steps of each stacked.

The two railing tiles are transparent overlays: a balustrade that repeats along
x. Rotate 90° for a railing that runs down a stairwell, and mirror it for the
other side.

## Doors

Transparent, sized to drop into a 200 px opening (frame included, art inset ~10 px).

| File | Use |
| --- | --- |
| `door_wood_panel.png` | Two-panel wooden door, stone frame, iron straps |
| `door_wood_arched.png` | Arched plank door with porthole and ring handle |
| `door_metal_hatch.png` | Riveted steel hatch, spoked wheel, brass porthole |
| `door_iron_gate.png` | Spear-topped iron gate, brass lock plate |
| `door_wood_double.png` | Variant: double doors, two leaves, brass ring handles |
| `door_metal_sliding.png` | Variant: sliding blast door, toothed track, hazard stripes |

## Victorian furniture

Transparent props, all 200×200: `furniture_armchair`, `furniture_sofa`,
`furniture_table_round`, `furniture_bookcase`, `furniture_desk`,
`furniture_grandfather_clock`, `furniture_cabinet`.

## Edge and transition tiles

These make the floor/wall junction work with **every** material combination: they
are transparent overlays (except the three thresholds) that stack on the tiles
above, so one skirting works on brick, wallpaper, panelling or steel. Draw them
on a second `TileMapLayer` above the level tiles.

| File | Sits | Use |
| --- | --- | --- |
| `edge_skirting_wood.png` | bottom of wall | Skirting board, brass rosettes |
| `edge_skirting_iron.png` | bottom of wall | Riveted steel skirting |
| `edge_skirting_stone.png` | bottom of wall | Stone plinth |
| `edge_cornice_wood.png` | top of wall | Dentil cornice |
| `edge_cornice_stone.png` | top of wall | Stone cavetto cornice |
| `edge_pilaster.png` | full wall height | Fluted column, base + capital |
| `edge_wall_base_shadow.png` | bottom of wall | Contact shadow, seats wall on floor |
| `edge_floor_divider_brass.png` | edge of a floor run | Brass strip (rotate 90° for vertical) |
| `edge_floor_divider_wood.png` | edge of a floor run | Dark wood border strip |
| `edge_step_nosing.png` | lip of a platform | Brass nosing + drop shadow |
| `edge_threshold_wood.png` | doorway floor cell | Opaque wooden sill |
| `edge_threshold_stone.png` | doorway floor cell | Opaque stone sill |
| `edge_threshold_brass.png` | doorway floor cell | Opaque tread-plate sill |

`tools/preview_edges_scene.png` shows them assembled in one room.

## Godot notes

- Import as `Texture2D`; these are flat 2D art, so leave **Mipmaps off** and
  **Filter on** (bilinear). For crisp pixel snapping keep sprites at 1:1 scale.
- All sprites are 200×200 with the artwork inset a few px, so a `Sprite2D` with
  `centered = true` lines up exactly and effects (glow, particles) have room.
- Suggested project setting for a PC build: stretch mode `canvas_items`,
  reference resolution 1920×1080; the 200px art scales cleanly at 1×/2×.
- Godot generates the `.import` files itself the first time the project is opened;
  they are intentionally not committed here.
- Lighting baked in (upper-left), so additive lights/glow work best placed over
  `tesla_coil`, `automaton_head`, `steam_walker` eyes and `brass_lantern` glass.

## Godot tileset

The fifteen floor/wall files (nine base, six variants) make a `TileSet`
directly: add them as 200×200
atlas sources (or one atlas if you prefer), set `texture_filter` to bilinear,
and keep `mipmaps` off. Because the art is seamless, `TileMapLayer` can paint
them without seams or margins.

Edges are overlays: put them on a second `TileMapLayer` above the level layer
(transparent tiles composite normally). The three `edge_threshold_*` files are
the exception — they are opaque, so place them on the floor layer itself under a
door.

## Regenerating

```
python3 tools/gen_sprites.py    # 20 props/sprites
python3 tools/gen_tiles.py      # 9 tiles + 4 doors + 7 furniture
python3 tools/gen_edges.py      # 13 edge/transition tiles
python3 tools/gen_stairs.py     # 3 stair treads + 2 railings
python3 tools/gen_variants.py   # 6 tile variants + 2 doors
python3 tools/gen_enemies.py    # 5 enemies
python3 tools/gen_players.py    # 6 player characters
python3 tools/gen_outfits.py    # 12 alternate outfits
python3 tools/gen_anim.py       # 4-frame walk cycles, players + enemies
python3 tools/gen_side.py       # side-view walk, 6 builds x 4 frames
python3 tools/gen_death.py      # 4-frame death, players + enemies
python3 tools/gen_idle.py       # 4-frame idle, players + enemies
python3 tools/gen_attack.py     # 4-frame attack, players + enemies
```

Every animation generator draws frame by frame and is slow. Each of
`gen_anim.py`, `gen_side.py`, `gen_death.py`, `gen_idle.py`, `gen_attack.py` and
`gen_outfits.py` can be split
across processes — `python3 tools/<script>.py --shard K 4` for K in 0..3 in four
shells writes its share and exits, then `python3 tools/<script>.py --sheet` (no
re-render) rebuilds the preview sheet.

All need Pillow (`pip install pillow`). Art is drawn at 4× and downsampled to
200×200. Review sheets: `tools/preview.png` (sprites), `preview_tiles.png`
(tiles, doors, furniture), `preview_tiling.png` (each tile repeated 2×2 to check
seams), `preview_edges.png` + `preview_edges_scene.png`, `preview_stairs.png`,
`preview_variants.png`, `preview_enemies.png`, `preview_players.png`
(plus `preview_players_big.png` at 2× for face detail), `preview_outfits.png`
and `preview_outfits_pairs.png` (each build above its outfit swap),
`preview_walk_players.png` and `preview_walk_enemies.png` (one row per
character, one column per frame), `preview_side.png`, `preview_death.png`, `preview_idle.png` and
`preview_attack.png` (same layout, one row per character).
