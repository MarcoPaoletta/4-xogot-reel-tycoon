# Optional: build the video look characters

This guide is written so you can hand it to your own AI coding agent. Every step is a plain command or a file check, so any agent that can run a shell can follow it.

## 1. Why this is optional

The repository runs out of the box with free CC0 stand in characters (Quaternius). The characters in the video are different: they come from the **itHappy Creative Characters FREE** pack, and its license forbids redistributing the files, even for free, and forbids distributing modified versions unless they are part of a finished product. The assembled `Pescador.glb` and `Cliente 1.glb` to `Cliente 10.glb` are modified versions of that pack, so they are not in this repository and nobody can download them from here.

Policy: https://ithappystudios.com/free-asset-usage-policy/

What you can do is build them locally from your own copy of the pack. That is what this guide and `tools/build_characters.py` do. Keep the result on your machine. A compiled build of the game (for example a TestFlight build) is a finished product and may contain them.

When the files are in place the game picks them up automatically. When they are missing it falls back to the CC0 characters, so you can delete them at any time.

## 2. Get the pack

Download **Creative Characters FREE** from one of these sources. Check which one you get and what format it ships in, because only the first one is known to contain the Blender file the script needs.

1. The official site: https://ithappystudios.com/free/creative-characters-free/ (the page lists Blender, FBX, OBJ, GLTF and engine versions).
2. The Unity Asset Store listing: https://assetstore.unity.com/packages/3d/characters/humanoids/creative-characters-free-animated-pack-304841 (Unity packages, under the Standard Unity Asset Store EULA).

What the build script needs is the Blender file of the pack, named `Creative_Characters_Free.blend`. It must contain:

- the rig object named `Skeleton` (44 bones, Mixamo style names such as `Root`, `Hips`, `LeftUpLeg`);
- the part objects listed in the recipe below (`Body_010`, `Hat_010`, `Pants_014`, and so on);
- the material `Color` and the texture `Textures_4.png`;
- animation actions as NLA tracks on the rig, including at least `Idle_Breathing`, `Walk_Forward` and `Run_Forward`.

The script checks all of this first and stops with a list of whatever is missing. See "Known limitations" about the animations.

## 3. Exactly what the game expects

Files, in `assets/itHappy Characters GLB/` (this folder is in `.gitignore`):

```
Pescador.glb
Cliente 1.glb
Cliente 2.glb
...
Cliente 10.glb
```

Each file must be a GLB that Godot imports as one scene with:

- exactly one `Skeleton3D` and one `AnimationPlayer`, found by `find_child`, at any depth;
- a skinned human rig of 44 bones. The top bone is named `Root` (the tests look it up by that name) and its child is `Hips`. `scripts/in_place_animation.gd` pins every top level bone to its rest pose and removes horizontal drift from `Hips`;
- these three clips, spelled exactly like this (the game reads nothing else): `Idle_Breathing`, `Walk_Forward`, `Run_Forward`. `scripts/world.gd`, `scripts/player.gd` and `scripts/people.gd` duplicate them at runtime into a `locomotion` library;
- a character standing on the origin, feet at Y 0, about 1.86 to 1.9 units tall, arms spread about 1.44 wide, front facing +Z (the game turns it with `atan2(x, z)`);
- skin, materials and the texture embedded in the GLB.

Reference measurements from the original files, all reproduced by the script: Pescador 1.44 x 1.90 x 0.47, Cliente 1 1.44 x 1.86 x 0.39, Cliente 3 1.44 x 1.86 x 0.46 (see `docs/asset-inventory.md` for the rest). `Idle_Breathing` is 9.47 s, `Walk_Forward` 1.03 s, `Run_Forward` 0.77 s.

## 4. The assembly recipe

All 11 characters share one rig and one texture atlas. Each one is a list of parts bound to its own copy of the rig, with an optional color shift per part. Hue 0.5 means no hue change. Saturation is never changed.

