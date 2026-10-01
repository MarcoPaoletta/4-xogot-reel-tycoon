extends Control
var direction = Vector2.ZERO
var finger = -1
var mouse_down = false

func _ready() -> void:
	custom_minimum_size = Vector2(160, 160)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _draw() -> void:
	var center = size * 0.5
	draw_circle(center, 68, Color(0.025, 0.16, 0.2, 0.42))
	draw_arc(center, 68, 0, TAU, 64, Color(0.82, 1, 0.95, 0.65), 2.0, true)
	draw_circle(center + direction * 44, 27, Color(0.84, 1, 0.94, 0.88))
	for v in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_circle(center + v * 53, 2, Color(0.8, 1, 0.94, 0.7))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1:
			finger = event.index
			update_direction(event.position)
		elif event.index == finger:
			finger = -1
			direction = Vector2.ZERO
			queue_redraw()
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_down = event.pressed
		if mouse_down: update_direction(event.position)
		else:
			direction = Vector2.ZERO
			queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion and mouse_down:
		update_direction(event.position)
		accept_event()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag and event.index == finger:
		update_direction(event.position - global_position)
	if event is InputEventScreenTouch and not event.pressed and event.index == finger:
		finger = -1
		direction = Vector2.ZERO
		queue_redraw()

func update_direction(point: Vector2) -> void:
	direction = ((point - size * 0.5) / 50.0).limit_length()
	if direction.length() < 0.12: direction = Vector2.ZERO
	queue_redraw()

func reset() -> void:
	finger = -1
	mouse_down = false
	direction = Vector2.ZERO
	queue_redraw()
