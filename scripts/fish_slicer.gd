extends RefCounted
## Slice the supplied fish mesh into real geometry; source resources stay untouched.
static func clip_polygon(polygon: Array, axis: int, boundary: float, keep_above: bool) -> Array:
	var clipped: Array = []
	if polygon.is_empty(): return clipped
	var previous: Dictionary = polygon.back()
	var was_inside = float(previous.p[axis]) >= boundary if keep_above else float(previous.p[axis]) <= boundary
	for current: Dictionary in polygon:
		var inside = float(current.p[axis]) >= boundary if keep_above else float(current.p[axis]) <= boundary
		if inside != was_inside:
			var t = (boundary - float(previous.p[axis])) / (float(current.p[axis]) - float(previous.p[axis]))
			clipped.append({"p":previous.p.lerp(current.p,t),"n":previous.n.lerp(current.n,t).normalized(),"uv":previous.uv.lerp(current.uv,t),"c":previous.c.lerp(current.c,t)})
		if inside: clipped.append(current)
		previous = current
		was_inside = inside
	return clipped

static func meshes(source: Node3D, count: int, cap_material: Material = null) -> Array[ArrayMesh]:
	var surfaces: Array = []
	var bounds = AABB()
	var found = false
	for node in source.find_children("*", "MeshInstance3D", true, false):
		if node.mesh == null: continue
		var transform: Transform3D = source.global_transform.affine_inverse() * node.global_transform
		var box: AABB = transform * node.get_aabb()
		bounds = bounds.merge(box) if found else box
		found = true
		for s in node.mesh.get_surface_count():
			surfaces.append({"arrays":node.mesh.surface_get_arrays(s),"transform":transform,"material":node.get_active_material(s)})
	var axis = bounds.size.max_axis_index()
	var planes: Array[float]=[bounds.position[axis]]
	var core_low=bounds.position[axis]
	var core_high=bounds.end[axis]
	if cap_material!=null:
		var areas: Array[float]=[]
		var peak=0.0
		for sample_index in range(1,24):
			var sample=core_low+bounds.size[axis]*float(sample_index)/24
			var area=hull_area(section_hull(surfaces,axis,sample))
			areas.append(area)
			peak=maxf(peak,area)
		if peak>0.00001:
			var first=-1
			var last=-1
			for i in areas.size():
				if areas[i]>=peak*0.12:
					if first<0:first=i
					last=i
			if first>=0 and last>first:
				core_low=bounds.position[axis]+bounds.size[axis]*float(first+1)/24
				core_high=bounds.position[axis]+bounds.size[axis]*float(last+1)/24
	for boundary_index in range(1,count):planes.append(lerpf(core_low,core_high,float(boundary_index)/count))
	planes.append(bounds.end[axis])
	var sections: Dictionary = {}
	if cap_material != null:
		for boundary_index in range(1,count):
			var boundary = planes[boundary_index]
			sections[boundary_index]=section_hull(surfaces,axis,boundary)
	var results: Array[ArrayMesh] = []
	for piece in count:
		var result = ArrayMesh.new()
		var lo = planes[piece]
		var hi = planes[piece+1]
		for surface in surfaces:
			var arrays: Array = surface.arrays
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
			var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var total = indices.size() if not indices.is_empty() else vertices.size()
			var tool = SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			tool.set_material(surface.material)
			var vertex_count = 0
			var normal_transform: Basis = surface.transform.basis.inverse().transposed()
			for triangle in range(0,total,3):
				var polygon: Array = []
				for corner in 3:
					var index = indices[triangle+corner] if not indices.is_empty() else triangle+corner
					polygon.append({"p":surface.transform * vertices[index],"n":(normal_transform * normals[index]).normalized() if normals.size()>index else Vector3.UP,"uv":uvs[index] if uvs.size()>index else Vector2.ZERO,"c":colors[index] if colors.size()>index else Color.WHITE})
				polygon = clip_polygon(clip_polygon(polygon,axis,lo,true),axis,hi,false)
				for i in range(1,polygon.size()-1):
					for vertex: Dictionary in [polygon[0],polygon[i],polygon[i+1]]:
						tool.set_normal(vertex.n)
						tool.set_uv(vertex.uv)
						tool.set_color(vertex.c)
						tool.add_vertex(vertex.p)
						vertex_count += 1
			if vertex_count > 0: tool.commit(result)
		if cap_material != null:
			var cap_tool=SurfaceTool.new()
			cap_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			cap_tool.set_material(cap_material)
			var cap_vertices=0
			for boundary_index in [piece,piece+1]:
				if not sections.has(boundary_index): continue
				var hull: PackedVector2Array = sections[boundary_index]
				if hull.size()<4: continue
				var boundary = planes[boundary_index]
				var normal=Vector3.ZERO
				normal[axis]=-1.0 if boundary_index==piece else 1.0
				for corner in range(1,hull.size()-2):
					for point in [hull[0],hull[corner],hull[corner+1]]:
						var vertex=Vector3.ZERO
						vertex[axis]=boundary
						vertex[(axis+1)%3]=point.x
						vertex[(axis+2)%3]=point.y
						cap_tool.set_normal(normal)
						cap_tool.set_uv(point)
						cap_tool.add_vertex(vertex)
						cap_vertices+=1
			if cap_vertices>0: cap_tool.commit(result)
		results.append(result)
	return results

static func section_hull(surfaces: Array, axis: int, boundary: float) -> PackedVector2Array:
	var points=PackedVector2Array()
	for surface in surfaces:
		var vertices: PackedVector3Array=surface.arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array=surface.arrays[Mesh.ARRAY_INDEX] if surface.arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		var total=indices.size() if not indices.is_empty() else vertices.size()
		for triangle in range(0,total,3):
			for edge in 3:
				var first=indices[triangle+edge] if not indices.is_empty() else triangle+edge
				var second=indices[triangle+(edge+1)%3] if not indices.is_empty() else triangle+(edge+1)%3
				var a: Vector3=surface.transform*vertices[first]
				var b: Vector3=surface.transform*vertices[second]
				var da=a[axis]-boundary
				var db=b[axis]-boundary
				if absf(da)<0.00001: points.append(Vector2(a[(axis+1)%3],a[(axis+2)%3]).snapped(Vector2.ONE*0.00001))
				if da*db<0:
					var p=a.lerp(b,da/(da-db))
					points.append(Vector2(p[(axis+1)%3],p[(axis+2)%3]).snapped(Vector2.ONE*0.00001))
	return Geometry2D.convex_hull(points) if points.size()>=3 else PackedVector2Array()

static func hull_area(hull: PackedVector2Array) -> float:
	var area=0.0
	for i in range(hull.size()-1):area+=hull[i].cross(hull[i+1])
	return absf(area)*0.5
