---
name: xogot-game-design
description: Design, review, teach, and build Godot 4.x games, and control the Xogot editor (a native Godot editor) with the bundled `xo` command. Use this skill when the user mentions Godot, Xogot, `xo`, GDScript, or a `.tscn`, `.tres`, `.gd`, `.gdshader` or `project.godot` file. Use it also when the user asks about "my game", "my scene" or "my player" in a Godot project, even when the user does not name a tool. Design tasks - plan or review scene trees, node choices, physics, input, cameras, UI, accessibility, performance and production; teach newcomers; find anti-patterns in GDScript, C#, Swift or other bindings. Control tasks - inspect or change a project that is open in Xogot (nodes, properties, groups, signals, scripts, files, scenes, project settings, InputMap), take editor and game screenshots, run, debug and test the project, send input to the running game, and build UI, themes, materials, particles, cameras, audio, CSG, tilemaps, GridMaps, sprite and AnimationPlayer animations, and 3D meshes.
x-xogot-version: 1.7.2
---

# Xogot Game Design

Give newcomers a clear starting path, give working teams defaults that blend into the structure they already have, and act on the project through `xo` when a Xogot instance is running.

## Existing project conventions come first

The guidance in this skill is a set of defaults. It is not a standard that a project must meet.

- When the project has an established pattern, follow that pattern. Examples: an event bus, autoload services, a state-machine framework, a directory layout, naming rules, a component system, or a script language.
- Use the idioms in this skill only where the project has no established pattern, or when you write a new system that has no precedent in the project.
- Make new code look like the code around it. Match its structure, naming, signal style, and comment density, also when the project differs from these defaults.
- Do not recommend a migration away from an existing decision unless the user asks, or the decision causes a concrete defect. A concrete defect is a bug, a crash, a measured performance problem, or an engine-correctness problem (for example, movement outside the physics step).
- When a default from this skill could help, mention it one time as an option. Do not repeat it, and do not apply it without agreement.
- A difference from these defaults is not a finding. Report it only when it causes a concrete failure mode.

## Acting on the project with `xo`

Xogot is a Godot editor. The `xo` command controls a running Xogot instance from the shell. The command might not be on the path, so run it as /Applications/Xogot.app/Contents/MacOS/xo. Use `xo` when the user asks you to inspect, change, or run a Godot project that is open in Xogot. Use it instead of AppleScript, `osascript`, direct file edits, or other indirect methods. The editor can keep unsaved changes that are not on the disk, so read and write project files through `xo`. Each `xo` edit goes into the undo history of the editor.


### Global flags

Every command accepts:

- `--output json|table|markdown`: output format (default: `json`)
- `--pretty`: pretty-print JSON
- `--app <name>`: target a specific Xogot instance

Use JSON when you parse the output. Add `--pretty` when a person reads it.

If more than one Xogot instance runs, get their names with `xo list`. Then give `--app <name>` to each command. Instance names change when Xogot starts again (`xogot-1` can become `xogot-96`). Do not keep a name for a long time. Get it again from `xo list` by its `projectPath` and `launchKind`.

### Critical conventions

- **Editor node paths start at the root of the edited scene, and that root is `/`.** Its children are `/Child`, not `/SceneRootName/Child`. The name of the root node does not resolve. Do not use the relative `..` form. The *running* game uses different paths: `game` commands use the `/root/...` paths of the live tree, as `xo game tree` shows them.
- **Godot paths** use `res://…` for the project and `user://…` for the writable user directory. Use `xo path resolve` only when you give a path to a different tool.
- **Property values** for `node property set` and `project setting set` go through `GD.strToVar`. Put strings in two sets of quotes: `'"hello"'`. Do not put inner quotes around structured values: `'Vector3(0,1,5)'`, `'Color(1,0,0,1)'`. Numbers need no quotes: `100`. The value `'"Vector3(0,1,5)"'` parses as a String, and `xo` refuses to assign it to a Vector3 property. To clear a property, use `--nil` with `node property set`.
- **Negative values:** The parser reads a value that starts with a minus sign as an option.
  - For an option, join the value to the option with `=`: `--position=-1,2,3`, `--rotation=-32,125,0`, `--volume=-6`. The parser refuses `node transform3d --position -1,2,3` with "Missing value for '--position'".
  - For a positional value, put `--` before it: `xo node property set /Player ammo_max -- -1`. The same form operates in `xo batch` steps: `["node","property","set","/","volume_db","--","-4.0"]`.
