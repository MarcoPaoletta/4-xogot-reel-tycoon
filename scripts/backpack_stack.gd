extends Node3D
## Full-size, unbounded-height inventory. Batches meshes, never inventory quantities.
var world: Node3D
var raw: Array = []
var goods: Array = []
var geometry: Dictionary = {}
var batches: Dictionary = {}
var flights: Dictionary = {}
var visible_items = 0

func item_home(kind: String, index: int) -> Vector3:
	var goods_layers = ceili(float(goods.size())/9)
	return Vector3(-0.23+(index%3-1)*0.33,0.46+floori(float(index)/9)*0.19,-0.12+(floori(float(index)/3)%3-1)*0.31) if kind=="Goods" else Vector3(-0.23+(index%3-1)*0.36,0.46+goods_layers*0.19+floori(float(index)/9)*0.23,-0.12+(floori(float(index)/3)%3-1)*0.39)

func item_key(kind: String, index: int) -> String:
	return "%s:%d"%[kind,index]

func build_geometry(kind: String, species: int) -> Array:
	var key="%s:%d"%[kind,species]
	if geometry.has(key): return geometry[key]
	var path=world.PROPS+"Package_1.fbx" if kind=="Goods" else world.FISH+Economy.SPECIES[species]+".fbx"
	var source=world.normalized_model(path,self,Vector3.ZERO,world.PACKAGE_LENGTH if kind=="Goods" else world.FISH_LENGTH,0.0 if kind=="Goods" else PI*0.5)
	source.hide()
	if kind=="Goods": world.tint_package(source,species)
	var parts: Array=[]
	for model in source.find_children("*","MeshInstance3D",true,false):
		if model.mesh==null:continue
		var mesh=ArrayMesh.new()
		for surface in model.mesh.get_surface_count():
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,model.mesh.surface_get_arrays(surface))
			mesh.surface_set_material(surface,model.get_active_material(surface))
		parts.append({"mesh":mesh,"transform":source.global_transform.affine_inverse()*model.global_transform})
	remove_child(source)
	source.queue_free()
	geometry[key]=parts
	return parts

func sync_inventory(hub_world: Node3D, fishes: Array, packages: Array) -> void:
	world=hub_world
	raw=fishes
	goods=packages
	for key in flights.keys():
		var entry: Dictionary=flights[key]
		var items=goods if entry.kind=="Goods" else raw
		if int(entry.index)>=items.size():
			entry.actor.queue_free()
			flights.erase(key)
	rebuild_batches()

func rebuild_batches() -> void:
	var groups: Dictionary={}
	visible_items=0
	for kind in ["Goods","Raw"]:
		var items: Array=goods if kind=="Goods" else raw
		for i in items.size():
			if flights.has(item_key(kind,i)):continue
			var species=Economy.package_species(items[i]) if kind=="Goods" else int(items[i].species)
			var group="%s:%d"%[kind,species]
			if not groups.has(group):groups[group]=[]
			groups[group].append(Transform3D(Basis.IDENTITY,item_home(kind,i)))
			visible_items+=1
	for group in groups:
		var tokens: PackedStringArray=group.split(":")
		var parts=build_geometry(tokens[0],int(tokens[1]))
		for p in parts.size():
			var key="%s:%d"%[group,p]
			if not batches.has(key):
				var batch_node=MultiMeshInstance3D.new()
				batch_node.name="Stack_"+key.replace(":","_")
				var instances=MultiMesh.new()
				instances.transform_format=MultiMesh.TRANSFORM_3D
				instances.mesh=parts[p].mesh
				batch_node.multimesh=instances
				add_child(batch_node)
				batches[key]=batch_node
			var node: MultiMeshInstance3D=batches[key]
			node.show()
			node.multimesh.instance_count=groups[group].size()
			for i in groups[group].size():node.multimesh.set_instance_transform(i,groups[group][i]*parts[p].transform)
	for key in batches:
		var tokens: PackedStringArray=String(key).split(":")
		if not groups.has(tokens[0]+":"+tokens[1]):batches[key].hide()

func fly(kind: String, start: Vector3, species: int, accepted_index: int = -1, delay: float = 0.0) -> void:
	var items=goods if kind=="Goods" else raw
	var index=accepted_index if accepted_index>=0 else items.size()-1
	if index<0 or index>=items.size():return
	var key=item_key(kind,index)
	if flights.has(key):return
	var path=world.PROPS+"Package_1.fbx" if kind=="Goods" else world.FISH+Economy.SPECIES[species]+".fbx"
	var actor=world.normalized_model(path,self,Vector3.ZERO,world.PACKAGE_LENGTH if kind=="Goods" else world.FISH_LENGTH,0.0 if kind=="Goods" else PI*0.5)
	actor.name="Flying_"+key.replace(":","_")
	if kind=="Goods":world.tint_package(actor,species)
	actor.global_position=start
	actor.set_meta("flying",true)
	flights[key]={"actor":actor,"kind":kind,"index":index}
	rebuild_batches()
	var reduced: bool=Economy.data.settings.reduced_motion
	var tween=actor.create_tween()
	if delay>0 and not reduced:tween.tween_interval(delay)
	tween.tween_method(func(t:float):
		if actor.is_inside_tree():actor.global_position=start.lerp(to_global(item_home(kind,index)),t)+Vector3.UP*sin(t*PI)*(0.08 if reduced else 1.0),0.0,1.0,0.14 if reduced else 0.40)
	tween.tween_callback(func():
		flights.erase(key)
		actor.queue_free()
		rebuild_batches())
