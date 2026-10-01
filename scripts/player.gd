extends CharacterBody3D
var hub: Node3D
var visual: Node3D
var animation: AnimationPlayer
var basket: Node3D
var rod: Node3D
var moving = false
var footstep_time = 0.0

func _ready() -> void:
	var shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	add_child(shape)
	floor_snap_length = 0.3

func _physics_process(delta: float) -> void:
	if hub == null: return
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if hub.hud.joystick.direction.length() > 0.05: input = hub.hud.joystick.direction
	if hub.hud.modal_open or hub.focus_paused: input = Vector2.ZERO
	if input.length() > 0.08 and hub.fishing_state != "idle": hub.cancel_fishing()
	velocity.x = input.x * 4.4
	velocity.z = input.y * 4.4
	velocity.y = -1.0
	var proposed = position + velocity * delta
	# Validate the combined diagonal step, not two independent axis checks.
	if not hub.walkable(proposed):
		if hub.walkable(Vector3(proposed.x, 0, position.z)):
			velocity.z = 0
		elif hub.walkable(Vector3(position.x, 0, proposed.z)):
			velocity.x = 0
		else:
			velocity.x = 0
			velocity.z = 0
	move_and_slide()
	var now_moving = input.length() > 0.1
	if visual != null and now_moving:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(input.x, input.y), minf(1, delta * 14))
	if now_moving:
		footstep_time += delta
		if footstep_time > 0.32:
			footstep_time = 0
			hub.audio.tone(105, 0.05, float(Economy.data.settings.sfx) * 0.07)
	if now_moving != moving:
		moving = now_moving
		play_animation("Run_Forward" if moving else "Idle_Breathing")
	if basket != null and not Economy.data.settings.reduced_motion:
		basket.rotation.z = sin(Time.get_ticks_msec() * 0.008) * (0.06 if moving else 0.015)

func play_animation(clip: String) -> void:
	if animation == null or not animation.has_animation(clip): return
	animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation.play(clip, 0.15)
