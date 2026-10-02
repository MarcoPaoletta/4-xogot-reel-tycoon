extends Node3D
## Compact lakeside playable: authoritative state lives in Economy.
var world: Node3D
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var audio: Node
var nearest_station = ""
var station_time = 0.0
var machine_time = 0.0
var extra_machine_times = [0.0,0.0,0.0,0.0]
var extra_worker_times = [0.0,0.0,0.0,0.0,0.0,0.0]
var cutter_slot = 0
var worker_time = 0.0
var sale_time = 0.0
var dwell_time = 0.0
var last_station = ""
var fishing_state = "idle"
var fishing_species = 0
var landing = 0.0
var strain = 0.0
var fishing_time = 0.0
var break_time = 0.0
var ripple_time = 0.0
var danger_cue_time = 0.0
var reel_click_time = 0.0
var reel_toggled = false
var lunge_cycle = -1
var bobber: Node3D
var bobber_position = Vector3.ZERO
var hooked_fish: Node3D
var line: MeshInstance3D
var line_mesh: ImmediateMesh
var focus_paused = false
var initialized = false
var stack_signature = ""
var camera_mode: String = "follow"
var camera_transition: bool = false
var camera_tween: Tween
var debug_pause_business: bool = false
var impact_tween: Tween
var transfer_chain: int = 0
signal camera_settled

func _ready() -> void:
	world = $Lakeside
	audio = $Soundscape
	player = $Fisherman
	camera = $FollowCamera
	hud = $HUD
	player.hub = self
	player.visual = $Fisherman/Visual
	player.animation = player.visual.find_child("AnimationPlayer",true,false)
	player.basket = $Fisherman/Visual/Basket
	player.rod = $Fisherman/Visual/Rod
	player.play_animation("Idle_Breathing")
	create_rod()
	hud.action_pressed.connect(interact)
	line = $FishingLine
	line_mesh = line.mesh as ImmediateMesh
	Economy.changed.connect(on_state_changed)
	initialized = true
	on_state_changed()
	apply_settings()
	hud.toast(Economy.load_notice if not Economy.load_notice.is_empty() else "Welcome back to the lake")

func create_rod() -> void:
	if not is_instance_valid(player.rod): return
	for child in player.rod.get_children():
		player.rod.remove_child(child)
		child.queue_free()
	world.model(world.FISH + "FishingRod_Lvl%d.fbx" % (int(Economy.data.rod)+1), player.rod, Vector3.ZERO, 0.27)
	player.rod.visible = fishing_state != "idle"
	player.rod.set_meta("level",int(Economy.data.rod))

func on_state_changed() -> void:
	world.refresh()
	var signature = JSON.stringify([world.fish_signature(Economy.data.raw), world.package_signature(Economy.data.goods)])
	if signature != stack_signature:
		stack_signature = signature
		var carried = player.basket.get_node("Carried")
		world.sync_carried(carried,Economy.data.raw,Economy.data.goods)
	var count_label: Label3D = player.basket.get_node("Count")
	count_label.visible = not Economy.data.raw.is_empty() or not Economy.data.goods.is_empty()
	if not Economy.data.raw.is_empty() and not Economy.data.goods.is_empty(): count_label.text = "%d FISH · %d PKG" % [Economy.data.raw.size(), Economy.data.goods.size()]
	elif not Economy.data.raw.is_empty(): count_label.text = "%d / %d" % [Economy.data.raw.size(), Economy.capacity()]
	else: count_label.text = "%d %s" % [Economy.data.goods.size(),"PACKAGE" if Economy.data.goods.size()==1 else "PACKAGES"]
	count_label.position = Vector3(-0.23,1.03,0.42)
	count_label.no_depth_test = true
	hud.board.sync_inventory()
	if int(player.rod.get_meta("level", -1)) != int(Economy.data.rod): create_rod()

