extends Node3D
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
	instance.scale = Vector3.ONE * uniform_scale
	if path.begins_with(FISH) and path.get_file().get_basename() in Economy.SPECIES:
		color_fish(instance)
	return holder

func text3d(text: String, parent: Node, pos: Vector3, color: Color = Color.WHITE, font_size: int = 40) -> Label3D:
	var l = Label3D.new()
	l.text = text
	l.font_size = font_size
	l.pixel_size = 0.011
	l.outline_size = 6
	l.outline_modulate = Color("163b47")
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = false
	parent.add_child(l)
	l.position = pos
	return l

func pad(id: String, title: String, position3d: Vector3, color: Color, radius: float = 0.82) -> void:
	var p = Node3D.new()
	p.name = "Pad_" + id
	add_child(p)
	p.position = position3d
	var circle = MeshInstance3D.new()
	var disk = CylinderMesh.new()
	disk.top_radius = radius
	disk.bottom_radius = radius
	disk.height = 0.035
	circle.mesh = disk
	var mat = material(color)
	mat.emission_enabled = true
	mat.emission = color * 0.15
	circle.material_override = mat
	p.add_child(circle)
	circle.position.y = 0.035
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = radius - 0.065
	torus.outer_radius = radius + 0.035
	ring.mesh = torus
	ring.material_override = material(Color("f0ffe9"))
	p.add_child(ring)
	ring.position.y = 0.065
	var number = text3d(title, p, Vector3(0, 0.55, 0), Color.WHITE, 34)
	pads[id] = {"position": position3d, "node": p, "circle": circle, "radius": radius, "label": number}

