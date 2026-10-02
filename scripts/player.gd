extends CharacterBody3D
const IN_PLACE = preload("res://scripts/in_place_animation.gd")
@export_range(1.0, 5.0, 0.1) var move_speed: float = 3.1
const SPEED: float = 3.1 # Default pace retained for controller/test compatibility.
const ACCELERATION: float = 24.0
var hub: Node3D
var visual: Node3D
var animation: AnimationPlayer
var basket: Node3D
var rod: Node3D
var moving: bool = false
var footstep_time: float = 0.0
var current_clip: String = ""
var prepared: bool = false
var running: bool = false

func _ready() -> void:
	floor_snap_length = 0.45
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(45)

func _physics_process(delta: float) -> void:
	if hub == null or not is_instance_valid(hub.hud): return
	if not prepared and animation != null:
		prepare_locomotion()
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.12)
	if hub.hud.joystick.active() or not hub.hud.joystick.direction.is_zero_approx(): input = hub.hud.joystick.direction
	var blocked = hub.hud.modal_open or hub.focus_paused
	if blocked: input = Vector2.ZERO
	if input.length() > 0.12 and hub.fishing_state != "idle": hub.cancel_fishing()
	if blocked or hub.fishing_state != "idle" or input.is_zero_approx():
		velocity.x = 0
		velocity.z = 0
	else:
		var target = screen_aligned_direction(input) * move_speed
		var horizontal = Vector2(velocity.x, velocity.z).move_toward(Vector2(target.x, target.z), ACCELERATION * delta)
		velocity.x = horizontal.x
		velocity.z = horizontal.y
	if is_on_floor(): velocity.y = 0
	else: velocity.y -= 18 * delta
	var safe_position = position
	var proposed = position + velocity * delta
	if not hub.walkable(proposed):
		if hub.walkable(Vector3(proposed.x, 0, position.z)): velocity.z = 0
		elif hub.walkable(Vector3(position.x, 0, proposed.z)): velocity.x = 0
		else:
			velocity.x = 0
			velocity.z = 0
	move_and_slide()
	if not hub.walkable(position):
		position.x = safe_position.x
		position.z = safe_position.z
	var speed = Vector2(velocity.x, velocity.z).length()
	moving = speed > 0.12
	if visual != null and moving:
		visual.rotation.y = wrapf(lerp_angle(visual.rotation.y, atan2(velocity.x, velocity.z), 1.0 - exp(-delta * 22)), -PI, PI)
	running = speed > (1.85 if running else 2.15)
	play_animation("Run_Forward" if running else ("Walk_Forward" if moving else "Idle_Breathing"))
	if animation != null:
		animation.speed_scale = clampf(speed / (2.4 if running else 1.4), 0.35, 1.35) if moving else 1.0
	if moving:
		footstep_time += delta * clampf(speed / move_speed, 0.4, 1)
		if footstep_time > 0.29:
			footstep_time = 0
			hub.audio.tone(105, 0.045, float(Economy.data.settings.sfx) * 0.055)
	if basket != null:
		var sway = sin(Time.get_ticks_msec() * 0.009) * minf(speed / move_speed, 1) * 0.04
		basket.rotation.z = 0.0 if Economy.data.settings.reduced_motion else sway

func screen_aligned_direction(input: Vector2) -> Vector3:
	# Invert the fixed perspective camera at the player's feet. Mapping X/Y directly
	# to X/Z foreshortens diagonals and makes a 45-degree drag visibly slide sideways.
	var fallback = Vector3(input.x, 0, input.y).limit_length(1)
	if input.is_zero_approx() or hub.camera == null: return fallback
	var screen: Vector2 = hub.camera.unproject_position(global_position)
	var target: Vector2 = screen + input.normalized() * 24.0
	var ground = Plane(Vector3.UP, global_position.y)
	var point: Variant = ground.intersects_ray(hub.camera.project_ray_origin(target), hub.camera.project_ray_normal(target))
	if not point is Vector3: return fallback
	var direction: Vector3 = point - global_position
	direction.y = 0
	return direction.normalized() * minf(1, input.length())

func prepare_locomotion() -> void:
	prepared = true
	var skeleton = visual.find_child("Skeleton3D", true, false) as Skeleton3D
	var library = AnimationLibrary.new()
	for clip in ["Idle_Breathing", "Walk_Forward", "Run_Forward"]:
		if not animation.has_animation(clip): continue
		var copy = IN_PLACE.clip(animation.get_animation(clip), skeleton)
		library.add_animation(clip, copy)
	animation.add_animation_library("locomotion", library)
	current_clip = ""

func play_animation(clip: String) -> void:
	if animation == null: return
	var name_to_play = "locomotion/" + clip if prepared else clip
	if current_clip == name_to_play or not animation.has_animation(name_to_play): return
	current_clip = name_to_play
	animation.get_animation(name_to_play).loop_mode = Animation.LOOP_LINEAR
	animation.play(name_to_play, 0.16)
