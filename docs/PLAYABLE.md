> **V6 working-tree update:** five fish per catch, larger colorful piles, real mesh slicing, instant world-board merges, species requests, physical 1 debug tools, and confirmed Settings reset. Saved uncommitted work; V1 tag is unchanged.

# Reel Tycoon — authored-scene V3 playable

Godot 4.7.2 / Xogot 1.7.2. Follows `GAME_DESIGN.md`; the original first playable remains at local tag **V1**. V2/V3 changes are not a new release tag. See `V3_NOTES.md` for reference research and the reproduced root-motion fix.

## Play
Run `res://scenes/main.tscn`.

- WASD / arrows or joystick: screen-aligned walking at a 3.1 m/s default pace, accelerated starts and immediate release stops. The lower-left floating stick starts neutral under your thumb; partial travel walks more slowly. The perspective follow camera never rotates into an isometric/diagonal view.
- Space or action: cast at a dock, then hold to reel. Release to cool tension; the fishing panel shows landing percentage and symbol/color tension warnings. Movement cancels fishing without losing carried fish.
- Visit **CUT → OUT → STOCK → CASH**. Cutting, output pickup, stocking, selling and cash collection remain distinct transactions.
- Upgrade pads require 1.2 seconds of deliberate dwell; exit to cancel, and step off before another purchase.
- At MERGE, open the **3D workbench**. Drag actual carried fish models together. Matching releases merge immediately with a compression and bouncing reveal—no confirmation button. The workbench is in the lakeside world; the shared camera travels there and returns smoothly. Page controls expose inventories larger than sixteen fish. Unrelated drops return unchanged. Empty sockets rearrange the board without changing ownership.
- **Keep from cutting** protects the selected fish. Merge results are kept by default. Displaying consumes the exact selected fish once, activates its bonus and preserves discovery.
- The fish-book button opens the same carried-fish board anywhere for viewing, arranging and protection. Merging/displaying requires the station.
- Hire a fisher, collect its finite crate, and unlock the second dock. No offline earnings.
- Settings: separate music/SFX, tap-to-toggle reeling, assist, reduced motion, and battery saver. Native touch and its synthetic mouse events cannot trigger action twice.

## What is authored
The initial hub, player, collision capsule, stations, props, lighting, follow camera, HUD controls, settings, 3D board and board effects are saved scene nodes, not generated at startup.

See **`res://docs/AUTHORING.md`** for editable scene paths. The hub contains separate cutting, market, merge-garden and worker prefabs. UI positioning uses saved anchors/offsets. The workbench picks its actual authored socket transforms.

Saved zones now use dashed rectangular outlines with contextual icons, costs/levels and cancellable on-ground dwell bars. Front customers show package needs, and the HUD reports delivery/full-capacity/cash bottlenecks. Foam follows the saved sand edge.

Only changing content is instanced: carried fish/packages, stock indicators, replacement customers, upgrade-specific rods and short-lived effects. Those effects never create currency or perform inventory transactions. Unchanged inventory and stock actors are retained across wallet-only notifications; fish bounds/scales are normalized and cached.

## Scope and architecture
Four species, three matching recipes, four display bonuses, ten cycling customer appearances, four rod upgrades, three basket/cutting upgrades, one worker and one dock expansion. Supplied models are explicitly scaled; private itHappy sources remain Git-excluded.

- `main.gd`: binds the authored scenes; fishing, interaction, business clocks, guidance and focus handling.
- `world.gd`: binds station metadata; state-dependent visual contents, customers and effects.
- `economy.gd`: authoritative transactions, exact selected-pair merges/display and persistence.
- `player.gd` / `joystick.gd`: physics movement, root-locked locomotion and pointer ownership. `in_place_animation.gd` locks the actual top-level Root bone in runtime copies, not just Hips.
- `hud.gd` / `merge_board.gd`: bind authored controls, input ownership, physical-world picking/dragging, instant exact-index merging and pagination.
- `audio.gd`: independently scaled synthesized music and SFX.