func build() -> void:
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("83dce2")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f4f7db")
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, -25, 0)
	sun.light_color = Color("fff1d3")
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65
	add_child(sun)
	box(self, Vector3(0, -0.48, 9), Vector3(29, 0.95, 22), Color("58985e"), true)
	box(self, Vector3(0, -0.4, -1.8), Vector3(29, 0.6, 1.3), Color("eac88b"))
	var water = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(100, 100)
	plane.subdivide_width = 80
	plane.subdivide_depth = 80
	water.mesh = plane
	water_material = ShaderMaterial.new()
	water_material.shader = load("res://shaders/water.gdshader")
	water.material_override = water_material
	water.position = Vector3(0, -0.3, -27)
	add_child(water)
	# Dock planks are at local Y ~3.9; normalize to a level walking surface.
	model(FISH + "Dock_Long_NoRope.fbx", self, Vector3(-5, -1.1, -5.0), 0.28)
	box(self, Vector3(-5, -0.13, -5), Vector3(2.6, 0.26, 6.5), Color("a87444"), true).visible = false
	second_dock = model(FISH + "Dock_Long_NoRope.fbx", self, Vector3(5, -1.1, -5.0), 0.28)
	box(self, Vector3(5, -0.13, -5), Vector3(2.6, 0.26, 6.5), Color("a87444"), true).visible = false
	model(FISH + "Boat.fbx", self, Vector3(10, -0.1, -6), 0.35, 0.3)
	for z in [0.0, 1.75, 3.5, 5.25]:
		model(PROPS + "Path_Square.fbx", self, Vector3(-5, -0.17, z), 3.6)
	for x in [-8.5, -6.75, -3.25, -1.5, 0.25, 2.0, 3.75, 5.5, 7.25]:
		model(PROPS + "Path_Square.fbx", self, Vector3(x, -0.17, 5.25), 3.6)
	for x in [-11, -9, -1, 1, 9, 11]:
		model(PROPS + "Fence.fbx", self, Vector3(x, 0, -1.0), 2.5)
	model(PROPS + "Bench_1.fbx", self, Vector3(-10.6, 0, 7.6), 2.6, PI * 0.5)
	model(PROPS + "Crate.fbx", self, Vector3(-1.75, 0, 2.45), 5.4)
	model(PROPS + "Crate.fbx", self, Vector3(-0.25, 0, 2.45), 5.4)
	saw = model(PROPS + "Sawmill_saw.fbx", self, Vector3(-1, 0.78, 2.3), 1.6, -PI * 0.5)
	separate_saw_blade()
	input_stack = Node3D.new()
	add_child(input_stack)
	input_stack.position = Vector3(-1, 1.62, 2.3)
	model(PROPS + "Crate.fbx", self, Vector3(1.7, 0, 2.8), 4.7)
	output_stack = Node3D.new()
	add_child(output_stack)
	output_stack.position = Vector3(1.7, 0.8, 2.8)
	box(self, Vector3(-1, 0.55, 2.3), Vector3(2.6, 1.1, 1.5), Color.WHITE, true).visible = false
	labels.cut = text3d("CUTTING MACHINE", self, Vector3(-1, 2.35, 2.3), Color("fff0c4"), 36)
	model(PROPS + "MarketStand_1.fbx", self, Vector3(6.5, 0, 2.6), 2.25)
	box(self, Vector3(6.5, 1.1, 2.6), Vector3(2.0, 2.2, 2.0), Color.WHITE, true).visible = false
	labels.stall = text3d("LAKESIDE MARKET", self, Vector3(6.5, 2.85, 2.6), Color("fff0c4"), 36)
	sale_stack = Node3D.new()
	add_child(sale_stack)
	sale_stack.position = Vector3(6.5, 0.9, 2.6)
	cash_pile = Node3D.new()
	add_child(cash_pile)
	cash_pile.position = Vector3(8.15, 0.1, 4.4)
	model(PROPS + "Crate.fbx", self, Vector3(-8.6, 0, -0.1), 4.8)
	crate_stack = Node3D.new()
	add_child(crate_stack)
	crate_stack.position = Vector3(-8.6, 0.8, -0.1)
	worker = model(PEOPLE + "Pescador.glb", self, Vector3(-5.85, 0, -3.7), 0.97, PI)
	animate_person(worker, "Idle_Breathing")
	model(FISH + "FishingRod_Lvl1.fbx", worker, Vector3(-0.4, 1.0, -0.1), 0.27).rotation_degrees.x = -40
	labels.worker = text3d("FISHER CRATE", self, Vector3(-8.6, 1.9, -0.1), Color("c4ffef"), 34)
	for i in 4:
		var pos = Vector3(-9.7 + i * 1.2, 0, 3.8)
		model(PROPS + "Barrel.fbx", self, pos, 4.0)
		var water_top = MeshInstance3D.new()
		var disk = CylinderMesh.new()
		disk.top_radius = 0.25
		disk.bottom_radius = 0.25
		disk.height = 0.02
		water_top.mesh = disk
		water_top.material_override = material(Color("62dedb"))
		add_child(water_top)
		water_top.position = pos + Vector3(0, 0.81, 0)
		var fish = model(FISH + Economy.SPECIES[i] + ".fbx", self, pos + Vector3(0, 1.18, 0), 0.095, PI * 0.5)
		displays.append(fish)
	box(self, Vector3(-7.9, 0.4, 3.8), Vector3(4.4, 0.8, 0.7), Color.WHITE, true).visible = false
	labels.merge = text3d("DISCOVERIES", self, Vector3(-7.8, 2, 3.8), Color("c4ffef"), 38)
	pad("fish", "1  CAST", Vector3(-5, 0, -7.35), Color("54cfc1"))
	pad("fish2", "RARE CAST", Vector3(5, 0, -7.35), Color("ab96eb"))
	pad("cut", "2  CUT", Vector3(-1, 0, 4.25), Color("ffae73"))
	pad("out", "3  OUT", Vector3(1.75, 0, 4.4), Color("ffe494"))
	pad("stock", "4  STOCK", Vector3(4.8, 0, 5.1), Color("54cfc1"))
	pad("cash", "5  CASH", Vector3(7.8, 0, 5.6), Color("ffdc65"))
	pad("merge", "MERGE", Vector3(-7.5, 0, 6), Color("b9a4ef"))
	pad("crate", "PICK UP", Vector3(-8.6, 0, 1.45), Color("54cfc1"))
	for spec in [["rod", "ROD", -7.0], ["bag", "BASKET", -3.0], ["machine", "CUT SPEED", 1.0], ["worker", "HIRE FISHER", 5.0], ["dock", "NEW DOCK", 9.0]]:
		pad(spec[0], spec[1], Vector3(spec[2], 0, 10.3), Color("daa950"), 1.0)
	var random = RandomNumberGenerator.new()
	random.seed = 777
	for side in [-1, 1]:
		for i in 8:
			var x = side * random.randf_range(12.7, 14.4)
			var z = -1.0 + i * 2.4
			model(NATURE + ("CommonTree_2.fbx" if i % 3 else "CommonTree_Autumn_2.fbx"), self, Vector3(x, 0, z), random.randf_range(1.1, 1.5), random.randf_range(0, TAU))
			model(NATURE + "Bush_1.fbx", self, Vector3(x - side, 0, z + 0.8), 0.65)
	for i in 16:
		var x = random.randf_range(-14, 14)
		if absf(x + 5) < 1.6 or absf(x - 5) < 1.6: continue
		model(NATURE + "Rock_Moss_3.fbx", self, Vector3(x, -0.03, -1.9), random.randf_range(0.7, 1.4))
		model(NATURE + "Grass_Short.fbx", self, Vector3(x, 0, -1.1), 0.8)
	for i in 25:
		var x = random.randf_range(-11.5, 11.5)
		var z = random.randf_range(-0.8, 8.5)
		if absf(x + 5) < 1.3 or (x > -10.8 and x < 10 and z > 1.3): continue
		model(NATURE + "Grass_Short.fbx", self, Vector3(x, 0, z), 1.0)
		if i % 4 == 0: model(NATURE + "Flowers.fbx", self, Vector3(x + 0.2, 0, z), 0.65)
	for i in 18:
		model(NATURE + "Lilypad.fbx", self, Vector3(random.randf_range(-14, 14), -0.25, random.randf_range(-16, -9)), random.randf_range(0.4, 0.8), random.randf_range(0, TAU))
	box(self, Vector3(0, -0.3, -27), Vector3(65, 0.6, 8), Color("75b366"))
	for i in 20:
		model(NATURE + "PineTree_2.fbx", self, Vector3(-28 + i * 3, 0, -25), 1.6)
	for i in 3:
		spawn_customer(i)
	refresh()