| Character | Parts | Tints (part: hue, value) |
| :-- | :-- | :-- |
| Pescador | Body_010, Hat_010, Male_emotion_happy_002, Moustache_002, Outerwear_036, Pants_010, Shoe_Slippers_002, Socks_008, T_Shirt_009 | none |
| Cliente 1 | Body_010, Glasses_004, Hairstyle_male_010, Male_emotion_usual_001, Pants_014, Shoe_Sneakers_009, T_Shirt_009 | none |
| Cliente 2 | Body_010, Glasses_006, Hairstyle_male_012, Male_emotion_happy_002, Outerwear_029, Shoe_Slippers_005, Shorts_003 | Body_010: 0.5, 0.55 |
| Cliente 3 | Body_010, Hairstyle_male_012, Male_emotion_angry_003, Moustache_001, Outerwear_036, Pants_014, Shoe_Sneakers_009 | Body_010: 0.5, 1.15. Outerwear_036, Pants_014, Shoe_Sneakers_009: 0.75, 1.0 |
| Cliente 4 | Body_010, Hairstyle_male_010, Headphones_002, Male_emotion_happy_002, Shoe_Slippers_002, Shorts_003, T_Shirt_009 | Body_010: 0.5, 0.8. T_Shirt_009, Shorts_003, Shoe_Slippers_002: 0.2, 1.0 |
| Cliente 5 | Body_010, Glasses_004, Hairstyle_male_012, Male_emotion_usual_001, Outerwear_029, Pants_010, Shoe_Slippers_005 | Outerwear_029, Pants_010, Shoe_Slippers_005: 0.9, 1.0 |
| Cliente 6 | Body_010, Hairstyle_male_010, Male_emotion_happy_002, Outerwear_036, Pants_010, Shoe_Sneakers_009 | Body_010: 0.5, 0.5. Outerwear_036, Pants_010, Shoe_Sneakers_009: 0.1, 1.0 |
| Cliente 7 | Body_010, Hairstyle_male_012, Male_emotion_usual_001, Moustache_002, Pants_014, Shoe_Slippers_002, T_Shirt_009 | Body_010: 0.5, 1.15. T_Shirt_009, Pants_014, Shoe_Slippers_002: 0.85, 1.0 |
| Cliente 8 | Body_010, Glasses_006, Hairstyle_male_010, Male_emotion_happy_002, Shoe_Sneakers_009, Shorts_003, T_Shirt_009 | Body_010: 0.5, 0.6. T_Shirt_009, Shorts_003, Shoe_Sneakers_009: 0.35, 1.0 |
| Cliente 9 | Body_010, Hairstyle_male_012, Male_emotion_angry_003, Outerwear_029, Shoe_Slippers_005, Shorts_003 | Body_010: 0.5, 0.85. Outerwear_029, Shorts_003, Shoe_Slippers_005: 0.65, 1.0 |
| Cliente 10 | Body_010, Glasses_004, Hairstyle_male_010, Male_emotion_usual_001, Moustache_001, Outerwear_036, Pants_014, Shoe_Sneakers_009 | Body_010: 0.5, 1.1. Outerwear_036, Pants_014, Shoe_Sneakers_009: 0.3, 1.0 |

The same data lives in the `CHARACTERS` table at the top of `tools/build_characters.py`.

### Run it

Requirements: Blender on the command line (tested with 5.2, the exporter options used need 4.2 or newer), and the `Creative_Characters_Free.blend` from step 2. The script uses only Blender's bundled Python and NumPy. It reads the file you pass and writes only to the output folder.

1. Unzip the pack and note the full path of `Creative_Characters_Free.blend`.
2. From the repository root, run (adjust the Blender path for your system):

   ```
   blender -b "/path/to/Creative_Characters_Free.blend" -P tools/build_characters.py -- --out "assets/itHappy Characters GLB"
   ```

   To build only some characters add `--only Pescador "Cliente 3"`. Expect about one to two minutes per character.
3. Expect one `BUILT ...` line per character and a final `DONE: 11 characters written`. Each file is roughly 2.8 to 4.7 MB.
4. Open the project in Godot 4.7 or Xogot so the GLBs import, or run `godot --headless --path . --import`.
5. Run the checks in the next section.
6. Run `git status`. The new files must not appear (the folder is ignored). Never use `git add -f` on them.

### What the script does, step by step

For each character, in this order:

1. Copy the `Skeleton` rig object, name it `Skeleton_<character>`, put it at the origin and make `A-pose` its active action (the 30 NLA animation tracks come with the copy).
2. For each listed part, copy the object and its mesh data, parent the copy to the rig copy with an identity parent inverse, reset location, rotation and scale to zero and one (in the pack the parts sit in a display lineup), and point its Armature modifier at the rig copy. Modifiers (subdivision, auto smooth, weighted normal) are kept and applied at export.
3. For each tinted part, make a copy of the atlas texture `Textures_4.png` with the hue and value shift applied and swap it into a copy of the `Color` material for that part only. The glTF exporter cannot read a Hue/Saturation/Value node, so the shift is baked into the pixels. The math is the same as Blender's node: convert sRGB to linear, shift hue by (hue minus 0.5), multiply value, convert back.
4. Select the rig copy and its parts and export a GLB with these options: `export_format=GLB`, `use_selection=True`, `export_apply=True`, `export_yup=True`, `export_animations=True`, `export_animation_mode=NLA_TRACKS`, `export_skins=True`. All other exporter options keep Blender defaults.
5. Delete the temporary copies and continue with the next character.

