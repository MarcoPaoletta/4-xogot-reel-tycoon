> **Current V6 working design (2026-10-02).** Latest user direction supersedes earlier preview-confirm and generic-customer proposals: five-fish catches, immediate matching-drop merges, specific persistent fish orders, and physical resource piles. V1 and its save path remain preserved. No new release/tag is created.

# Reel Tycoon — Game Design Document

## Vision
A juicy 3D hybrid-casual fishing tycoon for Mac, iPad, and iPhone. Start as one fisherman on a small dock and grow a lively lakeside business. Every catch is playable, every delivery is visible, and every upgrade makes the world feel busier and more rewarding.

**Core promise:** feel the fish fight, land it with a pop, carry a satisfying stack, watch the machine chew through it, and scoop up a shower of earnings.

This document follows `HIGH_CONCEPT.md` and `asset-inventory.md`. Values below are initial tuning targets, not tested balance.

## View and Controls
- Landscape 16:9. Perspective follow camera high above and behind the player, looking forward; world aligned to the screen. Match `concept/CAMERA reference.png`: **never isometric, diagonal, or first-person**. Other concept images guide mood and interactions, not conflicting camera angles.
- Touch: virtual joystick plus one contextual action button. Mac: WASD/arrows and Space or mouse action. Movement remains screen-aligned; no manual camera rotation.
- Walk into station pads to deliver, collect, or interact. Unlock pads show cost and require a short deliberate dwell, with progress feedback and cancellation on exit.
- Fishing anchors the player at the dock; moving away cancels without losing carried fish. No jumping, combat, or precision platforming.

## The Loop
**Catch → carry → cut → stock → sell → collect → upgrade.**

Reserve matching catches for **merge → discover → display in water jars → gain passive bonuses**. Hire fishers and open docks to increase supply, while the player manages delivery and keeps enjoying manual fishing.

### 1. Fish
Cast from a marked dock spot. The float lands with a plop and ripples; a bite pulls it under and starts the tension-and-reel minigame.

Hold the action to reel: landing progress rises, but so does tension. Release to cool tension; the fish may regain a little distance. The safe range is marked with both color and symbols. Sustained maximum tension breaks the line; reaching full landing progress catches the fish.

Species have distinct, readable fight patterns: Goldfish is steady, Clownfish bursts, Puffer resists in pulses, and Swordfish makes strong lunges. Telegraph lunges with a ripple and sound before tension spikes. Rod upgrades improve control, not remove the minigame.

Target an early catch in roughly 6–10 seconds. Failure costs only time: a soft snap, splash, and quick recast. The first tutorial catch is forgiving.

### 2. Carry and Process
Catches arc into a visible basket/stack, bounce once, and settle. Each landing grants up to five fish. Start with room for 100 raw fish (upgrades: 200/300/400) and 500 packages (1000/1500/2000). Full capacity gives a clear “Deliver or merge” prompt instead of allowing more catches.

At the cutting machine, stepping on its button transfers fish one at a time. Each fish visibly leaves inventory only when accepted. The saw spins up, the frame gives a small rhythmic kick, and processed goods pop into an output crate. Keep processing playful and clean: no gore.

The machine produces sale stock, **not money**. Capacity limits pause transfer without deleting fish. The player carries output to the stall; processing and stocking are distinct, visible steps.

### 3. Sell and Grow
Human customers queue at the stall, buy stocked portions, and leave happily. Every active customer has a persistent species request shown by a real fish in a speech bubble. Sell only matching species (old mixed-catch saved portions remain compatible). Maintain three active requests, retain a reachable Goldfish request, and prioritize currently unrequested stocked species when replacing customers. Use all ten customer appearances for variety; keep the visible queue small.

Sales build a visible cash pile. The collection pad sweeps coins toward the HUD in a short cascade; the wallet updates accurately once per collection. Purchase pads spend wallet cash to unlock rods, capacity, faster machines, new docks, and hired fishers.

