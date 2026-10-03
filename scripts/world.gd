extends Node3D
const SLICER = preload("res://scripts/fish_slicer.gd")
const IN_PLACE = preload("res://scripts/in_place_animation.gd")
const PEOPLE_LIB = preload("res://scripts/people.gd")
const FISH_LENGTH = 0.50
const PACKAGE_LENGTH = 0.32
var factory: Node3D
var machines: Dictionary = {}
var markets: Dictionary = {}
var fishers: Dictionary = {}
var ports: Dictionary = {}
var station_refs: Dictionary = {}
const FISH = "res://assets/Cute Fish Pack - Feb 2020/FBX/"
const NATURE = "res://assets/Ultimate Nature Pack - Jun 2019/FBX/"
const PROPS = "res://assets/Medieval Village Pack - Dec 2020/Props/FBX/"
const PEOPLE = "res://assets/itHappy Characters GLB/"
var water_material: ShaderMaterial
var model_cache: Dictionary = {}
var fish_materials: Dictionary = {}
var pads: Dictionary = {}
var labels: Dictionary = {}
var second_dock: Node3D
var worker: Node3D
var saw: Node3D
var input_stack: Node3D
var saw_blade: MeshInstance3D
var output_stack: Node3D
var sale_stack: Node3D
var crate_stack: Node3D
var displays: Array[Node3D] = []
var customers: Array[Dictionary] = []
var customer_index = 0
var cash_pile: Node3D
var slice_cache: Dictionary = {}
var package_materials: Dictionary = {}
var shared_coin_mesh: CylinderMesh
var shared_coin_material: StandardMaterial3D
var cut_active: bool = false
var cut_generation: int = 0
var cut_stage: Node3D
var cut_tween: Tween
var bounds_cache: Dictionary = {}
var stack_signatures: Dictionary = {}
const REQUEST = preload("res://scenes/world/customer_request.tscn")

func material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	return mat

func box(parent: Node, pos: Vector3, size: Vector3, color: Color, collision: bool = false) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var shape = BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = pos
	if collision:
		var body = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var b = BoxShape3D.new()
		b.size = size
		col.shape = b
		body.add_child(col)
		mesh.add_child(body)
	return mesh

func model(path: String, parent: Node, pos: Vector3, uniform_scale: float, yaw: float = 0) -> Node3D:
	# Character paths name the itHappy set. People.resolve falls back to the CC0 characters when it is absent.
	if path.begins_with(PEOPLE): path = PEOPLE_LIB.resolve(path.get_file().get_basename())
	var holder = Node3D.new()
	parent.add_child(holder)
	holder.position = pos
	holder.rotation.y = yaw
	if not model_cache.has(path): model_cache[path] = load(path)
	if model_cache[path] == null:
		push_warning("Missing asset: " + path)
		return holder
	var instance = model_cache[path].instantiate()
	holder.add_child(instance)
	instance.scale = Vector3.ONE * uniform_scale * PEOPLE_LIB.scale_for(path)
	if PEOPLE_LIB.is_person(path): PEOPLE_LIB.prepare(instance, path)
	if path.begins_with(FISH) and path.get_file().get_basename() in Economy.SPECIES:
		color_fish(instance)
	return holder

func normalized_model(path: String, parent: Node3D, pos: Vector3, length: float, yaw: float = 0) -> Node3D:
	var holder = model(path, parent, pos, 1.0, yaw)
	if holder.get_child_count() == 0: return holder
	var instance = holder.get_child(0) as Node3D
	if not bounds_cache.has(path):
		var bounds = AABB()
		var found = false
		for mesh in instance.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh == null: continue
			var relative: Transform3D = holder.global_transform.affine_inverse() * mesh.global_transform
			var box_bounds: AABB = relative * mesh.get_aabb()
			bounds = bounds.merge(box_bounds) if found else box_bounds
			found = true
		bounds_cache[path] = bounds
	var cached_bounds: AABB = bounds_cache[path]
	var extent = maxf(cached_bounds.size.x, maxf(cached_bounds.size.y, cached_bounds.size.z))
	var factor = length / maxf(extent, 0.001)
	instance.scale = Vector3.ONE * factor
	instance.position = Vector3(-cached_bounds.get_center().x, -cached_bounds.position.y, -cached_bounds.get_center().z) * factor
	return holder

func stack_changed(parent: Node3D, signature: String) -> bool:
	var id = parent.get_instance_id()
	if stack_signatures.get(id, "") == signature: return false
	stack_signatures[id] = signature
	return true

