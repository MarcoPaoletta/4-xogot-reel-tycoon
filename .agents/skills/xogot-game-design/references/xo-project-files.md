# xo: Project Files, Settings, InputMap, and Class Reference

## Contents

- Read and edit text files
- Find, rescan, and reimport files
- Transfer binary files
- Project settings
- Input map
- Class reference

## Read and edit text files

These commands operate on all text files in the project: scripts, `.tscn`, `.tres`, and `project.godot`. Use them, and do not use the local path. The editor sees the changes that you make with `xo` immediately.

Read a file. For a large file, use `--offset` and `--limit`, in lines:

```sh
xo file read res://player/player.gd
xo file read res://main.tscn --offset 100 --limit 50
```

If a file is open in the editor, save it before you read or edit it with `xo`. This writes the pending changes of the editor to the disk:

```sh
xo file save res://player/player.gd
```

`file edit` replaces one or more substrings in a file. It does not check GDScript. For a `.gd` file, use `xo script patch`, or run `xo script check` after the edit. Each `--old-text` must occur only one time in the original file. To make more than one edit in one call, give more than one `--old-text` and `--new-text` pair. The aliases `--oldText` and `--newText` also work. `xo` matches each edit against the **original** file, so the edits must not overlap or contain each other. Put such edits in separate calls.

```sh
xo file edit res://player/player.gd \
  --old-text 'var speed = 5.0' --new-text 'var speed = 7.5' \
  --old-text 'func jump():' --new-text 'func jump(force: float = 1.0):'
```

## Find, rescan, and reimport files

```sh
xo file search --name 'player*' --ext gd tscn     # glob on the file name, extension filter
xo file search --type Texture2D --path assets/    # resource type (subclasses match) + path substring
xo file scan --wait                               # rescan after you add files outside the editor; reports added and removed script classes
xo file reimport res://assets/hero.png            # requested | not_importable | missing; does not wait for the import
```

## Transfer binary files

Use these commands for binary assets (images, sounds, models, fonts), or when `path resolve` cannot open the project location:

```sh
xo file send /tmp/hero.png res://art/hero.png            # local → project
xo file get  res://saves/level_1.tres /tmp/level_1.tres  # project → local
```

For `send`, the local path is first. For `get`, it is second. Do not change the order.

## Project settings

Get or set Godot project settings. Keys have the form `application/run/main_scene`:

```sh
xo project setting get application/run/main_scene
xo project setting set application/run/main_scene '"res://main.tscn"'
```

`<value>` follows the property-value rules in SKILL.md.

Autoload singletons and shader globals have their own subcommands. See `xo project autoload --help` and `xo project shader-global --help`.

## Input map

`xo inputmap` manages the InputMap actions of the project (Project Settings > Input Map). You can undo each edit. The project settings keep the changes.

```sh
xo inputmap list                                   # user actions, deadzone, bindings with indexes
xo inputmap add jump --deadzone 0.2 --ensure       # --ensure: no error when it already exists
xo inputmap bind jump --key Space                  # physical key by default; --keycode / --label alternatives
xo inputmap bind jump --joy-button 0 ; xo inputmap bind move_right --joy-axis 0 --value 1
xo inputmap bind fire --mouse left --mods shift --ensure
xo inputmap unbind jump --key Space ; xo inputmap unbind jump --index 0 ; xo inputmap unbind jump --all
xo inputmap deadzone jump 0.3 ; xo inputmap rename jump leap ; xo inputmap remove leap
```

## Class reference

Get the properties, methods, signals, and documentation of a class:

```sh
xo project types --basenode Control                 # every type below a base
xo project class CharacterBody2D                    # own properties (with defaults), methods, signals, enums, constants, inheritors
xo project class CharacterBody2D --inherited --docs # plus inherited members (tagged declared_in) and documentation
xo project class Player                             # a script class_name works too
```