func walkable(pos: Vector3) -> bool:
	if pos.x < -11.9 or pos.x > 52.9 or pos.z > 43.9:return false
	if pos.z>=-1.75:return true
	for dock in 4:
		if Economy.dock_owned(dock) and absf(pos.x-[-5.0,5.0,15.5,26.0][dock])<=1.06 and pos.z>=-7.9:return true
	return false

func _process(delta: float) -> void:
	if not initialized: return
	if Input.is_action_just_pressed("debug_toggle") and OS.is_debug_build():
		if hud.modal_kind == "debug": hud.close_modal()
		else: hud.show_debug()
	if Input.is_action_just_pressed("menu"):
		if hud.modal_open: hud.close_modal()
		else: hud.show_settings()
	if focus_paused: return
	if Input.is_action_just_pressed("interact") and not hud.modal_open: interact()
	if camera_mode == "follow":
		var target = follow_pose()
		camera.position = camera.position.lerp(target.origin, 1.0 - exp(-delta * 5.5))
		camera.rotation = target.basis.get_euler()
	find_station()
	if not hud.modal_open:
		update_stations(delta)
		update_fishing(delta)
	if not debug_pause_business:
		update_business(delta)
	for i in world.displays.size():
		if world.displays[i].visible and not Economy.data.settings.reduced_motion:
			world.displays[i].rotation.y += delta * 0.4
	world.update_zone_feedback(nearest_station if not hud.modal_open else "", dwell_time)
	update_context()
	update_guidance()
	hud.update_station_badges()

func follow_pose() -> Transform3D:
	return Transform3D(Basis.from_euler(Vector3(-atan2(7.6, 8.5), 0, 0)), player.global_position + Vector3(0, 8.5, 8.5))