func fish_signature(fishes: Array) -> String:
	var species: Array[int] = []
	for fish in fishes: species.append(int(fish.species))
	return JSON.stringify(species)

func text3d(text: String, parent: Node, pos: Vector3, color: Color = Color.WHITE, font_size: int = 40) -> Label3D:
	var l = Label3D.new()
	l.text = text
	l.font_size = font_size
	l.pixel_size = 0.0045
	l.outline_size = 3
	l.outline_modulate = Color("163b47")
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = false
	parent.add_child(l)
	l.position = pos
	return l

func _ready() -> void:
	# Bind the authored hub. No environment, stations or scenery are spawned here.
	water_material = $Terrain/LakeWater.material_override as ShaderMaterial
	for node in find_children("*", "Node", true, false):
		if node.has_meta("pad_id"):
			var id: String = node.get_meta("pad_id")
			var main_parent = get_parent() as Node3D
			var pad_position = main_parent.to_local(node.global_position) if main_parent != null else to_local(node.global_position)
			var surface: MeshInstance3D = node.get_node("Surface")
			var size2d: Vector2 = surface.mesh.size if surface.mesh is PlaneMesh else Vector2.ZERO
			var zone_material = surface.material_override as ShaderMaterial
			if zone_material != null: zone_material.set_shader_parameter("zone_size", size2d)
			pads[id] = {"position": pad_position, "node": node, "circle": surface, "radius": node.get_meta("radius",1.0), "kind":node.get_meta("pad_kind",id), "machine_slot":int(node.get_meta("machine_slot",0)), "market_slot":int(node.get_meta("market_slot",0)), "fisher_slot":int(node.get_meta("fisher_slot",0)), "title":node.get_meta("pad_title",""), "size": size2d, "material": zone_material, "label": node.get_node("Caption") }
		if node.has_meta("world_ref"):
			var ref=String(node.get_meta("world_ref"))
			station_refs[ref]=node
			if not ref.begins_with("mill") and not ref.begins_with("fisher") and not ref.begins_with("market"):set(ref,node)
		if node.has_meta("station_label"):
			node.hide()
			if node.get_meta("station_label") in ["cut","stall","worker"]:labels[node.get_meta("station_label")]=node
		if node.has_meta("customer_slot"):
			var slot = int(node.get_meta("customer_slot"))
			customers.append({"person":node,"slot":slot,"state":"waiting","species":0 if slot%3 < 2 else 1,"remaining":Economy.PORTIONS})
			animate_person(node,"Idle_Breathing")
	for i in 4:
		for node in find_children("*","Node3D",true,false):
			if node.get_meta("display_species",-1) == i:
				displays.append(node)
				color_fish(node)
	for id in pads:
		pads[id].label.visible = is_purchase_pad(id)
	for label_node in labels.values(): label_node.hide()
	cut_stage = $Workshop/CutStage
	factory = $Workshop/Conveyor
	factory.bind(cut_stage,self)
	slice_cache = factory.slice_cache
	saw_blade.hide()
	markets[0]=$Market
	machines[0]=$Workshop
	for node in find_children("*","Node3D",true,false):
		if node.has_meta("machine_slot") and node.has_node("Conveyor"):
			var slot=int(node.get_meta("machine_slot"))
			machines[slot]=node
			var cutter=node.get_node("Conveyor")
			cutter.bind(node.get_node("CutStage"),self)
			cutter.slice_cache=slice_cache
			station_refs["mill%d_saw_blade"%slot].hide()
		if node.has_meta("fisher_slot") and node.has_node("Worker"):fishers[int(node.get_meta("fisher_slot"))]=node
		if node.has_meta("dock_slot") and node.has_node("Floor"):ports[int(node.get_meta("dock_slot"))]=node
	for node in find_children("*","Node3D",true,false):
		if node.has_meta("market_slot") and node.has_node("SaleStock"):markets[int(node.get_meta("market_slot"))]=node
	customer_index = 3
	animate_person(worker, "Idle_Breathing")
	refresh()
	update_requests()

func align_person_origin(person: Node3D) -> void:
	# The supplied character exports retain their spaced-out source-scene origins
	# (-1.666m, -3.332m, ...). A locked root bone cannot correct this node offset.
	if person.get_meta("body_origin_aligned",false): return
	var skeleton = person.find_child("Skeleton3D",true,false) as Skeleton3D
	if skeleton != null:
		var offset = person.to_local(skeleton.global_position)
		offset.y = 0
		for child in person.get_children():
			if child is Node3D and child.name != "OrderBubble": child.position -= offset
	person.set_meta("body_origin_aligned",true)

