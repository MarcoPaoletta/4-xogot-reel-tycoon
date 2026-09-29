# Production and Review Principles

## Contents

- UI, audio, and accessibility
- Performance
- Code, tests, and version control
- Newcomer sequence
- Review rubric

## UI, audio, and accessibility

### UI

Use `Control` anchors for relations and containers for layout. Use a theme Resource for styles. Test these conditions:

- keyboard and controller focus;
- mouse and touch;
- safe areas;
- longer text after localization;
- large text;
- narrow, wide, and unusual aspect ratios.

Keep UI state separate from game state. A health bar shows the health. It does not own the health. A pause menu asks for a pause. It is not the only source of the pause state.

### Audio

Use named buses, for example Master, Music, SFX, Voice, and UI. Use positional players for sounds in the world, and non-positional players for UI and music. Limit the number of copies of a frequent sound that play at the same time. Use sound to show events that are off the screen or hard to see.

### Accessibility

Add these items with the first controls. It is expensive to add them after input, UI, camera, and feedback depend on each other.

- remappable actions and more than one input device;
- good contrast, and information that does not use only color;
- subtitles and text size settings;
- settings to reduce shake, flashes, and motion;
- a toggle as an alternative to a hold;
- separate volume for each audio category;
- pause, timing help, or aim help, as the game needs.

## Performance

Select a target frame rate and the weakest device that you support. A frame at 60 fps has 16.7 ms. A frame at 30 fps has 33.3 ms. Gameplay, physics, rendering, animation, navigation, audio, and the platform share this time.

Profile an exported build of a representative scene. Editor performance is not the final performance. Identify the type of problem:

- a CPU or GPU limit in all frames;
- spikes in some frames;
- pauses when content loads;
- memory that increases;
- battery use and heat.

Make a hypothesis, change one thing, and measure again. Do not optimize a system only because it looks slow.

Good defaults that do not need a profile:

- Disable processing on idle objects.
- Do not search the tree in each frame. Keep a reference, or use a signal.
- Do not use nodes for very small data items.
- Share Resources.

Use object pools only when a measurement shows that creation or deletion costs too much.

## Code, tests, and version control

Use one code style in the project. In GDScript, use static types on public methods, data structures, and long-lived code. Use `class_name` for important project types. Keep scripts short, with clear responsibilities. Keep the project's language (GDScript, C#, or Swift). Do not translate code to a different language without a reason.

Put source assets, project settings, scripts, scenes, and import sources in version control from the first day. Ignore the `.godot/` folder. Use text formats (`.tscn`, `.tres`) for scenes and Resources. Use a large-file system for large binary assets.

Test reusable scenes with small test scenes or `test_*.gd` suites. Test first the contracts that are easy to break:

- health stays in its limits;
- a signal fires one time only;
- state transitions accept the correct cases and refuse the incorrect cases;
- save data loads correctly, also from an older version;
- input buffers expire at the correct time;
- level exits operate when an actor is missing or duplicated;
- scenes survive pause, reload, and deletion;
- controller disconnect, focus loss, suspend, and resume operate correctly.

Use the collision, navigation, and debug-draw views. Show incorrect setup in the editor.

## Newcomer sequence

### First playable

1. Select one target platform, one renderer, one base resolution, and one primary input method.
2. Define the Input Map actions.
3. Build one actor, one room, one challenge, one goal, and a restart.
4. Tune movement, camera, and feedback with placeholder assets.
5. Export to the target device immediately.

### First reusable slice

1. Extract the player, the challenge, and the goal into their own scenes.
2. Define their public methods, exported properties, and signals.
3. Move reusable data into Resources.
4. Add a small `Main` scene that separates the world from the interface.
5. Add audio buses, settings, pause, and one value that the game saves.

### Before content production

1. Freeze the scale, the collision layer names, the naming rules, and the import workflow.
2. Set performance and memory budgets on the weakest device.
3. Build one worst-case room or encounter.
4. Examine UI scaling, space for localized text, and input remapping.
5. Show common setup errors in the editor.

### Before release

1. Profile exported builds on each device class.
2. Test save migration, suspend and resume, focus loss, controller disconnect, and damaged optional data.
3. Test all supported aspect ratios and safe areas.
4. Examine accessibility from a new installation.
5. Examine the licenses, and test the exact release package.

## Review rubric

Use only the dimensions that apply to the project:

| Dimension | Questions |
| --- | --- |
| Playable loop | Can you test the main verb? Is it clear and satisfying before other systems exist? |
| Ownership | Do the scene boundaries agree with lifetime and responsibility? |
| Coupling | Do reusable scenes operate without long paths or hidden global state? |
| Data | Is reusable data in Resources or small objects, not in nodes without a reason? |
| Communication | Are direct calls and signals used for the correct purposes? |
| Input and time | Are Input Map actions, pause, `_physics_process()`, and `delta` used correctly? |
| Physics | Does each body type agree with the owner of the motion? Is the collision simple? |
| Camera and feedback | Does the player get the information needed to act? |
| 2D or 3D pipeline | Are resolution or scale, imports, origins, draw order, transforms, renderer, and navigation consistent? |
| UI and accessibility | Does the game operate on different screens, devices, languages, and accessibility settings? |
| Performance | Are the budgets explicit? Does profiling support the conclusions? |
| Production | Are the content workflow, tests, version control, saves, and release steps repeatable? |

In a review, sort the findings by their effect, not by the order of this table. Give the evidence, and recommend the smallest change that corrects the result.
