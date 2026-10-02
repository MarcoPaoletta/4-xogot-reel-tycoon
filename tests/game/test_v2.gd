extends RefCounted
## Live V2 interaction checks. All player data and save flags are restored.
var tree: SceneTree
var root: Window
var checks: int = 0
var failures: Array[String] = []

func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: failures.append(caption)
	print(("PASS " if ok else "FAIL ") + caption)

func release_all() -> void:
	for action in ["move_left","move_right","move_up","move_down","interact","menu"]:
		Input.action_release(action)
	for code in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_RIGHT,KEY_DOWN,KEY_SPACE]: key(code,false)

func frames(count: int = 1) -> void:
	for i in count: await tree.physics_frame
	await tree.process_frame

func wait_for_home(b: Control, slot: int) -> void:
	# SceneTree timers run before tweens. Wait for the actual return, bounded to
	# 30 frames, instead of testing a 0.22s tween on a fragile 0.23s deadline.
	for i in 30:
		if not b.actors.has(slot) or b.actors[slot].position.distance_to(b.slot_position(slot)) < 0.002: return
		await tree.process_frame

func key(code: Key, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func touch(id: int, point: Vector2, pressed: bool) -> void:
	var event = InputEventScreenTouch.new()
	event.index = id
	event.position = point
	event.pressed = pressed
	Input.parse_input_event(event)

func drag(id: int, point: Vector2) -> void:
	var event = InputEventScreenDrag.new()
	event.index = id
	event.position = point
	Input.parse_input_event(event)

func mouse(point: Vector2, pressed: bool) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.global_position = point
	event.pressed = pressed
	Input.parse_input_event(event)

func motion(point: Vector2) -> void:
	var event = InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(event)

func board_drop(b: Control, first: int, last: int, id: int = 4) -> void:
	touch(id,b.screen_for_slot(first),true)
	await frames()
	drag(id,b.screen_for_slot(last))
	await frames()
	touch(id,b.screen_for_slot(last),false)
	await tree.create_timer(0.23).timeout

func _run() -> Dictionary:
	var h = tree.current_scene
	var economy = root.get_node("Economy")
	var saved_data: Dictionary = economy.data.duplicate(true)
	var saved_position: Vector3 = h.player.position
	var saved_saving: bool = economy.saving_enabled
	var protected_save_path:String=economy.save_path
	economy.save_path="user://reel_live_validation.json"
	economy.saving_enabled = false
	h.hud.close_modal()
	h.cancel_fishing()
	h.set_process(false)
	h.focus_paused = false
	economy.data = economy.fresh_data()
	economy.changed.emit()
	release_all()
	# Exact pair selection, including equal species with different stored values.
	var e = load("res://scripts/economy.gd").new()
	e.saving_enabled = false
	e.save_path = "user://reel_v2_transaction_test.json"
	root.add_child(e)
	e.data = e.fresh_data()
	e.data.raw = [{"species":0,"value":7,"reserved":false},{"species":0,"value":9,"reserved":true},{"species":0,"value":8,"reserved":false}]
	check(e.merge_indices(0,2) == 1 and e.data.raw.size() == 2 and int(e.data.raw[0].value) == 9 and bool(e.data.raw[0].reserved),"merge consumes exactly the chosen pair, not the first two species")
	check(int(e.data.raw[1].value) == 15 and bool(e.data.raw[1].reserved),"selected merge preserves value cap and protects result")
	var unchanged = JSON.stringify(e.data)
	check(e.merge_indices(0,0) == -1 and e.merge_indices(-1,1) == -1 and e.merge_indices(0,99) == -1 and unchanged == JSON.stringify(e.data),"invalid and repeated indices are atomic no-ops")
	check(e.merge_indices(0,1) == -1 and unchanged == JSON.stringify(e.data),"unrelated selected pair remains unchanged")
	e.data = e.fresh_data()
	e.data.raw = [{"species":0,"value":7,"reserved":false},{"species":0,"value":9,"reserved":true}]
	check(e.display_index(1) and e.data.raw.size() == 1 and int(e.data.raw[0].value) == 7,"display consumes the exact selected fish")
	check(not e.display_index(0) and e.data.raw.size() == 1,"duplicate display cannot consume another fish")
	e.queue_free()
	# Real InputMap keys, measured over fixed physics ticks.
	h.player.position = Vector3(-5,0.05,3)
	h.player.velocity = Vector3.ZERO
	await frames(2)
	var start: Vector3 = h.player.position
	key(KEY_D,true)
	await frames()
	check(h.player.velocity.x > 0 and h.player.velocity.x < h.player.SPEED,"keyboard starts with controlled acceleration")
	await frames(20)
	check(h.player.position.x > start.x + h.player.move_speed * 0.25 and is_equal_approx(h.player.velocity.x,h.player.move_speed),"keyboard reaches predictable screen-right speed")
	check(h.player.current_clip == "locomotion/Run_Forward","actual motion selects the root-locked run clip")
	var hips_locked = true
	var run: Animation = h.player.animation.get_animation("locomotion/Run_Forward")
	for track in run.get_track_count():
		if run.track_get_type(track) != Animation.TYPE_POSITION_3D or not String(run.track_get_path(track)).ends_with(":Hips"): continue
		for i in run.track_get_key_count(track):
			var value: Vector3 = run.track_get_key_value(track,i)
			hips_locked = hips_locked and is_zero_approx(value.x) and is_zero_approx(value.z)
	check(hips_locked,"imported animation cannot drift the player horizontally")
	var release: Vector3 = h.player.position
	key(KEY_D,false)
	await frames()
	check(h.player.velocity.x < h.player.SPEED,"key release brakes immediately")
	await frames(14)
	check(Vector2(h.player.velocity.x,h.player.velocity.z).length() < 0.01 and h.player.position.distance_to(release) < 0.45,"release settles without skating or a stuck run")
	key(KEY_RIGHT,true)
	key(KEY_DOWN,true)
	await frames(20)
	check(Vector2(h.player.velocity.x,h.player.velocity.z).length() <= h.player.SPEED + 0.01 and h.player.velocity.x > 0 and h.player.velocity.z > 0,"arrow diagonals stay normalized and screen-aligned")
	key(KEY_RIGHT,false)
	key(KEY_DOWN,false)
	await frames(12)
	# Pointer ownership, clamping, release outside, dead zone and modal reset.
	var joy: Control = h.hud.joystick
	var center: Vector2 = joy.get_global_rect().get_center()
	touch(0,center,true)
	await frames()
	check(joy.finger == 0 and joy.direction.is_zero_approx(),"joystick center has a true dead zone")
	drag(0,center + Vector2(350,-90))
	await frames()
	check(joy.direction.x > 0.8 and joy.direction.length() <= 1.001,"touch drag beyond joystick bounds stays captured and clamped")
	touch(1,center + Vector2(-40,0),true)
	touch(1,center + Vector2(-40,0),false)
	await frames()
	check(joy.finger == 0 and joy.direction.x > 0.8,"second finger cannot steal or release movement")
	touch(0,center + Vector2(350,-90),false)
	await frames()
	check(joy.finger == -1 and joy.direction.is_zero_approx(),"touch release outside the pad clears movement")
	await tree.create_timer(0.25).timeout
	mouse(center + Vector2(40,0),true)
	await frames()
	motion(center + Vector2(-220,-80))
	await frames()
	check(joy.mouse_down and joy.direction.x < -0.8,"mouse joystick drag remains owned outside the pad")
	mouse(center + Vector2(-220,-80),false)
	await frames()
	check(not joy.mouse_down and joy.direction.is_zero_approx(),"mouse release outside clears the joystick")
	touch(0,center + Vector2(40,0),true)
	key(KEY_D,true)
	await frames()
	h._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await frames(2)
	check(joy.finger == -1 and joy.direction.is_zero_approx() and not h.hud.held and h.player.velocity.x == 0,"focus loss clears touch/action ownership and stops the player")
	h._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	release_all()
	key(KEY_D,false)
	h.hud.show_settings()
	start = h.player.position
	key(KEY_W,true)
	await frames(10)
	check(h.hud.modal_open and not joy.enabled and absf(h.player.position.z-start.z) < 0.01,"modal UI suspends walking and the joystick")
	key(KEY_W,false)
	h.hud.close_modal()
	check(joy.enabled and joy.direction.is_zero_approx(),"closing a modal re-enables neutral movement")
	# The real 3D workbench uses the same carried inventory, never sample cards.
	h.player.set_physics_process(false)
	h.player.position = h.world.pads.merge.node.global_position+Vector3(0,0.05,0)
	h.find_station()
	economy.data.bag = 3
	for species in [0,0,1,1,2,3]: economy.catch_fish(species,1)
	h.hud.show_collection()
	await h.camera_settled
	await frames(2)
	var b: Control = h.hud.board
	var base_merges: int = b.merge_count
	check(b.can_merge and b.actors.size() == 6 and b.fishes.get_child_count() == 6,"authored board displays every carried fish as a 3D actor")
	var picks = true
	for i in 16: picks = picks and b.slot_at(b.screen_for_slot(i)) == i
	check(picks,"camera-plane picking resolves all sixteen board slots")
	var edited_socket: Node3D = b.slots_root.get_node("Slot15")
	var original_socket: Vector3 = edited_socket.position
	edited_socket.position.x += 0.18
	check(is_equal_approx(b.slot_position(15).x,edited_socket.position.x) and b.slot_at(b.screen_for_slot(15)) == 15,"workbench picking and fish positions follow authored socket edits")
	edited_socket.position = original_socket
	unchanged = JSON.stringify(economy.data.raw)
	touch(4,b.screen_for_slot(0),true)
	drag(4,b.screen_for_slot(4))
	await frames()
	check(b.pointer == 4 and b.actors[0].scale.x < 1.2,"drag lift preserves normalized fish scale")
	touch(5,b.screen_for_slot(4),false)
	check(b.pointer == 4,"unrelated finger cannot release a fish drag")
	touch(4,b.screen_for_slot(4),false)
	await tree.create_timer(0.23).timeout
	await wait_for_home(b,0)
	check(b.preview.is_empty() and unchanged == JSON.stringify(economy.data.raw) and b.actors[0].position.distance_to(b.slot_position(0)) < 0.01,"nonmatching drop returns the actual fish without consuming inventory")
	await board_drop(b,0,1)
	check(economy.data.raw.size()==5 and b.merge_count==base_merges+1,"matching drop commits immediately without a confirmation")
	check(not b.has_node("Details/Confirm") and b.busy,"instant merge locks repeat input during its reveal")
	b.commit_preview()
	check(economy.data.raw.size()==5 and b.merge_count==base_merges+1,"repeated confirmation compatibility call cannot duplicate a drop")
	await tree.create_timer(0.55).timeout
	check(not b.busy and bool(economy.data.raw.back().reserved),"instant result settles and remains protected from cutting")
	var indices: Array = b.slots.values()
	indices.sort()
	check(indices == [0,1,2,3,4] and b.actors.size() == 5,"merge animation remaps all remaining inventory indices exactly once")
	unchanged = JSON.stringify(economy.data.raw)
	await board_drop(b,1,15)
	check(not b.slots.has(1) and b.slots.has(15) and unchanged == JSON.stringify(economy.data.raw),"empty-slot rearrangement changes layout, never ownership")
	await tree.create_timer(0.25).timeout
	mouse(b.screen_for_slot(3),true)
	await frames()
	check(b.pointer == -1 and b.dragging == 3,"physical mouse picks up the 3D fish, not a GUI card")
	motion(b.screen_for_slot(12))
	await frames()
	mouse(b.screen_for_slot(12),false)
	await tree.create_timer(0.23).timeout
	check(not b.slots.has(3) and b.slots.has(12) and unchanged == JSON.stringify(economy.data.raw),"mouse drag rearranges the same fish into an empty socket")
	mouse(b.screen_for_slot(15),true)
	await frames()
	motion(Vector2(-20,4))
	await frames()
	mouse(Vector2(-20,4),false)
	await frames(2)
	check(b.pointer == -2,"outside-window mouse release relinquishes ownership immediately")
	await tree.create_timer(0.35).timeout
	check(b.pointer == -2 and b.actors[15].position.distance_to(b.slot_position(15)) < 0.01 and unchanged == JSON.stringify(economy.data.raw),"mouse release outside the workbench returns the fish and clears ownership")
	touch(4,b.screen_for_slot(15),true)
	await frames()
	drag(4,b.screen_for_slot(8))
	await frames()
	b._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await tree.create_timer(0.23).timeout
	check(b.pointer == -2 and b.dragging == -1 and b.actors[15].scale.is_equal_approx(Vector3.ONE) and unchanged == JSON.stringify(economy.data.raw),"focus loss cancels a fish drag without consuming it")
	touch(4,b.screen_for_slot(8),false)
	b.selected = 15
	b.update_details()
	b.toggle_keep()
	check(not bool(economy.data.raw[int(b.slots[15])].reserved),"keep protection toggles on the selected result")
	b.toggle_keep()
	check(bool(economy.data.raw[int(b.slots[15])].reserved),"keep protection can be restored")
	b.display_selected()
	check(bool(economy.data.displayed[1]) and economy.data.raw.size() == 4 and b.actors.size() == 4,"selected display activates the bonus and removes only that actor")
	var after_display = JSON.stringify(economy.data.raw)
	b.display_selected()
	check(after_display == JSON.stringify(economy.data.raw),"double display cannot consume another fish")
	b.close()
	await h.camera_settled
	check(not h.hud.modal_open and not b.is_processing_input() and h.camera_mode=="follow","closed world board returns the camera and releases input")
	# Restore player state even though every test transaction had saving disabled.
	release_all()
	h.hud.joystick.reset()
	h.cancel_fishing()
	economy.data = saved_data
	economy.changed.emit()
	economy.save_path=protected_save_path
	economy.saving_enabled = saved_saving
	h.player.position = saved_position
	h.player.velocity = Vector3.ZERO
	h.player.set_physics_process(true)
	h.set_process(true)
	h.focus_paused = false
	print("RESULT %d V2 checks / %d failures" % [checks,failures.size()])
	return {"checks":checks,"failures":failures}
