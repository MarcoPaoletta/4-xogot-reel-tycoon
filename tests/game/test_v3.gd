extends RefCounted
## Regression for the actual moving Root bone, floating stick and authored V3 feedback.
var tree: SceneTree
var root: Window
var checks = 0
var failures: Array[String] = []
func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok: failures.append(caption)
	print(("PASS " if ok else "FAIL ") + caption)
func frames(count: int = 1) -> void:
	for i in count: await tree.physics_frame
	await tree.process_frame
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
func bounds(actor: Node3D) -> AABB:
	var result = AABB()
	var found = false
	for mesh in actor.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null: continue
		var relative: Transform3D = actor.global_transform.affine_inverse() * mesh.global_transform
		var box: AABB = relative * mesh.get_aabb()
		result = result.merge(box) if found else box
		found = true
	return result
func horizontal(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)
func _run() -> Dictionary:
	var h = tree.current_scene
	var e = root.get_node("Economy")
	var p = h.player
	var j = h.hud.joystick
	var saved = e.data.duplicate(true)
	var saving: bool = e.saving_enabled
	var saved_pos: Vector3 = p.position
	var saved_rotation: Vector3 = p.visual.rotation
	var camera_transform: Transform3D = h.camera.transform
	var original_speed: float = p.move_speed
	var protected_save_path:String=e.save_path
	e.save_path="user://reel_live_validation.json"
	e.saving_enabled = false
	h.hud.close_modal()
	h.cancel_fishing()
	h.set_process(false)
	h.focus_paused = false
	for action in ["move_left", "move_right", "move_up", "move_down", "interact", "menu"]: Input.action_release(action)
	e.data = e.fresh_data()
	e.data.bag = 3
	for species in [0,1,2,3]: e.catch_fish(species,1)
	p.position = Vector3(-5, 0.05, 7)
	p.velocity = Vector3.ZERO
	h.camera.position = p.position + Vector3(0,8.5,8.5)
	h.camera.look_at(h.camera.position - Vector3(0,8.5,10))
	await tree.create_timer(0.35).timeout
	p.set_physics_process(false)
	var sk = p.visual.find_child("Skeleton3D", true, false) as Skeleton3D
	var hips = sk.find_bone("Hips")
	var root_bone = sk.find_bone("Root")
	check(root_bone >= 0 and sk.get_bone_parent(root_bone) == -1, "fixture finds Root above Hips, not just a hip track")
	# Negative control: the original clip reproduces the reported character/basket separation.
	p.animation.play("Run_Forward", 0)
	p.animation.seek(0.01, true)
	sk.force_update_all_bone_transforms()
	var baseline: Vector3 = sk.to_global(sk.get_bone_global_pose(hips).origin)
	p.animation.seek(p.animation.current_animation_length * 0.999, true)
	sk.force_update_all_bone_transforms()
	check(horizontal(sk.to_global(sk.get_bone_global_pose(hips).origin) - baseline).length() > 1.7, "negative control reproduces original 1.9m run drift and snap-back")
	for clip in ["Idle_Breathing", "Walk_Forward", "Run_Forward"]:
		p.animation.play("locomotion/" + clip, 0)
		var max_error = 0.0
		for phase in [0.0,0.25,0.5,0.75,0.999,0.0]:
			p.animation.seek(p.animation.current_animation_length * phase, true)
			sk.force_update_all_bone_transforms()
			var point: Vector3 = sk.to_global(sk.get_bone_global_pose(hips).origin)
			max_error = maxf(max_error, horizontal(point - p.global_position).length())
		check(max_error < 0.005, clip + " stays on the capsule through the loop seam")
		var root_pose: Transform3D = sk.get_bone_pose(root_bone)
		check(root_pose.origin.distance_to(sk.get_bone_rest(root_bone).origin) < 0.001, clip + " locks top-level root to rest")
	p.current_clip = ""
	p.set_physics_process(true)
	check(is_equal_approx(p.move_speed, 3.1), "default movement is reduced to 3.1 m/s, independently of animation")
	# Geometry normalization and attachment are checked with every actual carried species.
	var carried = p.basket.get_node("Carried")
	var scales_ok = carried.visible_items==4
	for species in 4:
		var box=AABB()
		var found=false
		for part in carried.geometry["Raw:%d"%species]:
			var extent:AABB=part.transform*part.mesh.get_aabb()
			box=box.merge(extent) if found else extent
			found=true
		scales_ok=scales_ok and absf(maxf(box.size.x,maxf(box.size.y,box.size.z))-h.world.FISH_LENGTH)<0.002
	check(scales_ok,"all four batched fish retain full 0.50m geometry and original aspect ratio")
	check(p.basket.get_node("Count").text == "4 / 400","authored carry count reports real hundreds-capable inventory")
	# Screen direction, including diagonals, follows the thumb rather than world-axis foreshortening.
	var origin_screen: Vector2 = h.camera.unproject_position(p.global_position)
	var directions_ok = true
	var magnitudes_ok = true
	for input in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN,Vector2(1,1).normalized(),Vector2(-1,1).normalized(),Vector2(1,-1).normalized(),Vector2(-1,-1).normalized()]:
		var world_vector: Vector3 = p.screen_aligned_direction(input)
		var projected: Vector2 = h.camera.unproject_position(p.global_position + world_vector * 0.25) - origin_screen
		directions_ok = directions_ok and projected.normalized().dot(input) > 0.998
		magnitudes_ok = magnitudes_ok and absf(world_vector.length() - 1.0) < 0.001
	check(directions_ok, "all eight movement directions visually match the screen-space thumb direction")
	check(magnitudes_ok, "perspective correction does not boost diagonal movement speed")
	check(absf(p.screen_aligned_direction(Vector2(0.5,0)).length() - 0.5) < 0.001, "half-stick preserves analog walking speed")
	var pointer: Vector2 = j.get_global_rect().position + Vector2(280,155)
	touch(7,pointer,true)
	await frames(2)
	check(j.finger == 7 and j.direction.is_zero_approx() and p.velocity.is_zero_approx(), "off-center touch spawns a neutral floating stick with no position jump")
	drag(7,pointer + Vector2(3,0))
	await frames(2)
	check(j.direction.is_zero_approx(), "small thumb tremor remains inside the radial dead zone")
	drag(7,pointer + Vector2(29.7,0))
	await frames(10)
	check(absf(j.direction.length()-0.5) < 0.01 and absf(horizontal(p.velocity).length()-1.55) < 0.02, "mid-radius thumb movement produces half the default pace")
	touch(8,pointer,true)
	touch(8,pointer,false)
	check(j.finger == 7, "second finger cannot steal or release the floating thumbstick")
	drag(7,pointer + Vector2(350,0))
	await frames(10)
	check(j.direction.length() <= 1.001 and absf(horizontal(p.velocity).length()-3.1)<0.02, "overdrag is clamped to the lower full-speed cap")
	var start: Vector3 = p.position
	var last: Vector3 = p.position
	var root_error = 0.0
	var snap_back = false
	var actor = carried.batches["Raw:0:0"]
	var local_offset: Vector3 = actor.position
	var attached = true
	for i in 120:
		await tree.physics_frame
		sk.force_update_all_bone_transforms()
		root_error = maxf(root_error, horizontal(sk.to_global(sk.get_bone_global_pose(hips).origin) - p.global_position).length())
		if p.position.x < last.x - 0.002: snap_back = true
		last = p.position
		attached = attached and actor.position.is_equal_approx(local_offset) and horizontal(actor.global_position - p.global_position).length() < 0.85
	check(root_error < 0.01 and not snap_back, "visible character never runs ahead or snaps backwards across multiple live animation loops")
	check(attached and p.basket.get_parent() == p.visual, "fish and basket remain attached to the same moving visual rig")
	check(absf(horizontal(p.position-start).length()-6.2) < 0.16, "two seconds of actual movement covers approximately 6.2m, not capsule plus root speed")
	touch(7,pointer+Vector2(350,0),false)
	await frames(2)
	var stopped: Vector3 = p.position
	check(not j.active() and j.direction.is_zero_approx() and horizontal(p.velocity).is_zero_approx(), "release outside the input area stops immediately without skating")
	await frames(12)
	check(horizontal(p.position-stopped).length() < 0.005, "release cannot return the character to a previous root-animation position")
	# All station markers are authored rectangles whose visible size controls entry detection.
	var zones_ok = h.world.pads.size() == 45
	for pad in h.world.pads.values(): zones_ok = zones_ok and pad.circle.mesh is PlaneMesh and pad.material is ShaderMaterial
	check(zones_ok, "all forty-five saved interaction zones use outlined rounded rectangles")
	p.set_physics_process(false)
	var pad: Dictionary = h.world.pads.rod
	p.global_position = pad.node.to_global(Vector3(pad.size.x*0.49,0,pad.size.y*0.49))
	h.find_station()
	check(h.nearest_station == "rod", "visible purchase-zone corner is interactable, not an invisible circle")
	p.global_position = pad.node.to_global(Vector3(pad.size.x*0.52,0,0))
	h.find_station()
	check(h.nearest_station != "rod", "outside the outlined rectangle cannot begin a purchase")
	e.data.coins = 200
	e.changed.emit()
	p.global_position = pad.node.global_position
	h.find_station()
	h.dwell_time = 0
	h.update_stations(0.45)
	h.world.update_zone_feedback(h.nearest_station,h.dwell_time)
	check(int(e.data.coins)==200 and absf(float(pad.material.get_shader_parameter("progress"))-0.5)<0.001, "half dwell shows a half-filled ground bar without spending coins")
	p.position = Vector3(0,0,7)
	h.find_station()
	h.world.update_zone_feedback(h.nearest_station,h.dwell_time)
	check(int(e.data.coins)==200 and float(pad.material.get_shader_parameter("progress")) < 0, "leaving an upgrade zone clears progress and preserves currency")
	# Unchanged stacks are reused instead of respawning after every state notification.
	e.data.output = [{"species":0,"value":3},{"species":0,"value":3},{"species":0,"value":3}]
	e.changed.emit()
	var package_id: int = h.world.output_stack.get_child(0).get_instance_id()
	var fish_id: int = carried.batches["Raw:0:0"].get_instance_id()
	e.data.coins += 1
	e.changed.emit()
	check(package_id == h.world.output_stack.get_child(0).get_instance_id() and fish_id == carried.batches["Raw:0:0"].get_instance_id(), "wallet-only updates do not respawn carried or stationary stack actors")
	var customer = h.world.customers[0]
	var previous_state: String = customer.state
	var previous_slot: int = customer.slot
	customer.state = "waiting"
	customer.slot = 0
	h.world.update_requests()
	check(customer.person.get_node("OrderBubble").visible and customer.person.get_node("OrderBubble/Caption").text == e.SPECIES[int(customer.species)], "customer bubble always identifies its requested fish")
	e.data.stock = [{"species":int(customer.species),"value":3}]
	h.world.update_requests()
	check(customer.person.get_node("OrderBubble/Icon").modulate == Color("c5ffe1"), "customer bubble responds to matching species in real stock")
	customer.state = previous_state
	customer.slot = previous_slot
	var npc_animation = customer.person.find_child("AnimationPlayer",true,false) as AnimationPlayer
	check(npc_animation.has_animation("locomotion/Walk_Forward"), "customers also use safe in-place locomotion")
	e.data.settings.reduced_motion = true
	h.apply_settings()
	check(float(h.world.water_material.get_shader_parameter("motion_amount")) == 0, "reduced motion freezes shoreline and water animation")
	# Restore player save, controls and presentation after all fixture transactions.
	j.reset()
	for action in ["move_left","move_right","move_up","move_down","interact","menu"]: Input.action_release(action)
	e.data = saved
	e.changed.emit()
	e.save_path=protected_save_path
	e.saving_enabled = saving
	p.position = saved_pos
	p.visual.rotation = saved_rotation
	p.velocity = Vector3.ZERO
	p.move_speed = original_speed
	p.current_clip = ""
	p.set_physics_process(true)
	h.camera.transform = camera_transform
	h.set_process(true)
	h.apply_settings()
	print("RESULT %d V3 checks / %d failures" % [checks,failures.size()])
	return {"checks":checks,"failures":failures}
