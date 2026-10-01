# Reel Tycoon — first playable

Built against `GAME_DESIGN.md` on Godot 4.7.2 / Xogot 1.7.2.

## Play
Run `res://scenes/main.tscn` (the project main scene).

- WASD / arrows or the on-screen joystick: screen-aligned walking.
- Space or the action button: cast at a dock, then hold to reel. Release to cool tension. Movement cancels fishing without losing carried fish.
- Walk onto **CUT → OUT → STOCK → CASH** pads. Each is a distinct inventory transaction; cutting is not a money source.
- Stay on an upgrade pad for 1.2 seconds to buy. Exit to cancel; step off before another purchase.
- At MERGE, use the action button. Drag matching fish cards together, or use a recipe; confirm the preview. **Keep** protects selected fish from automatic cutting. Merge results are kept by default.
- Display a carried fish to activate its bonus. Discoveries remain permanent.
- Hire a fisher and collect its finite crate. Buy the second dock for rarer catches. There are no offline earnings.
- Settings: separate music/SFX, tap-to-toggle reel, fishing assist, reduced motion, and a 30 FPS battery-saver option.

The first catch is forgiving. The next-step arrow and business counters explain delivery and the first rod purchase.

## Implemented scope
Four species (Goldfish, Clownfish, Puffer, Swordfish), three explicit merge recipes, four displays, ten cycling customer appearances, four rod upgrades, three basket upgrades, three cutting-speed upgrades, one fisher and one dock expansion. Models are drawn from the supplied packs, with explicit scale normalization and per-instance fish palette overrides.

The camera is a fixed-yaw perspective follow camera above and behind the player, not isometric. Props move through visible feed/pickup/stock/catch arcs. Catch splashes, merge anticipation/pop, customer reactions, cash trails to the HUD, upgrade bursts, reel/danger cues, cutting spin-up and batch chimes provide feedback.

## Architecture and saves
- `scripts/main.gd`: runtime composition, fishing, pad dwell/interaction, business clocks, guidance, focus pause.
- `scripts/world.gd`: deterministic hub, asset instances, customers, station displays and cosmetic effects.
- `scripts/economy.gd`: authoritative transactions and save validation; autoload `Economy`.
- `scripts/player.gd`, `joystick.gd`: physics movement and multitouch.
- `scripts/hud.gd`, `fish_card.gd`: interface, collection/merge preview, settings, dragging.
- `scripts/audio.gd`: synthesized, independently scaled music and SFX.

The main scene intentionally composes the hub at runtime. Save data is in `user://reel_tycoon_v1.json`, with a checksum, temporary-file replacement and a valid `.bak` fallback. Committed inventories, queues, stock, cash, wallet, reservations, upgrades, discoveries, displays, workers, tutorial and settings persist. Small sale bonuses retain sub-coin remainders so rounding portions cannot erase or multiply their value. Fishing/animations and worker timers are not offline rewards.

## Verification
70 checks pass: 6 editor structure/asset checks, 62 live gameplay/economy checks, and 2 live multitouch checks. Also manually exercised keyboard fishing, mouse recipe buttons, drag-to-merge with confirmation, and display activation.

From the project directory, with Xogot open:

```sh
XO=/Applications/Xogot.app/Contents/MacOS/xo
"$XO" test run --full
"$XO" project run --wait
"$XO" game eval --file tests/game/test_behavior.gd --timeout 90
"$XO" game eval --file tests/game/test_touch.gd --timeout 10
```

Game suites live under `.gdignore` and are not editor behavior tests. The economy suite uses a separate test save and preserves the live player's data. Do not play concurrently with automation: it temporarily teleports the player and substitutes test state. The touch suite leaves the player at the main dock.

## Remaining release work (not claimed complete)
- **Final jars:** water-filled barrels are the GDD's prototype fallback; a suitable approved glass/water-jar asset is still needed.
- **Saw art:** the supplied `Sawmill_saw` contains a straight saw, not a circular blade. Its existing Metal surface is separated without changing geometry and oscillates; the frame kicks. No replacement machine was custom-modeled.
- **Character actions:** use supplied idle/walk/run clips and procedural rod/prop motion. Cast/reel/carry/celebration clips need verified import/retargeting if added later.
- Goldfish and Puffer's documented empty imported mesh is skipped; visible remaining geometry was checked. Final art should resolve the small missing parts.
- Expanded embedded hub was inspected and sampled around 30 FPS, roughly 105 MB static memory and 550 draw calls with shadows. This is not an exported-device benchmark or proof of the 60 FPS target. Test exported Mac/iPad/iPhone builds, quality modes and thermal behavior on the weakest device.
- Verify itHappy licensing/redistribution terms before shipping. See `res://THIRD_PARTY_NOTICES.md`.
- New-player onboarding, balance, phone safe areas/touch ergonomics, audio comfort and sustained expanded-hub performance still need real-device/playtester acceptance.
