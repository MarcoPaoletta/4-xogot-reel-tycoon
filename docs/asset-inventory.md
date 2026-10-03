# Asset inventory

Every 3D model available to the game, with its `res://` path and its size measured in Xogot (merged mesh bounds of the imported scene, in Godot units, meters at scale 1). "Min Y" is the lowest point of the model relative to its origin, so a model with Min Y 0 stands on its origin. Measured on 277 imported models plus the 11 characters below.

Only the FBX files are listed. Each Quaternius pack also ships the same models as OBJ (imported too, ignore them) and as `.blend` (excluded from import by a `.gdignore` in every `Blends/` folder).

## Scale warning

The packs were not authored to a common scale. The fish are roughly 3.8 to 6.89 units long, a single tree is far larger than a village prop, and the itHappy characters are about 1.86 units tall. Every prefab must set an explicit scale and the GDD lists the target sizes. Never assume 1 unit is 1 meter across packs.

## Import status

| Pack | Models | Imported | Notes |
|---|---|---|---|
| Cute Fish Pack, Feb 2020 | 52 | 52 | `BlueGoldfish`, `Goldfish` and `Puffer` each carry one empty mesh out of three (the importer skips it with a warning). Still usable, one small part is missing. |
| Ultimate Nature Pack, Jun 2019 | 150 | 150 | No errors. |
| Medieval Village Pack, Dec 2020 | 44 | 44 | No errors. |
| itHappy Creative Characters FREE (not redistributed) | 11 character GLB plus 31 GLB from the original pack | 42 | Each of the 11 characters has 1 `Skeleton3D`, 6 to 9 meshes and 33 animations. See Characters. |

The remaining console output is OBJ material warnings ("Ambient light ... ignored in PBR") from the duplicate OBJ imports, which are harmless.

## Fish and fishing gear (Cute Fish Pack, Feb 2020)

### Fish species (35)

