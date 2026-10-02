extends Control
## Real 3D workbench: camera-plane picking, independently owned mouse/touch drags.
var hud: CanvasLayer
@onready var surface: Control = $BoardArea
var viewport: Viewport
var workbench: Node3D
var transitioning: bool = false
var inventory_signature: String = ""
var camera: Camera3D
var fishes: Node3D
var slots_root: Node3D
var preview_stage: Node3D
var preview_result: Node3D
var effects: Node3D
var effect_animation: AnimationPlayer
var sparks: GPUParticles3D
@onready var info: Label = $Details/Info
@onready var bonus: Label = $Details/Bonus
@onready var keep_button: Button = $Details/Keep
@onready var display_button: Button = $Details/Display
@onready var page_label: Label = $Details/Page
@onready var previous_button: Button = $Details/Previous
@onready var next_button: Button = $Details/Next
@onready var hint: Label = $Hint
@onready var access: Label = $Access
var slots: Dictionary = {}
var actors: Dictionary = {}
var selected: int = -1
var dragging: int = -1
var hovered: int = -1
var pointer: int = -2
var preview: Array[int] = []
var busy: bool = false
var mouse_suppression: int = 0
var can_merge: bool = false
var drag_origin: Vector2 = Vector2.ZERO
var drag_moved: bool = false
var merge_count: int = 0
var page: int = 0
var reveal_tween: Tween
const COUNT = 16
const COLORS = [Color("ffb84e"), Color("ff8b60"), Color("bada80"), Color("87c7f0")]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Close.pressed.connect(close)
	keep_button.pressed.connect(toggle_keep)
	display_button.pressed.connect(display_selected)
	previous_button.pressed.connect(func(): change_page(-1))
	next_button.pressed.connect(func(): change_page(1))
	set_process_input(false)



func bind_workbench(node: Node3D, active_camera: Camera3D) -> void:
	workbench = node
	camera = active_camera
	viewport = get_viewport()
	fishes = node.get_node("Fish")
	slots_root = node.get_node("Slots")
	preview_stage = node.get_node("Preview")
	preview_result = node.get_node("Preview/Result")
	effects = node.get_node("Effects")
	effect_animation = node.get_node("Effects/AnimationPlayer")
	sparks = node.get_node("Effects/Sparks")

var presentation: Array[int] = []

func reset_presentation() -> void:
	presentation.resize(COUNT*maxi(1,ceili(float(Economy.data.raw.size())/COUNT)))
	presentation.fill(-1)
	for i in Economy.data.raw.size(): presentation[i]=i

func capture_page() -> void:
	for i in COUNT:
		var offset=page*COUNT+i
		if offset<presentation.size(): presentation[offset]=int(slots.get(i,-1))

func normalize_presentation() -> void:
	var limit=COUNT*maxi(1,ceili(float(Economy.data.raw.size())/COUNT))
	if presentation.size()>limit: presentation.resize(limit)
	while presentation.size()<limit: presentation.append(-1)
	var used: Array[int]=[]
	for i in presentation.size():
		var index=presentation[i]
		if index<0 or index>=Economy.data.raw.size() or index in used: presentation[i]=-1
		else: used.append(index)
	for index in Economy.data.raw.size():
		if index in used: continue
		var empty=presentation.find(-1)
		if empty>=0: presentation[empty]=index
	page=clampi(page,0,maxi(0,ceili(float(limit)/COUNT)-1))
	slots.clear()
	for socket in COUNT:
		var index=presentation[page*COUNT+socket]
		if index>=0: slots[socket]=index
	if not slots.has(selected): selected=-1

func sync_inventory() -> void:
	if visible or workbench == null: return
	var signature = JSON.stringify(Economy.data.raw)
	if signature == inventory_signature: return
	inventory_signature = signature
	page = 0
	reset_presentation()
	slots.clear()
	for i in mini(COUNT,Economy.data.raw.size()): slots[i] = i
	selected = -1
	preview.clear()
	rebuild()

func set_transitioning(value: bool) -> void:
	transitioning = value
	set_process_input(visible and not value)
	if not value and visible: update_details()

func open(allow_merge: bool) -> void:
	page = 0
	reset_presentation()
	can_merge = allow_merge
	show()
	set_transitioning(true)
	slots.clear()
	for i in mini(COUNT,Economy.data.raw.size()): slots[i] = i
	selected = 0 if not slots.is_empty() else -1
	preview.clear()
	busy = false
	pointer = -2
	dragging = -1
	access.text = "Drag matching fish together" if can_merge else "Visit MERGE to combine fish"
	rebuild()
	hud.hub.focus_workbench()

func close() -> void:
	if busy: return
	if hud != null: hud.close_modal()

