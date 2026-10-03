extends RefCounted
## Character lookup. The assembled itHappy GLBs cannot be redistributed, so they are local
## only. When they are missing the CC0 Quaternius characters shipped in the repository
## stand in for them, with the same idle/walk/run clip names the game expects.
const PRIVATE_DIR = "res://assets/itHappy Characters GLB/"
const FALLBACK_DIR = "res://assets/Quaternius Ultimate Animated Characters/"
const FALLBACK_FISHER = "Casual_Male"
const FALLBACK_CUSTOMERS: Array[String] = ["Casual2_Female", "Suit_Male", "Chef_Female", "Cowboy_Male", "Doctor_Female_Young", "OldClassy_Male"]
# The Quaternius characters stand about 3.3 units tall in Godot, the itHappy ones 1.86.
const FALLBACK_SCALE = 0.56
const CLIP_ALIASES = {"Idle": "Idle_Breathing", "Walk": "Walk_Forward", "Run": "Run_Forward"}
# The Quaternius pack ships black skin with white eyes. The game draws real looking people,
# so each fallback character gets a skin tone and dark eyes at runtime (the files stay untouched).
const SKIN_TONES = {"Casual_Male": "e0ac86", "Casual2_Female": "f1c9a5", "Suit_Male": "c68863", "Chef_Female": "d99a73", "Cowboy_Male": "a96f4a", "Doctor_Female_Young": "f1c9a5", "OldClassy_Male": "8d5a3b"}
const EYE_COLOR = Color("2b1d16")
static var announced: bool = false

# "Pescador" or "Cliente 1" to "Cliente 10", the file names of the itHappy set.
static func fallback_file(character: String) -> String:
	if character == "Pescador": return FALLBACK_FISHER
	var index = maxi(int(character.get_slice(" ", 1)), 1)
	return FALLBACK_CUSTOMERS[(index - 1) % FALLBACK_CUSTOMERS.size()]

static func resolve(character: String) -> String:
	var private_path = PRIVATE_DIR + character + ".glb"
	var found = ResourceLoader.exists(private_path)
	if not announced:
		announced = true
		print("Characters: " + ("itHappy models found" if found else "CC0 Quaternius fallback (see README, section Characters)"))
	return private_path if found else FALLBACK_DIR + fallback_file(character) + ".glb"

static func is_person(path: String) -> bool:
	return path.begins_with(PRIVATE_DIR) or path.begins_with(FALLBACK_DIR)

static func scale_for(path: String) -> float:
	return FALLBACK_SCALE if path.begins_with(FALLBACK_DIR) else 1.0

# The game looks clips up by their itHappy names. Alias the fallback names to them,
# sharing the same Animation resource, so every caller works unchanged. Pass the model path
# to also give a fallback character its skin tone.
static func prepare(instance: Node, path: String = "") -> void:
	if path.begins_with(FALLBACK_DIR): paint_fallback(instance, path.get_file().get_basename())
	var animation = instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation == null: return
	var library = animation.get_animation_library(&"")
	if library == null: return
	for clip in CLIP_ALIASES:
		var alias: String = CLIP_ALIASES[clip]
		if library.has_animation(clip) and not library.has_animation(alias): library.add_animation(alias, library.get_animation(clip))

static func paint_fallback(instance: Node, fallback_name: String) -> void:
	var tone = Color(SKIN_TONES.get(fallback_name, "e0ac86"))
	for node in instance.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh == null: continue
		for surface in mesh_instance.mesh.get_surface_count():
			var source = mesh_instance.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null or not source.resource_name in ["Skin", "Face"]: continue
			var copy = source.duplicate() as StandardMaterial3D
			copy.albedo_color = tone if source.resource_name == "Skin" else EYE_COLOR
			mesh_instance.set_surface_override_material(surface, copy)

static func instantiate(character: String) -> Node3D:
	var path = resolve(character)
	var packed = load(path) as PackedScene
	if packed == null:
		push_warning("Missing asset: " + path)
		return null
	var instance = packed.instantiate() as Node3D
	instance.scale = Vector3.ONE * scale_for(path)
	prepare(instance, path)
	return instance