| res:// path | Size X x Y x Z (units) | Min Y |
|---|---|---|
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Anglerfish.fbx` | 3.8 x 3.37 x 5.53 | -1.12 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/ArmoredCatfish.fbx` | 3.69 x 2.44 x 5.87 | -1.12 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Betta.fbx` | 3.07 x 3.38 x 5.59 | -1.73 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/BlackLionFish.fbx` | 3.84 x 6.06 x 6.89 | -1.37 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Blobfish.fbx` | 3.41 x 2.35 x 4.5 | -1.12 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/BlueGoldfish.fbx` | 3.28 x 4.48 x 5.64 | -1.69 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/BlueTang.fbx` | 3.24 x 2.87 x 4.8 | -1.36 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/ButterflyFish.fbx` | 3.38 x 2.87 x 4.8 | -1.36 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/CardinalFish.fbx` | 2.54 x 3.35 x 5.56 | -1.69 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Clownfish.fbx` | 4.41 x 3.04 x 5.27 | -1.22 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/CoralGrouper.fbx` | 3.18 x 2.57 x 5.28 | -1.14 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Cowfish.fbx` | 3.38 x 2.24 x 5.6 | -0.95 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Flatfish.fbx` | 2.09 x 4.05 x 4.74 | -1.98 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/FlowerHorn.fbx` | 3.18 x 2.98 x 5.37 | -1.36 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/GoblinShark.fbx` | 3.9 x 2.76 x 4.64 | -1.12 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Goldfish.fbx` | 3.28 x 4.48 x 5.64 | -1.69 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Humphead.fbx` | 4.16 x 3.29 x 5.94 | -1.54 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Koi.fbx` | 3.18 x 4.48 x 5.67 | -1.69 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Lionfish.fbx` | 3.84 x 5.19 x 6.35 | -1.4 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/MandarinFish.fbx` | 2.64 x 1.95 x 4.44 | -0.95 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/MoorishIdol.fbx` | 3.3 x 2.92 x 4.34 | -1.34 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/ParrotFish.fbx` | 3.9 x 3.05 x 5.8 | -1.23 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Piranha.fbx` | 3.18 x 2.42 x 4.76 | -1.12 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Puffer.fbx` | 3.47 x 2.62 x 4.02 | -1.22 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/RedSnapper.fbx` | 3.18 x 2.69 x 5.28 | -1.12 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/RoyalGramma.fbx` | 2.64 x 1.95 x 4.44 | -0.95 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Shark.fbx` | 3.81 x 3.79 x 5.36 | -1.31 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Sunfish.fbx` | 3.25 x 5.81 x 3.8 | -2.63 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Swordfish.fbx` | 3.59 x 3.82 x 6.45 | -1.22 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Tang.fbx` | 3.25 x 2.69 x 4.23 | -1.32 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Tetra.fbx` | 2.98 x 1.75 x 5.27 | -0.9 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Tuna.fbx` | 3.9 x 3.52 x 5.63 | -1.64 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Turbot.fbx` | 2.09 x 3.94 x 4.63 | -1.89 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/YellowTang.fbx` | 3.24 x 2.87 x 4.5 | -1.1 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/ZebraClownFish.fbx` | 4.32 x 3.01 x 5.27 | -1.22 |

### Fishing rods, lures, worm, dock pieces and boat

The pack ships its own dock pieces and a boat, so the dock and the rod in the hand do not need any other source.

| res:// path | Size X x Y x Z (units) | Min Y |
|---|---|---|
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Boat.fbx` | 4.67 x 2.01 x 9.01 | -0.03 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Dock_Long.fbx` | 9.21 x 7.8 x 21.69 | -0.21 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Dock_Long_NoRope.fbx` | 9.21 x 5.66 x 21.69 | -0.18 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Dock_Stairs.fbx` | 8.7 x 7.63 x 9.47 | -0.45 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Dock_Wide.fbx` | 14.63 x 7.68 x 21.69 | -0.23 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/FishingRod_Lvl1.fbx` | 0.21 x 6.3 x 0.58 | -1.39 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/FishingRod_Lvl2.fbx` | 0.47 x 6.34 x 0.5 | -1.39 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/FishingRod_Lvl3.fbx` | 0.36 x 6.59 x 0.43 | 0.0 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/FishingRod_Lvl4.fbx` | 0.66 x 7.38 x 0.47 | -0.74 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/FishingRod_Lvl5.fbx` | 0.69 x 7.78 x 0.5 | -0.78 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Lure_1.fbx` | 1.87 x 0.62 x 0.62 | -0.31 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Lure_2.fbx` | 1.87 x 0.62 x 0.62 | -0.31 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Lure_3.fbx` | 1.87 x 0.62 x 0.62 | -0.31 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Lure_4.fbx` | 1.87 x 0.62 x 0.62 | -0.31 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Lure_5.fbx` | 1.87 x 0.62 x 0.62 | -0.31 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Lure_6.fbx` | 1.87 x 0.62 x 0.62 | -0.31 |
| `res://assets/Cute Fish Pack - Feb 2020/FBX/Worm.fbx` | 0.49 x 0.48 x 0.43 | 0.0 |

## Nature (Ultimate Nature Pack, Jun 2019)

### Trees, willows and palms

Variants by season: plain, Autumn, Dead, Snow. The lake shore uses the plain and Autumn variants.

