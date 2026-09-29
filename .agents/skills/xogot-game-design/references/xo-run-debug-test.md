# xo: Run, Debug, Drive the Game, and Test

## Contents

- Run the project
- Debug sessions
- Drive the running game
- Run project tests

## Run the project

```sh
xo project destination list
xo project run                                                # main scene, active destination
xo project run --scene res://test_room.tscn --destination <id>
xo project run --wait                                         # return when the game is live
xo project run --no-save                                      # run the project on the disk; do not save the in-memory edits
xo project stop
```

Without `--no-save`, `project run` saves the in-memory edits first. `xo editor state` gives `game_automation` (`stopped`, `launching`, or `live`) without a round trip to the game.

Use `--wait` when the next command reads or controls the running game. It polls the same editor until the game is `live` and stops with an error after 60 seconds.

## Debug sessions

`xo debug` controls debug sessions: `run`, `stop`, `status`, `pause`, `resume`, `step`, `step-into`, `breakpoint`, `stack`, `frame`, `eval` in the paused frame, `console`, and `errors`. Before you control a session, run `xo debug --help` and `<subcommand> --help` to find the flags.

The debugger stops the game at each script error, also at an error in your own `xo game eval` code, for example a node path that is not correct. `xo game status` then shows `at-break`. When a command says that the game is paused at a breakpoint, inspect the failure, then continue the game:

```sh
xo debug errors
xo debug resume
```

## Drive the running game

`xo game` communicates with the game that `project run` or `debug run` started, through the debug session of the editor. It operates for embedded, windowed, and remote runs. Give `--session` when more than one session is attached, and `--timeout` for slow games. `xo game console` is different: the game instance itself replies to it.

```sh
xo game status                                   # stopped | launching | live | missing | at-break
xo game tree --root /root/Main --depth 3          # live node tree (path, class, script, child_count)
xo game node /root/Main/Player --props            # one node with its current property values
xo game ui list                                   # Controls: text, visible, disabled, rect, center
xo game input key Space                           # tap; --press / --release to hold; --mods ctrl,shift
xo game input mouse button left --at 320,240      # click at window coords (use `ui list` center)
xo game input mouse move --to 100,80              # or --by=-5,10 for a delta
xo game input action jump --press                 # InputMap action; --release later, or default tap
xo game input joy button 0 ; xo game input joy axis 0 --value=-1
xo game input sequence --json '[{"frame":0,"action":"jump","tap":true},{"frame":5,"key":"Right","press":true},{"frame":30,"key":"Right","press":false}]' --wait-frames 10
xo game actions                                   # currently pressed actions (--all for every action)
xo game eval 'tree.current_scene.name'            # `tree` (SceneTree) and `root` (Window) are predefined; get_tree()/get_node() are NOT available
xo game eval 'root.get_node("Main/Player").position'   # reach nodes through `root`, without the leading /root/
xo game eval --file /tmp/probe.gd --timeout 5     # coroutines with `await` return when they finish
xo game perf --monitor time_fps memory_static     # Performance monitors; --editor reads the editor process
```

Node paths in the game start at `/root`, as the `game tree` output shows. Editor commands are different: there, the root of the edited scene is `/`. The `game eval` output contains the `print` output of the game and the errors that occurred during the call, with one entry for each nonempty output line. A parse error gives an error with the compiler message. Commands that wait for frames (`tap`, `click`, `sequence`, and `eval` with `await`) cannot continue while the game is stopped at a breakpoint. Resume the game first.

Key presses and releases run on game process frames so `_process` can see `is_action_just_pressed`. A separate release after a press runs on the next frame. For an exact hold duration, use `game input sequence`; a release requested in the same frame as its press moves to the following frame. `tap` puts the release on the frame after the press.

`game ui list` includes `rect` and `center` in game-window coordinates. The mouse `--to` and `--at` values use the same coordinates. Injected mouse motion sets both the relative and screen-relative deltas. To press a button, you can also give it the focus and send `xo game input key Enter`.

