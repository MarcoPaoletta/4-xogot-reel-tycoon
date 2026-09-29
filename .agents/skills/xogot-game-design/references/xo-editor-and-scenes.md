# xo: Editor State, Screenshots, Scenes, and Instances

## Contents

- Inspect the editor
- Screenshots
- Output log and errors
- Editor modes
- Work with scenes
- Reload and quit
- Launch and target instances

## Inspect the editor

Show what is open: the Godot version, the project, the current scene, and the play and capture status. The reply also gives `new_errors_since_last_request` and `game_automation` (`stopped`, `launching`, or `live`). With one call, you know if your last command caused an error and if a game runs:

```sh
xo editor state
```

Show the current editor mode (one of `3d`, `2d`, `gameplay`, `code`, or a plugin name):

```sh
xo editor mode get
```

Show what is selected:

```sh
xo editor selection get
```

Replace the editor selection. Give one node path for each argument, or use `--paths-json`:

```sh
xo editor selection set /Player /Enemy
```

Undo or redo editor actions:

```sh
xo editor undo
xo editor undo --count 3
xo editor redo
```

Show the path of the active scene:

```sh
xo scene current
```

Show the node tree of the active scene. For a large scene, use `--depth`, `--offset`, and `--limit`:

```sh
xo scene tree
```

## Screenshots

Use `editor screenshot` to see what the editor or the game shows before and after a change. Follow the screenshot rules in step 4 of the session loop in SKILL.md: clear the selection first, and look at the image before you describe it.

```sh
xo editor screenshot /tmp/shot.png
xo editor screenshot --source game /tmp/game.png
xo editor screenshot --source viewport --view-target "Player,Enemy" --coverage /tmp/shots.png
xo editor screenshot --max-resolution 0 /tmp/full.png
xo editor screenshot --source viewport2d /tmp/2d.png  # the 2D editor viewport
xo editor screenshot --source game --allow-stale /tmp/game.png   # last frame (stale: true) when the game is frozen
xo editor screenshot --source game --session dbg-1 /tmp/sim.png  # a game deployed to a Simulator or device; --session picks it when several are attached
```

Flags:

- `--source`: `viewport` (the default, the 3D editor viewport), `viewport2d` (the 2D editor viewport), `cinematic`, or `game`.
- `--max-resolution N`: the maximum length of the longest edge. `0` keeps the native resolution.
- `--view-target "Player,Enemy"`: a comma-separated list of `Node3D` paths to put in the frame. Only `--source viewport` uses it.
- `--coverage`: with `--view-target`, writes more than one image to show all the targets. The output path becomes a base name, and each file gets a suffix.
- `--session dbg-N`, `--timeout S`: with `--source game`, the debug session to capture from, and the time to wait for its reply. Give `--session` when more than one game is attached, for example a Simulator deploy and an embedded run. These flags operate for embedded, Simulator, and device games. An old export template replies "does not support remote game screenshots".
- `--allow-stale`: with `--source game`, gives the last frame, with `stale: true`, when the game is frozen.
- `--elevation`, `--azimuth`, `--fov`: in degrees. Give `null` to keep the current camera value.

Know these limits of screenshots:

- **Size.** `--source game` with `--max-resolution 0` gives the pixel size of the game window, not the design size of the project. On a Retina display, a 1920 × 1080 project can give a 2816 × 1638 image. Scale the images before you compare them.
- **Gizmos.** `--source viewport` shows the gizmos of lights, cameras, and other nodes. For a clean image, add a temporary `Camera3D` in the running game with `xo game eval`, then use `--source game`. You can also use `--source cinematic`.
- **Short effects.** A muzzle flash or a hit effect can show for less than 0.1 seconds, so a usual screenshot does not show it. Pause the tree in the game immediately after the effect (`tree.paused = true` through `xo game eval`), take the `--source game` screenshot, then set `tree.paused = false`.
- **Look at the image.** Tests find wrong rules, but they do not find a wrong appearance: an arena that is too small, or an animation that moves one hand while the other hand holds the weapon. Look at the screenshots of each new animation and effect before you report the result.

