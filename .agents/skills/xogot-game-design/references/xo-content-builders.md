# xo: Content Builders

These commands build content from the node and resource commands: UI, themes, materials, particles, cameras, audio, CSG, resource files, TileSets and TileMapLayer cells, SpriteFrames, GridMap cells, and AnimationPlayer animations.

## Contents

- Value conventions
- UI
- Theme
- Material
- Particles
- Camera
- Audio
- CSG
- Resource builders
- TileSet and TileMapLayer
- SpriteFrames
- GridMap
- Animation

## Value conventions

You can undo each scene edit. Values are Godot Variant expressions, for example `Vector2(1, 2)`, `Color(1, 0, 0, 1)`, or `"text"`. Colors also accept `#rrggbb[aa]`.

## UI

```sh
xo ui build --parent / --spec '{"type":"VBoxContainer","name":"Menu","anchor":"center","children":[{"type":"Button","name":"Play","text":"Play"},{"type":"Label","text":"v1.0"}]}'
xo ui anchor /Menu full_rect --mode keep_size --margin 16 ; xo ui text /Menu/Play "Start"
xo ui draw /Hud --recipe '[{"circle":[40,40,30],"color":"#ff5500"},{"string":{"text":"HP","at":[10,90]},"color":"#fff"}]'
```

## Theme

```sh
xo theme create res://ui/main.tres
xo theme set res://ui/main.tres --class Button --color font_color=#ffffff --constant h_separation=8 --font-size font_size=18
xo theme stylebox res://ui/main.tres --class Button --item normal --bg '#223344' --border 2 --border-color '#88aaff' --radius 6 --margins 8 4 8 4
xo theme apply /Menu res://ui/main.tres
```

## Material

```sh
xo material create standard res://materials/hero.tres --preset metal --set albedo_color='Color(0.8,0.2,0.2,1)'
xo material create standard res://materials/brick.tres --set albedo_texture=res://textures/brick.png
xo material create shader res://materials/water.tres --shader res://shaders/water.gdshader --uniform speed=2.0
xo material assign /Hero res://materials/hero.tres --slot override      # surface:N | canvas | particles
xo material info res://materials/hero.tres ; xo material list
```

For a material property that accepts a resource, pass its `res://` path. The editor loads the resource and checks its type before saving the material.

## Particles

```sh
xo particles create --parent / --name Fire --dim 2d --preset fire       # fire | smoke | spark | magic | rain | explosion | lightning; --cpu for CPUParticles
xo particles configure /Fire --node amount=64 --process gravity='Vector3(0,-80,0)' color='Color(1,0.3,0,1)'
xo particles draw-pass /Sparks3D 1 res://meshes/spark.tres ; xo particles restart /Fire ; xo particles info /Fire
```

## Camera

```sh
xo camera create 2d --parent /Player --preset platformer --current    # top-down | platformer | cinematic | action
xo camera set /Camera2D --limits 0,0,4096,2048 --smoothing 6 --drag-h 0.2 0.2
xo camera follow /Camera2D /Player ; xo camera current /Camera2D ; xo camera list
```

## Audio

```sh
xo audio create 2d --parent /Player --name Footsteps --stream res://sfx/step.wav --volume=-6 --bus SFX
xo audio preview play res://sfx/step.wav ; xo audio preview stop ; xo audio list
```

## CSG

```sh
xo csg create box --parent /Level --name Wall --size 'Vector3(4,2,0.5)' --op union ; xo csg op /Level/Hole subtraction
```

## Resource builders

```sh
xo resource curve res://curves/ease.tres --points '[[0,0,0,2],[1,1,0,0]]'      # Curve; Curve2D/Curve3D by point arity or --type
xo resource environment res://env/night.tres --preset night                      # outdoor | indoor | studio | night, --sky
xo resource gradient-texture res://tex/sky.tres --stops '[{"offset":0,"color":"#0b1a3a"},{"offset":1,"color":"#7fb2ff"}]' --fill linear
xo resource noise-texture res://tex/noise.tres --noise-type simplex_smooth --frequency 0.02 --octaves 4 --seamless
```

For `xo resource inline` (create and configure a built-in resource on a node property), `xo node fit-shape`, and `xo resource search`, see [xo-nodes-and-scripts.md](xo-nodes-and-scripts.md).

## TileSet and TileMapLayer

`xo tileset` inspects and edits TileSet resources: sources, atlas tiles, alternative tiles, scene-collection tiles, and proxies. `xo tilemap` reads and paints the cells of a `TileMapLayer`, with patterns and terrains. It also converts a deprecated `TileMap` node into `TileMapLayer` nodes. The two groups have many subcommands. Before you use them, run `xo tileset --help` and `xo tilemap --help`, then `--help` on the subcommand.

```sh
xo tileset source export-image --resource res://tiles.tres 0 /tmp/atlas.png --max-size 512   # look at the atlas before you pick tiles
```

## SpriteFrames

`xo spriteframes` manages the animations and frames of a `SpriteFrames` resource, and controls `AnimatedSprite2D` and `AnimatedSprite3D` nodes. Run `xo spriteframes --help` for the subcommands.

## GridMap

```sh
xo gridmap library /Level/GridMap                          # MeshLibrary items: id, name, mesh, shapes, navmesh
xo gridmap cell set /Level/GridMap --at 0,0,0 --item floor --orientation 0   # item by id or name
xo gridmap fill /Level/GridMap --from 0,0,0 --to 9,0,9 --item floor
xo gridmap fill /Level/GridMap --from 4,1,4 --to 5,1,5    # no --item: erase the region
xo gridmap cell get /Level/GridMap --at 3,0,3 ; xo gridmap cell erase /Level/GridMap --at 3,0,3
xo gridmap used /Level/GridMap --item wall                # cells in use; --item filters by item
xo gridmap orient /Level/GridMap --at 2,0,2 --orientation 10   # or --basis 'Basis(...)', --to X,Y,Z for a region
xo gridmap clear /Level/GridMap
```

## Animation

`xo animation` creates and edits AnimationPlayer animations. You can undo each edit. You can give absolute scene paths, for example `/Sprite`. `xo` stores them relative to the root node of the player.

```sh
xo animation player create /                             # AnimationPlayer node
xo animation create /AnimationPlayer walk --length 1 --loop-mode pingpong --overwrite
xo animation list /AnimationPlayer ; xo animation get /AnimationPlayer walk --keys
xo animation track add-property /AnimationPlayer walk /Sprite position --keys '[{"t":0,"v":"Vector2(0,0)"},{"t":1,"v":"Vector2(100,0)"}]' --interpolation cubic
xo animation track add-method /AnimationPlayer walk / --calls '[{"t":0.5,"method":"play_step"}]'
xo animation tween /AnimationPlayer appear --spec '[{"path":"/Sprite:modulate","from":"Color(1,1,1,0)","to":"Color(1,1,1,1)","duration":0.4}]'
xo animation preset /AnimationPlayer hit shake --target /Sprite --duration 0.3   # fade-in | fade-out | slide | shake | pulse
xo animation validate /AnimationPlayer               # find tracks whose node or property does not resolve
xo animation autoplay /AnimationPlayer walk ; xo animation autoplay /AnimationPlayer --clear
xo animation preview play /AnimationPlayer walk ; xo animation preview stop /AnimationPlayer
xo animation delete /AnimationPlayer walk
```

Animation edits run in `xo batch`, but the batch cannot roll them back. See [xo-batch-and-eval.md](xo-batch-and-eval.md).