- **Read before you edit.** Run `file read` before you write a `file edit`, so that your `--old-text` agrees with the bytes on the disk. If the file can have unsaved changes in the editor, run `file save` first.

### Changes that the editor can lose without an error

- **A script edit can reset the exported values of open instances.** When you change a script that has `@export` properties, the editor reloads the script. The instances of that script in open scenes can then get the default values of the script. The next `scene save` writes these defaults into the scene as overrides, and replaces the values that the instanced scenes set. After you edit such a script, run `xo scene reload --force` on each open scene that instances it, before you save that scene. After the save, examine the diff of the scene file.
- **Check scene ownership before editing an instance.** An instanced scene is, for example, a glTF model or a prefab `.tscn`. A child added directly beneath the instance root belongs to the edited scene and saves without Editable Children. Edits to imported children require Editable Children; `xo` rejects changes that Godot would drop on save. Raw `xo eval` code can bypass this check. When an instance is editable, the saved file also keeps the current pose of each skeleton bone. This adds many `bones/N/...` lines to the diff.

### What you should not do

- Do not use node paths from memory. Get them with `xo scene tree` or `xo node find`, then use the exact paths that the command returns.
- Do not assume that your working directory is the Godot project. Use `res://` paths for project files.
- Do not change project files directly, also when you know their path. Always use `xo`.

### Discover the surface

`xo` is the authority. When you are not sure, ask it:

```sh
xo --help
xo <command> [<subcommand>] --help
```

### The session loop

1. Orient. `xo editor state` shows the Godot version, project, current scene, play status, and `new_errors_since_last_request`.
2. Discover. `xo scene tree` or `xo node find` return the exact node paths. `xo file read` shows a file as the editor sees it.
3. Act. Use the structured command for the task (see the routing table below). Use `xo batch` when several steps must succeed or fail together. Use `xo eval` only when no structured command can do the job.
4. Verify. Run `xo editor state` for new errors, `xo editor output` for prints and warnings, and `xo project run --wait` to play the result when the next step must control the live game. `xo project run` saves the in-memory edits first, unless you add `--no-save`.
   - After a script change, read the `diagnostics` in the reply of `xo script create` or `xo script patch`. `xo file edit` does not check the script, so run `xo script check` after you use it on a `.gd` file.
   - After a visible change, clear the selection with `xo editor selection set --paths-json '[]'`, so that the selection tint and gizmos are not in the image. Then take an `xo editor screenshot`, open the image file, and look at it. Do not report a visual result that you did not see.
5. Save. Run `xo scene save` when the user wants to keep the change. Tell the user when work is not saved. A `project run` without `--no-save` has already saved the edits.
6. Finish. Before you report that the work is done, run `git status` when the project uses Git. Look for files that you did not make, for example a copy of a scene at `res://`, and for scene files that you did not intend to change.

### Everyday commands

```sh
xo editor state                                    # what is open, errors since last request, game status
xo scene tree                                      # node paths of the active scene
xo node find --type Camera3D                       # search by --name/--iname/--regex/--regexi/--type/--group
xo node property get /Camera3D position,fov        # omit names for all properties
xo node property set /Player health 100
xo node create /Camera3D --type Camera3D
xo file read res://player/player.gd
xo script patch res://player/player.gd --old-text 'var speed = 5.0' --new-text 'var speed = 7.5'   # returns diagnostics
xo script create res://player/player.gd --string 'extends Node3D'
xo script attach /Player res://player/player.gd
xo scene save
xo project run --wait ; xo project stop
xo editor screenshot /tmp/shot.png                 # --source game for the running game
xo editor output --limit 50                        # Output panel: prints, warnings, errors
```

### When a command fails

Read the error message before you try again. Do not run the same command again without a change.