func animate_person(person: Node3D, clip: String) -> void:
	var animation = person.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation != null and animation.has_animation(clip):
		animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		animation.play(clip, 0.15)

func spawn_customer(_slot: int) -> void:
	var slot = 0
	for customer in customers:
		if customer.state != "leaving": slot += 1
	customer_index = customer_index % 10 + 1
	var person = model(PEOPLE + "Cliente %d.glb" % customer_index, self, Vector3(11.1, 0, 15 + slot), 0.98, PI)
	animate_person(person, "Walk_Forward")
	customers.append({"person": person, "slot": slot, "state": "arriving"})

func update_customers(delta: float) -> void:
	var expired: Array[Dictionary] = []
	for customer in customers:
		var p: Node3D = customer.person
		var target = Vector3(9.4, 0, 2.6 + int(customer.slot) * 1.4)
		if customer.state == "leaving": target = Vector3(11.5, 0, 17)
		var distance = p.position.distance_to(target)
		if distance > 0.05:
			var direction = (target - p.position).normalized()
			p.rotation.y = atan2(direction.x, direction.z)
			p.position = p.position.move_toward(target, delta * 2.2)
		elif customer.state == "arriving":
			customer.state = "waiting"
			p.rotation.y = -PI * 0.5
			animate_person(p, "Idle_Breathing")
		elif customer.state == "leaving":
			expired.append(customer)
	for c in expired:
		customers.erase(c)
		c.person.queue_free()
		spawn_customer(2)

func ready_customer() -> bool:
	for c in customers:
		if c.state == "waiting" and c.slot == 0: return true
	return false