Workers fish automatically and fill their dock crates; they do not silently create cash. Full crates stop production. Keep manual catches faster or more valuable than worker catches so playing still matters. No offline earnings in the initial release.

### 4. Merge and Collect
At the merge station, choose carried fish and drop one onto another. Two matching species become one rarer species using an explicit recipe table; unrelated pairs simply return unchanged. Show the result preview before committing. Merge animation never consumes fish twice.

First discovery fills the collection entry. Placing a fish in a water jar consumes that carried fish and activates its displayed bonus; the discovery record remains permanent. Bonus examples: sale value, reel control, machine speed. Use modest additive bonuses with a cap, and show their exact totals. Duplicates remain useful for selling or further merges.

Start with a short recipe chain, then expand through existing fish models. A final-tier fish cannot merge further. Never require sacrificing a displayed collection fish to progress.

## Juice: The Main Quality Bar
Make every action follow **anticipation → impact → reward → settle**. Feedback starts immediately; animations must not delay control or obscure the next action.

| Moment | Satisfaction treatment |
|---|---|
| Cast and bite | Rod wind-up, curved cast motion, float plop, expanding rings; sharp bob and distinct bite cue. |
| Reeling | Rod bend, taut line, fish splashes; reel clicks accelerate with progress. Danger sounds rise before the line can break. |
| Catch | Brief accent pause in the landing animation, splash burst, fish hop, basket bounce, and a bright ascending chime. Rare catches get a stronger but short reveal. |
| Carry | Slight stack sway and springy settling on pickup; crisp footsteps and responsive turns. Stack never blocks the destination. |
| Cutting | Spin-up hum, rhythmic clacks, fish feed arcs, output pops, and a satisfying batch-complete ding. Larger hauls build a faster sound rhythm. |
| Sale and cash | Customer handoff, happy reaction, coin clinks; collection creates a staggered coin trail and rolling HUD count. |
| Merge | Fish pull together, compress, then pop into the result with rings and sparkles. Reveal species, rarity, and newly available bonus. |
| Upgrade | Cost fills down visibly; construction dust clears into the real asset, followed by a bounce and celebratory chord. Show the improvement immediately. |

Prioritize responsive movement, clear silhouettes, warm light, turquoise water, and readable effects over visual clutter. Use short, layered sounds rather than constant loud rewards. Reserve stronger effects for rare catches, first discoveries, and expansions. Cosmetic coin particles are never the source of economy state.

Camera shake is subtle and optional; never rotate the camera for impact. Include reduced motion/flashes, independent music/SFX volume, a toggle alternative to holding reel, and forgiving fishing assistance. Tension and rarity must not rely on color alone.

## Progression and Economy
The opening teaches one system at a time: land a fish, deliver to the machine, stock the stall, collect cash, buy a visible upgrade, then introduce merge jars and hiring. Aim for the first sale within two minutes and the first upgrade within five; verify with new players.

One soft currency: coins. Sale prices scale with species rarity. Give each raw fish a stored total sale value, divided exactly across five species-colored processed portions, so cutting never accidentally multiplies earnings. A merge's sale value must not beat selling both inputs; its reward is discovery and permanent bonuses.

Tune machine output and customer demand against actual catch rates. Show bottlenecks clearly: “Crate full,” “Needs stock,” or “More customers.” No spoilage, bankruptcy, forced ads, premium currency, or prestige reset in the initial scope. Monetization is not specified by the high concept and is outside this design.

## World and Asset Rules
One compact lakeside hub: docks at the water, machine and stall on shore, merge display beside the main route. Keep early travel between stations around 3–5 seconds. Expansions add nearby docks and machines without turning delivery into long walks.

