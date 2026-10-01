extends RefCounted

func test_main_scene() -> Variant:
	var packed = load("res://scenes/main.tscn") as PackedScene
	if packed == null or not packed.can_instantiate(): return "Main scene is not loadable"
	var scene = packed.instantiate()
	var valid = scene is Node3D and scene.get_script() != null
	scene.free()
	return valid

func test_scripts_exist() -> Variant:
	for filename in ["main", "world", "player", "hud", "economy", "audio", "joystick", "fish_card"]:
		var script = load("res://scripts/" + filename + ".gd") as GDScript
		if script == null: return "Missing script: " + filename
	return true

func test_required_input_bindings() -> Variant:
	for action in ["move_left", "move_right", "move_up", "move_down", "interact", "menu"]:
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
	var filenames: Array[String] = ["Pescador"]
	for i in range(1, 11): filenames.append("Cliente %d" % i)
	for filename in filenames:
		var packed = load("res://assets/itHappy Characters GLB/" + filename + ".glb") as PackedScene
		if packed == null: return "Missing private character " + filename
		var scene = packed.instantiate()
		var animation = scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var valid = animation != null and animation.has_animation("Idle_Breathing") and animation.has_animation("Walk_Forward") and animation.has_animation("Run_Forward")
		scene.free()
		if not valid: return "Missing locomotion clips: " + filename
	return true