`--source cinematic` needs a `Camera3D` with `current = true`. To aim it, use `xo eval '…get_node("Cam").look_at_from_position(Vector3(…), Vector3(…))'`.

## Output log and errors

`xo editor output` reads the Output panel of the editor: `print()` output, warnings, and errors. It does not need a debug session. `xo debug console` reads the same log.

```sh
xo editor output --limit 50
xo editor output --limit 50 --details                 # Output panel with error stack frames; every entry has an index
xo editor output --since <cursor>                     # only entries newer than a previous reply's opaque `cursor`
xo editor output --source automation                  # what xo itself did (requests and replies); --source all merges both
xo editor output --previous-run                       # the Output panel from before the current game run
xo editor output --follow                             # stream new entries until Ctrl-C
xo editor clear --errors ; xo editor clear --automation
```

## Editor modes

Switch the editor between built-in modes (`3d`, `2d`, `gameplay`, `code`) or a plugin:

```sh
xo editor mode set 3d
xo editor mode set "<custom plugin name>"
```

## Work with scenes

```sh
xo scene list                                       # open scenes
xo scene list --all                                 # every scene in the project
xo scene activate res://main.tscn                   # open; creates a tab if necessary
xo scene save                                       # save current
xo scene save-as --path res://main_v2.tscn          # save current with a new path
xo scene create --path res://levels/level_2.tscn --root-type Node2D --root-name Level
xo scene new --unsaved --root-type Node2D           # untitled scene, nothing on disk
```

`scene list` returns the full `res://` path for each scene. Use that path with `scene activate` and other scene commands.

`scene create` (alias `scene new`) writes the file immediately. With `--unsaved`, you get an untitled scene in the editor: a new tab with unsaved changes. The file does not exist until you run `scene save`. With `--unsaved`, `--path` is optional, and the later save uses it.

`scene create` and all scene saves create missing parent folders. A successful save reply means that the scene file exists and the editor no longer reports the scene as unsaved.

Find if work is not saved, and what the next undo does:

```sh
xo scene state                                      # current scene: unsaved, undo/redo depth
xo scene state --all                                # every open tab, plus the undo history
```

`xo scene delete` and `xo scene rename` also manage scene files. See their `--help` for the flags.

`xo scene extract` saves a node as its own scene and replaces the node with an instance of that scene. `--copy-only` keeps the node as it is. The transform of the node moves into the root of the new scene, so set the position of each instance after the extract. To add more copies, use `node duplicate` or `node create --scene-type`:

```sh
xo scene extract /Level/Cart --path res://parts/cart.tscn
xo node create /Level/Cart2 --scene-type res://parts/cart.tscn
```

`xo scene close` closes a scene tab. It does not delete the file. Without a path, it closes the current scene. If the scene has unsaved changes, the command stops, unless you give `--save` or `--discard`. A different tab then becomes active, so run `scene activate` for the scene that you want next.

```sh
xo scene close                                      # the current scene
xo scene close res://parts/cart.tscn --save
```

You cannot delete, rename, or create again a scene that is open ("Cannot delete an open scene", "Cannot rename an open scene", "A scene already exists at ..."). Close it first. To make a scene again from nothing, close it, run `scene delete`, then run `scene create`.

## Reload and quit

```sh
xo scene reload --force                               # discard the in-memory scene and reload it from disk
xo editor quit --save                                 # save, then quit (--discard drops unsaved work)
```

## Launch and target instances

```sh
xo launch --new-project                                  # open project picker in a new instance
xo launch --new-project=/path/to/new --renderer mobile   # forward+, mobile, or compatibility
xo launch --editor /path/to/project                      # open editor on an existing project
xo launch --path /path/to/project                        # run a project without opening the editor
xo launch --download-git                                 # open the download-from-Git flow
xo activate "<instance-name>"                            # bring an instance to the front
xo ping "<instance-name>"                                # check liveness
xo list                                                  # running instances and their names, for --app
xo doctor                                                # diagnose xo, the Xogot broker, and running instances
```

Automatic target selection ignores project-run processes. Thus, after `xo project run`, `xo` still selects the sole editor instance. Use `--app` when more than one editor instance is available.