The old `fish_card.gd` is not used by V2's interface. Saves retain the V1 format: `user://reel_tycoon_v1.json`, checksum validation, temporary-file replacement and a valid `.bak` fallback. Committed inventories, queues, stock, cash, wallet, reservations, upgrades, discoveries, displays, workers, tutorial and settings persist. Fractional sale bonuses retain their remainder. Animations and worker timers are not offline rewards.

## Verification
**166 checks**: 12 editor structure/asset checks, 62 live gameplay/economy checks, 44 live controller/workbench checks, 7 touch/action-routing checks, 7 quality/reduced-motion checks and 34 V3 root-motion/joystick/zone/feedback checks. Visual inspection additionally covers the actual 3D board, result preview, fishing HUD and expanded hub. This does not establish new-player acceptance or finished presentation.

```sh
XO=/Applications/Xogot.app/Contents/MacOS/xo
"$XO" test run --full
"$XO" project run --wait
"$XO" game eval --file tests/game/test_behavior.gd --timeout 90
"$XO" game eval --file tests/game/test_v2.gd --timeout 30
"$XO" game eval --file tests/game/test_touch.gd --timeout 10
"$XO" game eval --file tests/game/test_quality.gd --timeout 10
"$XO" game eval --file tests/game/test_v3.gd --timeout 20
```

Game suites live under `.gdignore`; they run in the game, not the editor. They disable saving and restore the live player's data/position. The economy checks use a separate test save. Do not play concurrently with automation.

## Remaining acceptance/release work
- Final glass/water jars still need an approved asset; water-filled barrels remain the documented prototype fallback.
- The supplied straight saw is retained. Its existing metal surface is separated without changing geometry and oscillates; no replacement machine is custom-modeled.
- Supplied idle/walk/run clips plus procedural props remain the character-animation source. Dedicated cast/reel/carry/celebration clips need verified import/retargeting if added.
- Goldfish/Puffer's documented empty mesh is skipped; visible remaining geometry is checked. Final art should resolve missing parts.
- An expanded embedded sample was approximately **27 FPS, 96 MB static memory, 562 draw calls**. The normal embedded hub was about 30 FPS/311 draw calls. These are editor samples, not exported-device benchmarks or proof of the 60 FPS target. Exported Mac/iPad/iPhone profiling, thermal behavior, weakest-device performance and phone safe-area/touch ergonomics remain necessary.
- Real-player onboarding, balance, audio comfort and sustained visual/readability acceptance remain open. Passing economy checks is not a polish claim.
- Verify itHappy terms before shipping. See `res://THIRD_PARTY_NOTICES.md`.

## Current loop and controls

- Land five fish, or the available free basket slots. Raw capacity is 100–400; processed capacity is 500–2000. Reserved merge results still cannot auto-feed the cutter.
- CUT visibly cuts one fish into five pieces. OUT holds a colored 3×3 package pile. Walk onto it to collect packages onto your back, then STOCK them separately.
- Three customers always request a fish species; their bubbles show an actual fish and portion progress. Colored packages only serve the matching order. Legacy integer packages are mixed catch and remain usable.
- CASH displays a batched 3×3 coin tower. Collection flies directly to the HUD wallet, once per actual cash transaction. Pickup signs do not show collection counts; carried capacity, order progress and purchase prices remain truthful.
- **1** (development builds): add coins/fish/packages, fill/finish cutting, unlock upgrades, teleport, or pause business. Cheats intentionally persist. Settings has the same debug entry and a separate reset confirmation; cancel is harmless.
- Reset removes primary progress and its recovery backups only after validating a new checksum save. A storage failure keeps loaded progress intact. Do not use the real save for destructive testing.

## Verification

Updated structural, economy/full-loop, controller/workbench, touch, V3 movement/feedback, quality and V5 juice regression suites are in `tests/`. Run the live `tests/game/test_*.gd` scripts through `xo game eval --file`; they disable saving and restore fixtures. They cover five-fish/partial catches, exact portion value, typed/legacy saves, all ten NPC rig origins, instant merges, page boundaries, colorful 3×3 piles, backpack flight, slicing, camera transitions and isolated reset storage.