func deactivate() -> void:
	if dragging >= 0 and actors.has(dragging):
		actors[dragging].scale = Vector3.ONE
		actors[dragging].rotation.z = 0
		actors[dragging].position = slot_position(dragging)
	effect_animation.stop()
	effects.get_node("Ring").hide()
	sparks.emitting = false
	preview_stage.hide()
	hide()
	set_process_input(false)
	pointer = -2
	dragging = -1
	hovered = -1
	preview.clear()
	inventory_signature = JSON.stringify(Economy.data.raw)

func change_page(direction: int) -> void:
	if busy or transitioning or dragging >= 0: return
	capture_page()
	page = clampi(page+direction,0,maxi(0,ceili(float(Economy.data.raw.size())/COUNT)-1))
	selected = -1
	preview.clear()
	rebuild(false)

func slot_position(slot: int) -> Vector3:
	var socket: Node3D = slots_root.get_node("Slot%d" % slot)
	return fishes.to_local(socket.global_position) + Vector3(0,0.19,0)

func rebuild(capture: bool = true) -> void:
	if capture: capture_page()
	normalize_presentation()
	for child in fishes.get_children():
		fishes.remove_child(child)
		child.queue_free()
	actors.clear()
	if hud == null: return
	for slot in slots:
		var index = int(slots[slot])
		if index >= Economy.data.raw.size(): continue
		var species = int(Economy.data.raw[index].species)
		var actor = Node3D.new()
		actor.name = "FishSlot%d" % slot
		actor.position = slot_position(slot)
		fishes.add_child(actor)
		hud.hub.world.normalized_model(hud.hub.world.FISH + Economy.SPECIES[species] + ".fbx", actor, Vector3.ZERO, 0.84, PI * 0.5)
		actors[slot] = actor
	update_details()

func slot_at(screen: Vector2) -> int:
	if not surface.get_global_rect().has_point(screen): return -1
	var local = screen
	var ray_origin = camera.project_ray_origin(local)
	var direction = camera.project_ray_normal(local)
	var normal = fishes.global_transform.basis.y.normalized()
	var plane = Plane(normal,normal.dot(fishes.to_global(slot_position(0))))
	var intersection = plane.intersects_ray(ray_origin, direction)
	if intersection == null: return -1
	var hit: Vector3 = fishes.to_local(intersection)
	var nearest = -1
	var best = 0.57 * 0.57
	for slot in COUNT:
		var center = slot_position(slot)
		var distance = Vector2(hit.x-center.x,hit.z-center.z).length_squared()
		if distance < best:
			best = distance
			nearest = slot
	return nearest

func point_at(screen: Vector2) -> Vector3:
	var local = screen
	var normal = fishes.global_transform.basis.y.normalized()
	var intersection = Plane(normal,normal.dot(fishes.to_global(Vector3(0,0.62,0)))).intersects_ray(camera.project_ray_origin(local), camera.project_ray_normal(local))
	return fishes.to_local(intersection) if intersection != null else Vector3.ZERO

func screen_for_slot(slot: int) -> Vector2:
	return camera.unproject_position(fishes.to_global(slot_position(slot)))

