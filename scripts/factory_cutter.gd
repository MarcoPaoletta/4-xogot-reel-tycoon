extends Node3D
## The business clock owns progress. This machine only animates a committed queue fish.
const SLICE_COUNT = 10
const FEED_END = 0.18
const CUT_END = 0.91
const SLICER = preload("res://scripts/fish_slicer.gd")
var world: Node3D
var stage: Node3D
var slice_cache: Dictionary = {}
var pieces: Array[MeshInstance3D] = []
var species = -1
var cut_count = 0
var progress = 0.0
var active = false
var belt_distance = 0.0
var orientation = Basis.IDENTITY
var centers: Array[float]=[]
var cutting_lines: Array[float]=[]
@onready var belt: MeshInstance3D = $Belt
@onready var blade: Node3D = $BladeMount
@onready var spin: Node3D = $BladeMount/Spin
@onready var chips: GPUParticles3D = $Chips
@onready var status: Label3D = $Status

func bind(cut_stage: Node3D, hub_world: Node3D) -> void:
	stage = cut_stage
	world = hub_world

func begin(fish: Dictionary) -> void:
	clear()
	species = int(fish.species)
	if not slice_cache.has(species):
		var source = world.normalized_model(world.FISH+Economy.SPECIES[species]+".fbx",stage,Vector3.ZERO,world.FISH_LENGTH)
		source.hide()
		var source_axis: int = world.bounds_cache[world.FISH+Economy.SPECIES[species]+".fbx"].size.max_axis_index()
		var cap = StandardMaterial3D.new()
		cap.resource_name = "FreshCutFace"
		cap.albedo_color = [Color("ffe5bb"),Color("ffd5b9"),Color("eef3c5"),Color("d6eef5")][species]
		cap.roughness = 0.68
		cap.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cap.cull_mode = BaseMaterial3D.CULL_DISABLED
		slice_cache[species] = {"meshes":SLICER.meshes(source,SLICE_COUNT,cap),"axis":source_axis}
		stage.remove_child(source)
		source.queue_free()
	var axis: int = slice_cache[species].axis
	orientation = Basis(Vector3.UP,-PI*0.5) if axis==0 else (Basis(Vector3.RIGHT,PI*0.5) if axis==1 else Basis.IDENTITY)
	for i in SLICE_COUNT:
		var piece = MeshInstance3D.new()
		piece.name = "Slice%d"%i
		piece.mesh = slice_cache[species].meshes[i]
		piece.basis = orientation
		stage.add_child(piece)
		pieces.append(piece)
	centers.clear()
	cutting_lines.clear()
	for piece in pieces:
		var bounds: AABB=Transform3D(orientation,Vector3.ZERO)*piece.mesh.get_aabb()
		centers.append(bounds.get_center().z)
		cutting_lines.append(bounds.position.z)
	cutting_lines.reverse()
	active = true
	cut_count = 0
	progress = 0
	belt.material_override.set_shader_parameter("running",1.0)
	advance(0.0)

func advance(value: float) -> void:
	if not active: return
	var next = clampf(value,0,1)
	belt_distance += maxf(0,next-progress)*1.35
	progress = next
	var reduced: bool = Economy.data.settings.reduced_motion
	var phase = clampf((progress-FEED_END)/(CUT_END-FEED_END),0,1)*SLICE_COUNT
	var feed_z = lerpf(-0.72,-world.FISH_LENGTH*0.5,clampf(progress/FEED_END,0,1)) if progress<FEED_END else -cutting_lines[mini(SLICE_COUNT-1,floori(phase))]
	var stroke = (1.0-cos(fmod(phase,1.0)*TAU))*0.5 if progress>=FEED_END and progress<CUT_END else 0.0
	blade.position.y = 0.91 if reduced else 0.91-stroke*0.40
	spin.rotation.z = 0.0 if reduced else progress*TAU*17.0
	belt.material_override.set_shader_parameter("travel",0.0 if reduced else belt_distance)
	for roller in get_children():
		if roller is MeshInstance3D and String(roller.name).begins_with("Roller"):
			roller.rotation.x = 0.0 if reduced else belt_distance*7.0
	var complete = 0
	for i in SLICE_COUNT:
		var order = SLICE_COUNT-1-i
		var release_at = FEED_END+(float(order)+0.52)/SLICE_COUNT*(CUT_END-FEED_END)
		var piece = pieces[i]
		if progress < release_at:
			piece.position = Vector3(0,0.022,-world.FISH_LENGTH*0.5 if reduced else feed_z)
			piece.basis = orientation
		else:
			complete += 1
			var age = clampf((progress-release_at)/0.16,0,1)
			var center_z = centers[i]
			var origin = Vector3(0,0.022,-center_z)
			var target = Vector3((order%2-0.5)*0.51,0.027,0.40+floori(float(order)/2)*0.18-center_z)
			piece.position = target if reduced else origin.lerp(target,1.0-pow(1.0-age,2.0))+Vector3.UP*sin(age*PI)*0.13
			piece.basis = orientation if reduced else Basis(Vector3.FORWARD,sin(age*PI)*(1 if i%2==0 else -1)*0.12)*orientation
	if complete > cut_count:
		cut_count = complete
		if cut_count%2==0: world.get_parent().audio.cue("slice")
		if not reduced:
			chips.amount = 5 if Economy.data.settings.low_quality else 14
			chips.restart()
			world.get_parent().camera_impact(0.009)
	status.text = Economy.SPECIES[species].to_upper()+"  •  %d / 10 CUTS"%cut_count

func package_start(index: int) -> Vector3:
	return stage.to_global(Vector3(0,0.09,0.40+index*0.18))

func clear() -> void:
	active = false
	progress = 0
	cut_count = 0
	pieces.clear()
	if stage != null: world.clear_children(stage)
	if is_node_ready():
		blade.position.y = 0.91
		spin.rotation.z = 0
		chips.emitting = false
		belt.material_override.set_shader_parameter("running",0.0)
		status.text = "FISH WORKSHOP"
