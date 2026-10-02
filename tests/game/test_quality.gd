extends RefCounted
var tree:SceneTree
var root:Window
var checks=0
var failures:Array[String]=[]
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures.append(label)
	print(("PASS " if ok else "FAIL ")+label)
func _run():
	var h=tree.current_scene
	var e=root.get_node("Economy")
	var saved=e.data.duplicate(true)
	var saving:bool=e.saving_enabled
	var position:Vector3=h.player.position
	var protected_save_path:String=e.save_path
	e.save_path="user://reel_live_validation.json"
	e.saving_enabled=false
	h.set_process(false)
	h.player.set_physics_process(false)
	h.debug_pause_business=true
	var b=h.hud.board
	e.data=e.fresh_data()
	e.data.settings.low_quality=true
	h.apply_settings()
	check(Engine.max_fps==30 and b.viewport.msaa_3d==Viewport.MSAA_DISABLED and not h.world.get_node("Lighting/Sun").shadow_enabled and b.sparks.amount==16,"battery saver reduces world AA, shadows and merge particle count")
	e.data.settings.low_quality=false
	h.apply_settings()
	check(Engine.max_fps==60 and b.viewport.msaa_3d==Viewport.MSAA_2X and h.world.get_node("Lighting/Sun").shadow_enabled and b.sparks.amount==42,"normal quality restores main-world lighting and merge effects")
	e.data.settings.reduced_motion=true
	for i in 2:e.catch_fish(0,1)
	h.player.position=h.world.pads.merge.node.global_position+Vector3(0,0.05,0)
	h.find_station()
	h.hud.show_collection()
	await h.camera_settled
	b.preview.assign([0,1])
	b.commit_preview()
	await tree.create_timer(0.30).timeout
	check(e.data.raw.size()==1 and e.data.raw[0].reserved and not b.busy,"reduced-motion direct merge commits once and settles quickly")
	check(not b.effect_animation.is_playing() and not b.sparks.emitting and not b.effects.get_node("Ring").visible,"reduced motion suppresses merge flashes and sparkles")
	h.world.begin_cut_visual({"species":1,"value":20},0.8)
	h.world.advance_cut_visual(0.85)
	await tree.create_timer(0.42).timeout
	var positions: Array[Vector3]=[]
	for piece in h.world.cut_stage.get_children():
		if piece is MeshInstance3D: positions.append(piece.position)
	await tree.create_timer(0.16).timeout
	var static_slices=positions.size()==10
	var slice_index=0
	for piece in h.world.cut_stage.get_children():
		if piece is MeshInstance3D:
			static_slices=static_slices and piece.position.distance_to(positions[slice_index])<0.001
			slice_index+=1
	check(static_slices,"reduced-motion fish cuts stay visible without slice bounce or feed motion")
	h.world.cancel_cut_visual()
	b.close()
	await h.camera_settled
	e.data=e.fresh_data()
	for i in 2:e.catch_fish(0,1)
	h.hud.show_collection()
	await h.camera_settled
	b.preview.assign([0,1])
	b.commit_preview()
	await tree.create_timer(0.67).timeout
	check(b.effect_animation.is_playing() and b.effects.get_node("Ring").visible,"normal instant merge plays the authored ring animation")
	h.hud.close_modal()
	check(not b.effect_animation.is_playing() and not b.sparks.emitting and not b.effects.get_node("Ring").visible and not b.is_processing_input(),"closing the world board cancels effects and picking")
	await h.camera_settled
	check(e.data.raw.size()==1 and int(e.data.coins)==0,"cosmetic merge effects never consume twice or award currency")
	e.data=saved
	e.changed.emit()
	e.save_path=protected_save_path
	e.saving_enabled=saving
	h.player.position=position
	h.player.set_physics_process(true)
	h.debug_pause_business=false
	h.set_process(true)
	h.apply_settings()
	print("RESULT %d quality checks / %d failures"%[checks,failures.size()])
	return {"checks":checks,"failures":failures}
