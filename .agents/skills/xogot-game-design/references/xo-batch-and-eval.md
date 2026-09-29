# xo: Batch Commands and GDScript Evaluation

## Contents

- Batch commands with rollback
- Evaluate GDScript in the editor

## Batch commands with rollback

`xo batch` runs several commands as one operation. Each step is an ordinary `xo` argument array. `xo` first validates all the steps, then runs them in sequence. A step can refer to a node that an earlier step creates. When a step fails, `xo` skips the remaining steps and rewinds the editor undo history to the start of the batch. Use a batch when a scene edit is correct only as a whole: for example, build a node tree, configure it, and attach resources.

```sh
xo batch --json '{"steps":[
  ["node","create","/Hero","--type","CharacterBody2D"],
  ["node","create","/Hero/Sprite","--type","Sprite2D"],
  ["node","property","set","/Hero/Sprite","texture","..."],
  ["script","attach","/Hero","res://hero.gd"]
]}'
xo batch --file plan.json --dry-run          # validate only
xo batch --file plan.json --strict           # refuse steps that could not be rolled back
```

`xo` runs some steps but cannot roll them back: steps that write files, change project settings, or edit animations. The reply marks these steps `not_rolled_back`, with `rollback_scope: partial`. With `--strict`, `xo` refuses these steps before the batch starts.

You cannot put these commands in a batch: run and stop, debug, screenshots, export, eval, `game *`, `test *`, `node group add`, and `node group remove`. In a batch, use `node group set`.

Exit codes: 30 when `xo` refuses the batch or the batch is not valid, 31 when a step fails, and 32 when the rollback is not complete.

Validation rules:

- A step can set an exported property of a script only after an earlier step attaches that script. Put `script attach` before the `node property set` steps for that node.
- For a negative positional value in a step, put `"--"` before the value. See the negative-value rule in SKILL.md.
- A large batch is a good way to build a level. Write the steps to a JSON file, run it with `--dry-run`, and then run it without `--dry-run`. A batch of more than 500 steps completes in some seconds.

In JSON output, a rejected dry run and a successful dry run both return one result object. Read `ok`, `failed_index`, and `steps`; do not expect a top-level rejection array. If a batch deletes and recreates a node path, the recreated subtree is new. Old descendants do not remain available to later validation steps.

## Evaluate GDScript in the editor

`xo eval` runs GDScript in the editor as an `@tool extends EditorScript`. Use it only for work that no structured command can do: custom inspections, bulk edits on many nodes, and `EditorInterface` calls. When a structured command can do the task, use that command. Structured commands validate the input, give clear replies, and go into the undo history.

```sh
xo eval 'Engine.get_version_info()'
xo eval 'EditorInterface.get_edited_scene_root().get_child_count()'
xo eval $'{\n"width": 4,\n"height": 2\n}'
xo eval --file /tmp/dump_tree.gd
```

The inline form accepts an expression, including a multiline dictionary, or a short block of statements. For functions, use `--file`. Give inline code or `--file`, not both.

The file can contain one of these:

- a block of statements. `xo` puts the block in `func _run():`.
- a block with its own `func _run():`. `xo` adds the `@tool` and `extends EditorScript` lines.
- a complete script that starts with `@tool` or `extends …`.

`return` operates in all forms. The reply gives `result` and `result_type` from the return value of `_run()`, and `output` from the `print` calls.

If the code uses `await`, `xo eval` waits for it to finish. Use `--timeout SECONDS` to change the 10 second limit. On timeout, `xo` disconnects the pending await signal so the coroutine cannot resume when that signal fires later. Changes made before the timeout remain.

Before execution, `xo eval` checks the wrapped script. A parse error reports the first compiler diagnostic and its wrapped-script line. The `output` array contains print lines from the initial synchronous call. Prints after an `await` appear in the editor Output panel.

To run GDScript in the running game, use `xo game eval`. See [xo-run-debug-test.md](xo-run-debug-test.md).

### Compile errors

The error has the form "GDScript error at line N of the wrapped script: <message>". For a block of statements, `xo` adds 4 lines before your code, so your line is N − 4. For a complete script, N is your line.

Most compile errors come from `:=` on a value that has no static type. GDScript cannot infer a type from a Variant. Give these variables an explicit type:

| Fails | Compiles |
| --- | --- |
| `var p := "res://" + f` (`f` comes from an untyped `Array`) | `var p: String = "res://" + f` |
| `var x := max(a, b)`, also `min` and `clamp` | `var x := maxf(a, b)`, or `var x: float = max(a, b)` |
| `var s := node.get_world_3d().direct_space_state` (`node` has the type `Node`) | `var s: PhysicsDirectSpaceState3D = …` |

### Recipes

Use `xo eval --file` for these tasks. No structured command does them.

- **Make an instance editable**, so that the save keeps the changes to its child nodes:

  ```gdscript
  var root := EditorInterface.get_edited_scene_root()
  root.set_editable_instance(root.get_node("Model"), true)
  ```

  The scene file then has `[editable path="Model"]`.
- **Set a typed array export**, for example `Array[PackedScene]`, which `node property set` cannot express. Make the typed array in GDScript and assign it with `set()`.
- **Bake a `NavigationRegion3D`.** Set `geometry_source_geometry_mode`, `geometry_collision_mask`, and `filter_baking_aabb` on its `NavigationMesh`, then call `bake_navigation_mesh(false)`.
- **Make an audio bus layout.** Use `AudioServer.add_bus` and `AudioServer.add_bus_effect`, then `ResourceSaver.save(AudioServer.generate_bus_layout(), "res://default_bus_layout.tres")`.
- **Measure a model.** Make an instance of the scene, merge the `get_aabb()` of each `VisualInstance3D` in global space, then free the instance.
- **Make a resource with sub-resources**, for example an `Environment` with a `ProceduralSkyMaterial`, or a `ParticleProcessMaterial` with curve textures. Save it with `ResourceSaver.save`. First look for a builder in [xo-content-builders.md](xo-content-builders.md).

`xo resource inline` operates only on properties of Resource type. Set built-in value types such as `AABB`, `Transform3D`, and `Color` with `node property set` and a Variant expression: `xo node property set / visibility_aabb 'AABB(-2, -1, -2, 4, 4, 4)'`.
