extends RefCounted
## Live juicy-loop regression. Fixtures never save over the player's data.
var tree:SceneTree
var root:Window
var checks=0
var failures:Array[String]=[]
func check(ok:bool,label:String):
	checks+=1
	if not ok:failures.append(label)
	print(("PASS " if ok else "FAIL ")+label)
func frames(n:int=1):
	for i in n:await tree.physics_frame
	await tree.process_frame
func _run():
	var h=tree.current_scene
	var economy=root.get_node("Economy")
	var saved=economy.data.duplicate(true)
	var saving:bool=economy.saving_enabled
	var pos:Vector3=h.player.position
	var pause:bool=h.debug_pause_business
	var protected_save_path:String=economy.save_path
	economy.save_path="user://reel_live_validation.json"
	economy.saving_enabled=false
	h.hud.close_modal()
	h.cancel_fishing()
	h.set_process(false)
	h.player.set_physics_process(false)
	h.debug_pause_business=true
	var e=load("res://scripts/economy.gd").new()
	e.save_path="user://reel_juice_test.json"
	for suffix in ["",".bak",".tmp",".reset"]:DirAccess.remove_absolute(e.save_path+suffix)
	e.saving_enabled=false
	root.add_child(e)
	check(e.capacity()==100 and e.goods_capacity()==500,"hundreds-capable fish and package capacities")
	check(e.catch_fish(0) and e.data.raw.size()==5,"one fishing reward gives a school of five")
	e.data.raw.resize(99)
	for i in 99:e.data.raw[i]={"species":0,"value":12,"reserved":false}
	check(e.catch_fish(1) and e.data.raw.size()==100 and int(e.data.raw.back().species)==1,"last free basket slot accepts a partial school without overflow")
	check(not e.catch_fish(1) and not e.catch_fish(9),"full and invalid catches are atomic no-ops")
	e.data=e.fresh_data()
	e.catch_fish(1,1)
	e.feed_machine()
	e.process_fish()
	var total=0
	var typed=true
	for p in e.data.output:total+=e.package_value(p);typed=typed and e.package_species(p)==1
	check(e.data.output.size()==5 and total==20 and typed,"cutting makes five typed portions without multiplying fish value")
	for i in 5:e.take_output();e.stock_stall()
	var before=JSON.stringify(e.data)
	check(e.sell(2)==0 and before==JSON.stringify(e.data),"wrong requested species cannot consume market stock")
	for i in 5:e.sell(1)
	check(int(e.data.cash)==20 and e.data.stock.is_empty(),"species-specific sales preserve complete fish value")
	e.data.stock=[6]
	check(e.sell(3)==6,"legacy mixed-catch portions stay sellable to any customer")
	e.data=e.fresh_data()
	e.data.worker=true
	check(e.worker_catch(0) and e.data.worker_crate.size()==5,"worker rewards also arrive in schools of five")
	for i in 19:e.worker_catch(0)
	check(e.data.worker_crate.size()==100 and not e.worker_catch(0),"larger worker pile still has a hard capacity")
	e.data=e.fresh_data()
	e.data.output=[{"species":2,"value":7}]
	e.data.goods=[6]
	e.data.coins=99
	e.saving_enabled=true
	e.save_game()
	e.data.coins=101
	e.save_game()
	check(e.load_game() and e.package_species(e.data.output[0])==2 and e.data.goods==[6],"typed and legacy portions survive the same backward-compatible save")
	check(FileAccess.file_exists(e.save_path+".bak"),"test fixture has a real old-progress backup")
	check(e.debug_action("coins1000") and int(e.data.coins)==1101,"debug coin cheat changes the isolated authoritative wallet")
	e.data.coins=0
	check(e.load_game() and int(e.data.coins)==1101,"development cheats survive save reload")
	check(e.reset_all_data() and int(e.data.coins)==0 and e.data.raw.is_empty(),"reset clears authoritative data")
	check(not FileAccess.file_exists(e.save_path+".bak") and not FileAccess.file_exists(e.save_path+".tmp") and not FileAccess.file_exists(e.save_path+".reset"),"reset removes old backup and temporary saves")
	e.data.coins=999
	check(e.load_game() and int(e.data.coins)==0,"reset reload cannot recover previous progress")
	e.saving_enabled=false
	for suffix in ["",".bak",".tmp",".reset"]:DirAccess.remove_absolute(e.save_path+suffix)
	e.queue_free()
	# All ten supplied customers, not just the fisherman or the first skin.
	for skin in range(1,11):
		var person=load("res://scripts/people.gd").instantiate("Cliente %d"%skin)
		root.add_child(person)
		person.hide()
		var sk=person.find_child("Skeleton3D",true,false) as Skeleton3D
		var a=person.find_child("AnimationPlayer",true,false) as AnimationPlayer
		h.world.animate_person(person,"Walk_Forward",1.45)
		var origin=person.to_local(sk.global_position)
		check(Vector2(origin.x,origin.z).length()<0.001,"customer %d visual rig is centered on its actual movement and speech-bubble anchor"%skin)
		var bone=sk.find_bone("Root")
		if bone<0: bone=sk.get_parentless_bones()[0] # the CC0 fallback rig names its top bone differently
		var clean=true
		for phase in [0.0,0.25,0.5,0.75,0.999,0.0]:
			a.seek(a.current_animation_length*phase,true)
			sk.force_update_all_bone_transforms()
			clean=clean and Vector2(sk.get_bone_pose(bone).origin.x-sk.get_bone_rest(bone).origin.x,sk.get_bone_pose(bone).origin.z-sk.get_bone_rest(bone).origin.z).length()<0.001 # pinned to its rest pose
		check(clean,"customer %d has no top-level root translation or loop seam"%skin)
		a.seek(0.30,true)
		var phase=a.current_animation_position
		h.world.animate_person(person,"Walk_Forward",1.45)
		check(absf(a.current_animation_position-phase)<0.001,"customer %d movement update never restarts the walk clip"%skin)
		person.queue_free()
	# Physical, colorful 3x3 piles and exact accepted-object flight.
	economy.data=economy.fresh_data()
	for i in 27:economy.data.output.append({"species":i%4,"value":3})
	economy.data.cash=180
	economy.changed.emit()
	var pile=h.world.output_stack
	check(pile.get_child_count()==27,"output pile displays many actual package models")
	var grid=true
	for i in 9:
		var p:Vector3=pile.get_child(i).position
		grid=grid and absf(p.x-(i%3-1)*0.30)<0.001 and absf(p.z-(floori(float(i)/3)%3-1)*0.29)<0.001
	check(grid,"package pile has a real three-by-three footprint")
	check(int(pile.get_child(2).get_meta("package_species"))==2,"package appearance retains its original fish species")
	check(h.world.cash_pile.get_node("CoinPile3x3") is MultiMeshInstance3D,"dense coin pile is batched rather than dozens of draw calls")
	var source=pile.global_position+Vector3.UP*0.2
	check(economy.take_output(),"collecting a pile accepts exactly one authoritative package")
	h.world.fly_to_back("Goods",source,0)
	var stack=h.player.basket.get_node("Carried")
	var carried=stack.flights["Goods:0"].actor
	check(carried.get_meta("flying",false) and carried.global_position.distance_to(source)<0.01,"accepted package starts at the pile rather than teleporting into the backpack")
	await tree.create_timer(0.5).timeout
	check(stack.flights.is_empty() and stack.visible_items==1,"accepted package lands exactly once in the batched backpack")
	var batch=stack.batches["Goods:0:0"]
	var id=batch.get_instance_id()
	economy.data.coins+=1
	economy.changed.emit()
	check(stack.batches["Goods:0:0"].get_instance_id()==id,"wallet updates preserve the carried batch")
	# Real mesh slicing, not a package swap with a whole fish still intact.
	h.world.begin_cut_visual({"species":1,"value":20},0.8)
	h.world.advance_cut_visual(0.72)
	await tree.create_timer(0.46).timeout
	var pieces=0
	var nonempty=true
	for child in h.world.cut_stage.get_children():
		if child is MeshInstance3D:
			pieces+=1
			nonempty=nonempty and child.mesh is ArrayMesh and child.mesh.get_surface_count()>0
	check(pieces==10 and nonempty,"the supplied fish is cut into ten separate real meshes")
	h.world.cancel_cut_visual()
	check(h.world.cut_stage.get_child_count()==0 and not h.world.cut_active,"cut cancellation clears transient slices without granting output")
	# Instant merge with camera blend and exact-index remapping.
	economy.data=economy.fresh_data()
	for species in [0,0,1,2,3]:economy.catch_fish(species,1)
	h.player.position=h.world.pads.merge.node.global_position+Vector3(0,0.05,0)
	h.find_station()
	var b=h.hud.board
	var baseline=b.merge_count
	var before_camera:Transform3D=h.camera.global_transform
	h.hud.show_collection()
	check(h.camera_transition and h.camera_mode=="board" and h.world.visible,"merge entry uses the live world and begins a camera transition")
	b.begin_drag(Vector2(400,300),7)
	check(b.dragging==-1,"picking is suspended until the board camera arrives")
	await h.camera_settled
	check(h.camera.global_transform.origin.distance_to(before_camera.origin)>0.5 and not b.transitioning,"camera reaches the authored physical workbench")
	var picks=true
	for i in 16:picks=picks and b.slot_at(b.screen_for_slot(i))==i
	check(picks,"main-world projection picks all sixteen sockets")
	b.begin_drag(b.screen_for_slot(0),7)
	b.move_drag(b.screen_for_slot(1))
	b.end_drag(b.screen_for_slot(1))
	check(economy.data.raw.size()==4 and b.merge_count==baseline+1 and b.busy,"matching release commits immediately and starts one reveal")
	b.commit_preview()
	b.close()
	check(economy.data.raw.size()==4 and h.hud.modal_open,"repeat input and closing cannot interrupt or duplicate a committed merge")
	await tree.create_timer(0.70).timeout
	check(not b.busy and b.actors.size()==4 and economy.data.raw.back().reserved,"direct merge leaves one protected result and valid actor indices")
	b.close()
	check(h.camera_transition and not h.hud.joystick.enabled,"return blend keeps movement neutral")
	await h.camera_settled
	check(h.camera_mode=="follow" and not h.hud.modal_open and h.hud.joystick.enabled and h.player.basket.visible,"camera return restores the world backpack and controls")
	# Every fish in the larger inventory remains reachable across socket pages.
	economy.data=economy.fresh_data()
	economy.data.bag=3
	for i in 37:economy.catch_fish(i%4,1)
	h.hud.show_collection()
	await h.camera_settled
	b.change_page(1)
	check(b.page==1 and b.slots.size()==16 and int(b.slots[0])==16,"second page exposes exact raw-fish indices rather than copies")
	b.change_page(1)
	check(b.page==2 and b.slots.size()==5 and int(b.slots[4])==36,"last partial page exposes fish beyond the first thirty-two")
	b.change_page(1)
	check(b.page==2 and b.slots.size()==5,"next-page input is harmless at the inventory boundary")
	b.change_page(-1)
	var amount=economy.data.raw.size()
	b.begin_drag(b.screen_for_slot(0),9)
	b.move_drag(b.screen_for_slot(4))
	b.end_drag(b.screen_for_slot(4))
	check(economy.data.raw.size()==amount-1,"instant merge also consumes the exact selected fish on later pages")
	await tree.create_timer(0.65).timeout
	b.change_page(1)
	var reachable: Array[int]=[]
	b.change_page(-2)
	var unique=true
	for p in 3:
		for raw_index in b.slots.values():
			unique=unique and not raw_index in reachable
			reachable.append(raw_index)
		b.change_page(1)
	check(unique and reachable.size()==economy.data.raw.size() and 35 in reachable,"all fish remain reachable exactly once across pages after a merge")
	economy.data.raw.resize(32)
	b.rebuild()
	check(b.page==1 and b.slots.size()==16,"an emptied final page clamps safely to the preceding page")
	b.close()
	await h.camera_settled
	# At least three active species requests, including arriving customers.
	var active=0
	var bubbles=true
	for c in h.world.customers:
		if c.state=="leaving":continue
		active+=1
		bubbles=bubbles and c.person.get_node("OrderBubble").visible and c.person.get_node("OrderBubble/Fish").get_child_count()==1 and c.person.get_node("OrderBubble/Caption").text==economy.SPECIES[int(c.species)]
	check(active>=3 and bubbles,"every active customer has a visible requested-fish speech bubble")
	# Settings cancellation is harmless; destructive reset was tested on an isolated path above.
	var unchanged=JSON.stringify(economy.data)
	h.hud.show_settings()
	h.hud.request_reset()
	h.hud.cancel_reset()
	check(unchanged==JSON.stringify(economy.data),"canceling reset never changes saved progression")
	h.hud.show_debug()
	check(h.hud.modal_kind=="debug" and h.hud.debug_panel.visible and not h.hud.joystick.enabled,"developer panel is a safe gameplay modal")
	h.hud.close_modal()
	# Restore the player's real state and save behavior.
	economy.data=saved
	economy.changed.emit()
	economy.save_path=protected_save_path
	economy.saving_enabled=saving
	h.player.position=pos
	h.player.velocity=Vector3.ZERO
	h.player.set_physics_process(true)
	h.debug_pause_business=pause
	h.set_process(true)
	h.apply_settings()
	print("RESULT %d juice checks / %d failures"%[checks,failures.size()])
	return {"checks":checks,"failures":failures}