func serve_customer(value: int) -> void:
	for c in customers:
		if c.state == "waiting" and c.slot == 0:
			c.state = "leaving"
			if not Economy.data.settings.reduced_motion:
				var reaction = create_tween()
				reaction.tween_property(c.person, "scale", Vector3.ONE * 1.06, 0.12)
				reaction.tween_property(c.person, "scale", Vector3.ONE, 0.18)
			animate_person(c.person, "Walk_Forward")
			floating_text("+%d" % value, c.person.position + Vector3(0, 2, 0), Color("ffe083"))
			for other in customers:
				if other.state != "leaving" and other != c:
					other.slot = maxi(0, int(other.slot) - 1)
					other.state = "arriving"
					animate_person(other.person, "Walk_Forward")
			return

func clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func packages(parent: Node3D, count: int) -> void:
	clear_children(parent)
	for i in mini(count, 8):
		model(PROPS + "Package_1.fbx", parent, Vector3((i % 2) * 0.3 - 0.15, floori(float(i) / 2.0) * 0.12, 0), 1.0)

func refresh() -> void:
	if pads.is_empty(): return
	second_dock.visible = Economy.data.dock
	pads.fish2.node.visible = Economy.data.dock
	worker.visible = Economy.data.worker
	pads.crate.node.visible = Economy.data.worker
	labels.worker.visible = Economy.data.worker
	labels.worker.text = "CRATE FULL • PICK UP" if Economy.data.worker_crate.size() >= 5 else "FISHER CRATE  %d / 5" % Economy.data.worker_crate.size()
	labels.cut.text = "OUTPUT FULL • PICK UP" if Economy.data.output.size() >= 20 else "CUT  %d / 10   ·   OUT  %d / 20" % [Economy.data.queue.size(), Economy.data.output.size()]
	labels.stall.text = "MARKET  %d / 20" % Economy.data.stock.size()
	pads.cash.label.text = "5  CASH\n%d coins" % int(Economy.data.cash)
	for kind in ["rod", "bag", "machine", "worker", "dock"]:
		var titles = {"rod": "ROD", "bag": "BASKET", "machine": "CUT SPEED", "worker": "HIRE FISHER", "dock": "NEW DOCK"}
		var cost = Economy.upgrade_cost(kind)
		pads[kind].label.text = titles[kind] + ("\n%d coins" % cost if cost >= 0 else "\n✓ COMPLETE")
	clear_children(input_stack)
	for i in mini(3, Economy.data.queue.size()):
		var fish: Dictionary = Economy.data.queue[i]
		model(FISH + Economy.SPECIES[int(fish.species)] + ".fbx", input_stack, Vector3(0, i * 0.15, 0), 0.095, PI * 0.5)
	packages(output_stack, Economy.data.output.size())
	packages(sale_stack, Economy.data.stock.size())
	clear_children(crate_stack)
	for i in mini(5, Economy.data.worker_crate.size()):
		var f: Dictionary = Economy.data.worker_crate[i]
		model(FISH + Economy.SPECIES[int(f.species)] + ".fbx", crate_stack, Vector3(0, i * 0.16, 0), 0.095, PI * 0.5)
	for i in 4: displays[i].visible = Economy.data.displayed[i]
	clear_children(cash_pile)
	for i in mini(12, int(ceil(float(Economy.data.cash) / 6.0))):
		coin_mesh(cash_pile, Vector3((i % 3) * 0.12, floori(float(i) / 3.0) * 0.055, 0))

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

func arc_asset(path: String, start: Vector3, end: Vector3, model_scale: float) -> void:
	var item = model(path, self, start, model_scale, PI * 0.5)
	var tween = create_tween()
	var hop_height = 0.3 if Economy.data.settings.reduced_motion else 1.8
	var duration = 0.25 if Economy.data.settings.reduced_motion else 0.48
	tween.tween_method(func(t: float): item.position = start.lerp(end, t) + Vector3.UP * sin(t * PI) * hop_height, 0.0, 1.0, duration)
	tween.tween_callback(item.queue_free)

func coin_cascade(start: Vector3, end: Vector3) -> void:
	for i in (3 if Economy.data.settings.reduced_motion else 9):
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
				mat.roughness = 0.6
				fish_materials[key] = mat
			mesh.set_surface_override_material(surface, fish_materials[key])

func burst(pos: Vector3, color: Color, amount: int = 14) -> void:
	var particles = CPUParticles3D.new()
	particles.amount = 4 if Economy.data.settings.reduced_motion else amount
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
