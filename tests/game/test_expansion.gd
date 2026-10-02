extends RefCounted
## V6 live contract checks; never writes or resets the real player save.
var tree:SceneTree
var root:Window
var checks=0
var failures:Array[String]=[]
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures.append(label)
	print(("PASS " if ok else "FAIL ")+label)
func geometry_bounds(stack:Node3D,kind:String,species:int)->AABB:
	var result=AABB()
	var found=false
	for part in stack.geometry["%s:%d"%[kind,species]]:
		var box:AABB=part.transform*part.mesh.get_aabb()
		result=result.merge(box) if found else box
		found=true
	return result
func actor_bounds(actor:Node3D)->AABB:
	var result=AABB()
	var found=false
	for model in actor.find_children("*","MeshInstance3D",true,false):
		if model.mesh==null:continue
		var box:AABB=(actor.global_transform.affine_inverse()*model.global_transform)*model.mesh.get_aabb()
		result=result.merge(box) if found else box
		found=true
	return result
func longest(box:AABB)->float:return maxf(box.size.x,maxf(box.size.y,box.size.z))
func _run():
	var h=tree.current_scene
	var economy=root.get_node("Economy")
	var saved=economy.data.duplicate(true)
	var saving:bool=economy.saving_enabled
	var process=h.is_processing()
	var physics=h.player.is_physics_processing()
	var pause=h.debug_pause_business
	var position:Vector3=h.player.position
	var rotation:Vector3=h.player.visual.rotation
	var camera:Transform3D=h.camera.transform
	var fov:float=h.camera.fov
	var protected_save_path:String=economy.save_path
	economy.save_path="user://reel_live_validation.json"
	economy.saving_enabled=false
	h.set_process(false);h.player.set_physics_process(false);h.debug_pause_business=true
	var e=load("res://scripts/economy.gd").new()
	e.save_path="user://reel_expansion_test.json"
	e.saving_enabled=false
	for suffix in ["",".bak",".tmp",".reset"]:DirAccess.remove_absolute(e.save_path+suffix)
	root.add_child(e)
	check(e.capacity()==100 and e.goods_capacity()==500,"starting basket holds hundreds, not a visual-only cheat")
	e.data.bag=3
	check(e.capacity()==400 and e.goods_capacity()==2000,"fully upgraded basket holds 400 fish and 2000 packages")
	check(e.valid_data(e.data),"expanded fresh data validates")
	e.data.coins=9999
	for kind in ["machine2","machine3","dock2","dock3","worker2","worker3","worker4"]:
		var wallet_before=int(e.data.coins)
		var price=e.upgrade_cost(kind)
		check(e.purchase(kind) and int(e.data.coins)==wallet_before-price,"%s purchase charges its exact price"%kind)
		wallet_before=int(e.data.coins)
		check(not e.purchase(kind) and int(e.data.coins)==wallet_before,"%s cannot be purchased twice"%kind)
	check(e.machine_owned(0) and e.machine_owned(1) and e.machine_owned(2),"all three workshops are real unlocked machines")
	check(e.dock_owned(0) and e.dock_owned(1)==false and e.dock_owned(2) and e.dock_owned(3),"new port flags do not silently unlock the legacy second dock")
	for slot in 3:
		e.catch_fish(slot,1)
		var fish=e.feed_machine(slot)
		check(not fish.is_empty() and e.queue_for(slot).size()==1,"workshop %d has its own input queue"%slot)
		e.process_fish(slot)
		var value=0
		for package in e.output_for(slot):value+=e.package_value(package)
		check(e.output_for(slot).size()==5 and value==e.VALUES[slot],"workshop %d conserves the exact whole-fish value"%slot)
		var packages=e.transfer_school("output",slot)
		check(packages.size()==5 and e.output_for(slot).is_empty(),"workshop %d output is picked up exactly once"%slot)
	e.data=e.fresh_data()
	e.catch_fish(1,1)
	var before=JSON.stringify(e.data)
	check(e.feed_machine(1).is_empty() and before==JSON.stringify(e.data),"locked workshop cannot consume a fish")
	check(not e.worker_catch(2,5,2),"unhired fisher cannot produce")
	e.data.coins=0
	check(not e.purchase("machine2") and e.data.raw.size()==1,"unaffordable machine cannot consume cash or cargo")
	e.data=e.fresh_data();e.data.bag=3
	for i in 398:e.catch_fish(i%4,1)
	check(e.catch_fish(2) and e.data.raw.size()==400,"hundreds-capable catch accepts only remaining capacity")
	check(not e.catch_fish(2) and e.data.raw.size()==400,"full large basket is still lossless")
	e.data=e.fresh_data()
	for i in 7:e.catch_fish(i%4,1)
	var events={"count":0}
	e.changed.connect(func():events.count+=1)
	var school=e.transfer_school("feed")
	check(school.size()==5 and e.data.raw.size()==2 and e.data.queue.size()==5,"school transfer consumes five selected unreserved fish")
	check(events.count==1,"school transfer emits and saves once, not five times")
	e.data=e.fresh_data()
	e.data.coins=900
	e.purchase("machine2")
	e.catch_fish(3,1);e.feed_machine(1);e.process_fish(1)
	e.saving_enabled=true;e.save_game()
	var serialized=e.data.duplicate(true)
	e.data=e.fresh_data()
	check(e.load_game() and e.data==serialized,"extra machine purchases and typed output survive checksum save reload")
	var legacy=e.fresh_data();legacy.erase("expansions");legacy.coins=77;legacy.goods=[6]
	var payload=JSON.stringify(legacy)
	var file=FileAccess.open(e.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"payload":payload,"checksum":payload.sha256_text()}));file.close()
	check(e.load_game() and int(e.data.coins)==77 and e.data.goods==[6] and not e.machine_owned(1),"actual V1 payload loads with empty new plots, without losing old cargo")
	var bad=e.fresh_data();bad.expansions.machines[0].queue=[{"species":4,"value":12}]
	check(not e.valid_data(bad),"malformed extra machine save is rejected")
	bad=e.fresh_data();bad.expansions.fishers[0].hired=1
	check(not e.valid_data(bad),"invalid extra fisher flags are rejected")
	e.saving_enabled=false
	for suffix in ["",".bak",".tmp",".reset"]:DirAccess.remove_absolute(e.save_path+suffix)
	e.queue_free()
	# New build plots obey the same cancellable whole-wallet dwell contract.
	economy.data=economy.fresh_data();economy.data.coins=1000;economy.changed.emit()
	var plot=h.world.pads.machine2
	h.player.position=plot.node.global_position+Vector3.UP*0.05;h.find_station();h.dwell_time=0
	h.update_stations(0.45);h.world.update_zone_feedback(h.nearest_station,h.dwell_time)
	check(int(economy.data.coins)==1000 and absf(float(plot.material.get_shader_parameter("progress"))-0.5)<0.001,"new workshop half-dwell shows progress without spending money")
	h.player.position=Vector3(0,0,8);h.find_station();h.world.update_zone_feedback(h.nearest_station,h.dwell_time)
	check(not economy.machine_owned(1) and int(economy.data.coins)==1000 and float(plot.material.get_shader_parameter("progress"))<0,"leaving a new build plot cancels its purchase")
	h.player.position=plot.node.global_position+Vector3.UP*0.05;h.find_station();h.update_stations(1.0)
	check(economy.machine_owned(1) and int(economy.data.coins)==780 and h.world.machines[1].visible,"finished workshop dwell spends 220 once and reveals the editable machine")
	h.update_stations(1.0)
	check(int(economy.data.coins)==780,"remaining on new build plot cannot charge twice")
	# Live authored workshops run in parallel, not decorative copies.
	economy.data=economy.fresh_data()
	for machine in economy.data.expansions.machines:machine.purchased=true
	for slot in 3:
		economy.data.raw.append({"species":slot,"value":economy.VALUES[slot],"reserved":false})
		economy.feed_machine(slot)
	h.machine_time=0;h.extra_machine_times=[0.0,0.0,0.0,0.0]
	h.update_business(0.96)
	for slot in 3:check(economy.output_for(slot).size()==5 and economy.queue_for(slot).is_empty(),"live workshop %d advances its own machine clock and output"%slot)
	economy.data=economy.fresh_data();economy.data.worker=true;economy.data.dock=true;economy.data.expansions.docks=[true,true]
	for fisher in economy.data.expansions.fishers:fisher.hired=true
	h.worker_time=0;h.extra_worker_times=[0.0,0.0,0.0,0.0,0.0,0.0]
	h.update_business(4.01)
	for fisher in 4:check(economy.crate_for(fisher).size()==5,"live fisher %d produces one five-fish school, not currency"%fisher)
	h.world.cancel_cut_visual()
	# Full geometry at every accepted slot: no quality-dependent inventory caps.
	economy.data=economy.fresh_data();economy.data.bag=3
	for i in 400:economy.data.raw.append({"species":i%4,"value":12,"reserved":false})
	for i in 600:economy.data.goods.append({"species":i%4,"value":3})
	economy.changed.emit()
	var stack=h.player.basket.get_node("Carried")
	check(stack.visible_items==1000,"all one thousand carried elements are rendered, with no height/visual cap")
	check(stack.item_home("Raw",399).y>20,"hundreds stack upward instead of compressing or truncating height")
	for species in 4:
		check(absf(longest(geometry_bounds(stack,"Raw",species))-h.world.FISH_LENGTH)<0.002,"carried species %d stays at the full pickup size"%species)
		check(absf(longest(geometry_bounds(stack,"Goods",species))-h.world.PACKAGE_LENGTH)<0.002,"carried package %d stays at the full pile size"%species)
	check(stack.batches.size()<24,"hundreds of items share a small number of GPU mesh batches")
	economy.data.settings.low_quality=true;h.apply_settings();economy.changed.emit()
	check(stack.visible_items==1000,"battery saver never hides stored backpack elements")
	economy.data=economy.fresh_data();economy.data.bag=3
	for i in 37:economy.data.raw.append({"species":0,"value":12,"reserved":false})
	economy.changed.emit()
	var start=h.world.fisher_crate().global_position+Vector3.UP
	h.world.fly_to_back("Raw",start,0,36)
	var flying=stack.flights["Raw:36"].actor
	var full=longest(actor_bounds(flying))
	check(absf(full-h.world.FISH_LENGTH)<0.002 and flying.global_position.distance_to(start)<0.01,"fish beyond the old 32-item cap flies at full world size")
	await tree.create_timer(0.13).timeout
	check(absf(longest(actor_bounds(flying))-full)<0.002 and flying.scale.is_equal_approx(Vector3.ONE),"pickup arc never shrinks or stretches geometry")
	await tree.create_timer(0.38).timeout
	check(stack.flights.is_empty() and stack.visible_items==37,"above-old-cap flight lands without duplicating the accepted fish")
	# Editable environment and actual cutter animation.
	check(h.world.pads.size()==45 and h.hud.station_badges.get_child_count()==48,"all expanded station controls and badges are authored")
	check(h.world.machines.size()==5 and h.world.fishers.size()==6 and h.world.ports.size()==2,"authored expansion contains four additional saws, six hires and two ports")
	economy.data.expansions.docks=[true,true];economy.changed.emit()
	check(h.walkable(Vector3(15.5,0,-7)) and h.walkable(Vector3(26,0,-7)),"bought east ports have real walkable pier floors")
	check(h.walkable(Vector3(30,0,28)) and not h.walkable(Vector3(55,0,28)),"bigger island keeps an explicit safe boundary")
	check(h.world.get_node("Terrain/ShoreGround").mesh.size.x==90 and h.world.get_node("Terrain/ShoreGround/Solid_9836/Shape_9835").shape.size.x==90,"expanded ground and its physical collision match")
	for species in 4:
		h.world.begin_cut_visual({"species":species,"value":12},0.95)
		h.world.advance_cut_visual(1.0)
		var cutter=h.world.factory
		var real=cutter.pieces.size()==10
		for piece in cutter.pieces:real=real and piece.mesh is ArrayMesh and piece.mesh.get_surface_count()>0 and piece.scale.is_equal_approx(Vector3.ONE)
		check(real and cutter.cut_count==10,"species %d has ten real, full-scale separated fish pieces"%species)
		h.world.cancel_cut_visual()
	var before_money=int(economy.data.coins)
	h.world.begin_cut_visual({"species":1,"value":20},0.95)
	h.world.advance_cut_visual(0.37)
	check(h.world.factory.blade.position.y<0.9 and absf(h.world.factory.spin.rotation.z)>0.1,"actual saw spins and lowers through the moving feed")
	check(int(economy.data.coins)==before_money and economy.data.output.is_empty(),"cutter visuals cannot mint packages or currency")
	h.world.cancel_cut_visual()
	economy.data.settings.reduced_motion=true;h.apply_settings()
	h.world.begin_cut_visual({"species":1,"value":20},0.95);h.world.advance_cut_visual(0.8)
	check(h.world.factory.spin.rotation.is_zero_approx() and not h.world.factory.chips.emitting and float(h.world.water_material.get_shader_parameter("motion_amount"))==0,"reduced motion freezes saw spin, sparks and cartoon water")
	h.world.cancel_cut_visual()
	economy.data.settings.reduced_motion=false
	# Camera and native touch safety remain shared with the physical workbench.
	h.player.position=h.world.pads.cut.position+Vector3.UP*0.05;h.find_station()
	h.hud.show_cutter()
	check(h.camera_mode=="cutter" and h.camera_transition and not h.hud.joystick.enabled,"watching the saw locks movement during the shared-camera transition")
	await h.camera_settled
	check(is_zero_approx(h.camera.rotation.y) and h.hud.cutter_view.visible and not h.player.basket.visible,"cutter close-up stays fixed-yaw in the same editable world")
	h.hud.show_settings();await h.camera_settled
	check(h.hud.modal_kind=="settings" and h.camera_mode=="follow","settings from cutter view waits for a safe camera return")
	h.hud.close_modal()
	# Restore the actual player's data, quality settings and input.
	economy.data=saved;economy.changed.emit();economy.save_path=protected_save_path
	economy.saving_enabled=saving
	h.player.position=position;h.player.visual.rotation=rotation;h.player.velocity=Vector3.ZERO
	h.camera.transform=camera;h.camera.fov=fov
	h.debug_pause_business=pause;h.set_process(process);h.player.set_physics_process(physics)
	h.apply_settings()
	print("RESULT %d expansion checks / %d failures"%[checks,failures.size()])
	return {"checks":checks,"failures":failures}
