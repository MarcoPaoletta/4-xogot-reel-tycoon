# Reel Tycoon

A 3D fishing tycoon for phones, tablets and desktop. You fish from a dock with a tension and reel minigame, carry the catch to a cutting machine, sell the slices to customers who line up at your stall, and merge matching fish into rarer ones that live in water jars with passive bonuses. Hire fishers and expand the lakeside to grow the business.

The whole game was built from scratch with the Xogot built in agent, as a Godot 4.7 project using the Mobile renderer. It plays in 16:9 with a follow camera behind the player and a virtual joystick.

## Open and run it

The repository runs out of the box. You do not need to download anything else.

**In Xogot**

1. Clone or download this repository and open the folder as a project in Xogot.
2. Wait for the first import to finish, then press Play. The main scene is `scenes/main.tscn`.

**In Godot 4.7**

1. Clone this repository.
2. Open Godot 4.7, choose Import, and select `project.godot`. Wait for the first import to finish.
3. Press F5. The main scene is `scenes/main.tscn`.

**Controls:** WASD or arrow keys to move (or drag the on screen joystick), Space for the context action, Escape for the menu.

## Characters

The fisherman and the ten customers are real looking people with an idle, walk and run animation.

- **In this public repository** they are free CC0 characters from the Quaternius Ultimate Animated Character Pack. They are included, so the game runs and animates out of the box. The game gives each of them a skin tone at runtime.
- **In the video version** they are made from **itHappy Creative Characters FREE**. That pack's license does not allow redistributing the files, even for free, and does not allow distributing modified versions unless they are part of a finished product. The assembled characters are modified versions, so they are not in this repository.

If the files `Pescador.glb` and `Cliente 1.glb` to `Cliente 10.glb` exist in `assets/itHappy Characters GLB/`, the game uses them. If not, it uses the CC0 characters. No code change is needed either way, and the game prints which set it found when it starts.

**Get the video look.** Download the pack from the official page (https://ithappystudios.com/free/creative-characters-free/) or from the Unity Asset Store (https://assetstore.unity.com/packages/3d/characters/humanoids/creative-characters-free-animated-pack-304841), then follow [`docs/CHARACTERS_SETUP.md`](docs/CHARACTERS_SETUP.md). The characters were assembled from the pack's parts in Blender, and that guide contains the exact recipe and a script, `tools/build_characters.py`, that rebuilds all 11 files from your own copy of the pack. You can hand the guide to your own AI coding agent.

**License summary** (ITHappy Studios Free Asset Usage Policy, https://ithappystudios.com/free-asset-usage-policy/, read the original for the exact terms):

- Personal and commercial projects are allowed, with an unlimited number of final products. No credit is required.
- You may not distribute the assets "as is", and you may not distribute modified versions, unless they are part of a finished product.
- A compiled build of the game (for example a TestFlight build) is a finished product and may include the characters.
- You may not use the assets in on demand or build it yourself tools.

Never commit the itHappy files or anything derived from them. Both asset folders are in `.gitignore`.

## Assets and credits

All 3D models in this repository are CC0 by Quaternius (https://quaternius.com/). Each pack folder keeps its `License.txt`.

- Cute Fish Pack: https://quaternius.com/packs/cutefish.html
- Ultimate Nature Pack: https://quaternius.com/packs/ultimatenature.html
- Medieval Village Pack: https://quaternius.com/packs/medievalvillage.html
- Ultimate Animated Character Pack, seven characters used as the stand in people: https://quaternius.com/packs/ultimatedanimatedcharacter.html
- itHappy Creative Characters FREE, not included, optional: https://ithappystudios.com/free/creative-characters-free/

Sound is synthesized by the game's own code. The interface icons, shaders and the customer request bubble are original to this project. Full details are in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Tests

The structural checks run headless with desktop Godot 4.7:

```
godot --headless --path . -s res://tools/run_structure_tests.gd
```

Expected: one `PASS` line per test and `FAILURES: 0`. The gameplay suites in `tests/game` run inside the game with the Xogot `xo` tool, as described in [`docs/PLAYABLE.md`](docs/PLAYABLE.md).

## Exporting to iOS

The project uses the Mobile renderer. A native iOS export needs ETC2/ASTC texture compression, so `rendering/textures/vram_compression/import_etc2_astc` is enabled in `project.godot` (Project Settings, Rendering, Textures, VRAM Compression, Import ETC2 ASTC). Leave it on, otherwise the export presets report that the target platform requires ETC2/ASTC texture compression. After changing it, let the project reimport.

## More documentation

- [`docs/HIGH_CONCEPT.md`](docs/HIGH_CONCEPT.md) and [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md): what the game is and how it should feel.
- [`docs/PLAYABLE.md`](docs/PLAYABLE.md) and [`docs/AUTHORING.md`](docs/AUTHORING.md): how the build is organized and how to edit it.
- [`docs/asset-inventory.md`](docs/asset-inventory.md): every available model with its measured size.
