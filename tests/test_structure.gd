extends RefCounted

func test_main_scene() -> Variant:
	var packed = load("res://scenes/main.tscn") as PackedScene
	if packed == null or not packed.can_instantiate(): return "Main scene is not loadable"
	var scene = packed.instantiate()
	var valid = scene is Node3D and scene.get_script() != null
	scene.free()
	return valid

func test_scripts_exist() -> Variant:
	for filename in ["main", "world", "player", "hud", "economy", "audio", "joystick", "merge_board", "fish_slicer", "debug_panel", "in_place_animation"]:
		var script = load("res://scripts/" + filename + ".gd") as GDScript
		if script == null: return "Missing script: " + filename
	return true

func test_required_input_bindings() -> Variant:
	for action in ["move_left", "move_right", "move_up", "move_down", "interact", "menu", "debug_toggle"]:
		var definition = ProjectSettings.get_setting("input/" + action, {})
		if not definition is Dictionary or definition.get("events", []).is_empty(): return "No bindings for " + action
	return true

func test_economy_autoload() -> bool:
	return ProjectSettings.get_setting("autoload/Economy", "") == "*res://scripts/economy.gd"

func test_fish_models_have_visible_meshes() -> Variant:
	for species in ["Goldfish", "Clownfish", "Puffer", "Swordfish"]:
		var packed = load("res://assets/Cute Fish Pack - Feb 2020/FBX/" + species + ".fbx") as PackedScene
		if packed == null: return "Missing fish " + species
		var scene = packed.instantiate()
		var visible_mesh_count = 0
		for mesh in scene.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh != null: visible_mesh_count += 1
		scene.free()
		if visible_mesh_count == 0: return "Empty fish " + species
	return true

func test_people_and_locomotion_clips() -> Variant:
	# Uses the itHappy models when they are present locally, otherwise the CC0 fallback.
	var people = load("res://scripts/people.gd")
	var filenames: Array[String] = ["Pescador"]
	for i in range(1, 11): filenames.append("Cliente %d" % i)
	for filename in filenames:
		var path: String = people.resolve(filename)
		var packed = load(path) as PackedScene
		if packed == null: return "Missing character " + filename + " at " + path
		var scene = packed.instantiate()
		people.prepare(scene)
		var animation = scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var skeleton = scene.find_child("Skeleton3D", true, false) as Skeleton3D
		var valid = animation != null and skeleton != null and animation.has_animation("Idle_Breathing") and animation.has_animation("Walk_Forward") and animation.has_animation("Run_Forward")
		scene.free()
		if not valid: return "Missing locomotion clips: " + filename
	return true

func test_fallback_characters_are_complete() -> Variant:
	# The repository must run out of the box, so the CC0 stand ins must always load.
	var people = load("res://scripts/people.gd")
	var names: Array[String] = [people.FALLBACK_FISHER]
	names.append_array(people.FALLBACK_CUSTOMERS)
	for fallback_name in names:
		var packed = load(people.FALLBACK_DIR + fallback_name + ".glb") as PackedScene
		if packed == null: return "Missing fallback character " + fallback_name
		var scene = packed.instantiate()
		var animation = scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var valid = animation != null and animation.has_animation("Idle") and animation.has_animation("Walk") and animation.has_animation("Run") and not scene.find_children("*", "MeshInstance3D", true, false).is_empty()
		scene.free()
		if not valid: return "Fallback character is incomplete: " + fallback_name
	return true

func test_authored_hub_tree() -> Variant:
	var scene = load("res://scenes/world/lakeside.tscn").instantiate()
	for path in ["Lighting/Sun","Lighting/Atmosphere","Terrain/LakeWater","Terrain/ShoreGround","Workshop/CuttingMachine","Waterfront/SecondDock","MergeGarden/Pad_merge"]:
		if not scene.has_node(path):
			scene.free()
			return "Missing authored hub node: " + path
	var pad_count = 0
	for node in scene.find_children("*","Node",true,false):
		if node.has_meta("pad_id"): pad_count += 1
	var valid = pad_count == 45 and scene.find_children("*","MeshInstance3D",true,false).size() > 80
	scene.free()
	return valid

func test_authored_player() -> Variant:
	var scene = load("res://scenes/player/fisherman.tscn").instantiate()
	var valid = scene is CharacterBody3D and scene.get_node("CollisionShape3D").shape is CapsuleShape3D and scene.has_node("Visual/Model") and scene.has_node("Visual/Basket/Carried") and scene.has_node("Visual/Rod")
	scene.free()
	return valid

func test_authored_hud() -> Variant:
	var scene = load("res://scenes/ui/hud.tscn").instantiate()
	for path in ["Interface/Play/Wallet/Coins","Interface/Play/Joystick","Interface/Play/Action","Interface/Play/Fishing","Interface/MergeBoard","Interface/Settings"]:
		if not scene.has_node(path):
			scene.free()
			return "Missing authored HUD node: " + path
	var valid = scene.get_node("Interface/Play/Action").focus_mode == Control.FOCUS_NONE
	scene.free()
	return valid

func test_authored_merge_workbench() -> bool:
	var board = load("res://scenes/world/merge_workbench.tscn").instantiate()
	var ui = load("res://scenes/ui/merge_board.tscn").instantiate()
	var valid = board.get_node("Slots").get_child_count()==16 and board.has_node("Preview/Result") and board.get_node("Effects/AnimationPlayer").has_animation("merge") and board.has_node("Solid/Shape") and ui.has_node("Details/Next") and not ui.has_node("Details/Confirm") and ui.find_children("*","SubViewport",true,false).is_empty()
	board.free()
	ui.free()
	return valid

func test_authored_feedback_and_debug() -> bool:
	var main = load("res://scenes/main.tscn").instantiate()
	var valid = main.has_node("Lakeside/Workshop/CutStage") and main.has_node("Lakeside/MergeGarden/Workbench/Slots/Slot15") and main.has_node("HUD/Interface/Play/Orders/Order2") and main.has_node("HUD/Interface/DebugPanel/Panel/Money1000") and main.has_node("HUD/Interface/ResetConfirm/Panel/Confirm") and main.has_node("Lakeside/Market/Customer0/OrderBubble/Fish")
	main.free()
	return valid

func test_main_instances_prefabs() -> bool:
	var scene = load("res://scenes/main.tscn").instantiate()
	var valid = scene.get_child_count() == 6 and scene.has_node("Lakeside") and scene.has_node("Fisherman") and scene.has_node("HUD") and scene.has_node("Soundscape") and scene.get_node("FollowCamera").projection == Camera3D.PROJECTION_PERSPECTIVE and is_zero_approx(scene.get_node("FollowCamera").rotation.y)
	scene.free()
	return valid

func test_editable_station_prefabs() -> Variant:
	var requirements = {
		"cutting_station":["CuttingMachine","InputCrate","OutputCrate","Pad_cut","Pad_out","Status"],
		"market":["MarketStand_1","SaleStock","CashPile","Pad_stock","Pad_cash","Status"],
		"merge_garden":["Goldfish","Clownfish","Puffer","Swordfish","Pad_merge","Barrel"],
		"worker_station":["Worker","WorkerCrateFish","CatchCrate","Pad_crate","Status"]}
	for filename in requirements:
		var scene = load("res://scenes/stations/"+filename+".tscn").instantiate()
		for path in requirements[filename]:
			if not scene.has_node(path):
				scene.free()
				return "Missing station component: " + filename + "/" + path
		if filename=="merge_garden" and scene.has_node("DisplayWater0"):
			scene.free()
			return "Removed barrel-top disc returned"
		scene.free()
	return true
