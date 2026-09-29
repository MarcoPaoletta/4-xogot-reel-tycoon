# xo: Nodes, Properties, Groups, Scripts, and Resources

## Contents

- Path rules
- Find and read nodes
- Create, move, and delete nodes
- Set properties and transforms
- Groups
- Signals
- Scripts
- Resources and collision shapes

## Path rules

Editor node paths follow the path rule in SKILL.md: the root of the edited scene is `/`, and its children are `/Child`. Get paths from `xo scene tree` or `xo node find`. The running game uses different paths. See [xo-run-debug-test.md](xo-run-debug-test.md).

## Find and read nodes

Find nodes by name, type, or group. You can combine the filters:

```sh
xo node find --type Camera3D
xo node find --iname player --group enemies --limit 5
xo node find --regexi '^enemy_\d+$'
```

Filters: `--name` / `--iname` (substring), `--regex` / `--regexi`, `--type` (exact Godot class), `--group`, `--offset`, `--limit`.

List the children of a node. Add `--recurse` for the full subtree:

```sh
xo node children /Level
xo node children /Level --recurse
```

List the properties of a node. Without a path, the command uses the scene root:

```sh
xo node property list /Camera3D
```

Get one or more property values. Without names, the command gives all the properties:

```sh
xo node property get /Camera3D position,fov
```

Get the groups of a node:

```sh
xo node group get /Player
```

## Create, move, and delete nodes

Create a node from a built-in class, or make an instance of a packed scene:

```sh
xo node create /Camera3D --type Camera3D
xo node create /Enemy --scene-type res://actors/enemy.tscn
```

Rename, move, reparent, duplicate, and delete nodes:

```sh
xo node rename /Camera3D MainCamera
xo node move /Player /Players --index 0
xo node duplicate /Enemy /Enemy2
xo node delete /Placeholder
```

## Set properties and transforms

Values follow the property-value rules in SKILL.md. Use `--nil` to clear a property.

```sh
xo node property set /Camera3D position 'Vector3(0, 1, 5)'
xo node property set /Player health 100
xo node property set /Player nickname --nil
```

The transform commands accept the short form `x,y[,z]` or a Godot Variant string. Use only one rotation form:

```sh
xo node transform2d /Sprite --position 100,50 --rotation 45 --scale 2,2
xo node transform3d /Camera3D --position 0,1,5 --rotation-quaternion 0,0,0,1
```

To change array properties, for example `Path3D.curve.points` or exported `Array` fields, use `xo node array append` and `xo node array remove`. See `--help` for the index and value rules.

## Groups

```sh
xo node group add /Enemy hostile
xo node group remove /Enemy hostile
xo node group set /Enemy hostile,boss   # comma-separated; no groups removes all
```

In an `xo batch`, use `node group set`. See [xo-batch-and-eval.md](xo-batch-and-eval.md).

## Signals

List the signals of a node. Connect or disconnect a signal and a method on a target node:

```sh
xo signal list /Player
xo signal connect --signal died --source /Player --target /Hud --method _on_player_died
xo signal disconnect --signal died --source /Player --target /Hud --method _on_player_died
```

The target method must exist in the script of the target. The scene file keeps the connections that you make here. It does not keep the connections that code makes with `connect()`.

## Scripts

Create, attach, or detach a script:

```sh
xo script create res://player/player.gd
xo script create res://player/player.gd --string 'extends Node3D'
xo script create res://player/player.gd --source /tmp/player.gd
xo script attach /Player res://player/player.gd
xo script detach /Player
```

Check a script and read its outline:

```sh
xo script check res://player.gd                   # GDScript diagnostics (line, column, message, severity)
xo script outline res://player.gd                 # class_name, base, functions, signals, @export vars, constants
```

`script patch` changes the text of a script. `--old-text` must occur only one time in the file, unless you add `--replace-all`. An empty `--new-text` deletes the text. The aliases `--oldText` and `--newText` also work:

```sh
xo script patch res://player/player.gd --old-text 'var speed = 5.0' --new-text 'var speed = 7.5'
xo script patch res://player/player.gd --old-text 'Vector2.ZERO' --new-text 'Vector2.UP' --replace-all
```

Register the autoloads (`xo project autoload add`) before you check the scripts that use them. Otherwise, each reference to an autoload gives an error such as `Identifier "Game" not declared`. After you write scripts outside the editor, run `xo file scan --wait` before `script check`.

`script create` and `script patch` check the GDScript after they write it. The reply gives `check` (`full`, `partial`, or `none`) and `diagnostics`. Correct the errors before you continue. `xo file edit` does not check scripts. See [xo-project-files.md](xo-project-files.md).

## Resources and collision shapes

`xo resource` operates on `.tres` files and on properties of resource type: `info`, `search`, `load`, `set` (assign a resource to a node property), and `create`, `update`, and `delete` for saved files. See `xo resource --help` for the arguments.

```sh
xo resource inline /Body/CollisionShape2D shape --type CircleShape2D --set radius=24   # create and configure a built-in resource
xo node fit-shape /Body/CollisionShape2D                                    # fit the shape to the sibling visuals
xo resource search --base Texture2D                                              # subclasses match
```

For 3D shapes, `node fit-shape` recursively scans each `Node3D` source. Thus, a plain instance root can contribute the visual bounds of MeshInstance3D children in an imported glTF model. Read `warnings` in the reply. If an instanced source has no readable visual descendants, enable Editable Children or pass `--source` for a visual descendant.

Builders for curves, environments, gradient and noise textures, materials, and themes are in [xo-content-builders.md](xo-content-builders.md).