| res:// path | Size X x Y x Z (units) | Min Y |
|---|---|---|
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_1.fbx` | 1.7 x 3.57 x 2.48 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_2.fbx` | 1.47 x 4.03 x 1.69 | -0.04 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_3.fbx` | 1.57 x 4.09 x 1.77 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_4.fbx` | 1.15 x 3.56 x 3.29 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_5.fbx` | 1.19 x 5.01 x 1.93 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Autumn_1.fbx` | 1.7 x 3.57 x 2.48 | -0.03 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Autumn_2.fbx` | 1.47 x 4.03 x 1.69 | -0.04 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Autumn_3.fbx` | 1.57 x 4.09 x 1.77 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Autumn_4.fbx` | 1.15 x 3.56 x 3.29 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Autumn_5.fbx` | 1.19 x 5.01 x 1.93 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Dead_1.fbx` | 0.48 x 2.25 x 1.63 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Dead_2.fbx` | 0.69 x 2.63 x 0.88 | -0.04 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Dead_3.fbx` | 0.72 x 3.18 x 0.81 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Dead_4.fbx` | 0.5 x 2.69 x 2.6 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Dead_5.fbx` | 0.57 x 4.37 x 1.05 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Dead_Snow_1.fbx` | 0.48 x 2.25 x 1.63 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Dead_Snow_2.fbx` | 0.69 x 2.63 x 0.88 | -0.04 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Dead_Snow_3.fbx` | 0.72 x 3.18 x 0.81 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Dead_Snow_4.fbx` | 0.5 x 2.69 x 2.6 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Dead_Snow_5.fbx` | 0.57 x 4.37 x 1.05 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Snow_1.fbx` | 1.7 x 3.59 x 2.48 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Snow_2.fbx` | 1.47 x 4.09 x 1.69 | -0.04 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Snow_3.fbx` | 1.57 x 4.15 x 1.77 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Snow_4.fbx` | 1.15 x 3.6 x 3.29 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BirchTree_Snow_5.fbx` | 1.19 x 5.06 x 1.93 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_1.fbx` | 1.89 x 2.48 x 2.77 | -0.04 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_2.fbx` | 1.66 x 3.12 x 2.54 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_3.fbx` | 1.28 x 3.46 x 1.56 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_4.fbx` | 1.58 x 2.78 x 1.8 | -0.11 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_5.fbx` | 1.29 x 2.53 x 2.25 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Autumn_1.fbx` | 1.89 x 2.48 x 2.77 | -0.04 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Autumn_2.fbx` | 1.66 x 3.12 x 2.54 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Autumn_3.fbx` | 1.28 x 3.46 x 1.56 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Autumn_4.fbx` | 1.58 x 2.78 x 1.8 | -0.11 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Autumn_5.fbx` | 1.29 x 2.53 x 2.25 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Dead_1.fbx` | 1.04 x 2.22 x 2.12 | -0.04 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Dead_2.fbx` | 1.33 x 2.96 x 1.86 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Dead_3.fbx` | 0.64 x 3.0 x 0.81 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Dead_4.fbx` | 0.82 x 2.37 x 1.08 | -0.11 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Dead_5.fbx` | 0.84 x 2.3 x 1.2 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Dead_Snow_1.fbx` | 1.04 x 2.22 x 2.12 | -0.04 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Dead_Snow_2.fbx` | 1.33 x 2.96 x 1.86 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Dead_Snow_3.fbx` | 0.64 x 3.0 x 0.81 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Dead_Snow_4.fbx` | 0.82 x 2.37 x 1.08 | -0.11 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Dead_Snow_5.fbx` | 0.84 x 2.3 x 1.2 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Snow_1.fbx` | 1.89 x 2.51 x 2.77 | -0.04 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Snow_2.fbx` | 1.66 x 3.16 x 2.54 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Snow_3.fbx` | 1.28 x 3.47 x 1.56 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Snow_4.fbx` | 1.58 x 2.8 x 1.8 | -0.11 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CommonTree_Snow_5.fbx` | 1.29 x 2.57 x 2.25 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PalmTree_1.fbx` | 2.88 x 4.47 x 2.61 | -0.02 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PalmTree_2.fbx` | 2.32 x 2.91 x 3.18 | -0.04 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PalmTree_3.fbx` | 2.88 x 3.93 x 2.51 | -0.02 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PalmTree_4.fbx` | 2.34 x 3.47 x 2.59 | 0.0 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_1.fbx` | 1.96 x 2.7 x 1.82 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_2.fbx` | 1.8 x 3.56 x 1.96 | -0.02 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_3.fbx` | 2.16 x 3.3 x 1.95 | 0.0 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_4.fbx` | 1.25 x 3.34 x 1.39 | 0.0 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_5.fbx` | 1.47 x 2.69 x 1.34 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_Autumn_1.fbx` | 1.96 x 2.7 x 1.82 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_Autumn_2.fbx` | 1.8 x 3.56 x 1.96 | -0.02 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_Autumn_3.fbx` | 2.16 x 3.3 x 1.95 | 0.0 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_Autumn_4.fbx` | 1.25 x 3.34 x 1.39 | 0.0 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_Autumn_5.fbx` | 1.47 x 2.69 x 1.34 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_Snow_1.fbx` | 1.96 x 2.7 x 1.82 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_Snow_2.fbx` | 1.8 x 3.56 x 1.96 | -0.02 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_Snow_3.fbx` | 2.16 x 3.3 x 1.95 | 0.0 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_Snow_4.fbx` | 1.25 x 3.34 x 1.39 | 0.0 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/PineTree_Snow_5.fbx` | 1.47 x 2.69 x 1.34 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_1.fbx` | 1.45 x 2.85 x 2.55 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_2.fbx` | 1.95 x 3.32 x 3.11 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_3.fbx` | 1.32 x 2.35 x 1.98 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_4.fbx` | 2.19 x 3.39 x 3.04 | -0.03 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_5.fbx` | 1.01 x 2.42 x 2.49 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Autumn_1.fbx` | 1.45 x 2.85 x 2.55 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Autumn_2.fbx` | 1.95 x 3.32 x 3.11 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Autumn_3.fbx` | 1.32 x 2.35 x 1.98 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Autumn_4.fbx` | 2.19 x 3.39 x 3.04 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Autumn_5.fbx` | 1.01 x 2.42 x 2.49 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Dead_1.fbx` | 0.5 x 2.69 x 1.81 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Dead_2.fbx` | 1.17 x 2.84 x 2.4 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Dead_3.fbx` | 0.31 x 1.91 x 1.58 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Dead_4.fbx` | 1.01 x 2.72 x 2.59 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Dead_5.fbx` | 0.57 x 2.04 x 1.95 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Dead_Snow_1.fbx` | 0.5 x 2.69 x 1.81 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Dead_Snow_2.fbx` | 1.17 x 2.84 x 2.4 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Dead_Snow_3.fbx` | 0.31 x 1.91 x 1.58 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Dead_Snow_4.fbx` | 1.01 x 2.72 x 2.59 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Dead_Snow_5.fbx` | 0.57 x 2.04 x 1.95 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Snow_1.fbx` | 1.45 x 2.93 x 2.57 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Snow_2.fbx` | 1.95 x 3.46 x 3.16 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Snow_3.fbx` | 1.32 x 2.41 x 1.98 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Snow_4.fbx` | 2.19 x 3.46 x 3.04 | -0.03 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Willow_Snow_5.fbx` | 1.01 x 2.46 x 2.49 | -0.01 |