func animate_person(person: Node3D, clip: String, speed: float = 1.0) -> void:
	align_person_origin(person)
	var animation = person.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation == null: return
	if not animation.has_animation_library("locomotion"):
		var skeleton = person.find_child("Skeleton3D", true, false) as Skeleton3D
		animation.stop()
		if skeleton != null: skeleton.reset_bone_poses()
		var library = AnimationLibrary.new()
		for clip_name in ["Idle_Breathing", "Walk_Forward", "Run_Forward"]:
			if animation.has_animation(clip_name): library.add_animation(clip_name, IN_PLACE.clip(animation.get_animation(clip_name), skeleton))
		animation.add_animation_library("locomotion", library)
	var key = "locomotion/" + clip
	if not animation.has_animation(key): return
	if animation.current_animation != key: animation.play(key,0.14)
	animation.speed_scale = speed

func customer_target(slot: int) -> Vector3:
	var local_slot=slot%3
	return to_global(market_offset(floori(float(slot)/3))+Vector3(9.1+local_slot*0.75,0,2.6+local_slot*1.9))

func market_offset(slot: int) -> Vector3:
	return [Vector3.ZERO,Vector3(22,0,0),Vector3(22,0,12)][slot]
func market_stock(slot: int = 0) -> Node3D:
	return sale_stack if slot==0 else station_refs["market%d_sale_stack"%slot]
func market_cash(slot: int = 0) -> Node3D:
	return cash_pile if slot==0 else station_refs["market%d_cash_pile"%slot]

func request_species() -> int:
	# A reachable common order always remains available; no unavailable-tier gate.
	var has_common = false
	for c in customers:
		if c.state != "leaving" and int(c.species) == 0: has_common = true
	if not has_common: return 0
	for package in Economy.data.stock:
		var stocked_species = Economy.package_species(package)
		if stocked_species < 0: continue
		var requested = false
		for customer in customers:
			if customer.state != "leaving" and int(customer.species)==stocked_species: requested = true
		if not requested: return stocked_species
	var choices: Array[int] = [0,0,1]
	for species in [2,3]:
		if Economy.data.discoveries[species] or Economy.data.dock: choices.append(species)
	return choices.pick_random()

func spawn_customer(slot: int) -> void:
	customer_index = customer_index % 10 + 1
	var person = model(PEOPLE + "Cliente %d.glb" % customer_index, self, market_offset(floori(float(slot)/3))+Vector3(11.3,0,11.0 + (slot%3)*0.5),0.98,PI)
	person.add_child(REQUEST.instantiate())
	var species = request_species()
	customers.append({"person":person,"slot":slot,"state":"arriving","species":species,"remaining":Economy.PORTIONS})
	animate_person(person,"Walk_Forward",1.45)

func _physics_process(delta: float) -> void:
	var hub = get_parent()
	if hub.initialized and not hub.focus_paused and not hub.debug_pause_business: update_customers(delta)

func update_customers(delta: float) -> void:
	var expired: Array[Dictionary] = []
	for customer in customers:
		var person: Node3D = customer.person
		var target = customer_target(int(customer.slot))
		if customer.state == "leaving": target = to_global(market_offset(floori(float(customer.slot)/3))+Vector3(11.8,0,13.0))
		var offset = target - person.global_position
		var moving = offset.length() > 0.035
		if moving:
			var direction = offset.normalized()
			person.rotation.y = lerp_angle(person.rotation.y,atan2(direction.x,direction.z),1.0-exp(-delta*12))
			person.global_position = person.global_position.move_toward(target,delta*2.7)
			animate_person(person,"Walk_Forward",1.45)
		else:
			if customer.state == "leaving": expired.append(customer); continue
			customer.state = "waiting"
			person.rotation.y = lerp_angle(person.rotation.y,-PI*0.5,1.0-exp(-delta*8))
			animate_person(person,"Idle_Breathing")
	for customer in expired:
		customers.erase(customer)
		customer.person.queue_free()
	update_requests()

