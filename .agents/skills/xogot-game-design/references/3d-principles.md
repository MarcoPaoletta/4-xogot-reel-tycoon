# Godot 3D Principles

## Contents

- Scale and axes
- Imported assets
- Transforms and actors
- Navigation
- Rendering, lighting, and materials
- 3D review checklist

## Scale and axes

One Godot unit is one meter. Godot is Y-up and right-handed. Forward is -Z: `Vector3.FORWARD`, cameras, and `look_at()` all use -Z. An imported model that faces +Z looks backward.

Make assets at the correct scale in the modeling tool. Do not correct the scale after import. Physics, navigation, lighting, camera clipping, and movement all depend on a consistent scale.

Before you build levels, make a metrics kit: the player capsule and eye height, door and corridor sizes, stair and cover sizes, interaction reach, and jump height and distance. Use it in each blockout.

## Imported assets

Treat an imported model as generated input. Put it in a wrapper scene that the game owns. The wrapper holds the scripts, collision, interaction, navigation, and audio. Then a new export of the art does not delete gameplay work.

Use glTF for interchange. To change an imported scene, use import settings, the Advanced Import Settings dialog, inherited scenes, import scripts, or name suffixes such as `-col`. Do not edit the generated content by hand.

## Transforms and actors

Do not scale a physics body. Change the size of its shapes and meshes.

A starting shape for a first- or third-person actor:

```text
Player (CharacterBody3D)
├── BodyCollision (CollisionShape3D)
├── Yaw (Node3D)
│   ├── Visuals
│   └── Pitch (Node3D)
│       └── Camera3D
└── InteractionRay (RayCast3D)
```

The body moves and collides. `Yaw` turns around the up axis. `Pitch` looks up and down. Change this shape for camera collision in third person, or when the visuals must face a different direction.

Euler angles are good for the Inspector. Do not use them to combine or interpolate rotations. Use `Basis`, `Transform3D`, or `Quaternion`.

Set the camera near and far planes only as wide as the game needs.

## Navigation

**A `NavigationAgent3D` does not move its parent.** It only gives the path. In `_physics_process()`, read the next path position and move the actor with its own controller:

```gdscript
func _physics_process(_delta: float) -> void:
	if agent.is_navigation_finished():
		return
	var next_position := agent.get_next_path_position()
	velocity = global_position.direction_to(next_position) * speed
	move_and_slide()
```

`NavigationAgent2D` operates in the same way.

Bake the navigation mesh for the real agent radius, height, step height, and slope. Keep it simpler than the render geometry. Turn on the navigation debug view to find missing links and areas that the agent cannot reach.

Look at each level from the play camera, not only from the editor camera. At each decision point, the player must see the next goal, the routes, the threats, and a landmark.

## Rendering, lighting, and materials

Select the renderer from the weakest target device:

- **Forward+**: desktop projects that need advanced rendering.
- **Mobile**: newer mobile devices, XR, and simpler scenes on modern GPUs.
- **Compatibility**: web, old or low-end hardware, and simple projects.

Select the renderer early. A change of renderer can change the available features and the appearance.

Start with one environment and the smallest number of lights that show form and gameplay. Use baked lighting for static areas when it fits the game. Use real-time shadows only for movement that is important. Count the shadow-casting lights, and set the shadow distance and resolution.

Use opaque materials by default. For foliage, fences, and hair, use alpha scissor or alpha hash. Use alpha blending only for real partial transparency. It costs more, it has sort problems, and some render features ignore it. Share meshes, materials, and textures. Each different material can prevent batching.

Use these tools only after profiling shows the problem:

- mesh LOD for objects that become small on the screen;
- visibility ranges (HLOD) for distant groups;
- occlusion culling for rooms, corridors, and dense cities. It does not help an open field.
- `MultiMesh` for many copies of one mesh, such as grass or debris. Its visibility is for the full group.

## 3D review checklist

- Is the scale consistent from the modeling tool to gameplay?
- Do models face -Z, and are their origins at gameplay points?
- Can you import the art again without loss of gameplay work?
- Do physics bodies have a scale of 1?
- Do collision and navigation follow gameplay, not mesh detail?
- Do NavigationAgents move their actor through the controller?
- Can the player see goals, routes, threats, and landmarks from the play camera?
- Does the renderer agree with the target hardware?
- Are shadowed lights, transparency, post effects, and particles in the budget?
- Did you test the worst-case scene in an exported build?
