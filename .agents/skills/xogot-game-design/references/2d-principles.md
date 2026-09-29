# Godot 2D Principles

## Contents

- Canvas and resolution
- Pixel art
- Origins and draw order
- Tilemaps
- Actor structure and movement
- 2D review checklist

## Canvas and resolution

In Godot 2D, positive X goes right and positive Y goes down.

Select a base resolution early. Then set how the game fits wider, taller, and denser screens with `display/window/stretch/mode` and `display/window/stretch/aspect`. Test the narrowest, widest, smallest, and largest layouts that you support.

- Put world content under `Node2D` nodes.
- Build UI from `Control` nodes and containers. Do not position responsive UI by hand.
- Put screen-space UI under a `CanvasLayer`, so that the world camera does not move it.
- Use anchors for relations and containers for layout. Use a theme Resource for styles.

## Pixel art

Smooth, illustrated 2D art can use fractional positions and filtered scaling. For pixel art, set these project settings together:

- a low base resolution;
- `rendering/textures/canvas_textures/default_texture_filter` = `Nearest`;
- `display/window/stretch/mode` = `viewport`;
- `display/window/stretch/scale_mode` = `integer`, when the target screens allow it;
- `rendering/2d/snap/snap_2d_transforms_to_pixel`, when movement must stay on the pixel grid.

Rotated and scaled pixel art does not stay sharp. Look at it in the game before you accept it. Pixel snapping changes the appearance. It is not an optimization.

## Origins and draw order

Put the origin of each object at its gameplay point: the feet of a standing actor, the hinge of a door, the grip of a weapon. Keep the scene root at that point, and offset the visual children when the art has a different pivot.

Use a small set of named `z_index` bands. Do not use random values. In a top-down game, Y-sort draws lower objects in front. For Y-sort to work, put each origin at the point where the object touches the ground. Keep foreground overlays and UI out of the Y-sorted branch.

## Tilemaps

Use `TileMapLayer` nodes. The `TileMap` node is deprecated since Godot 4.3. Do not use one sprite node for each tile.

- Use separate layers for background, solid terrain, decoration, foreground, and gameplay markers when this makes draw order or ownership clear.
- Save a TileSet that more than one scene uses as an external `.tres` file.
- Put collision, occlusion, navigation, and custom tile data in the TileSet.
- For large pathfinding needs, bake a `NavigationRegion2D`. Do not depend only on tile navigation for the shipped level.

## Actor structure and movement

A starting shape for a player scene:

```text
Player (CharacterBody2D)
├── BodyCollision (CollisionShape2D)
├── Visuals (Node2D)
│   ├── Sprite (AnimatedSprite2D)
│   └── Effects
├── Hurtbox (Area2D)
│   └── CollisionShape2D
├── InteractionArea (Area2D)
│   └── CollisionShape2D
└── CameraRig (Node2D)
    └── Camera2D
```

This shape keeps movement collision, damage, interaction, visuals, and camera separate. It is a starting point, not a rule.

Minimal free movement:

```gdscript
class_name Player
extends CharacterBody2D

@export var maximum_speed: float = 320.0


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(
		&"move_left", &"move_right", &"move_up", &"move_down"
	)
	velocity = direction * maximum_speed
	move_and_slide()
```

`Input.get_vector()` applies the dead zone and limits diagonal input to a length of 1. Add acceleration only when the game feel needs it.

Move the camera to its own rig when it needs look-ahead, dead zones, room limits, smoothing, zoom, or shake. The camera must not change the position of the actor.

## 2D review checklist

- Are the base resolution and the stretch settings explicit?
- Do world and UI use the correct coordinate systems?
- Do the pixel-art settings agree with each other?
- Are the origins at gameplay points, not at image corners?
- Are the Y-sort and `z_index` rules predictable?
- Does each tile layer have one clear role?
- Are body collision, hitboxes, hurtboxes, and interaction areas separate when they have different rules?
- Does movement use Input Map actions and `_physics_process()`?
- Does the camera show the information that the player needs?
- Did you test extreme aspect ratios, touch, controllers, and exported builds on the device?