func update_requests() -> void:
	for customer in customers:
		var bubble = customer.person.get_node_or_null("OrderBubble")
		if bubble == null: continue
		bubble.visible = customer.state != "leaving"
		var view=get_viewport().get_camera_3d()
		if is_instance_valid(view):bubble.global_basis=view.global_basis.orthonormalized()
		if not bubble.visible:continue
		var species=int(customer.get("species",0))
		bubble.get_node("Caption").text=Economy.SPECIES[species]
		bubble.get_node("Progress").text="%d / %d packages"%[Economy.PORTIONS-int(customer.get("remaining",Economy.PORTIONS)),Economy.PORTIONS]
		bubble.get_node("Icon").modulate=Color("c5ffe1") if Economy.stock_count(species)>0 else Color.WHITE
		bubble.get_node("Fish/Glyph").modulate=Economy.COLORS[species]

func next_customer() -> Dictionary:
	for customer in customers:
		if customer.state == "waiting" and Economy.stock_index(int(customer.get("species",0))) >= 0: return customer
	return {}

func ready_customer() -> bool:
	return not next_customer().is_empty()

func serve_customer(value: int, customer: Dictionary = {}) -> void:
	if customer.is_empty(): customer = next_customer()
	if customer.is_empty() or customer.state != "waiting": return
	customer.remaining = maxi(0,int(customer.remaining)-1)
	customer["earned"] = int(customer.get("earned",0))+value
	if value > 0: sale_coin(customer.person.global_position+Vector3.UP,floori(float(customer.slot)/3))
	if int(customer.remaining) > 0: update_requests(); return
	customer.state = "leaving"
	floating_text("SOLD!",to_local(customer.person.global_position)+Vector3.UP*1.9,Color("bdffe3"))
	floating_text("+%d"%int(customer.earned),to_local(market_cash(floori(float(customer.slot)/3)).global_position)+Vector3.UP,Color("ffe083"))
	customer.person.get_node("OrderBubble").hide()
	animate_person(customer.person,"Walk_Forward",1.45)
	# Spawn the next request NOW rather than waiting for the old customer to exit.
	spawn_customer(int(customer.slot))
	if not Economy.data.settings.reduced_motion:
		burst(to_local(customer.person.global_position)+Vector3(0,1.3,0),Color("a9f7cf"),8)
		var visual: Node3D = customer.person.get_child(0)
		var home = visual.position.y
		var reaction = create_tween()
		reaction.tween_property(visual,"position:y",home+0.12,0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		reaction.tween_property(visual,"position:y",home,0.12)
	update_requests()

func zone_feedback(id: String, active_zone: String, dwell: float) -> void:
	var pad: Dictionary = pads[id]
	var mat: ShaderMaterial = pad.material
	if mat == null: return
	var active_now = id == active_zone
	mat.set_shader_parameter("active", 1.0 if active_now else 0.0)
	var progress = -1.0
	if active_now and is_purchase_pad(id) and Economy.upgrade_cost(id) >= 0 and int(Economy.data.coins) >= Economy.upgrade_cost(id) and dwell >= 0:
		progress = clampf(dwell / 0.9, 0, 1)
	mat.set_shader_parameter("progress", progress)

func update_zone_feedback(active_zone: String, dwell: float) -> void:
	for id in pads: zone_feedback(id, active_zone, dwell)

func clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func package_signature(items: Array) -> String:
	var species: Array[int] = []
	for item in items: species.append(Economy.package_species(item))
	return JSON.stringify(species)

func tint_package(actor: Node3D, species: int) -> void:
	if int(actor.get_meta("package_species",-2)) == species: return
	actor.set_meta("package_species",species)
	var color: Color = Economy.COLORS[species] if species >= 0 else Color("d7b78f")
	for mesh in actor.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh == null: continue
		for surface in mesh.mesh.get_surface_count():
			var original = mesh.mesh.surface_get_material(surface)
			if not original is StandardMaterial3D: continue
			var key = str(original.get_instance_id())+"_"+str(species)
			if not package_materials.has(key):
				var mat = original.duplicate() as StandardMaterial3D
				mat.albedo_color = color.lerp(Color("fff0cb"),0.25) if "Light" in mat.resource_name else color
				mat.vertex_color_use_as_albedo = false
				mat.emission_enabled = false
				mat.roughness = 0.72
				package_materials[key] = mat
			mesh.set_surface_override_material(surface,package_materials[key])

func packages(parent: Node3D, items: Array) -> void:
	var visible_count = mini(items.size(),60 if not Economy.data.settings.low_quality else 36)
	while parent.get_child_count() > visible_count:
		var child = parent.get_child(parent.get_child_count()-1)
		parent.remove_child(child)
		child.queue_free()
	for i in visible_count:
		if i >= parent.get_child_count():
			var pos = Vector3((i%3-1)*0.30,floori(float(i)/9)*0.19,(floori(float(i)/3)%3-1)*0.29)
			var package = normalized_model(PROPS+"Package_1.fbx",parent,pos,PACKAGE_LENGTH)
			package.name = "Package%02d"%i
			# Arrival juice is position-only: the item never changes size.
			if not Economy.data.settings.reduced_motion:
				package.position.y += 0.06
				package.create_tween().tween_property(package,"position:y",pos.y,0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tint_package(parent.get_child(i),Economy.package_species(items[i]))

func refresh() -> void:
	if pads.is_empty(): return
	second_dock.visible = Economy.data.dock
	pads.fish2.node.visible = Economy.data.dock
	worker.visible = Economy.data.worker
	pads.crate.node.visible = Economy.data.worker
	labels.worker.visible = false
	labels.worker.text = "CRATE FULL • PICK UP" if Economy.data.worker_crate.size() >= Economy.WORKER_CAP else "FISHER CRATE  %d / %d" % [Economy.data.worker_crate.size(),Economy.WORKER_CAP]
	labels.cut.text = "OUTPUT FULL • PICK UP" if Economy.data.output.size() >= Economy.OUTPUT_CAP else "CUT  %d / %d   ·   OUT  %d / %d" % [Economy.data.queue.size(),Economy.QUEUE_CAP,Economy.data.output.size(),Economy.OUTPUT_CAP]
	labels.stall.text = "MARKET  %d / %d" % [Economy.data.stock.size(),Economy.STOCK_CAP]
	pads.cash.label.text = "CASH\n%d COINS" % int(Economy.data.cash)
	for kind in pads:
		if not is_purchase_pad(kind):continue
		var cost = Economy.upgrade_cost(kind)
		pads[kind].label.text = "%d" % cost if cost >= 0 else "✓"
		pads[kind].material.set_shader_parameter("ready", 1.0 if cost >= 0 and int(Economy.data.coins) >= cost else 0.0)
		pads[kind].material.set_shader_parameter("complete", 1.0 if cost < 0 else 0.0)
	if stack_changed(input_stack, fish_signature(Economy.data.queue)):
		clear_children(input_stack)
		for i in mini(20, Economy.data.queue.size()):
			var fish: Dictionary = Economy.data.queue[i]
			normalized_model(FISH + Economy.SPECIES[int(fish.species)] + ".fbx", input_stack, Vector3((i%3-1)*0.30,floori(float(i)/9)*0.15,(floori(float(i)/3)%3-1)*0.26), FISH_LENGTH, PI * 0.5)
	packages(output_stack, Economy.data.output)
	var portions=[[],[],[]]
	for i in Economy.data.stock.size():portions[i%3].append(Economy.data.stock[i])
	for stall in Economy.MARKET_COUNT:packages(market_stock(stall),portions[stall])
	if stack_changed(crate_stack, fish_signature(Economy.data.worker_crate)):
		clear_children(crate_stack)
		for i in mini(25, Economy.data.worker_crate.size()):
			var fish: Dictionary = Economy.data.worker_crate[i]
			normalized_model(FISH + Economy.SPECIES[int(fish.species)] + ".fbx", crate_stack, Vector3((i%3-1)*0.30,floori(float(i)/9)*0.15,(floori(float(i)/3)%3-1)*0.26), FISH_LENGTH, PI * 0.5)
	for i in 4: displays[i].visible = Economy.data.displayed[i]
	var total_coins=mini(180,ceili(float(Economy.data.cash)/2))
	for stall in Economy.MARKET_COUNT:coin_pile(market_cash(stall),floori(float(total_coins)/3)+(1 if stall<total_coins%3 else 0))
	update_requests()
	refresh_expansion()

func coin_pile(parent: Node3D, amount: int) -> void:
	var coins_visible=mini(180,amount)
	if stack_changed(parent,str(coins_visible)):
		clear_children(parent)
		if shared_coin_mesh == null:
			shared_coin_mesh = CylinderMesh.new()
			shared_coin_mesh.top_radius = 0.12
			shared_coin_mesh.bottom_radius = 0.12
			shared_coin_mesh.height = 0.045
			shared_coin_mesh.radial_segments = 12
			shared_coin_material = material(Color("ffd268"))
			shared_coin_material.metallic = 0.32
		var pile = MultiMeshInstance3D.new()
		pile.name = "CoinPile3x3"
		pile.material_override = shared_coin_material
		var instances = MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = shared_coin_mesh
		instances.instance_count = coins_visible
		for i in coins_visible:
			instances.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3((i%3-1)*0.26,floori(float(i)/9)*0.064,(floori(float(i)/3)%3-1)*0.26)))
		pile.multimesh = instances
		parent.add_child(pile)

