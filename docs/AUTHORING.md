> **Current V6 authoring:** the physical workbench is `res://scenes/world/merge_workbench.tscn`, instanced beneath `Lakeside/MergeGarden`. `ui/merge_board.tscn` is a transparent control overlay, not a separate viewport/world. Older descriptions below are historical where superseded by this note.

# Reel Tycoon — scene-authoring guide

The hub is authored, not built from an empty root at startup. Open these `.tscn` files in Xogot to edit their nodes, transforms, collision shapes, lighting, materials and controls.

## Start here
`res://scenes/main.tscn`

```
ReelTycoon
├── Lakeside       → world/lakeside.tscn
├── Fisherman      → player/fisherman.tscn
├── HUD            → ui/hud.tscn
├── FollowCamera   (fixed-yaw perspective gameplay camera)
├── Soundscape
└── FishingLine
```

Open a prefab using its scene icon, rather than changing imported children without enabling Editable Children. The initial layout, character, collision capsule, props, board, lights and HUD controls exist before Play.

## Hub and stations
`res://scenes/world/lakeside.tscn` contains Lighting, Terrain, Waterfront, Scenery, upgrade/fishing pads, and four station instances:

| Instance | Scene to edit | Contents |
|---|---|---|
| Workshop | `res://scenes/stations/cutting_station.tscn` | Supplied saw, moving metal surface, crates, CUT/OUT pads, collision, status label, visual-stack anchors |
| Market | `res://scenes/stations/market.tscn` | Stand, stock/cash anchors, STOCK/CASH pads, initial customers, collision, status |
| MergeGarden | `res://scenes/stations/merge_garden.tscn` | Supplied barrels/fish, prototype water surfaces, display collision and MERGE pad |
| Crew | `res://scenes/stations/worker_station.tscn` | Fisher, rod, finite catch crate and pickup pad |

`world.gd` binds saved `pad_id`, `world_ref`, `station_label`, `display_species` and `customer_slot` metadata. Keep these IDs intact. Station references are not inferred from decoration names. All twenty-nine pads have a saved PlaneMesh Surface with `interaction_zone.gdshader`, an icon and a flat purchase-cost Caption plus a screen-projected HUD badge. The Surface mesh size drives both shader dimensions and rectangular interaction detection; edit that size rather than independently changing the old compatibility `radius` metadata. Progress/affordability/completion uniforms are updated by state, not by spawning new pad geometry. The market authors an OrderBubble instance beneath each initial customer; replacement customers use `world/customer_request.tscn`. Pad positions are resolved through their authored parent transforms. Fishing/water walk limits are still explicit in `main.gd`; moving docks or shore boundaries requires updating those limits too. The station prefabs represent the current named stations, three separate workshop queues/outputs, four ports and four fisher crates.

## Player
`res://scenes/player/fisherman.tscn`: capsule, Visual/Model, Basket/Carried, and Rod. Edit attachments and collision here. `player.gd` owns acceleration, immediate stopping, facing and floor movement. Its exported `move_speed` defaults to 3.1 m/s and can be tuned in the Inspector. Model, Basket/Carried and Rod stay under the same Visual transform. `in_place_animation.gd` duplicates the supplied idle/walk/run clips and pins their top-level Root bones to rest, while preserving Hips vertical bob. The original Root travels 1.48m/1.90m per walk/run cycle; only removing hip drift does not solve snap-back. Private assets are never modified. Basket/Count reports the real carried inventory.

## HUD
`res://scenes/ui/hud.tscn`: Interface/Play contains the wallet, quest, capacity readouts, joystick, action, fishing feedback and guidance. Settings and MergeBoard are separate children. Responsive anchors/offsets are saved in the scene; HUD initialization no longer resets their layout to hardcoded coordinates. The Joystick Control is an authored lower-left touch region, not only the circle you see at rest; its saved anchors delimit where a floating stick can begin. Gameplay buttons do not retain keyboard focus. The destination badge and cosmetic coin trails are intentionally animated at runtime.

## 3D workbench
`res://scenes/ui/merge_board.tscn`