| Exit code | Meaning | What to do |
| --- | --- | --- |
| 1 | `xo` reported an error. The message is on stderr. | Read the message. Then run `xo editor state` and `xo editor output --limit 20` to find the cause. |
| 64 | The command line is not correct. | Run `xo <command> <subcommand> --help` and correct the arguments. |
| 4 | A downloadable component is missing. | The reply names the `xo component install` command to run. Ask the user before you install it. |
| 30, 31, 32 | `xo batch` was rejected, a step failed, or the rollback is incomplete. | See [references/xo-batch-and-eval.md](references/xo-batch-and-eval.md). |
| 40 | `xo test run` has failures, errors, or a timeout. | Read the report on stdout. |

Some errors are about the Xogot instance:

- "no Xogot instances are running": ask the user to open the project in Xogot, or run `xo launch --editor <project folder>`.
- "more than one Xogot instance is running": run `xo list`, then pass `--app <name>` to each command.
- "instance '…' not found": Xogot started again, and the instance has a new name. Run `xo list` again.
- After `xo launch --editor <project folder>`, run `xo editor state` again until it replies. The instance can need some seconds to start.
- For other connection problems, run `xo doctor`. It examines `xo`, the Xogot broker, and the running instances.

### Where to read more

Read only the reference that the task needs.

| Task | Command groups | Reference |
| --- | --- | --- |
| Editor state, selection, undo, screenshots, output log, scene files, editor modes, quit, or ping | `editor`, `scene`, `ping` | [references/xo-editor-and-scenes.md](references/xo-editor-and-scenes.md) |
| Launch or target instances | `list`, `launch`, `activate`, `doctor`, `--app` | [references/xo-editor-and-scenes.md](references/xo-editor-and-scenes.md) |
| Find, create, move, delete nodes; properties, transforms, arrays, groups; signal connections; scripts; resources; collision shapes | `node`, `signal`, `script`, `resource` | [references/xo-nodes-and-scripts.md](references/xo-nodes-and-scripts.md) |
| Read, edit, search, transfer files; project settings, autoloads, shader globals; InputMap; class docs | `file`, `path`, `project setting`, `project autoload`, `project shader-global`, `inputmap`, `project class` | [references/xo-project-files.md](references/xo-project-files.md) |
| Run, stop, debug; drive the running game with input and GDScript; run `test_*.gd` suites | `project run`, `debug`, `game`, `test` | [references/xo-run-debug-test.md](references/xo-run-debug-test.md) |
| Build UI, themes, materials, particles, cameras, audio, CSG, curves, environments, textures, TileSets, TileMapLayer cells, SpriteFrames, GridMap cells, animations | `ui`, `theme`, `material`, `particles`, `camera`, `audio`, `csg`, `resource`, `tileset`, `tilemap`, `spriteframes`, `gridmap`, `animation` | [references/xo-content-builders.md](references/xo-content-builders.md) |
| Create and edit meshes with the 3D Modeler | `modeler` | [references/xo-modeler.md](references/xo-modeler.md) |
| Run several commands as one undoable operation; run GDScript in the editor; eval compile errors; recipes for editable instances, typed array exports, navigation bakes, and audio bus layouts | `batch`, `eval` | [references/xo-batch-and-eval.md](references/xo-batch-and-eval.md) |
| Export presets and export builds (macOS only) | `export` | Run `xo export --help`. |

## Workflow

Use this workflow for design, review, teaching, and build tasks. When you act on a project that is open in Xogot, do each step that reads or changes the project through the session loop above.

1. Establish the game before you suggest architecture.
   - Identify the central player verbs and the smallest playable loop.
   - Determine whether the project is 2D, 3D, or hybrid.
   - Determine genre, target platforms, primary inputs, weakest device, expected content scale, and multiplayer needs when they have an effect on the answer.
   - Ask only for missing facts that would change the recommendation. Otherwise, state a reasonable assumption and continue.
2. Examine the project when one is available.
   - When a Xogot instance runs, inspect the project through `xo`: `xo editor state`, `xo scene tree`, `xo file read`, `xo project setting get`. Otherwise, read the files directly.
   - Read `project.godot`, representative `.tscn`/`.tres` files, scripts, autoloads, input actions, collision layers, renderer choice, and the project tree.
   - Record the conventions the project already uses: architecture patterns, communication style, data layout, naming, and language. These conventions have priority over the defaults in this skill.
   - Trace ownership and lifetime through the real scene boundaries. Do not infer architecture from filenames alone.
   - Keep the diagnosis in the requested scope. Do not implement a fix when the user asks only for a review.