func coin_mesh(parent: Node, pos: Vector3) -> MeshInstance3D:
	var coin = MeshInstance3D.new()
	var shape = CylinderMesh.new()
	shape.top_radius = 0.12
	shape.bottom_radius = 0.12
	shape.height = 0.045
	coin.mesh = shape
	var mat = material(Color("ffd268"))
	mat.metallic = 0.4
	coin.material_override = mat
	parent.add_child(coin)
	coin.position = pos
	return coin

func floating_text(text: String, pos: Vector3, color: Color) -> void:
	var l = text3d(text, self, pos, color, 42)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(l, "position:y", pos.y + (0.3 if Economy.data.settings.reduced_motion else 1.3), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(l, "modulate:a", 0.0, 1.1)
	tween.chain().tween_callback(l.queue_free)

func ripple(pos: Vector3, color: Color = Color("d4fff6")) -> void:
	var ring = MeshInstance3D.new()
	var mesh = TorusMesh.new()
	mesh.inner_radius = 0.22
	mesh.outer_radius = 0.25
	ring.mesh = mesh
	var mat = material(color)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat
	add_child(ring)
	ring.position = pos
	var tween = create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(1.5, 0.3, 1.5) if Economy.data.settings.reduced_motion else Vector3(4, 0.3, 4), 0.7)
	tween.tween_property(mat, "albedo_color:a", 0, 0.7)
	tween.chain().tween_callback(ring.queue_free)

