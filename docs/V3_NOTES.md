# V3 — reference and movement pass

V3 is a saved working-tree pass, not a release, commit or new tag. V1 and the V1 save format are unchanged.

## Reported movement bug: reproduced and fixed
The supplied walk/run animations translate **Skeleton3D:Root**, above Hips, by **1.48 m / 1.90 m** each cycle. Previously only Hips X/Z was locked. The animated character therefore ran ahead of its physics capsule and basket, then snapped back at the loop seam. This also made its apparent speed much higher than the controller's 4.7 m/s.

`in_place_animation.gd` duplicates locomotion clips and pins all top-level bones to rest; Hips retains vertical bob but no horizontal drift. Player and customers use these copies. Private source assets and their original animations are untouched. The physics capsule is the only translation owner; Model, Basket/Carried and Rod share its Visual parent.

The default pace is now **3.1 m/s**, configurable as `move_speed` on Fisherman. Starts accelerate briefly; release stops immediately. Animation speed follows actual movement with walk/run hysteresis. The stick now floats from the initial touch, initially neutral, within the authored lower-left input region. Its 10% radial dead zone, analog travel, clamping, independent pointer ownership, outside release and modal/focus resets are retained. Inverse camera projection makes diagonals visually follow the thumb without a speed boost or camera rotation.

## Reference-inspired presentation
- Bright blue/turquoise water with subtle warped caustics and a broad scalloped foam edge. Foam follows the actual saved sand boundary at Z=-2.45, rather than being hidden under land. Reduced motion freezes the water.
- Thirteen saved rounded-rectangle interaction zones, dashed outlines, contextual icons, cost/level/completion text and on-ground upgrade dwell bars. Camera-facing captions preserve landscape readability. The authored Surface PlaneMesh size also controls the interaction footprint, including corners.
- Consistently sized actual fish (0.54 m carried length), aligned over the basket; compact package grids at output/market, with an inventory count over the carry stack. Visual caps: eight carried fish, five carried packages, twelve packages at output/market. HUD/labels always show authoritative counts, not these visual caps.
- Unchanged carried/station stacks are reused rather than respawned after wallet-only notifications. Geometry bounds and model resources are cached.
- Front-customer package request bubble (any stock accepted), full-capacity/delivery/cash status and an onboarding milestone bar. These indicators never award currency or consume inventory.

## Lightweight mobile-feature research
Sources consulted on 2026-10-01:
- [Apple: Game controls](https://developer.apple.com/design/human-interface-guidelines/game-controls). Retrieved Apple's documentation JSON, including its June 2025 guidance: floating movement controls where the thumb lands, generous reachable areas, predictable mapping, visible press states and contextual controls. Applied floating input, active-direction feedback and context-specific icons. Real device safe-area/haptic validation is still needed.
- [My Mini Mart — App Store](https://apps.apple.com/us/app/my-mini-mart/id1592004814). Listing describes processing, stock supply, staff and reinvestment/expansion. Existing workers, finite stock and upgrade loops already fit; this pass improves their visible needs and feedback.
- [Burger Please! — App Store](https://apps.apple.com/us/app/burger-please/id1668713081). Listing describes stocking/serving, hiring/training, upgrades and expansion, plus challenges/events. Consider small optional delivery goals later, only after validating the core loop and balance.

These are design examples and platform guidance, not a market survey or evidence of retention/balance. No forced ads, premium currencies, energy gates, daily-login pressure, offline rewards or prestige reset were added.

## Verification
**166 checks passed**: the existing 132 checks plus 34 V3 checks. V3 includes a negative control that reproduces drift with the original clip, corrected poses across every loop seam, actual multi-loop movement with attached fish, measured 3.1 m/s full-stick and 1.55 m/s half-stick pace, screen diagonals, neutral touch starts, release, geometry scales, rectangular zone corners, cancellable purchase progress, actor reuse, stock requests and frozen reduced-motion water.

The older V2 speed assertion now follows the slower configured pace. Its invalid-drop test waits for the actual actor to return (bounded to 30 frames) rather than checking a 0.22s tween against a fragile 0.23s timer; timer callbacks can precede tween completion within the same frame. Economy/ownership assertions are unchanged.

Visually inspected shoreline, expanded hub, upgrade zones, carried stack during actual injected keyboard movement and saved scene composition. Tests/fixtures disable saving and restore player data. Passing checks still does not establish new-player onboarding, balance, sustained polish or exported-device performance. Original assets/animations, licensing, final jar art and dedicated carry/fishing clips remain the same release limitations as V2.