Mouse motion and stretch: with the `canvas_items` stretch mode, `InputEventMouseMotion.relative` changes with the size of the window. A camera that reads `relative` then turns by a different angle in a larger window. Read `screen_relative` for camera control. When you make motion events yourself with `Input.parse_input_event` in `xo game eval`, set both `relative` and `screen_relative`.

### Forms of `game eval`

`game eval` accepts the same three forms as `xo eval` (see [xo-batch-and-eval.md](xo-batch-and-eval.md)):

- **An expression or a block of statements.** `tree` (the `SceneTree`) and `root` (the root `Window`) are available.
- **A block with its own `func _run():`.** `tree` and `root` are available.
- **A complete script** that starts with `extends`, for example `extends RefCounted`, with `func _run():` and helper functions. `xo` sets `tree` and `root` only when the script declares them (`var tree: SceneTree` and `var root: Window`). Otherwise, use `Engine.get_main_loop() as SceneTree`. Use this form for test suites.

In each form, `await` operates, and `--timeout` can be several minutes for a long simulation.

For a scene that `project run --scene` started, `tree.current_scene` is the most reliable start point. A path from `root` can change when the project puts the scene in a slot of a main scene.

The `errors` array of the reply also contains warnings, as entries that start with `warning:`, for example `SHADOWED_VARIABLE`. A warning is not a failure.

## Run project tests

`xo test` runs GDScript test suites in the editor. The game does not have to run. A suite is a `test_*.gd` file in the project, or under the `--root` directory, for example `--root res://tests`. Each `test_*` method with no required arguments is a test. The hooks `before_all`, `after_all`, `before_each`, and `after_each` are optional. A test **fails** when it returns `false` or a String message. A test has an **error** when an error is logged during the test, for example a script error or a failed `assert()`. A test **times out** when an awaited coroutine does not finish in the `--per-test-timeout` time.

```sh
xo test list                                       # suites and their test names
xo test run                                        # everything; exit code 40 unless all passed
xo test run --suite test_player --test 'test_jump*' --exclude test_slow --full
xo test run --timeout 60                           # stops early with partial=true; checks only between tests, so it cannot stop an infinite loop without await
xo test last                                       # the previous run's full report
```

The runner compiles the suites as `@tool` scripts, because the editor cannot make instances of plain scripts. The runner adds the suites that extend `Node` to the editor tree, so `get_tree()` and `await get_tree().process_frame` operate.

Test discovery does not enter a directory that contains `.gdignore`, even when that directory is below an explicit `--root`.

### Test gameplay

`xo test` runs in the editor. The scripts of the game are not `@tool` scripts, so in a suite, their `_ready`, `_process`, `_physics_process`, and input functions do not run. Use `xo test` for structure: a scene exists, it has the named nodes, the collision shapes are correct, and the properties of a prefab are correct. Do not use it for behavior.

To test behavior, run the checks in the game:

1. Put each behavior suite in a folder that contains a `.gdignore` file, for example `res://tests/game/`. The editor then does not import the suites, and `xo test` does not run them.
2. Write each suite as a complete script (`extends RefCounted` with `func _run():`). Let it print one line for each check, `PASS <name>` or `FAIL <name>: <reason>`.
3. For each suite, start a new game and run the suite:

   ```sh
   xo project run --scene res://levels/arena.tscn --wait
   xo game eval --file tests/game/test_weapons.gd --timeout 120
   xo project stop
   ```

4. Look for `FAIL` in `output`, and look for errors that do not start with `warning:` in `errors`.

Techniques that help:

- Set `Engine.time_scale` to 2 or more to simulate a long period quickly.
- Add a negative control. For example, a test that an enemy moves also runs an enemy with speed 0, and makes sure that the check fails for that enemy.
- To stop a test target, use `set_physics_process(false)`. Do not set `process_mode` to `PROCESS_MODE_DISABLED`: this removes a `CollisionObject3D` from the physics space, so rays and bullets go through it.
