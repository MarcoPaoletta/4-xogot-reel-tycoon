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
	check(not e.saving_enabled and e.save_path!="user://reel_tycoon_v1.json","validation cannot write the unresolved gameplay save")
	var saved=e.data.duplicate(true)
	var process=h.is_processing();var physics=h.player.is_physics_processing();var pause=h.debug_pause_business
	var position:Vector3=h.player.position;var camera:Transform3D=h.camera.transform
	h.set_process(false);h.player.set_physics_process(false);h.debug_pause_business=true
	h.hud.close_modal()
	if h.camera_transition:await h.camera_settled
	check(not h.player.basket.has_node("Crate") and h.player.basket.has_node("Carried"),"wooden back box is removed, not the full-size inventory attachment")
	for i in 4:check(not h.world.get_node("MergeGarden").has_node("DisplayWater%d"%i),"barrel %d has no blue top disc"%i)
	check(h.world.machines.size()==5 and h.world.fishers.size()==6 and h.world.markets.size()==3,"authored world has five saws, seven fishers and three stalls")
	check(h.world.pads.size()==45,"all forty-five authored station footprints bind without duplicated IDs")
	e.data=e.fresh_data();e.data.coins=20000;e.data.dock=true;e.data.worker=true;e.data.expansions.docks=[true,true]
	for kind in ["machine4","machine5","worker5","worker6","worker7"]:
		var coins=int(e.data.coins);var cost=e.upgrade_cost(kind)
		check(e.purchase(kind) and int(e.data.coins)==coins-cost,"%s charges its exact whole purchase price"%kind)
		coins=int(e.data.coins)
		check(not e.purchase(kind) and int(e.data.coins)==coins,"%s cannot be bought twice"%kind)
	for slot in range(4,7):check(h.world.fishers[slot].visible and e.fisher_dock(slot)==slot%4,"new fisher %d shares an existing bought pier and becomes visible"%slot)
	for machine in e.data.expansions.machines:machine.purchased=true
	for fisher in e.data.expansions.fishers:fisher.hired=true
	e.changed.emit()
	for slot in 5:
		e.data.raw.append({"species":slot%4,"value":e.VALUES[slot%4],"reserved":false});e.feed_machine(slot)
	h.machine_time=0;h.extra_machine_times=[0.0,0.0,0.0,0.0]
	h.update_business(0.96)
	for slot in 5:
		var value=0
		for item in e.output_for(slot):value+=e.package_value(item)
		check(e.output_for(slot).size()==5 and e.queue_for(slot).is_empty() and value==e.VALUES[slot%4],"live saw %d makes five exact-value packages independently"%slot)
	h.worker_time=0;h.extra_worker_times=[0.0,0.0,0.0,0.0,0.0,0.0]
	h.update_business(4.01)
	for slot in 7:check(e.crate_for(slot).size()==5,"live fisher %d adds one five-fish school to its own crate"%slot)
	# Three complete customer queues draw from one truthful warehouse and cash balance.
	e.data=e.fresh_data();e.data.discoveries=[true,true,true,true]
	for i in 90:e.data.stock.append({"species":i%4,"value":3})
	e.changed.emit()
	var active=0
	for c in h.world.customers:
		if c.state=="leaving":continue
		active+=1;c.state="waiting";c.species=int(c.slot)%4;c.remaining=5
		c.person.global_position=h.world.customer_target(int(c.slot))
	check(active==9,"nine simultaneous customer slots belong to the three editable stalls")
	h.sale_time=0;h.update_business(0.36)
	check(e.data.stock.size()==81 and int(e.data.cash)==27 and int(e.data.coins)==0,"nine customers consume nine packages exactly once, never multiplying cash")
	var shown=0
	for stall in 3:shown+=h.world.market_stock(stall).get_child_count()
	check(shown==81,"three stock piles partition, rather than duplicate, displayed stock")
	for c in h.world.customers:
		if c.state=="leaving":continue
		var bubble=c.person.get_node("OrderBubble")
		check(bubble.get_node("Icon").billboard==0 and bubble.get_node("Caption").billboard==0 and bubble.global_basis.is_equal_approx(h.camera.global_basis.orthonormalized()),"customer %d has one coherent camera-facing card"%int(c.slot))
		check(bubble.get_node("Caption").text==e.SPECIES[int(c.species)] and bubble.get_node("Progress").text=="1 / 5 packages","customer %d card shows truthful species and accepted progress"%int(c.slot))
	# Cancellable green fill never means partial spending.
	e.data=e.fresh_data();e.data.coins=2000;e.changed.emit()
	h.player.position=h.world.pads.machine4.position+Vector3.UP*0.05;h.find_station();h.dwell_time=0
	h.update_stations(0.45);h.world.update_zone_feedback(h.nearest_station,h.dwell_time)
	check(absf(float(h.world.pads.machine4.material.get_shader_parameter("progress"))-0.5)<0.001 and int(e.data.coins)==2000,"half-green new saw plot has not spent any coins")
	h.player.position=Vector3(0,0,8);h.find_station();h.world.update_zone_feedback(h.nearest_station,h.dwell_time)
	check(float(h.world.pads.machine4.material.get_shader_parameter("progress"))<0 and not e.machine_owned(3),"leaving cancels the green reveal and purchase")
	check(h.world.pads.machine4.label.text=="760","build price is a price, not a misleading partial-investment fraction")
	# V6 checksummed purchases/cargo migrate by append-only defaults.
	var isolated=load("res://scripts/economy.gd").new();isolated.save_path="user://reel_v7_migration_test.json";isolated.saving_enabled=false
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(isolated.save_path+suffix)
	root.add_child(isolated)
	var old=isolated.fresh_data();old.expansions.machines.resize(2);old.expansions.fishers.resize(3)
	old.coins=777;old.expansions.machines[0].purchased=true;old.expansions.machines[0].output=[{"species":2,"value":7}]
	var payload=JSON.stringify(old);var file=FileAccess.open(isolated.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"payload":payload,"checksum":payload.sha256_text()}));file.close()
	check(isolated.load_game() and int(isolated.data.coins)==777 and isolated.data.expansions.machines.size()==4 and isolated.data.expansions.fishers.size()==6,"actual older expansion payload loads without erasing purchases or wallet")
	check(isolated.output_for(1)==[{"species":2,"value":7}] and not isolated.machine_owned(3) and not isolated.fisher_hired(6),"new slots are empty and locked; old species/value cargo is unchanged")
	for suffix in ["",".bak",".tmp"]:DirAccess.remove_absolute(isolated.save_path+suffix)
	isolated.queue_free()
	# Real board is centered; optional actions fit a short toolbar beneath all sockets.
	e.data=e.fresh_data()
	for i in 20:e.data.raw.append({"species":i%3,"value":12,"reserved":false})
	e.changed.emit();h.player.position=h.world.pads.merge.position+Vector3.UP*0.05;h.find_station();h.hud.show_collection()
	if h.camera_transition:await h.camera_settled
	var b=h.hud.board
	var middle=Vector2.ZERO
	for socket in 16:middle+=b.screen_for_slot(socket)
	middle/=16
	check(absf(middle.x-640)<6 and absf(middle.y-360)<80,"physical merge grid is centered in the actual world camera")
	check(b.surface.get_global_rect().size.x>1200 and b.get_node("Details").size.y<100 and not b.bonus.visible,"merge UI has full-width picking and a short toolbar, not a crowded sidebar")
	check(b.display_button.size.x<220 and b.previous_button.visible and b.next_button.visible,"compact optional controls retain readable inventory pagination")
	b.change_page(1)
	check(b.page==1 and b.presentation.size()==32,"simplification retains access to every fish beyond sixteen sockets")
	h.hud.close_modal()
	if h.camera_transition:await h.camera_settled
	e.data=saved;e.changed.emit();h.player.position=position;h.camera.transform=camera
	h.debug_pause_business=pause;h.set_process(process);h.player.set_physics_process(physics);h.apply_settings()
	print("RESULT %d V7 checks / %d failures"%[checks,failures.size()])
	return {"checks":checks,"failures":failures}