### Rocks

| res:// path | Size X x Y x Z (units) | Min Y |
|---|---|---|
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_1.fbx` | 0.49 x 0.88 x 0.47 | -0.05 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_2.fbx` | 0.56 x 0.65 x 0.57 | -0.09 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_3.fbx` | 0.74 x 0.68 x 0.8 | -0.12 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_4.fbx` | 0.74 x 0.78 x 1.25 | -0.27 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_5.fbx` | 0.66 x 0.65 x 0.91 | -0.06 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_6.fbx` | 0.91 x 0.71 x 1.14 | 0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_7.fbx` | 0.88 x 0.85 x 1.1 | -0.3 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_Moss_1.fbx` | 0.49 x 0.95 x 0.47 | -0.17 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_Moss_2.fbx` | 0.61 x 0.69 x 0.65 | -0.14 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_Moss_3.fbx` | 0.74 x 0.56 x 0.8 | 0.0 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_Moss_4.fbx` | 0.74 x 0.78 x 1.25 | -0.27 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_Moss_5.fbx` | 0.66 x 0.58 x 0.91 | 0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_Moss_6.fbx` | 0.91 x 0.71 x 1.14 | 0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_Moss_7.fbx` | 0.88 x 0.77 x 1.1 | -0.23 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_Snow_1.fbx` | 0.49 x 0.98 x 0.47 | -0.17 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_Snow_2.fbx` | 0.61 x 0.72 x 0.65 | -0.14 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_Snow_3.fbx` | 0.74 x 0.58 x 0.8 | 0.0 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_Snow_4.fbx` | 0.74 x 0.8 x 1.25 | -0.27 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_Snow_5.fbx` | 0.66 x 0.61 x 0.91 | 0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_Snow_6.fbx` | 0.91 x 0.74 x 1.14 | 0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Rock_Snow_7.fbx` | 0.88 x 0.79 x 1.1 | -0.23 |

### Logs and stumps

| res:// path | Size X x Y x Z (units) | Min Y |
|---|---|---|
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/TreeStump.fbx` | 1.36 x 0.62 x 1.03 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/TreeStump_Moss.fbx` | 1.36 x 0.62 x 1.03 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/TreeStump_Snow.fbx` | 1.36 x 0.62 x 1.03 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/WoodLog.fbx` | 0.63 x 0.75 x 2.67 | 0.0 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/WoodLog_Moss.fbx` | 0.9 x 0.69 x 2.67 | 0.0 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/WoodLog_Snow.fbx` | 0.63 x 0.58 x 2.49 | -0.02 |

### Plants, bushes, grass, flowers and crops

`Lilypad` is the only water plant.

| res:// path | Size X x Y x Z (units) | Min Y |
|---|---|---|
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BushBerries_1.fbx` | 1.39 x 1.28 x 1.72 | -0.03 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/BushBerries_2.fbx` | 1.34 x 1.13 x 1.33 | -0.06 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Bush_1.fbx` | 1.33 x 1.24 x 1.69 | -0.04 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Bush_2.fbx` | 1.35 x 1.11 x 1.33 | -0.08 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Bush_Snow_1.fbx` | 1.39 x 1.28 x 1.78 | -0.06 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Bush_Snow_2.fbx` | 1.36 x 1.16 x 1.36 | -0.07 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CactusFlower_1.fbx` | 0.88 x 0.36 x 0.87 | -0.19 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CactusFlowers_2.fbx` | 0.77 x 1.94 x 1.28 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CactusFlowers_3.fbx` | 0.48 x 1.67 x 1.12 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CactusFlowers_4.fbx` | 0.11 x 1.38 x 0.97 | -0.02 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/CactusFlowers_5.fbx` | 0.11 x 0.94 x 0.73 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Cactus_1.fbx` | 0.55 x 1.01 x 0.56 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Cactus_2.fbx` | 0.7 x 1.7 x 1.05 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Cactus_3.fbx` | 0.34 x 1.41 x 1.0 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Cactus_4.fbx` | 0.11 x 1.37 x 0.92 | -0.02 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Cactus_5.fbx` | 0.11 x 0.88 x 0.68 | -0.02 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Corn_1.fbx` | 0.82 x 1.98 x 1.09 | 0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Corn_2.fbx` | 0.82 x 1.98 x 1.09 | 0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Flowers.fbx` | 0.49 x 0.83 x 0.61 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Grass.fbx` | 0.37 x 1.01 x 0.33 | -0.02 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Grass_2.fbx` | 0.32 x 1.2 x 0.44 | -0.02 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Grass_Short.fbx` | 0.32 x 0.4 x 0.44 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Lilypad.fbx` | 1.2 x 0.22 x 1.19 | -0.03 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Plant_1.fbx` | 1.2 x 0.51 x 0.95 | -0.03 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Plant_2.fbx` | 0.69 x 1.77 x 0.69 | 0.0 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Plant_3.fbx` | 1.09 x 0.94 x 0.97 | -0.02 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Plant_4.fbx` | 1.91 x 0.81 x 2.12 | -0.01 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Plant_5.fbx` | 1.74 x 1.39 x 1.72 | -0.02 |
| `res://assets/Ultimate Nature Pack - Jun 2019/FBX/Wheat.fbx` | 0.36 x 1.1 x 0.36 | 0.0 |