3. Use the shared guidance in [references/core-principles.md](references/core-principles.md) to fill gaps. Do not use it to replace choices the project already made.
4. Load only the domain references that you need:
   - Read [references/2d-principles.md](references/2d-principles.md) for 2D games, pixel art, tilemaps, 2D cameras, or 2D physics.
   - Read [references/3d-principles.md](references/3d-principles.md) for 3D scale, imports, transforms, lighting, navigation, materials, or rendering.
   - Read [references/production-and-review.md](references/production-and-review.md) for UI, audio, accessibility, profiling, production plans, project reviews, testing, or release readiness.
   - Read all four design references when you produce a curriculum or a broad onboarding guide.
   - Read the `xo-*` reference named in the routing table above when you act on a project that is open in Xogot.
5. For new work, choose the smallest architecture that supports the demonstrated game.
   - Avoid speculative systems and generic frameworks before the first playable loop.
   - Distinguish a durable principle from a project-specific choice.
   - Explain the exceptions when you recommend a strong default.
6. Verify version-sensitive claims against the official Godot documentation when exact current behavior is important. Prefer the Godot primary documentation, and state the Godot version you assume. With Xogot running, `xo project class <Class> --docs` gives the class documentation of the engine build in use.

## Response patterns

### Plan a game or feature

Start with the playable slice. Then give these items, as necessary:

1. player loop and feedback;
2. proposed scene tree with ownership;
3. public methods, signals, and exported configuration;
4. Resources or other data definitions;
5. input, physics, camera, UI, and audio choices;
6. target-device constraints;
7. milestones and validation criteria.

For a feature in an existing project, put the feature into the project's current structure. Use its existing autoloads, buses, base classes, and data formats.

For a new project, do not start with a universal inventory, service locator, event bus, or state-machine framework unless the demonstrated requirements need one. If the project already has one of these systems, use it.

### Review a project or proposal

Start with the most important findings, in order of severity. For each finding:

- cite the related file, scene, node path, or supplied design detail;
- explain the concrete failure mode or maintenance cost;
- recommend the smallest corrective change that agrees with the project's conventions;
- identify the concern as correctness, maintainability, game feel, accessibility, or performance;
- do not claim a performance problem without measurement or strong structural evidence.

If a different approach would give a clear benefit, put it in a short, optional section after the findings.

End with what is already sound and the next three changes that are worth making.

### Teach a newcomer

Teach one complete vertical slice before you show a catalog of nodes. Connect each engine concept to a visible result in the game. Introduce an abstraction only after the learner meets the problem that it solves.

### Write code

Use the project's existing language, style, and patterns. When the project has no example for the code you write, use the idioms in this skill. If no language is specified, use typed Godot 4.x GDScript and say that the architecture is language-independent. Keep examples small so that they show the idiom and do not bring in a framework.

When Xogot runs and the user wants the change applied, apply it through `xo`: `xo script create` or `xo script patch` for scripts, `xo file edit` for other text files, `xo node create` and `xo node property set` for scene structure. Then verify it with step 4 of the session loop.

## Default checks

Use these checks as defaults for new projects and new code. Some items are engine facts and not style choices (for example, physics work in the physics step, and a correct body type for the owner of motion). Report a violation of an engine fact only when it causes a real defect.

- Organize scenes by ownership and lifetime, not only by spatial appearance.
- Treat scenes as reusable game objects, nodes as capabilities, and Resources as data.
- Prefer direct commands to owned children, and signals for facts that parents or peers observe.
- Use semantic Input Map actions, not physical keys, in gameplay logic.
- Put physics movement and queries in the fixed physics step.
- Match `Area`, `StaticBody`, `RigidBody`, or `CharacterBody` to the owner of the motion.
- Keep collision shapes simpler and more stable than the visible geometry.
- Treat camera, feedback, UI scaling, audio, and accessibility as gameplay systems.
- Choose the renderer and content budgets from the target hardware backward.
- Profile representative exported builds before you recommend optimizations.

## Tone

Be decisive enough to give newcomers a path. Do not present one scene-tree shape as a law of Godot. Prefer "start with this because…" to "always do this."