- **Fish, rods, docks:** Quaternius Cute Fish FBX models. Start with a small usable roster; add inventory species as content expands. Inspect Goldfish, BlueGoldfish, and Puffer for the documented missing-mesh issue before featuring them.
- **Nature:** Quaternius Ultimate Nature; plain and autumn trees, rocks, grass, and lily pads frame routes without hiding pads or customers.
- **People:** `Pescador.glb` and `Cliente 1–10.glb` from the assembled itHappy characters. Real people, not creatures. Reuse their rigged idle/walk/run clips. Cast, reel, carry, handoff, and celebration clips are not supplied: drive props procedurally first; any later Mixamo work requires import/retarget verification.
- **Machine and stall:** assemble only existing Medieval Village models, especially `Sawmill_saw`, crates, barrels, and market stands. **No custom modeling.** Represent processed stock with existing package props rather than assuming steak meshes exist.
- **Water jars:** no dedicated glass jar is listed. Transparent water jars remain the final visual goal; approve a suitable asset before final art. Water-filled barrel displays are an optional prototype fallback, not a change to the high concept.
- **Scale:** normalize every prefab explicitly; packs have incompatible authored scales. Target people at 1.8–1.9 m tall, carried fish at 0.35–0.65 m long, rods at 1.5–2 m, docks at 2–3 m wide, and machine work surfaces around 1 m high. Preserve aspect ratios, correct pivots, and validate hand attachments and clearances in-engine.
- Keep itHappy source assets out of Git and comply with their redistribution restrictions. Verify licenses before release.

## Delivery and Acceptance
Build in order: **one juicy catch → complete catch-to-cash loop → upgrade → merge and jar bonus → worker and expansion → polish**. The first playable needs one dock, one machine, one stall, a short merge chain, one worker, and a few upgrades—not all 35 fish.

Save coins, inventories, machine queues, sale stock, uncollected cash, upgrades, discoveries, displayed fish, and workers. Save after committed transactions and on suspend; visual effects must never duplicate rewards after reload. Pause fishing on focus loss. Keep a valid backup save.

Done means a new player understands the loop without explanation; catches, cutting, collecting, and merging feel satisfying repeatedly; rewards remain exact through capacity limits and save/load; and all controls work on touch and Mac. Target 60 fps, with a stable 30 fps quality option on the weakest supported device, tested in exported builds. Do not declare the game polished until its busiest expanded hub stays readable and responsive.

## V5 transaction and presentation contracts

- Catch → carry → CUT → OUT pickup → STOCK → species-specific sale → CASH remain separate transactions. Five portions sum to the original fish value; species color survives processing, storage, delivery and saves.
- The original cutter feeds a whole supplied fish and visibly separates ten capped mesh pieces before producing packages. Cosmetic pieces and arcs never award output. Reduced motion removes feed/slice bounce.
- Matching fish dropped together on the actual lakeside workbench merge immediately. Invalid/outside drops are harmless. Keep the result protected, commit exact indices once, lock repeated input during the reveal, and provide 16-socket pages for all carried fish.
- Camera entry/return is a smooth fixed-yaw perspective transition in the same world. No isolated SubViewport, isometric camera, or hidden player/world swap.
- Collection pads display layered 3×3 resource piles, not “X to collect” quantity signs. Accepted fish/packages fly into persistent backpack slots; collected coins fly to the wallet UI. Visual caps do not truncate the economy.
- Purchase pads use white corner outlines, hammer stamps, real costs and cancellable 0.9s dwell. Coin trails happen only after the atomic purchase; there is no partial-investment mechanic.
- Queue/output/stock/worker capacities: 200 fish per machine / 1000 packages per machine / 1000 stocked packages / 100 fish per fisher. Transfers move schools of up to five every 0.08s in one saved transaction; base cutting is about 0.95s/fish; sales about 0.35s/portion; worker schools every 4s. Tune against exported performance and playtests, not only automated checks.
- Physical **1** opens debug tools in development builds. Settings requires confirmation to reset. Reset validates a fresh checksum file and removes old recovery files so old progress cannot reappear.

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