## Village (Medieval Village Pack, Dec 2020)

### Buildings

| res:// path | Size X x Y x Z (units) | Min Y |
|---|---|---|
| `res://assets/Medieval Village Pack - Dec 2020/Buildings/FBX/Bell_Tower.fbx` | 1.94 x 4.76 x 2.23 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Buildings/FBX/Blacksmith.fbx` | 3.89 x 3.0 x 3.28 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Buildings/FBX/House_1.fbx` | 2.14 x 3.39 x 2.66 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Buildings/FBX/House_2.fbx` | 2.22 x 3.25 x 3.42 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Buildings/FBX/House_3.fbx` | 1.94 x 2.09 x 2.12 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Buildings/FBX/House_4.fbx` | 1.94 x 1.07 x 2.12 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Buildings/FBX/Inn.fbx` | 4.03 x 3.49 x 4.02 | -0.01 |
| `res://assets/Medieval Village Pack - Dec 2020/Buildings/FBX/Mill.fbx` | 3.4 x 4.8 x 2.73 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Buildings/FBX/Sawmill.fbx` | 4.4 x 2.86 x 3.28 | -0.05 |
| `res://assets/Medieval Village Pack - Dec 2020/Buildings/FBX/Stable.fbx` | 4.7 x 2.49 x 3.33 | -0.02 |

