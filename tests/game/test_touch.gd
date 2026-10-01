extends RefCounted
var tree: SceneTree
var root: Window

func touch(index: int, position: Vector2, pressed: bool) -> void:
	var event = InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	Input.parse_input_event(event)

func _run() -> Dictionary:
	var h = tree.current_scene
	h.set_process(true)
	h.player.set_physics_process(true)
	h.hud.close_modal()
	h.cancel_fishing()
	h.player.position = Vector3(-5,0.05,-7.35)
	h.find_station()
	h.update_context()
	await tree.process_frame
	var joy: Vector2 = h.hud.joystick.get_global_rect().get_center()
	var action: Vector2 = h.hud.action_button.get_global_rect().get_center()
	touch(0, joy, true)
	await tree.process_frame
	touch(1, action, true)
	await tree.process_frame
	var recognized = h.hud.joystick.finger == 0 and h.hud.touch_action_id == 1 and h.hud.held and h.fishing_state == "casting"
	print("PASS independent joystick and action fingers" if recognized else "FAIL independent touch")
	touch(1, action, false)
	touch(0, joy, false)
	await tree.process_frame
	var released = not h.hud.held and h.hud.touch_action_id == -1 and h.hud.joystick.finger == -1
	print("PASS touch release clears both controls" if released else "FAIL touch release")
	h.cancel_fishing()
	return {"multitouch": recognized, "release": released}