func arc_asset(path: String, start: Vector3, end: Vector3, _model_scale: float, species: int = -1) -> void:
	var item = normalized_model(path,self,start,FISH_LENGTH if path.begins_with(FISH) else PACKAGE_LENGTH,PI*0.5)
	if path.begins_with(PROPS): tint_package(item,species)
	var tween = create_tween()
	var hop_height = 0.3 if Economy.data.settings.reduced_motion else 1.8
	var duration = 0.25 if Economy.data.settings.reduced_motion else 0.28
	tween.tween_method(func(t: float): item.position = start.lerp(end, t) + Vector3.UP * sin(t * PI) * hop_height, 0.0, 1.0, duration)
	tween.tween_callback(item.queue_free)

func coin_cascade(start: Vector3, end: Vector3) -> void:
	for i in (4 if Economy.data.settings.reduced_motion else 24):
		var coin = coin_mesh(self, start + Vector3(randf_range(-0.3, 0.3), 0.3, randf_range(-0.3, 0.3)))
		var tween = create_tween()
		tween.tween_interval(i * 0.04)
		tween.tween_property(coin, "position", end + Vector3(0, 1.6, 0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(coin.queue_free)

func separate_saw_blade() -> void:
	# Reuse the imported Metal surface verbatim; no new modeled geometry.
	var source = saw.find_child("Sawmill_saw", true, false) as MeshInstance3D
	if source == null: return
	var frame_mesh = ArrayMesh.new()
	var blade_mesh = ArrayMesh.new()
	for surface in source.mesh.get_surface_count():
		var mat = source.mesh.surface_get_material(surface)
		var target: ArrayMesh = blade_mesh if mat != null and mat.resource_name == "Metal" else frame_mesh
		target.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, source.mesh.surface_get_arrays(surface))
		target.surface_set_material(target.get_surface_count() - 1, mat)
	source.mesh = frame_mesh
	saw_blade = MeshInstance3D.new()
	saw_blade.name = "MovingSawBlade"
	saw_blade.mesh = blade_mesh
	saw_blade.transform = source.transform
	source.get_parent().add_child(saw_blade)

func color_fish(instance: Node3D) -> void:
	# Shared surface overrides brighten the supplied FBX palette, without editing assets.
	var colors = {
		"Goldfish_Main": Color("ff963f"), "Goldfish_Light": Color("ffe1a0"), "Goldfish_Fins": Color("ffba60"), "Material.016": Color("ffe1a0"),
		"Clownfish_Main": Color("ff8443"), "Clownfish_Light": Color("fff9e8"), "Clownfish_Dark": Color("263947"),
		"Pufferfish_Main": Color("d7e684"), "Pufferfish_Light": Color("fff0c4"), "Puffefish_Black": Color("426455"),
		"Swordfish_Main": Color("74bcdf"), "Swordfish_Light": Color("dff4f3"), "Swordfish_Dark": Color("32637b")}
	for mesh in instance.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null: continue # Documented empty mesh in Goldfish/Puffer.
		for surface in mesh.mesh.get_surface_count():
			var original = mesh.mesh.surface_get_material(surface)
			if original == null or not colors.has(original.resource_name): continue
			var key: String = original.resource_name
			if not fish_materials.has(key):
				var mat = original.duplicate() as StandardMaterial3D
				mat.albedo_color = colors[key]
				mat.roughness = 0.68
				mat.emission_enabled = false
				fish_materials[key] = mat
			mesh.set_surface_override_material(surface, fish_materials[key])

func burst(pos: Vector3, color: Color, amount: int = 14) -> void:
	var particles = CPUParticles3D.new()
	particles.amount = 3 if Economy.data.settings.reduced_motion else mini(amount,12) if Economy.data.settings.low_quality else amount
	particles.lifetime = 0.65
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.direction = Vector3.UP
	particles.spread = 65
	particles.gravity = Vector3(0, -5, 0)
	particles.initial_velocity_min = 1.2
	particles.initial_velocity_max = 2.8
	particles.scale_amount_min = 0.4
	particles.scale_amount_max = 1
	var mesh = SphereMesh.new()
	mesh.radius = 0.055
	mesh.height = 0.11
	mesh.radial_segments = 8
	mesh.rings = 4
	mesh.material = material(color)
	particles.mesh = mesh
	particles.local_coords = false
	add_child(particles)
	particles.position = pos
	particles.emitting = true
	get_tree().create_timer(0.9).timeout.connect(particles.queue_free)

func merge_pop(species: int, pos: Vector3) -> void:
	var left = model(FISH + Economy.SPECIES[maxi(0, species - 1)] + ".fbx", self, pos + Vector3(-0.65, 1.0, 0), 0.13, PI * 0.5)
	var right = model(FISH + Economy.SPECIES[maxi(0, species - 1)] + ".fbx", self, pos + Vector3(0.65, 1.0, 0), 0.13, -PI * 0.5)
	var anticipation = create_tween().set_parallel(true)
	anticipation.tween_property(left, "position", pos + Vector3(-0.05, 1.0, 0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	anticipation.tween_property(right, "position", pos + Vector3(0.05, 1.0, 0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	anticipation.chain().tween_callback(func():
		left.queue_free()
		right.queue_free()
		var result = model(FISH + Economy.SPECIES[species] + ".fbx", self, pos + Vector3(0, 1.2, 0), 0.18, PI * 0.5)
		burst(pos + Vector3(0, 1.2, 0), Color("d7bbff"), 22)
		var reward = create_tween()
		reward.tween_property(result, "position:y", pos.y + 2.1, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		reward.tween_interval(0.3)
		reward.tween_property(result, "scale", Vector3.ONE * 0.05, 0.2)
		reward.tween_callback(result.queue_free))

func machine_factory(slot: int = 0) -> Node3D:
	return machines[slot].get_node("Conveyor")
func machine_input(slot: int = 0) -> Node3D:
	return input_stack if slot==0 else station_refs["mill%d_input_stack"%slot]
func machine_output(slot: int = 0) -> Node3D:
	return output_stack if slot==0 else station_refs["mill%d_output_stack"%slot]
func fisher_crate(slot: int = 0) -> Node3D:
	return crate_stack if slot==0 else station_refs["fisher%d_crate_stack"%slot]

func begin_cut_visual(fish: Dictionary, _duration: float, slot: int = 0) -> void:
	var cutter=machine_factory(slot)
	if cutter.active:return
	if slot==0:cut_active=true
	cut_generation+=1
	cutter.begin(fish)
func advance_cut_visual(progress: float, slot: int = 0) -> void:
	machine_factory(slot).advance(progress)
func finish_cut_visual(fish: Dictionary, slot: int = 0) -> void:
	var cutter=machine_factory(slot)
	cutter.advance(1.0)
	var species=int(fish.species)
	for i in Economy.PORTIONS:
		arc_asset(PROPS+"Package_1.fbx",to_local(cutter.package_start(i)),to_local(machine_output(slot).global_position)+Vector3.UP*0.2,1.0,species)
	if slot==0:cut_active=false
	cutter.clear()
	ripple(to_local(machine_output(slot).global_position)+Vector3(0,0.04,0),Economy.COLORS[species])
func cancel_cut_visual(slot: int = -1) -> void:
	cut_generation+=1
	if slot<=0:cut_active=false
	if cut_tween!=null:cut_tween.kill()
	for index in machines:
		if slot==-1 or index==slot:machine_factory(index).clear()

func purchase_coins(kind: String, cost: int) -> void:
	var start = get_parent().player.global_position + Vector3(0,1.4,0)
	var end = pads[kind].node.global_position + Vector3(0,0.10,0)
	for i in (5 if Economy.data.settings.reduced_motion else 18):
		var coin = coin_mesh(self,to_local(start))
		var tween = create_tween()
		tween.tween_interval(i*0.024)
		tween.tween_property(coin,"position",to_local(end),0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(coin.queue_free)
	floating_text("-%d"%cost,to_local(end)+Vector3.UP*0.65,Color("ffe99e"))

func sync_carried(parent: Node3D, raw: Array, goods: Array) -> void:
	parent.sync_inventory(self,raw,goods)
func fly_to_back(kind: String, start: Vector3, species: int, accepted_index: int = -1, delay: float = 0.0) -> void:
	get_parent().player.basket.get_node("Carried").fly(kind,start,species,accepted_index,delay)

func sale_coin(start: Vector3, stall: int = 0) -> void:
	var coin = coin_mesh(self,to_local(start))
	var end = to_local(market_cash(stall).global_position)+Vector3.UP*0.25
	var origin = to_local(start)
	var tween = coin.create_tween()
	tween.tween_method(func(t): coin.position = origin.lerp(end,t)+Vector3.UP*sin(t*PI)*(0.10 if Economy.data.settings.reduced_motion else 0.45),0.0,1.0,0.28)
	tween.tween_callback(coin.queue_free)

func is_purchase_pad(id: String) -> bool:
	return id in ["rod","bag","machine","worker","dock","machine2","machine3","machine4","machine5","dock2","dock3","worker2","worker3","worker4","worker5","worker6","worker7"]
func pad_kind(id: String) -> String:
	return String(pads[id].kind) if pads.has(id) else ""
func refresh_expansion() -> void:
	for slot in range(1,Economy.MACHINE_COUNT):
		machines[slot].visible=Economy.machine_owned(slot)
		for collision in machines[slot].find_children("*","CollisionShape3D",true,false):collision.set_deferred("disabled",not Economy.machine_owned(slot))
		if not Economy.machine_owned(slot):continue
		var stack=machine_input(slot)
		var queue=Economy.queue_for(slot)
		if stack_changed(stack,fish_signature(queue)):
			clear_children(stack)
			for i in mini(20,queue.size()):
				normalized_model(FISH+Economy.SPECIES[int(queue[i].species)]+".fbx",stack,Vector3((i%3-1)*0.28,floori(float(i)/9)*0.14,(floori(float(i)/3)%3-1)*0.32),FISH_LENGTH,PI*0.5)
		packages(machine_output(slot),Economy.output_for(slot))
	for slot in range(1,Economy.FISHER_COUNT):
		var crew=fishers[slot]
		var hired=Economy.fisher_hired(slot) and Economy.dock_owned(Economy.fisher_dock(slot))
		crew.visible=hired
		crew.get_node("Worker").visible=hired
		crew.get_node("Pad_crate").visible=hired
		if hired:animate_person(crew.get_node("Worker"),"Idle_Breathing")
		var stack=fisher_crate(slot)
		var crate=Economy.crate_for(slot)
		if stack_changed(stack,fish_signature(crate)):
			clear_children(stack)
			for i in mini(25,crate.size()):normalized_model(FISH+Economy.SPECIES[int(crate[i].species)]+".fbx",stack,Vector3((i%3-1)*0.28,floori(float(i)/9)*0.15,(floori(float(i)/3)%3-1)*0.32),FISH_LENGTH,PI*0.5)
	for slot in [2,3]:
		ports[slot].visible=Economy.dock_owned(slot)
		for collision in ports[slot].find_children("*","CollisionShape3D",true,false):collision.set_deferred("disabled",not Economy.dock_owned(slot))
		pads["fish%d"%(slot+1)].node.visible=Economy.dock_owned(slot)
	for slot in range(1,Economy.FISHER_COUNT):pads["worker%d"%(slot+1)].node.visible=Economy.dock_owned(Economy.fisher_dock(slot))