### Props

Crates, barrels, bags, packages, market stands and `Sawmill_saw` are the source for the cutting machine placeholder.

| res:// path | Size X x Y x Z (units) | Min Y |
|---|---|---|
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Bag.fbx` | 0.15 x 0.06 x 0.11 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Bag_Open.fbx` | 0.15 x 0.1 x 0.2 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Bags.fbx` | 0.27 x 0.11 x 0.24 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Barrel.fbx` | 0.16 x 0.2 x 0.16 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Bell.fbx` | 0.63 x 0.73 x 0.63 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Bench_1.fbx` | 0.66 x 0.32 x 0.24 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Bench_2.fbx` | 0.66 x 0.19 x 0.22 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Bonfire.fbx` | 0.41 x 0.11 x 0.36 | -0.03 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Bonfire_Lit.fbx` | 0.41 x 0.35 x 0.36 | -0.01 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Cart.fbx` | 0.46 x 0.8 x 0.93 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Cauldron.fbx` | 0.36 x 0.25 x 0.3 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Crate.fbx` | 0.16 x 0.16 x 0.16 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Door_Round.fbx` | 0.5 x 0.72 x 0.3 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Door_Straight.fbx` | 0.5 x 0.71 x 0.3 | -0.04 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Fence.fbx` | 0.79 x 0.33 x 0.03 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Gazebo.fbx` | 1.04 x 1.35 x 1.26 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Hay.fbx` | 0.12 x 0.18 x 0.12 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/MarketStand_1.fbx` | 0.95 x 1.05 x 1.19 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/MarketStand_2.fbx` | 0.52 x 1.04 x 1.15 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Package_1.fbx` | 0.28 x 0.13 x 0.18 | -0.01 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Package_2.fbx` | 0.19 x 0.16 x 0.19 | -0.01 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Path_Square.fbx` | 0.49 x 0.05 x 0.48 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Path_Straight.fbx` | 0.5 x 0.04 x 0.98 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Rock_1.fbx` | 0.26 x 0.17 x 0.21 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Rock_2.fbx` | 0.24 x 0.15 x 0.09 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Rock_3.fbx` | 0.3 x 0.08 x 0.26 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Sawmill_saw.fbx` | 0.71 x 0.54 x 1.7 | -0.02 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Smoke.fbx` | 0.44 x 1.07 x 0.27 | -0.01 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Stairs.fbx` | 0.5 x 0.12 x 0.29 | 0.0 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Well.fbx` | 0.67 x 1.25 x 1.0 | -0.25 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Window_1.fbx` | 0.38 x 0.38 x 0.12 | -0.19 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Window_2.fbx` | 0.45 x 0.37 x 0.15 | -0.12 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Window_3.fbx` | 0.45 x 0.56 x 0.15 | -0.12 |
| `res://assets/Medieval Village Pack - Dec 2020/Props/FBX/Window_4.fbx` | 0.45 x 0.56 x 0.15 | -0.12 |

## Characters (itHappy Creative Characters FREE, kept out of git)

The license allows use in a game but forbids redistributing the files, so `assets/itHappy Characters GLB/` and `assets/itHappy Creative Characters Free/` are both listed in `.gitignore` and are never committed. Forks must download the pack themselves (see `THIRD_PARTY_NOTICES.md` and `docs/CHARACTERS_SETUP.md`). Without those files the game uses seven CC0 Quaternius characters from `assets/Quaternius Ultimate Animated Characters/`, chosen by `scripts/people.gd`.