## 5. Verification checklist

Run these in order. Every step has an expected result.

1. Files exist: `assets/itHappy Characters GLB/` holds 11 files with the exact names from section 3.
2. Import is clean: `godot --headless --path . --import` prints no `ERROR` lines about those files.
3. The structure tests pass. From the repository root:

   ```
   godot --headless --path . -s res://tools/run_structure_tests.gd
   ```

   Expected: the line `Characters: itHappy models found`, fourteen lines starting with `PASS` and the final line `FAILURES: 0`. If you see `Characters: CC0 Quaternius fallback`, the game did not find your files (see troubleshooting).
4. People appear and animate: open `scenes/main.tscn` and run the game. The fisherman at the dock and the customers at the stall must be the colorful characters, not the CC0 stand ins (the stand ins have flat low poly clothes and small dark eyes). The fisherman must switch between idle, walk and run when you move with WASD or the joystick, without sliding or snapping back.
5. Optional, with the Xogot `xo` tool as in `docs/PLAYABLE.md`: `xo game eval --file tests/game/test_juice.gd` checks all ten customer rigs.

### If a step fails

- The script prints `ERROR: This .blend does not match ...`: the file is not the expected pack file. Read the list of missing names it prints. You need the Blender version of the official pack (section 2).
- Blender exits with a Python error about an add on: run it with `--factory-startup` before `-b` to ignore your own add ons.
- `Characters: CC0 Quaternius fallback` even though the folder exists: check that the folder name is exactly `assets/itHappy Characters GLB/` (case sensitive on macOS and Linux), that the file names match section 3, and that the project finished importing.
- Tests report `Missing locomotion clips`: open the GLB in Godot and list the `AnimationPlayer` clips. `Idle_Breathing`, `Walk_Forward` and `Run_Forward` must exist. If your .blend names them differently, rename the actions or NLA tracks in Blender and run the script again.
- Characters look gray or untextured: the texture was not embedded. Make sure the .blend still has `Textures_4.png` (packed or in a `textures` folder next to it).
- Characters float, sink or face sideways: the origin or the facing was changed. Rebuild with the unmodified script.

## 6. Known limitations

These are the parts that could not be proven identical to the original video files, stated plainly.

- **Animations in the official download are unverified.** The script was developed and tested against the `Creative_Characters_Free.blend` that was used for the video. That file carries 30 NLA animation tracks. The official page of the pack lists a smaller animation count, and it says the GLB, OBJ and FBX versions ship without animations. We could not download the official pack to confirm that its Blender file contains `Idle_Breathing`, `Walk_Forward` and `Run_Forward`. If it does not, the script stops at its first check and the fallback characters stay in use. Without those three clips you would have to supply them yourself (for example Mixamo clips retargeted to the same 44 bone rig and added as NLA tracks with those exact names).
- **Clip set differs slightly from the original export.** The original files had 33 clips, this script exports the 30 NLA tracks. The original also had `run(back)`, `Armature|Take 001|BaseLayer` and a `Jump` clip that this export does not produce (it has `Jump_Loop`). The game uses none of them. The three clips the game reads match the original lengths (9.47 s, 1.03 s, 0.77 s).
- **Origin offsets.** In the original files each character kept its position from the display lineup in the Blender scene (spaced about 1.7 units apart), and the game recenters them at runtime. This script exports every character at the origin. The runtime recentering still runs and finds nothing to move.
- **Exporter options are inferred.** The exact options used for the original export were not recorded. The values above reproduce the original dimensions (all 11 match `docs/asset-inventory.md`), the clip lengths, the 44 bone rig and the colors seen in the concept image, but byte for byte equality was not possible.
- **Tints are baked, not shader nodes.** The original blend used a Hue/Saturation/Value node. The GLB cannot carry it, so each tinted part gets its own copy of the texture. This is why Cliente files are larger than Pescador.
- **No hand adjusted parts were found.** All 78 variant meshes in the original assembled blend were compared with the pack's part meshes: vertices, UVs, vertex groups and modifier stacks are identical. The only differences are the reset transforms and the tints listed above, and both are encoded in the script. Nothing in the recipe depends on the original assembled `.blend`.
- **Unity Asset Store version.** The Unity package does not contain a Blender file. The script does not support it. Use the official site download.