The measured busy fixture is around 27 FPS in this embedded editor, not an exported 60-FPS acceptance claim. Device performance, touch safe areas, balance/onboarding, dedicated fishing/carry clips and full private-asset license review remain release work.

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

## Latest verification and save incident (2026-10-02)
The updated suites passed **418 checks, zero failures** (13 structure, 157 behavior/economy, 44 controller/workbench, 34 movement/feedback, 7 touch, 8 quality, 75 juice, 80 expansion). Seven changed gameplay scripts checked without diagnostics. Full-size 580-item stacks and the actual cutter close-up were captured and inspected. These are embedded-editor checks, not exported-device acceptance.

**Save recovery is unresolved.** During a debugger interruption, a queued live test resumed while saving was temporarily re-enabled, overwriting the primary gameplay save and its ordinary backup with fixture progress. The affected files were preserved as `user://reel_agent_incident_primary.json` and `user://reel_agent_incident_backup.json`; these are incident evidence, not an intact pre-test backup. The game was stopped. An intact pre-test save was not found. The last confirmed progress was 4,274 coins, one carried fish and 92 carried packages; other fields cannot be reconstructed with certainty. Do not claim that the original gameplay progress has been preserved, and do not guess or reset it. Recovery requires an external backup or the user's authorization to reconstruct known progress.

All live regression suites now also redirect `save_path` to `user://reel_live_validation.json`, preserving/restoring the prior path only after fixture cleanup. This prevents incidental re-enabling of saving from writing fixture data to the gameplay file. Run one suite at a time; if a suite breaks or times out, do not queue another or re-enable saving: stop the game to cancel pending coroutines first.

## V7 requested UI and serving-area pass
- Removed the wooden box from `Fisherman/Visual/Basket`, leaving `Carried` and its full-size, uncapped stacks intact. Removed all four `MergeGarden/DisplayWater*` top-disc meshes; the authored barrels and display bonuses remain.
- Customer requests now form one rigid camera-facing card: background, species-colored fish glyph, name and exact accepted-package progress share the same plane. No independently billboarded text/model offsets. Three stalls support **nine active orders**. Shared stock/cash remain single authoritative balances; their visible piles are partitioned across three stands, never triplicated. STOCK and CASH work at each stand.
- Purchase footprints fill bottom-to-top in green during the cancellable 0.9-second dwell. Purchase hammer stamps are suppressed, floor text shows the full price rather than `0 / price`, and completed purchase badges disappear. Currency is still charged only after a successful complete dwell.
- Added **two more buyable saws** (760/1100 coins), for five total. Added **three adjacent fisher hires** (900/1200/1500), for seven total; they share the existing original/second/Puffer piers. All saws have independent queues/output and all fishers have independent crates. Existing expansion payloads append empty locked slots only after checksum and content validation.
- Added two editable market stand scenes east of the original hub, serving six additional customers. The district expands to 90×54m ground with matching collision and connected promenade; old border foliage is moved clear of customer lanes. Camera yaw and movement remain screen-aligned.
- The world merge camera is centered horizontally on all sixteen sockets. Full-width picking replaces the crowded right sidebar; short instructions and a compact bottom strip retain KEEP, DISPLAY and pages without covering the board. Immediate matching-drop merging, reservations and all-page inventory reachability remain intact.
- **Validation: 481 checks, zero failures**: structure 13, economy/full loop 157, controller/board 44, movement/feedback 34, touch 7, quality 8, juice 75, expansions 80, new marina/UI 63. Captured and inspected coherent customer cards, the centered board and half-green purchase feedback. This is not exported-device performance or safe-area acceptance.
- Testing launches `tests/game/validation_sandbox.tscn`, which redirects saving to a separate path and disables it before entering the main scene. The previously reported gameplay-save recovery incident remains unresolved; this pass does not claim to reconstruct the lost progress. No commit/tag/push is created.
