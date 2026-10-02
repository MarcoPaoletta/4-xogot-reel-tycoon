extends RefCounted
## Duplicate imported locomotion, never modify private source resources.
static func clip(source: Animation, skeleton: Skeleton3D) -> Animation:
	var copy = source.duplicate(true) as Animation
	copy.loop_mode = Animation.LOOP_LINEAR
	# The supplied clips translate Root by 1.48m/1.90m per cycle. Hips alone
	# is NOT the root! Lock every top-level bone to rest in these runtime copies.
	# The capsule moves the whole Visual (character, basket, fish and rod).
	for track in copy.get_track_count():
		var path = String(copy.track_get_path(track))
		var bone_name = path.get_slice(":", 1)
		var bone = skeleton.find_bone(bone_name) if skeleton != null else -1
		var root_bone = bone >= 0 and skeleton.get_bone_parent(bone) == -1
		var track_type = copy.track_get_type(track)
		if root_bone:
			var rest = skeleton.get_bone_rest(bone)
			for key in copy.track_get_key_count(track):
				match track_type:
					Animation.TYPE_POSITION_3D: copy.track_set_key_value(track, key, rest.origin)
					Animation.TYPE_ROTATION_3D: copy.track_set_key_value(track, key, rest.basis.get_rotation_quaternion())
					Animation.TYPE_SCALE_3D: copy.track_set_key_value(track, key, rest.basis.get_scale())
		elif bone_name == "Hips" and track_type == Animation.TYPE_POSITION_3D:
			for key in copy.track_get_key_count(track):
				var value: Vector3 = copy.track_get_key_value(track, key)
				copy.track_set_key_value(track, key, Vector3(0, value.y, 0))
	return copy