func focus_workbench() -> void:
	if camera_tween != null: camera_tween.kill()
	camera_mode = "board"
	camera_transition = true
	player.basket.hide()
	player.velocity = Vector3.ZERO
	var view: Camera3D = world.get_node("MergeGarden/Workbench/Camera")
	var duration = 0.12 if Economy.data.settings.reduced_motion else 0.75
	camera_tween = create_tween().set_parallel(true)
	camera_tween.tween_property(camera, "global_transform", view.global_transform.orthonormalized(), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(camera, "fov", view.fov, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.chain().tween_callback(func():
		camera_transition = false
		hud.board.set_transitioning(false)
		camera_settled.emit())

func focus_cutter() -> void:
	if camera_tween != null: camera_tween.kill()
	camera_mode = "cutter"
	camera_transition = true
	player.basket.hide()
	player.velocity = Vector3.ZERO
	cutter_slot = int(world.pads[nearest_station].machine_slot)
	world.machine_factory(cutter_slot).status.hide()
	var view: Camera3D = world.machine_factory(cutter_slot).get_node("Camera")
	var duration = 0.12 if Economy.data.settings.reduced_motion else 0.6
	camera_tween = create_tween().set_parallel(true)
	camera_tween.tween_property(camera,"global_transform",view.global_transform.orthonormalized(),duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(camera,"fov",view.fov,duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.chain().tween_callback(func(): camera_transition=false; camera_settled.emit())

func return_from_workbench() -> void:
	for slot in world.machines:world.machine_factory(slot).status.show()
	if camera_tween != null: camera_tween.kill()
	camera_mode = "returning"
	camera_transition = true
	var duration = 0.12 if Economy.data.settings.reduced_motion else 0.65
	camera_tween = create_tween().set_parallel(true)
	camera_tween.tween_property(camera, "global_transform", follow_pose(), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(camera, "fov", 50.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	camera_tween.chain().tween_callback(func():
		camera_mode = "follow"
		camera_transition = false
		player.basket.show()
		hud.finish_close_modal()
		camera_settled.emit())

func find_station() -> void:
	nearest_station = ""
	var closest = 100.0
	for id in world.pads:
		var p: Dictionary = world.pads[id]
		if not p.node.is_visible_in_tree(): continue
		var a = Vector2(player.position.x, player.position.z)
		var b = Vector2(p.position.x, p.position.z)
		var distance = a.distance_to(b)
		var local_point: Vector3 = p.node.to_local(player.global_position)
		var on_zone: bool = absf(local_point.x) <= p.size.x * 0.5 and absf(local_point.z) <= p.size.y * 0.5 if p.size != Vector2.ZERO else distance < float(p.radius) + 0.16
		if on_zone and distance < closest:
			nearest_station = id
			closest = distance
	if nearest_station != last_station:
		dwell_time = 0
		station_time = 0.08
		last_station = nearest_station

func update_stations(delta: float) -> void:
	station_time += delta
	hud.dwell.visible = false
	if world.is_purchase_pad(nearest_station):
		var cost = Economy.upgrade_cost(nearest_station)
		if cost >= 0 and int(Economy.data.coins) >= cost and dwell_time >= 0:
			dwell_time += delta
			hud.dwell.visible = true
			hud.dwell.value = dwell_time / 0.9
			if dwell_time >= 0.9:
				var purchase_id = nearest_station
				if Economy.purchase(purchase_id):
					audio.cue("upgrade")
					world.purchase_coins(purchase_id,cost)
					camera_impact(0.020)
					world.ripple(world.pads[purchase_id].position + Vector3(0, 0.1, 0), Color("ffe087"))
					world.burst(world.pads[purchase_id].position + Vector3.UP * 0.5, Color("ffe087"), 20)
					world.floating_text("UPGRADED!", world.pads[purchase_id].position + Vector3.UP, Color("ffe087"))
					hud.toast(upgrade_description(purchase_id))
				dwell_time = -1000 # Must step off before a second purchase.
		return
	if station_time < 0.08: return
	station_time -= 0.08
	var kind=world.pad_kind(nearest_station)
	var slot=int(world.pads[nearest_station].machine_slot) if world.pads.has(nearest_station) else 0
	var fisher=int(world.pads[nearest_station].fisher_slot) if world.pads.has(nearest_station) else 0
	match kind:
		"cut":
			var fishes=Economy.transfer_school("feed",slot)
			for fish in fishes:world.arc_asset(world.FISH+Economy.SPECIES[int(fish.species)]+".fbx",player.position+Vector3.UP*1.5,world.to_local(world.machine_input(slot).global_position)+Vector3.UP*0.2,1.0)
			if not fishes.is_empty():audio.cue("transfer")
		"out":
			var before=Economy.data.goods.size()
			var packages=Economy.transfer_school("output",slot)
			for i in packages.size():world.fly_to_back("Goods",world.machine_output(slot).global_position+Vector3.UP*0.22,Economy.package_species(packages[i]),before+i,i*0.03)
			if not packages.is_empty():audio.cue("transfer")
		"stock":
			var packages=Economy.transfer_school("stock")
			for package in packages:world.arc_asset(world.PROPS+"Package_1.fbx",player.position+Vector3.UP*1.3,world.to_local(world.market_stock(int(world.pads[nearest_station].market_slot)).global_position)+Vector3.UP*0.15,1.0,Economy.package_species(package))
			if not packages.is_empty():audio.cue("transfer")
		"cash":
			var value=Economy.collect()
			if value>0:
				hud.cash_sweep(camera.unproject_position(world.market_cash(int(world.pads[nearest_station].market_slot)).global_position+Vector3.UP*0.15))
				audio.cue("coin")
		"crate":
			var before=Economy.data.raw.size()
			var fishes=Economy.transfer_school("worker",fisher)
			for i in fishes.size():world.fly_to_back("Raw",world.fisher_crate(fisher).global_position+Vector3.UP*0.15,int(fishes[i].species),before+i,i*0.04)
			if not fishes.is_empty():audio.cue("transfer")

func update_business(delta: float) -> void:
	for slot in Economy.MACHINE_COUNT:
		if not Economy.machine_owned(slot):continue
		var queue=Economy.queue_for(slot)
		var timer=machine_time if slot==0 else float(extra_machine_times[slot-1])
		if queue.is_empty() or Economy.output_for(slot).size()>Economy.OUTPUT_CAP-Economy.PORTIONS:
			if world.machine_factory(slot).active:world.cancel_cut_visual(slot)
			timer=0
		else:
			var duration=0.95/(1.0+int(Economy.data.machine)*0.25+Economy.bonus("machine"))
			if not world.machine_factory(slot).active:
				world.begin_cut_visual(queue[0],duration,slot)
				audio.cue("spin")
			timer+=delta
			world.advance_cut_visual(timer/duration,slot)
			if timer>=duration:
				timer-=duration
				var fish=Economy.process_fish(slot)
				if not fish.is_empty():world.finish_cut_visual(fish,slot);audio.cue("batch")
		if slot==0:machine_time=timer
		else:extra_machine_times[slot-1]=timer
	sale_time+=delta
	if sale_time>=0.35:
		sale_time-=0.35
		# Nine matching customers can each buy one portion per sales beat.
		for customer in world.customers.duplicate():
			if customer.state!="waiting":continue
			var before=Economy.data.stock.size()
			var value=Economy.sell(int(customer.species))
			if Economy.data.stock.size()<before:
				world.arc_asset(world.PROPS+"Package_1.fbx",world.to_local(world.market_stock(floori(float(customer.slot)/3)).global_position)+Vector3.UP*0.15,world.to_local(customer.person.global_position)+Vector3.UP,1.0,int(customer.species))
				world.serve_customer(value,customer)
				audio.cue("sale")
	for fisher in Economy.FISHER_COUNT:
		if not Economy.fisher_hired(fisher) or not Economy.dock_owned(Economy.fisher_dock(fisher)):
			if fisher==0:worker_time=0
			else:extra_worker_times[fisher-1]=0.0
			continue
		var timer=worker_time if fisher==0 else float(extra_worker_times[fisher-1])
		timer+=delta
		if timer>=4:
			timer-=4
			var species=fisher%4 if fisher>0 else (1 if randf()<0.24 else 0)
			var before=Economy.crate_for(fisher).size()
			if Economy.worker_catch(species,Economy.CATCH_BATCH,fisher):
				var person:Node3D=world.worker if fisher==0 else world.fishers[fisher].get_node("Worker")
				var source=world.to_local(person.global_position)+Vector3(0,-0.15,-1.7)
				var destination=world.to_local(world.fisher_crate(fisher).global_position)+Vector3.UP*0.3
				for i in Economy.crate_for(fisher).size()-before:world.arc_asset(world.FISH+Economy.SPECIES[species]+".fbx",source+Vector3((i-2)*0.14,0,0),destination,1.0)
				world.ripple(destination,Color("7de4c5"))
		if fisher==0:worker_time=timer
		else:extra_worker_times[fisher-1]=timer

func camera_impact(strength: float) -> void:
	if Economy.data.settings.reduced_motion or camera_transition: return
	if impact_tween != null: impact_tween.kill()
	camera.h_offset = strength
	camera.v_offset = -strength*0.5
	impact_tween = create_tween().set_parallel(true)
	impact_tween.tween_property(camera,"h_offset",0.0,0.18).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	impact_tween.tween_property(camera,"v_offset",0.0,0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func interact() -> void:
	if hud.modal_open or focus_paused: return
	if fishing_state == "reeling":
		if Economy.data.settings.toggle_reel: reel_toggled = not reel_toggled
		return
	if fishing_state != "idle": return
	match nearest_station:
		"fish", "fish2", "fish3", "fish4": start_fishing()
		"merge": hud.show_collection()
		"cut", "cut2", "cut3": hud.show_cutter()
		"rod", "bag", "machine", "worker", "dock", "machine2", "machine3", "worker2", "worker3", "worker4", "dock2", "dock3":
			if int(Economy.data.coins) < Economy.upgrade_cost(nearest_station): hud.toast("Earn and collect more coins first")

func start_fishing() -> void:
	if Economy.data.raw.size() >= Economy.capacity():
		hud.toast("Basket full — deliver to CUT or MERGE")
		return
	var rare = nearest_station in ["fish2","fish3","fish4"]
	var roll = randf()
	fishing_species = 0
	if int(Economy.data.tutorial) > 0:
		if rare:
			fishing_species = 1 if roll < 0.55 else (2 if roll < 0.93 else 3)
		elif roll > 0.83:
			fishing_species = 1
	if nearest_station == "fish3": fishing_species = 2 if randf()<0.7 else 1
	if nearest_station == "fish4": fishing_species = 3 if randf()<0.7 else 2
	fishing_state = "casting"
	fishing_time = 0
	landing = 0
	strain = 0.12
	break_time = 0
	lunge_cycle = -1
	reel_toggled = false
	player.velocity = Vector3.ZERO
	player.visual.rotation.y = PI
	player.rod.visible = true
	bobber_position = Vector3(world.pads[nearest_station].position.x, -0.17, -10.15)
	bobber = world.model(world.FISH + "Lure_1.fbx", world, player.position + Vector3(0, 0.9, 0), 0.18)
	hooked_fish = world.normalized_model(world.FISH + Economy.SPECIES[fishing_species] + ".fbx", world, bobber_position + Vector3(0, -0.6, 0), world.FISH_LENGTH, PI)
	hooked_fish.visible = false
	audio.cue("cast")

func update_fishing(delta: float) -> void:
	if fishing_state == "idle": return
	fishing_time += delta
	var warning = false
	if fishing_state == "casting":
		var t = clampf(fishing_time / 0.40, 0, 1)
		bobber.position = (player.position + Vector3(0, 0.9, 0)).lerp(bobber_position, t) + Vector3.UP * sin(t * PI) * 2
		player.rod.rotation_degrees.x = -35 - sin(t * PI) * 20
		if t >= 1:
			fishing_state = "waiting"
			fishing_time = 0
			world.ripple(bobber_position)
	elif fishing_state == "waiting":
		bobber.position.y = bobber_position.y + sin(fishing_time * 4) * 0.055
		if fishing_time >= 0.70:
			fishing_state = "reeling"
			fishing_time = 0
			audio.cue("bite")
			hud.toast("Bite! Hold to reel. Release when tension rises.")
			world.ripple(bobber_position)
	elif fishing_state == "reeling":
		var reeling = reel_toggled if Economy.data.settings.toggle_reel else (Input.is_action_pressed("interact") or hud.held)
		var period = [3.4, 2.8, 2.1, 3.0][fishing_species]
		var cycle = int(fishing_time / period)
		var phase = fmod(fishing_time, period)
		warning = fishing_species > 0 and phase > period - 0.55
		if warning and phase < period - 0.55 + delta:
			audio.cue("bite")
			world.ripple(bobber_position)
		var pulse = 0.0
		var resistance = 1.0
		if fishing_species == 2: resistance += 0.22 * (0.5 + 0.5 * sin(fishing_time * 4.5))
		elif fishing_species == 3: resistance = 1.12
		if cycle > lunge_cycle:
			if lunge_cycle >= 0: pulse = [0.025, 0.14, 0.11, 0.25][fishing_species]
			lunge_cycle = cycle
		var control = 1.0 - int(Economy.data.rod) * 0.085 - Economy.bonus("control")
		var assisted = bool(Economy.data.settings.assist) or int(Economy.data.tutorial) == 0
		if reeling:
			landing += delta * (0.45 + int(Economy.data.rod) * 0.024)
			strain += delta * (0.135 if assisted else 0.255) * control * resistance
			reel_click_time += delta
			if reel_click_time > 0.22:
				reel_click_time = 0
				audio.cue("transfer")
		else:
			strain -= delta * 0.48
			landing -= delta * 0.028
		strain = clampf(strain + pulse * (0.5 if assisted else 1.0), 0, 1)
		landing = clampf(landing, 0, 1)
		danger_cue_time += delta
		if strain > 0.82 and danger_cue_time > 0.45:
			danger_cue_time = 0
			audio.tone(540 + strain * 400, 0.12, float(Economy.data.settings.sfx) * 0.13)
		break_time = break_time + delta if strain >= 0.995 else 0.0
		bobber.position = bobber_position + Vector3(sin(fishing_time * 8) * 0.1, -0.1, cos(fishing_time * 6) * 0.1)
		player.rod.rotation_degrees.x = -38 - strain * 17
		ripple_time += delta
		if ripple_time > 0.8:
			ripple_time = 0
			world.ripple(bobber_position)
		if landing > 0.7:
			hooked_fish.visible = true
			hooked_fish.position = bobber.position + Vector3(0, 0.12, 0)
		if break_time > (1.3 if assisted else 0.65):
			audio.cue("fail")
			world.ripple(bobber_position)
			cancel_fishing()
			hud.toast("Line snapped — just time lost. Try cooling sooner.")
			return
		if landing >= 1:
			land_fish()
			return
	line_mesh.clear_surfaces()
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var start = player.position + Vector3(0.15, 2.15, -0.35)
	for i in 12:
		var t = float(i) / 11.0
		line_mesh.surface_add_vertex(start.lerp(bobber.position, t) + Vector3.DOWN * sin(t * PI) * (0.18 if fishing_state == "reeling" else 0.5))
	line_mesh.surface_end()
	hud.fishing(fishing_species, fishing_state, landing, strain, warning)

func land_fish() -> void:
	var species = fishing_species
	var start = bobber_position
	var discovered = bool(Economy.data.discoveries[species])
	var before = Economy.data.raw.size()
	if Economy.catch_fish(species):
		var quantity = Economy.data.raw.size()-before
		for i in quantity:
			world.fly_to_back("Raw",world.to_global(start+Vector3((i-2)*0.16,0,i*0.08)),species,before+i,i*0.045)
		camera_impact(0.028)
		world.ripple(start)
		world.burst(start, Color("c2fff4"), 24 if species > 1 else 14)
		world.floating_text("+%d %s!" % [quantity,Economy.SPECIES[species]], player.position + Vector3(0, 2.3, 0), Color("ffe292"))
		audio.cue("catch")
		hud.toast(("NEW DISCOVERY! " if not discovered else "") + "+%d %s • %s • %d total value" % [quantity,Economy.SPECIES[species],Economy.RARITIES[species],Economy.VALUES[species]*quantity])
	cancel_fishing()

func cancel_fishing() -> void:
	fishing_state = "idle"
	reel_toggled = false
	if is_instance_valid(bobber): bobber.queue_free()
	if is_instance_valid(hooked_fish): hooked_fish.queue_free()
	if is_instance_valid(line_mesh): line_mesh.clear_surfaces()
	if is_instance_valid(player) and is_instance_valid(player.rod): player.rod.visible = false
	if is_instance_valid(hud): hud.fish_panel.visible = false

func upgrade_description(kind: String) -> String:
	match kind:
		"rod": return "Better rod! Calmer tension & faster landing."
		"bag": return "Bigger basket! Capacity is now %d fish." % Economy.capacity()
		"machine": return "Faster cutting! Watch packages pop out sooner."
		"worker": return "Fisher hired! Pick up catches from the shore crate."
		"dock": return "New dock open! Clownfish, Puffer & Swordfish await."
	if kind in ["machine2","machine3"]:return "New saw workshop! Feed fish here; collect its OUT pile."
	if kind in ["dock2","dock3"]:return "New fishing port open! Follow the shore east."
	if kind in ["worker2","worker3","worker4"]:return "Fisher hired! Five catches every four seconds."
	return "Upgraded!"

func merge_effect(species: int) -> void:
	audio.cue("merge")
	world.ripple(Vector3(-7.5, 0.1, 6), Color("cebaff"))
	world.merge_pop(species, Vector3(-7.5, 0, 6))
	world.floating_text(Economy.SPECIES[species] + " discovered", Vector3(-7.5, 2, 6), Color("cebaff"))

func update_context() -> void:
	if hud.modal_open: return
	if fishing_state == "reeling":
		hud.context("Release before the line breaks", "TAP TO TOGGLE" if Economy.data.settings.toggle_reel else "HOLD TO REEL  ·  SPACE")
		return
	if fishing_state != "idle":
		hud.context("Wait for the bite…", "CASTING…", false)
		return
	match world.pad_kind(nearest_station):
		"fish", "fish2": hud.context("Basket full — deliver or merge" if Economy.data.raw.size() >= Economy.capacity() else "Cast, then hold to reel", "CAST  ·  SPACE", Economy.data.raw.size() < Economy.capacity())
		"cut":
			if not Economy.queue_for(int(world.pads[nearest_station].machine_slot)).is_empty() or world.machine_factory(int(world.pads[nearest_station].machine_slot)).active:
				hud.context("10 slices · 5 colored packages. Tap to watch.","WATCH SAW",true)
			elif Economy.processable_count()==0 and not Economy.data.raw.is_empty():
				hud.context("Kept fish stay safe. Uncheck Keep to cut.","KEPT FISH",false)
			else: hud.context("Stand here to feed your fish automatically.","NEEDS FISH",false)
		"out": hud.context("Carry packages to STOCK", "PACKAGES FULL" if Economy.data.goods.size() >= Economy.goods_capacity() else ("PICKING UP…" if not Economy.output_for(int(world.pads[nearest_station].machine_slot)).is_empty() else "OUTPUT EMPTY"), false)
		"stock": hud.context("Customers buy from the queue", "STALL FULL" if Economy.data.stock.size() >= Economy.STOCK_CAP else ("STOCKING…" if not Economy.data.goods.is_empty() else "NEEDS PACKAGES"), false)
		"cash": hud.context("Sales leave cash here", "COLLECTING…" if int(Economy.data.cash) > 0 else "NO CASH YET", false)
		"merge": hud.context("Matching fish → rare discovery", "MERGE & DISPLAY")
		"crate": hud.context("Worker catches, not free cash", "PICKING UP…" if not Economy.crate_for(int(world.pads[nearest_station].fisher_slot)).is_empty() else "CRATE EMPTY", false)
		"purchase", "rod", "bag", "machine", "worker", "dock":
			var cost = Economy.upgrade_cost(nearest_station)
			hud.context(("Stand to buy · %d coins · leave to cancel" % cost if int(Economy.data.coins) >= cost else "Need %d more coins" % (cost - int(Economy.data.coins))) if cost >= 0 else "All done!", ("BUY  ·  %d COINS" % cost if int(Economy.data.coins) >= cost else "NEED %d COINS" % cost) if cost >= 0 else "COMPLETE", false)
		_: hud.context("Walk onto a labeled station pad", "FIND A STATION", false)

func apply_settings() -> void:
	Engine.max_fps = 30 if Economy.data.settings.low_quality else 60
	if is_instance_valid(world):
		world.water_material.set_shader_parameter("motion_amount", 0.0 if Economy.data.settings.reduced_motion else 1.0)
		for sun in world.find_children("*", "DirectionalLight3D", true, false): sun.shadow_enabled = not Economy.data.settings.low_quality
	if is_instance_valid(hud):
		hud.board.sparks.amount = 16 if Economy.data.settings.low_quality else 42
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED if Economy.data.settings.low_quality else Viewport.MSAA_2X

func _notification(what: int) -> void:
	if not initialized: return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		focus_paused = true
		hud.held = false
		reel_toggled = false
		hud.joystick.reset()
		hud.touch_action_id = -1
		for action in ["move_left", "move_right", "move_up", "move_down", "interact"]:
			Input.action_release(action)
		Economy.save_game()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
		focus_paused = false

func update_guidance() -> void:
	hud.guide.visible = not hud.modal_open and fishing_state == "idle"
	if not hud.guide.visible: return
	var targets = ["fish", "cut", "out", "stock", "cash", "rod", "merge"]
	var target: String = targets[mini(6, int(Economy.data.tutorial))]
	if int(Economy.data.tutorial) >= 5 and int(Economy.data.rod) == 0 and int(Economy.data.coins) < 30:
		target = next_delivery_target()
		hud.objective.text = "Earn %d more coins for your rod" % (30 - int(Economy.data.coins))
	elif target == "merge" and Economy.data.raw.is_empty():
		target = "crate" if Economy.data.worker and not Economy.data.worker_crate.is_empty() else "fish"
		hud.objective.text = "Catch a matching pair"
	elif target == "cut" and Economy.processable_count() == 0 and not Economy.data.raw.is_empty():
		target = "merge"
		hud.objective.text = "Try the merge workbench"
	if int(Economy.data.tutorial)>=6:target=next_delivery_target()
	elif target=="cut":target=nearest_pad("cut")
	elif target=="out":target=nearest_pad("out",true) if nearest_pad("out",true)!="" else "out"
	var location: Vector3 = world.pads[target].position
	var delta_pos = location - player.position
	var distance = Vector2(delta_pos.x, delta_pos.z).length()
	if distance < 1.3:
		hud.guide.visible = false
		return
	var arrow = "↑" if delta_pos.z < 0 else "↓"
	if absf(delta_pos.x) > absf(delta_pos.z): arrow = "→" if delta_pos.x > 0 else "←"
	var destination = "CAST" if target == "fish" else ("FISHER CRATE" if target == "crate" else target.to_upper())
	hud.guide.text = "%s %s · %d m" % [arrow, destination, int(ceil(distance))]
	var viewport_size = get_viewport().get_visible_rect().size
	hud.guide.position = Vector2((viewport_size.x-hud.guide.size.x)*0.5,viewport_size.y-211)

func nearest_pad(kind: String, available_only: bool = false) -> String:
	var chosen=""
	var distance=INF
	for id in world.pads:
		var pad:Dictionary=world.pads[id]
		if String(pad.kind)!=kind or not pad.node.is_visible_in_tree():continue
		if available_only and kind=="out" and Economy.output_for(int(pad.machine_slot)).is_empty():continue
		if available_only and kind=="crate" and Economy.crate_for(int(pad.fisher_slot)).is_empty():continue
		var d=player.position.distance_squared_to(pad.position)
		if d<distance:chosen=id;distance=d
	return chosen

func next_delivery_target() -> String:
	if int(Economy.data.cash)>0:return "cash"
	if not Economy.data.goods.is_empty():return "stock"
	var output=nearest_pad("out",true)
	if output!="":return output
	if Economy.processable_count()>0:return nearest_pad("cut")
	if not Economy.data.raw.is_empty():return "merge"
	var crate=nearest_pad("crate",true)
	return crate if crate!="" else "fish"

func display_effect(species: int) -> void:
	var position3d = Vector3(-9.7 + species * 0.9, 1.1, 3.8)
	audio.cue("upgrade")
	world.ripple(position3d, Color("bdfff0"))
	world.burst(position3d, Color("bdfff0"), 16)
	var text = ["+6% SALES", "+12% REEL CONTROL", "+15% CUTTING SPEED", "+12% SALES"][species]
	world.floating_text(text, position3d + Vector3.UP, Color("bdfff0"))