func _input(event: InputEvent) -> void:
	if not visible or busy or transitioning: return
	if event is InputEventScreenTouch:
		mouse_suppression = Time.get_ticks_msec() + 180
		if event.pressed and pointer == -1 and event.position.distance_to(drag_origin) < 10:
			pointer = event.index
		elif event.pressed and pointer == -2 and surface.get_global_rect().has_point(event.position):
			begin_drag(event.position, event.index)
			get_viewport().set_input_as_handled()
		elif not event.pressed and pointer == event.index:
			end_drag(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == pointer:
		move_drag(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == -1 or pointer >= 0 or Time.get_ticks_msec() < mouse_suppression: return
		if event.pressed and surface.get_global_rect().has_point(event.position):
			begin_drag(event.position, -1)
			get_viewport().set_input_as_handled()
		elif not event.pressed and pointer == -1:
			end_drag(event.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and pointer == -1 and event.device != -1:
		move_drag(event.position)
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	# A viewport can discard mouse releases outside the game window. The device
	# state is still updated, so return the fish rather than leaving a stuck drag.
	if visible and pointer == -1 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		end_drag(Vector2(-1,-1))

func begin_drag(screen: Vector2, owner_id: int) -> void:
	if transitioning or busy or not visible: return
	if not preview.is_empty(): cancel_preview()
	var slot = slot_at(screen)
	if not slots.has(slot): return
	selected = slot
	dragging = slot
	pointer = owner_id
	drag_origin = screen
	drag_moved = false
	update_details()
	hud.hub.audio.cue("click")

func move_drag(screen: Vector2) -> void:
	if dragging == -1: return
	drag_moved = drag_moved or screen.distance_to(drag_origin) > 9
	var fish: Node3D = actors[dragging]
	fish.position = point_at(screen)
	fish.scale = Vector3.ONE * 1.12
	fish.rotation.z = -clampf((screen.x - drag_origin.x) * 0.0015, -0.18, 0.18)
	hovered = slot_at(screen)
	if matching(dragging, hovered):
		var species = int(Economy.data.raw[int(slots[dragging])].species)
		hint.text = "RELEASE TO MERGE  →  " + Economy.SPECIES[species + 1] + " • " + Economy.RARITIES[species + 1]
	else: hint.text = "Drop into an empty slot to arrange • match two identical fish to merge"
	update_highlights()

func matching(first: int, second: int) -> bool:
	if first == second or not slots.has(first) or not slots.has(second): return false
	var a: Dictionary = Economy.data.raw[int(slots[first])]
	var b: Dictionary = Economy.data.raw[int(slots[second])]
	return can_merge and int(a.species) == int(b.species) and Economy.RECIPES.has(int(a.species))

func end_drag(screen: Vector2) -> void:
	if dragging == -1: return
	var source = dragging
	var target = slot_at(screen)
	var feedback = ""
	pointer = -2
	dragging = -1
	hovered = -1
	var fish: Node3D = actors[source]
	fish.rotation.z = 0
	fish.scale = Vector3.ONE
	if not drag_moved:
		settle(fish, slot_position(source))
	elif target >= 0 and not slots.has(target):
		slots[target] = slots[source]
		slots.erase(source)
		actors[target] = actors[source]
		actors.erase(source)
		selected = target
		settle(fish, slot_position(target))
	elif matching(source, target):
		preview.assign([source,target])
		commit_preview()
		return
	else:
		settle(fish, slot_position(source))
		if target < 0: feedback = "Drop cancelled — your fish is back in its spot."
		elif not can_merge: feedback = "Visit the merge garden to combine your catches."
		else: feedback = "Those fish don't match — both are safely returned."
	update_details()
	if not feedback.is_empty(): hint.text = feedback

func settle(fish: Node3D, location: Vector3) -> void:
	create_tween().tween_property(fish, "position", location, 0.05 if Economy.data.settings.reduced_motion else 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func update_details() -> void:
	if preview_result == null: return
	for child in preview_result.get_children():
		preview_result.remove_child(child)
		child.queue_free()
	preview_stage.hide()
	update_highlights()
	$Close.disabled = busy
	var pages = maxi(1,ceili(float(Economy.data.raw.size())/COUNT))
	page_label.text = "%d / %d" % [page+1,pages]
	previous_button.visible=pages>1
	next_button.visible=pages>1
	page_label.visible=pages>1
	$Details.visible=slots.has(selected) or pages>1
	bonus.hide()
	previous_button.disabled = busy or transitioning or dragging >= 0 or page <= 0
	next_button.disabled = busy or transitioning or dragging >= 0 or page >= pages-1
	keep_button.visible = slots.has(selected) and not busy
	display_button.visible = keep_button.visible
	if not slots.has(selected):
		info.text = "%d fish"%Economy.data.raw.size()
		bonus.text = "Instant recipes\nGoldfish → Clownfish\nClownfish → Puffer\nPuffer → Swordfish"
		hint.text = "Matching drops merge immediately. Empty sockets only rearrange your fish."
		return
	var fish: Dictionary = Economy.data.raw[int(slots[selected])]
	var species = int(fish.species)
	info.text = Economy.SPECIES[species] + "\n%d coins" % int(fish.value)
	bonus.text = "Display bonus\n" + Economy.DISPLAY_BONUSES[species] + ("\n\n✓ Already displayed" if Economy.data.displayed[species] else "")
	display_button.text="✓ DISPLAYED" if Economy.data.displayed[species] else "DISPLAY "+Economy.DISPLAY_BONUSES[species].split(" ")[0]
	keep_button.disabled = transitioning or dragging >= 0
	keep_button.text = "✓ KEEP" if fish.get("reserved",false) else "KEEP"
	display_button.disabled = transitioning or dragging >= 0 or not can_merge or bool(Economy.data.displayed[species])
	hint.text = "Drop a matching fish to merge instantly. No confirmation needed."

func commit_preview() -> void:
	if busy or transitioning or preview.size() != 2: return
	var source = preview[0]
	var target = preview[1]
	if not matching(source, target): cancel_preview(); return
	var first = int(slots[source])
	var second = int(slots[target])
	var species = int(Economy.data.raw[first].species) + 1
	busy = true
	keep_button.hide()
	display_button.hide()
	previous_button.disabled = true
	next_button.disabled = true
	$Close.disabled = true
	preview_stage.hide()
	capture_page()
	var result = Economy.merge_indices(first, second)
	if result < 0:
		busy = false
		cancel_preview()
		return
	for i in presentation.size():
		var old=presentation[i]
		presentation[i]=-1 if old==first or old==second else old-(1 if old>mini(first,second) else 0)-(1 if old>maxi(first,second) else 0)
	presentation[page*COUNT+target]=Economy.data.raw.size()-1
	merge_count += 1
	var destination = slot_position(target)
	var duration = 0.08 if Economy.data.settings.reduced_motion else 0.24
	hud.hub.audio.cue("merge_pull")
	hint.text = "MERGING → " + Economy.SPECIES[species]
	var tween = create_tween().set_parallel(true)
	tween.tween_property(actors[source], "position", destination, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(actors[target], "scale", Vector3(0.72,0.45,0.72), duration)
	tween.tween_property(actors[source], "scale", Vector3.ONE*0.35,duration)
	tween.chain().tween_callback(func():
		var next_slots: Dictionary = {}
		for slot in slots:
			if slot == source or slot == target: continue
			var old_index = int(slots[slot])
			next_slots[slot] = old_index - (1 if old_index > mini(first, second) else 0) - (1 if old_index > maxi(first, second) else 0)
		next_slots[target] = Economy.data.raw.size() - 1
		slots = next_slots
		selected = target
		preview.clear()
		rebuild(false)
		var actor: Node3D = actors[target]
		actor.scale = Vector3.ONE*(0.92 if Economy.data.settings.reduced_motion else 0.10)
		reveal_tween = create_tween().set_parallel(true)
		if not Economy.data.settings.reduced_motion:
			actor.position = destination+Vector3.UP*0.65
			actor.rotation.z = -0.24
			reveal_tween.tween_property(actor,"position",destination,0.34).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			reveal_tween.tween_property(actor,"rotation:z",0.0,0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		reveal_tween.tween_property(actor,"scale",Vector3.ONE,0.12 if Economy.data.settings.reduced_motion else 0.34).set_trans(Tween.TRANS_SINE if Economy.data.settings.reduced_motion else Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if not Economy.data.settings.reduced_motion:
			effects.position = effects.get_parent().to_local(fishes.to_global(destination))
			effect_animation.play("merge")
			sparks.restart()
			sparks.emitting = true
			hud.hub.world.burst(hud.hub.world.to_local(fishes.to_global(destination))+Vector3.UP*0.3,Economy.COLORS[species],36)
			hud.hub.camera_impact(0.035)
		hud.hub.audio.cue("merge")
		hud.hub.world.floating_text(Economy.SPECIES[species]+"!",hud.hub.world.to_local(fishes.to_global(destination))+Vector3.UP*0.65,Economy.COLORS[species])
		reveal_tween.chain().tween_callback(func():
			busy = false
			update_details()
			hint.text = "" + Economy.SPECIES[species] + " merged! Result kept safe from cutting."))

func cancel_preview() -> void:
	preview.clear()
	update_details()

func toggle_keep() -> void:
	if busy or transitioning or not slots.has(selected): return
	var index = int(slots[selected])
	Economy.reserve_fish(index, not Economy.data.raw[index].get("reserved", false))
	update_details()

func display_selected() -> void:
	if busy or transitioning or not can_merge or not slots.has(selected): return
	var index = int(slots[selected])
	var species = int(Economy.data.raw[index].species)
	capture_page()
	if not Economy.display_index(index): return
	for i in presentation.size():
		var old=presentation[i]
		presentation[i]=-1 if old==index else old-(1 if old>index else 0)
	# Display consumes exactly the selected fish; remap every remaining inventory index.
	var remaining: Dictionary = {}
	for slot in slots:
		var old = int(slots[slot])
		if old == index: continue
		remaining[slot] = old - (1 if old > index else 0)
	slots = remaining
	selected = -1
	rebuild(false)
	hud.hub.audio.cue("upgrade")
	hint.text = Economy.DISPLAY_BONUSES[species] + " activated. Discovery stays permanent."

func update_highlights() -> void:
	for i in COUNT:
		var surface_mesh: MeshInstance3D = slots_root.get_node("Slot%d/Surface" % i)
		var slot_material = surface_mesh.material_override as StandardMaterial3D
		var color = Color("d8c5a2")
		if slots.has(i): color = Color("f0e3bd")
		if i == selected: color = Color("b5ead5")
		if i in preview or (dragging >= 0 and i == hovered and matching(dragging,i)): color = Color("69d4b1")
		slot_material.albedo_color = color

func _notification(what: int) -> void:
	if what != NOTIFICATION_APPLICATION_FOCUS_OUT and what != NOTIFICATION_APPLICATION_PAUSED: return
	if dragging >= 0 and actors.has(dragging):
		actors[dragging].scale = Vector3.ONE
		actors[dragging].rotation.z = 0
		settle(actors[dragging],slot_position(dragging))
	pointer = -2
	dragging = -1
	hovered = -1
	if is_node_ready() and slots_root != null: update_highlights()
