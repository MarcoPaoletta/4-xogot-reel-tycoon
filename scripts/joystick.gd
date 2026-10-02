extends Control
## Floating mobile thumbstick. The first touch is neutral; only its owner can move it.
const DEAD_ZONE: float = 0.10
const TRAVEL: float = 54.0
var direction: Vector2 = Vector2.ZERO
var knob: Vector2 = Vector2.ZERO
var finger: int = -1
var mouse_down: bool = false
var enabled: bool = true
var suppress_mouse_until: int = 0
var origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func active() -> bool:
	return finger >= 0 or mouse_down

func resting_center() -> Vector2:
	return Vector2(86, size.y - 96)

func local_point(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * point

func owns_point(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(local_point(point))

func _draw() -> void:
	var c = origin if active() else resting_center()
	var opacity = 1.0 if active() else 0.55
	draw_circle(c + Vector2(0, 4), 62, Color(0.02, 0.09, 0.14, 0.12 * opacity))
	draw_circle(c, 62, Color(0.96, 1, 0.98, 0.12 * opacity))
	draw_arc(c, 62, 0, TAU, 64, Color(0.96, 1, 0.98, 0.65 * opacity), 2, true)
	if active() and not knob.is_zero_approx():
		var angle = knob.angle()
		draw_arc(c, 62, angle - 0.45, angle + 0.45, 16, Color("8ef2cc"), 4, true)
	var p = c + knob * TRAVEL
	draw_circle(p + Vector2(0, 4), 25, Color(0.03, 0.16, 0.21, 0.18 * opacity))
	draw_circle(p, 25, Color(0.95, 1, 0.98, 0.95 * opacity))
	draw_circle(p + Vector2(-6, -7), 7, Color(1, 1, 1, 0.6 * opacity))

func begin(point: Vector2) -> void:
	origin = local_point(point)
	direction = Vector2.ZERO
	knob = Vector2.ZERO
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not enabled or not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		suppress_mouse_until = Time.get_ticks_msec() + 180
		if event.pressed and not active() and owns_point(event.position):
			finger = event.index
			mouse_down = false
			begin(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == finger:
			reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == finger:
		update_screen(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == -1 or finger >= 0 or Time.get_ticks_msec() < suppress_mouse_until: return
		if event.pressed and not active() and owns_point(event.position):
			mouse_down = true
			begin(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and mouse_down:
			reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and mouse_down and event.device != -1:
		update_screen(event.position)
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if mouse_down and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): reset()

func update_screen(point: Vector2) -> void:
	var c = origin if active() else resting_center()
	var vector = (local_point(point) - c) / TRAVEL
	var length = minf(1, vector.length())
	knob = vector.limit_length(1)
	direction = vector.normalized() * maxf(0, (length - DEAD_ZONE) / (1 - DEAD_ZONE))
	queue_redraw()

func update_direction(local_position: Vector2) -> void:
	update_screen(get_global_transform_with_canvas() * local_position)

func reset() -> void:
	finger = -1
	mouse_down = false
	direction = Vector2.ZERO
	knob = Vector2.ZERO
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		reset()