- `BoardView/Viewport/Rig`: real wooden board, frame, sixteen physical sockets, studio lighting, straight-yaw perspective camera, Fish and Preview anchors.
- `Details`: selected fish, exact display bonus, keep/display, and previous/next page controls. There are no confirmation controls.
- Fish models are populated from the actual carried inventory when opened. Camera-plane picking follows the authored socket transforms; moving a socket in the editor changes picking and fish placement.
- At the MERGE station, drag one matching fish onto another. Release commits the exact pair immediately and reveals the result. Compatible hover is not a transaction. Unrelated drops return unchanged. Empty sockets rearrange only the current board presentation.
- Merges/display transactions target the exact selected inventory indices. The economy commits before the cosmetic merge animation. Repeated input cannot consume the same pair twice.
- Away from MERGE, the fish book opens the same board for viewing, arrangement and cutting protection. Combining/displaying remains station-gated.
- The board's viewport and input are disabled while closed. Touch owns its pointer independently of synthetic mouse events; release/focus-loss cancellation returns the fish safely.

## Intentionally dynamic content
Carried fish/packages, stock/queue indicators, replacement customer appearances, upgrade-dependent rod models, splashes, coin trails and other short-lived effects are still instanced at runtime. They reflect changing saved state; they are not a hidden replacement for the authored environment or interface.

Authoring and gameplay do not bypass `Economy`. Cosmetic nodes never award currency. `V1` remains the original checkpoint; these scene/controller/UI improvements are working-tree changes.

## Water and dynamic stacks
`Terrain/LakeWater` owns the saved shader/material. `shore_z=-2.45` matches the sand edge; change it if the shore is moved. `foam_width` controls the scalloped wash. Reduced motion sets water motion to zero. `normalized_model()` caches supplied model bounds and preserves aspect ratio; all pickup, flight and carried fish are 0.50m long; packages stay 0.32m and package piles use compact grids. The backpack has no visual count or height cap. MultiMeshes render every stored element at its full size; stationary collection piles may still use representative visual caps. HUD always reports authoritative quantities.

## V4/V5 authored extensions

- `world/merge_workbench.tscn` saves 16 sockets, result/effects, collision, supports and a non-current target Camera. `main.gd` interpolates FollowCamera to that orthonormalized global pose (FOV 44) and returns to fixed-yaw follow (FOV 50). The world/player stay present; only the backpack is hidden during board focus.
- `stations/cutting_station.tscn` owns `CutStage` and collection anchors. `fish_slicer.gd` caches ten clipped ArrayMeshes from the supplied fish, retaining materials and interpolated mesh attributes. Original GLBs/FBXs are never edited. Fresh-cut interiors use capped, readable cream-colored surfaces; thin fins remain attached to the end sections.
- `world/customer_request.tscn` authors a billboard speech bubble, real-fish anchor, species and progress text. `world.align_person_origin()` corrects the supplied customers’ baked source-scene offsets (-1.666m, -3.332m, etc.) on runtime instances. Resetting root bone motion alone is insufficient. Movement owns the actor origin; animation clips are copied in place and never restarted each tick.
- `ui/station_badge.tscn`, `ui/debug_panel.tscn`, and `ui/reset_confirm.tscn` are authored scenes. Debug 1 is a genuine InputMap action, development-only. HUD badges project saved pad anchors and suppress collection quantity labels.
- OUT/STOCK/CASH/pickup resource anchors sit on their actual pads. Fish/packages form layered 3×3 piles; coins use one cached MultiMesh. `sync_carried()` preserves unchanged backpack actors; `fly_to_back()` binds its tween to the accepted actor so removed items cannot leave freed callbacks. Schools can specify an exact accepted inventory index.
- Typed portions are `{species,value}`; old integer portions remain valid mixed catch. The save schema/path stays V1. Cosmetic animations cannot invoke rewards.
- The saved lakeside includes warm Sun/cool SkyFill, procedural sky reflections, richer ground colors, bushes and flowers off core routes. Preserve fixed yaw and landscape framing. No diagonal/isometric conversion.

