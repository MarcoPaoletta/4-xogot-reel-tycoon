# Core Godot Game-Design Principles

Use these rules when the project has no pattern of its own. They do not replace the decisions that the project already made.

## Contents

- Start with the playable loop
- Scenes, nodes, and Resources
- Communication and dependencies
- Input, time, and physics
- States, animation, camera, and feel
- Common traps

## Start with the playable loop

Build the smallest loop that shows the game before you add an inventory, a skill tree, procedural generation, a save format, or an event bus:

1. The player does an action.
2. The world responds.
3. The player can see success or failure.
4. The game resets or continues.

Use graybox geometry, flat colors, and placeholder audio. Tune movement, timing, camera, and spatial metrics before you make final content.

For each player verb (move, jump, aim, build), identify what starts it, what can interrupt it, the state it leaves, and the feedback that the player gets. Feedback is part of the action. Keep the strongest feedback for the most important information.

## Scenes, nodes, and Resources

Make a scene for each reusable game object: a player, an enemy, a projectile, a door, a health bar, a camera rig, or a menu. Scenes are not only for levels.

A good scene:

- has one purpose;
- owns the nodes for that purpose;
- can run alone for a test;
- has a small set of exported settings;
- does not use node paths outside its own tree.

To find the correct parent for a node, ask: "When the parent is deleted, must this child also be deleted?" If the answer is no, the child has the wrong parent.

A small application root:

```text
Main
├── World
│   ├── CurrentLevel
│   ├── Actors
│   └── Effects
└── Interface (CanvasLayer)
    ├── HUD
    └── Screens
```

Add a branch only when a lifetime or a coordination need makes it necessary.

Use a node only when the object needs the scene tree: a transform, rendering, physics, input, audio, a timer, or an engine callback. For data and for logic that does not need the tree, use a `Resource`, a `RefCounted`, or a plain class. Examples are item definitions, weapon parameters, enemy statistics, and movement profiles.

**Loaded Resources are shared.** All instances that load the same `.tres` file get the same object. When each instance must change its own copy, call `duplicate()` or set `resource_local_to_scene`.

Prefer composition to deep inheritance. Use inheritance only for a stable "is-a" relation with a useful shared contract. A component does not have to be a node.

Export the values that a designer tunes, and give the unit and the safe range. Show incorrect setup in the editor with `assert()` or `_get_configuration_warnings()`.

## Communication and dependencies

Commands go down, and events go up. A parent calls methods on the children that it owns:

```gdscript
weapon.fire(direction)
health.apply_damage(amount)
```

A reusable child emits a signal to announce a fact. The child does not select the response:

```gdscript
signal died
signal health_changed(current: int, maximum: int)
```

Name signals as past events. Let the common parent connect two siblings. Do not use long node paths across scene boundaries. Do not use a signal where a direct call is correct.

Use an autoload only for application scope: settings, save and load, platform services, persistent progress, or music that continues across levels. Put a system for one match or one level under the node that owns that lifetime.

Use groups as tags, for example `damageable` or `interactable`. Do not scan a large group in each frame. Do not use a group to hide a relation that must be an explicit reference.

## Input, time, and physics

Read Input Map actions (`move_left`, `jump`, `interact`) in gameplay code. Do not read physical keys.

- Use input events for single presses. Read the action strength in each frame for continuous movement and aim.
- Use `_unhandled_input()` for gameplay input, so that the UI gets the events first.
- Decide which input operates while the game is paused.

Do physics movement and physics queries in `_physics_process(delta)`. Use `_process(delta)` for visual work.

**Do not multiply a `CharacterBody` velocity by `delta` before `move_and_slide()`.** `move_and_slide()` applies the time step. Multiply accelerations by `delta` when you add them to `velocity`, for example `velocity.y += gravity * delta`. Multiply by `delta` also when you integrate a value yourself, for example `position += speed * delta`. Give speeds in units per second.

| Need | Body | Motion owner |
| --- | --- | --- |
| Detect an overlap, or change a region | `Area2D` / `Area3D` | Game code. There is no solid response. |
| Fixed world geometry | `StaticBody2D` / `StaticBody3D` | The world |
| Simulated object | `RigidBody2D` / `RigidBody3D` | The physics engine, through forces and impulses |
| Actor with precise control | `CharacterBody2D` / `CharacterBody3D` | Your controller code |

Do not set the transform of a `RigidBody` in each frame. Apply forces and impulses. A `CharacterBody` does not move by itself. Your code moves it. Godot physics is not deterministic. Do not design replays or lockstep networking that need identical results.

Keep collision simpler than the visible geometry:

- Use primitive shapes when possible.
- Use a small number of convex shapes for moving 3D bodies.
- Use concave or triangle-mesh shapes only for static level geometry.
- Keep body collision, interaction areas, hitboxes, and hurtboxes separate when they have different rules.
- Give the collision layers a small set of names for the full project.

## States, animation, camera, and feel

Use booleans only while they are independent. When states can conflict (jumping, attacking, stunned, climbing), use an enum or a state machine, and put all transitions in one place. Do not start each actor with a general state-machine framework.

Animation shows the state. It does not own the state. Use `AnimatedSprite2D` for frame animation and `AnimationPlayer` for property animation. Use `AnimationTree` only when blends or transitions make it necessary. Game rules must not depend on track names or on the length of a clip.

The camera is part of gameplay. Tune look-ahead, dead zones, smoothing, limits, and zoom or field of view. Keep camera shake short and limited, and let the player disable it.

Give names and values to forgiveness mechanics: input buffer, coyote time, variable jump height, and hit pause. Give times in milliseconds, for example "100 ms jump buffer".

## Common traps

| Trap | Better default |
| --- | --- |
| One very large scene or script | Extract a scene when an object becomes reusable or has its own owner. |
| A node for each idea | Use nodes for tree behavior. Use Resources or classes for data and simple logic. |
| Each manager is an autoload | Put each system under the owner of its lifetime. |
| A child searches up the tree for a service | Give the child the dependency, or let the parent coordinate. |
| Long node paths across scene boundaries | Keep references to owned nodes. Export or inject external references. |
| Signals used as commands | Call the owned object directly. Use signals to announce facts. |
| Physical keys in gameplay code | Read Input Map actions. |
| Physics movement in `_process()` | Use `_physics_process()` and the body API. |
| Render geometry used as collision for a moving body | Use primitive or convex collision shapes. |
| A framework before the first room | Build the loop first. Extract the pattern that the game shows. |
