extends RefCounted
var tree: SceneTree
var root: Window
var checks: int = 0
var failures: Array[String] = []

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: failures.append(caption)
	print(("PASS " if ok else "FAIL ") + caption)

func touch(index: int, point: Vector2, pressed: bool) -> void:
	var event = InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	Input.parse_input_event(event)

func _run() -> Dictionary:
	var h = tree.current_scene
	var economy = root.get_node("Economy")
	var original_position: Vector3 = h.player.position
	var original_toggle: bool = economy.data.settings.toggle_reel
	var original_saving: bool = economy.saving_enabled
	var protected_save_path:String=economy.save_path
	economy.save_path="user://reel_live_validation.json"
	economy.saving_enabled = false
	h.set_process(true)
	h.player.set_physics_process(true)
	h.hud.close_modal()
	h.cancel_fishing()
	h.player.velocity = Vector3.ZERO
	h.player.position = Vector3(-5,0.05,-7.35)
	h.find_station()
	h.update_context()
	await tree.process_frame
	var joy: Vector2 = h.hud.joystick.get_global_rect().get_center()
	var action: Vector2 = h.hud.action_button.get_global_rect().get_center()
	touch(0,joy,true)
	await tree.process_frame
	touch(1,action,true)
	await tree.process_frame
	check(h.hud.joystick.finger == 0 and h.hud.touch_action_id == 1 and h.hud.held and h.fishing_state == "casting","independent joystick and action fingers")
	touch(1,action,false)
	touch(0,joy,false)
	await tree.process_frame
	check(not h.hud.held and h.hud.touch_action_id == -1 and h.hud.joystick.finger == -1,"touch release clears both controls")
	h.cancel_fishing()
	# Native touch may be accompanied by a synthetic mouse press. It must NOT
	# switch the accessibility reel toggle twice in the same frame.
	h.set_process(false)
	economy.data.settings.toggle_reel = true
	h.fishing_state = "reeling"
	h.reel_toggled = false
	h.hud.context("Tap to reel","TOGGLE REEL",true)
	touch(2,action,true)
	await tree.process_frame
	check(h.reel_toggled,"one native action tap toggles reeling exactly once")
	touch(2,action,false)
	await tree.process_frame
	check(h.reel_toggled and not h.hud.held,"releasing the native action leaves toggle mode on")
	touch(2,action,true)
	await tree.process_frame
	touch(2,action,false)
	await tree.process_frame
	check(not h.reel_toggled,"the next native action tap switches reeling off")
	h.cancel_fishing()
	economy.data.settings.toggle_reel = original_toggle
	h.set_process(true)
	h.update_context()
	var signals_seen: Array[int] = [0]
	var listener = func(): signals_seen[0] += 1
	h.hud.action_pressed.connect(listener)
	var mouse = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = action
	mouse.global_position = action
	mouse.pressed = true
	Input.parse_input_event(mouse)
	await tree.process_frame
	mouse = mouse.duplicate()
	mouse.pressed = false
	Input.parse_input_event(mouse)
	await tree.process_frame
	check(signals_seen[0] == 1 and not h.hud.action_button.has_focus() and h.fishing_state == "casting","physical mouse action works without retaining GUI focus")
	h.cancel_fishing()
	var space = InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.keycode = KEY_SPACE
	space.pressed = true
	Input.parse_input_event(space)
	await tree.process_frame
	space = space.duplicate()
	space.pressed = false
	Input.parse_input_event(space)
	await tree.process_frame
	check(signals_seen[0] == 1 and h.fishing_state == "casting","Space routes through gameplay once, not through a focused button")
	h.hud.action_pressed.disconnect(listener)
	h.cancel_fishing()
	h.hud.joystick.reset()
	h.hud.held = false
	h.player.position = original_position
	h.player.velocity = Vector3.ZERO
	economy.save_path=protected_save_path
	economy.saving_enabled = original_saving
	print("RESULT %d touch/action checks / %d failures" % [checks,failures.size()])
	return {"checks":checks,"failures":failures}