### The fisherman and the ten customers (use these)

Eleven ready to use GLB files, exported from the assembled blend. Each one has its own mesh set, texture and the same shared rig, so any animation plays on any of them.

| res:// path | Size X x Y x Z (units) | Min Y |
|---|---|---|
| `res://assets/itHappy Characters GLB/Pescador.glb` | 1.44 x 1.9 x 0.47 | 0.0 |
| `res://assets/itHappy Characters GLB/Cliente 1.glb` | 1.44 x 1.86 x 0.39 | -0.01 |
| `res://assets/itHappy Characters GLB/Cliente 2.glb` | 1.44 x 1.85 x 0.4 | 0.0 |
| `res://assets/itHappy Characters GLB/Cliente 3.glb` | 1.44 x 1.86 x 0.46 | -0.01 |
| `res://assets/itHappy Characters GLB/Cliente 4.glb` | 1.44 x 1.86 x 0.39 | 0.0 |
| `res://assets/itHappy Characters GLB/Cliente 5.glb` | 1.44 x 1.85 x 0.4 | 0.0 |
| `res://assets/itHappy Characters GLB/Cliente 6.glb` | 1.44 x 1.86 x 0.46 | -0.01 |
| `res://assets/itHappy Characters GLB/Cliente 7.glb` | 1.44 x 1.85 x 0.39 | 0.0 |
| `res://assets/itHappy Characters GLB/Cliente 8.glb` | 1.44 x 1.86 x 0.39 | -0.01 |
| `res://assets/itHappy Characters GLB/Cliente 9.glb` | 1.44 x 1.85 x 0.4 | 0.0 |
| `res://assets/itHappy Characters GLB/Cliente 10.glb` | 1.44 x 1.86 x 0.46 | -0.01 |

Width is the arms spread in the rest pose, so the body itself is narrower. All are about 1.86 tall standing on their origin (Min Y is 0, give or take 0.01).

**Rig:** every file has one node named `Skeleton3D` and one `AnimationPlayer`, both at the same names in all 11, and 33 animations each:

- Idles: `Idle_Breathing` (9.47 s), `Idle_Look_Around`, `Idle_Relaxed`.
- Walk: `Walk_Forward` (1.03 s), `Walk_Backward`.
- Run: `Run_Forward` (0.77 s), `Run_Backward`, `Run_Left`, `Run_Right`, `Strafe_Left`, `Strafe_Right`.
- Crouch: `Crouch_Walk_Forward`, `Crouch_Walk_Backward`, `Crouch_Walk_Left`, `Crouch_Walk_Right`, and `Crouch_Walk _Forward` (the same name written with a space, so use the spelling without it).
- Jump and fall: `Jump_Start`, `Jump` (1.6 s), `Jump_End`, `Fall`, `Climb_Ladder`.
- Dodge: `Dodge_Roll`, `Dodge_Sidestep`.
- Combat and reactions: `Attack_Kick`, `Attack_Punch`, `Block_With_Hands`, `Hit_Reaction_Light`, `Hit_Reaction_Heavy`, `Death_Forward`, `Death_Backward`.
- Other: `A-pose` (rest pose), `run(back)`, and `Armature|Take 001|BaseLayer` (an export leftover, ignore it).

**Not in the set:** no cast, reel, carry, hand over or celebrate clips. Fishing animations come from Mixamo later. Until then use the idle and run clips and drive the rod and the reel from code.

### Original pack files (fallback, for reference only)

- `res://assets/itHappy Creative Characters Free/glb/Creative_Character_free.glb`: one skeleton and 30 meshes, no animations, not split into characters.
- `res://assets/itHappy Creative Characters Free/glb/separate/Separate_assets_glb/`: 30 separate GLB parts (bodies, hairstyles, hats, outwear, pants, shoes, glasses, emotions).
- `res://assets/itHappy Creative Characters Free/textures/Textures_4.png`: the 1024 x 1024 texture.
- The `.blend` files in that folder are not imported by Xogot and are not needed now that the 11 GLB exist.