## V6 expanded marina / full-size stacks
- The physical island is 64×44m with matching ground collision, a wider shore, promenade and authored gardens. Movement remains screen-aligned at 3.1m/s, with fixed-yaw perspective cameras. New workshops stay east of the customer entrance/exit lane.
- Three playable conveyor/saw workshops: the original plus SAW II (220 coins) and SAW III (480). Each owns its own 200-fish input queue and 1000-package output. CUT and OUT remain separate interactions; the shared cut-speed upgrade improves all workshops.
- Four ports: the original, the legacy second dock (110), Puffer Port (240), and Swordfish Port (480). The new ports specialize their five-fish catch schools. Four fishers: the original hire (90), then three hires (180/360/600). Each produces five real fish every four seconds into its own 100-fish crate; no worker grants free currency.
- Raw capacity is 100/200/300/400 and goods capacity is 500/1000/1500/2000. `backpack_stack.gd` batches full-size supplied geometry by species/material. **Every item is represented, with no maximum stack height and no shrinking.** The fixed camera does not zoom out to fit giant towers. Count text stays near the player's shoulder.
- Fish preserve 0.50m and packages 0.32m from piles through accepted-object flight to attachment. Positional arrival bounce replaces item-scale animation. Five-item transfers emit/save once and retain exact species/value; large collections do not issue five redundant saves per beat.
- `stations/cutting_conveyor.tscn` authors the moving tread belt, rollers, spinning toothed saw, lowering carriage, guard, chips and a non-current watch camera. The supplied sawmill remains the wooden support. Ten actual mesh sections (with fresh cut faces) bundle in pairs into the existing five colored packages: **whole-fish sale value is unchanged**.
- Tap **SAW** at any active CUT pad for a shared-world close-up. Business continues while movement/picking are locked; BACK, Settings and Debug return through the established camera/input guards. Reduced Motion suppresses feed/bounce/spin/chips and freezes the water, not transactions.
- Water uses stronger smooth vertex waves, moving cel bands, broken highlight strokes and scalloped shoreline wash. `shore_z=-2.45` remains aligned to the authored sand.
- `data.expansions` is optional in old schema-1 payloads. Checksums are verified before empty new plots are supplied; old wallets, inventories, upgrades, legacy integer packages and backup recovery remain intact. No V1 save reset or new release/tag is performed.
- `tests/game/test_expansion.gd` adds full-size/1000-item batches, above-old-cap pickup, independent live workshops/fishers, purchases, V1 payload loading, nested save validation, physical ground, real ten-piece geometry and cutter-camera/modal checks. Embedded-editor profiling is not exported-device, thermal or pacing acceptance. Asset licenses and real-device release validation remain required.

## V7 requested UI and serving-area pass
- Removed the wooden box from `Fisherman/Visual/Basket`, leaving `Carried` and its full-size, uncapped stacks intact. Removed all four `MergeGarden/DisplayWater*` top-disc meshes; the authored barrels and display bonuses remain.
- Customer requests now form one rigid camera-facing card: background, species-colored fish glyph, name and exact accepted-package progress share the same plane. No independently billboarded text/model offsets. Three stalls support **nine active orders**. Shared stock/cash remain single authoritative balances; their visible piles are partitioned across three stands, never triplicated. STOCK and CASH work at each stand.
- Purchase footprints fill bottom-to-top in green during the cancellable 0.9-second dwell. Purchase hammer stamps are suppressed, floor text shows the full price rather than `0 / price`, and completed purchase badges disappear. Currency is still charged only after a successful complete dwell.
- Added **two more buyable saws** (760/1100 coins), for five total. Added **three adjacent fisher hires** (900/1200/1500), for seven total; they share the existing original/second/Puffer piers. All saws have independent queues/output and all fishers have independent crates. Existing expansion payloads append empty locked slots only after checksum and content validation.
- Added two editable market stand scenes east of the original hub, serving six additional customers. The district expands to 90×54m ground with matching collision and connected promenade; old border foliage is moved clear of customer lanes. Camera yaw and movement remain screen-aligned.
- The world merge camera is centered horizontally on all sixteen sockets. Full-width picking replaces the crowded right sidebar; short instructions and a compact bottom strip retain KEEP, DISPLAY and pages without covering the board. Immediate matching-drop merging, reservations and all-page inventory reachability remain intact.
- **Validation: 481 checks, zero failures**: structure 13, economy/full loop 157, controller/board 44, movement/feedback 34, touch 7, quality 8, juice 75, expansions 80, new marina/UI 63. Captured and inspected coherent customer cards, the centered board and half-green purchase feedback. This is not exported-device performance or safe-area acceptance.
- Testing launches `tests/game/validation_sandbox.tscn`, which redirects saving to a separate path and disables it before entering the main scene. The previously reported gameplay-save recovery incident remains unresolved; this pass does not claim to reconstruct the lost progress. No commit/tag/push is created.
