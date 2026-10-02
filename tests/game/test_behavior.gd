extends RefCounted
var tree: SceneTree
var root: Window
var failures: Array[String] = []
var checks = 0

func check(condition: bool, title: String) -> void:
	checks += 1
	if condition: print("PASS " + title)
	else:
		failures.append(title)
		print("FAIL " + title)

func total(e: Node) -> int:
	var amount = int(e.data.coins) + int(e.data.cash)
	for key in ["raw", "queue", "worker_crate"]:
		for fish in e.data[key]: amount += int(fish.value)
	for key in ["goods", "output", "stock"]:
		for value in e.data[key]: amount += e.package_value(value)
	return amount

func _run() -> Dictionary:
	var script = load("res://scripts/economy.gd")
	var e = script.new()
	e.saving_enabled = false
	e.save_path = "user://reel_tycoon_test.json"
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(e.save_path + suffix)
	root.add_child(e)
	check(e.valid_data(e.data), "fresh data validates")
	for i in e.capacity(): check(e.catch_fish(0,1), "catch within capacity %d" % i)
	check(not e.catch_fish(0,1) and e.data.raw.size() == e.capacity(), "full basket rejects catch without loss")
	check(not e.catch_fish(-1,1) and not e.catch_fish(4,1), "invalid species rejected")
	for i in e.capacity(): e.feed_machine()
	check(e.data.raw.is_empty() and e.data.queue.size() == e.capacity() and int(e.data.coins) == 0, "feeding produces queues, never coins")
	for i in e.capacity(): e.process_fish()
	check(e.data.output.size() == e.capacity()*e.PORTIONS and e.data.queue.is_empty() and total(e) == e.capacity()*e.VALUES[0], "processing preserves raw sale value")
	for i in e.capacity()*e.PORTIONS: e.take_output()
	check(e.data.output.is_empty() and not e.take_output(), "output pickup is exact once")
	for i in e.capacity()*e.PORTIONS: e.stock_stall()
	for i in e.capacity()*e.PORTIONS: e.sell()
	check(e.data.stock.is_empty() and int(e.data.cash) == 1200 and int(e.data.coins) == 0, "sales accumulate uncollected cash")
	check(e.collect() == 1200 and e.collect() == 0 and int(e.data.coins) == 1200, "cash collection cannot duplicate rewards")
	check(e.purchase("rod") and int(e.data.coins) == 1170 and int(e.data.rod) == 1, "upgrade charges exact wallet cost")
	e.data.coins=30
	check(not e.purchase("rod") and int(e.data.coins) == 30, "unaffordable upgrade leaves wallet unchanged")
	check(not e.purchase("unknown"), "unknown upgrade cannot spend")
	e.data = e.fresh_data()
	e.catch_fish(0,1)
	e.catch_fish(1,1)
	var before = JSON.stringify(e.data.raw)
	check(e.merge(0) == -1 and JSON.stringify(e.data.raw) == before, "unrelated pair returns unchanged")
	e.catch_fish(0,1)
	check(e.merge(0) == 1 and e.data.raw.size() == 2 and e.data.discoveries[1], "explicit matching recipe merges once")
	check(total(e) == 40, "merge value does not exceed selling inputs")
	check(e.display_fish(1) and e.data.raw.size() == 1 and e.data.discoveries[1], "display consumes carried fish, preserves discovery")
	check(not e.display_fish(1) and e.data.raw.size() == 1, "duplicate display cannot consume a second fish")
	check(is_equal_approx(e.bonus("control"), 0.12), "display bonus total is exact")
	e.data = e.fresh_data()
	e.catch_fish(0,1)
	e.catch_fish(1,1)
	e.reserve_fish(0, true)
	var delivered = e.feed_machine()
	check(int(delivered.get("species", -1)) == 1 and e.data.raw.size() == 1, "cutting skips reserved fish but accepts unreserved catches")
	check(e.feed_machine().is_empty() and e.data.raw.size() == 1, "fully reserved basket is never processed automatically")
	e.reserve_fish(0, false)
	check(not e.feed_machine().is_empty(), "unchecking Keep makes fish processable again")
	e.data = e.fresh_data()
	e.catch_fish(3,1)
	e.catch_fish(3,1)
	before = JSON.stringify(e.data.raw)
	check(e.merge(3) == -1 and JSON.stringify(e.data.raw) == before, "final tier has no merge and remains intact")
	e.data = e.fresh_data()
	for i in e.QUEUE_CAP: e.data.queue.append({"species": 0, "value": 12})
	e.catch_fish(0,1)
	check(e.feed_machine().is_empty() and e.data.raw.size() == 1, "full machine queue never deletes carried fish")
	for i in e.OUTPUT_CAP: e.data.output.append(6)
	check(e.process_fish().is_empty() and e.data.queue.size() == e.QUEUE_CAP, "full output pauses processing without loss")
	for i in e.goods_capacity(): e.data.goods.append(6)
	check(not e.take_output() and e.data.output.size() == e.OUTPUT_CAP, "full package bag pauses pickup")
	for i in e.STOCK_CAP: e.data.stock.append(6)
	check(not e.stock_stall() and e.data.goods.size() == e.goods_capacity(), "full stall pauses stocking without loss")
	e.data = e.fresh_data()
	check(not e.worker_catch(0,1), "unhired worker cannot produce")
	e.data.worker = true
	for i in e.WORKER_CAP: e.worker_catch(0,1)
	check(not e.worker_catch(0,1) and e.data.worker_crate.size() == e.WORKER_CAP and int(e.data.coins) == 0, "full worker crate stops production, not cash")
	for i in e.WORKER_CAP: e.take_worker()
	check(not e.take_worker() and e.data.raw.size() == e.capacity() and e.data.worker_crate.is_empty(), "worker pickup honors basket capacity")
	e.data = e.fresh_data()
	e.catch_fish(0,1)
	e.data.raw[0].value = 13
	e.feed_machine()
	e.process_fish()
	check(e.data.output.map(func(p):return e.package_value(p)) == [3,3,3,2,2], "odd fish values split without multiplication")
	e.data = e.fresh_data()
	e.data.displayed[0] = true
	for i in 50:
		e.data.stock.append(6)
		e.sell()
	check(int(e.data.cash) == 318 and int(e.data.sale_fraction) == 0, "small sale bonuses accumulate exactly without per-portion rounding")
	e.data = e.fresh_data()
	e.data.coins = 215
	check(e.purchase("worker") and e.purchase("dock") and int(e.data.coins) == 15, "worker and expansion costs are exact")
	check(not e.purchase("worker") and not e.purchase("dock"), "one-time expansions cannot be bought twice")
	e.catch_fish(0,1)
	e.catch_fish(1,1)
	e.feed_machine()
	e.process_fish()
	e.take_output()
	e.stock_stall()
	e.sell()
	e.display_fish(1)
	e.data.rod = 2
	e.data.bag = 1
	e.data.settings.toggle_reel = true
	e.data.sale_fraction = 36
	e.saving_enabled = true
	e.save_game()
	var saved = e.data.duplicate(true)
	e.data = e.fresh_data()
	check(e.load_game() and e.data == saved, "save/load restores all committed state and settings")
	e.data.coins = 99
	e.save_game()
	var corrupt = FileAccess.open(e.save_path, FileAccess.WRITE)
	corrupt.store_string("broken save")
	corrupt.close()
	e.data = e.fresh_data()
	check(e.load_game() and int(e.data.coins) == int(saved.coins), "corrupted primary recovers valid backup")
	var bad = e.fresh_data()
	bad.raw.append({"species": -1, "value": 12})
	check(not e.valid_data(bad), "invalid saved species rejected")
	bad = e.fresh_data()
	bad.settings.sfx = "oops"
	check(not e.valid_data(bad), "invalid saved settings rejected")
	bad = e.fresh_data()
	bad.coins = 0.5
	check(not e.valid_data(bad), "fractional saved wallet quantities rejected")
	for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(e.save_path + suffix)
	e.saving_enabled = false
	e.queue_free()
	# Integration exercises the live scene, preserving the player's state.
	var hub = tree.current_scene
	var economy = root.get_node("Economy")
	var original: Dictionary = economy.data.duplicate(true)
	var original_position: Vector3 = hub.player.position
	var original_saving: bool = economy.saving_enabled
	var protected_save_path:String=economy.save_path
	economy.save_path="user://reel_live_validation.json"
	economy.saving_enabled = false
	economy.data = economy.fresh_data()
	economy.changed.emit()
	hub.focus_paused = false
	hub.hud.close_modal()
	check(not hub.walkable(Vector3(0, 0, -5)) and hub.walkable(Vector3(-5, 0, -5)), "shore and dock bounds prevent water walking")
	hub.player.position = Vector3(-3.98, 0.05, -1.72)
	Input.action_press("move_up")
	Input.action_press("move_right")
	var stayed_on_land = true
	for i in 20:
		await tree.physics_frame
		if not hub.walkable(hub.player.position): stayed_on_land = false
	Input.action_release("move_up")
	Input.action_release("move_right")
	check(stayed_on_land, "diagonal dock corners cannot slip into water")
	hub.player.position = Vector3(-5, 0.05, -7.35)
	await tree.process_frame
	hub.find_station()
	hub.interact()
	await tree.create_timer(2.2).timeout
	check(hub.fishing_state == "reeling", "cast anticipation, float and bite start minigame")
	hub.hud.held = true
	await tree.create_timer(5.1).timeout
	hub.hud.held = false
	check(economy.data.raw.size() == 5 and hub.fishing_state == "idle", "forgiving tutorial fishing lands a real catch")
	hub.interact()
	Input.action_press("move_down")
	await tree.create_timer(0.12).timeout
	Input.action_release("move_down")
	check(hub.fishing_state == "idle" and economy.data.raw.size() == 5, "movement cancels fishing without inventory loss")
	hub.player.position = Vector3(-5, 0.05, -7.35)
	await tree.process_frame
	hub.find_station()
	hub.interact()
	await tree.create_timer(2.2).timeout
	hub.strain = 0.85
	hub._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await tree.create_timer(0.7).timeout
	check(hub.fishing_state == "reeling" and is_equal_approx(hub.strain, 0.85), "focus loss pauses fishing without losing progress")
	hub._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	hub.hud.held = false
	await tree.create_timer(0.5).timeout
	check(hub.strain < 0.7, "releasing action cools line tension")
	hub.strain = 1.0
	hub.hud.held = true
	await tree.create_timer(0.8).timeout
	hub.hud.held = false
	check(hub.fishing_state == "idle" and economy.data.raw.size() == 5, "sustained maximum tension snaps line with no fish loss")
	economy.catch_fish(1,1)
	economy.catch_fish(2,1)
	var expected = total(economy)
	hub.player.position = hub.world.pads.cut.node.global_position+Vector3(0,0.05,0)
	await tree.create_timer(7.5).timeout
	check(economy.data.raw.is_empty() and economy.data.output.size() == 35, "CUT pad feeds fish and machine visibly produces output")
	hub.player.position = Vector3(1.75, 0.05, 4.4)
	await tree.create_timer(3.0).timeout
	check(economy.data.goods.size() == 35 and economy.data.output.is_empty(), "OUT pad carries packages separately")
	hub.player.position = Vector3(4.8, 0.05, 5.1)
	await tree.create_timer(3.0).timeout
	check(economy.data.goods.is_empty(), "STOCK pad delivers carried packages")
	var wait_time = 0.0
	while not economy.data.stock.is_empty() and wait_time < 35:
		await tree.create_timer(0.5).timeout
		wait_time += 0.5
	check(economy.data.stock.is_empty() and int(economy.data.cash) == expected, "human queue buys stock and leaves exact cash")
	hub.player.position = Vector3(7.8, 0.05, 5.6)
	await tree.create_timer(0.6).timeout
	check(int(economy.data.coins) == expected and int(economy.data.cash) == 0 and total(economy) == expected, "complete catch-to-cash loop conserves value")
	economy.data.coins = 200
	economy.changed.emit()
	hub.player.position = hub.world.pads.rod.node.global_position+Vector3(0,0.05,0)
	await tree.create_timer(0.5).timeout
	hub.player.position = hub.world.pads.rod.node.global_position+Vector3(0,0.05,-2)
	await tree.create_timer(0.15).timeout
	check(int(economy.data.rod) == 0 and int(economy.data.coins) == 200, "leaving an upgrade pad cancels deliberate purchase")
	hub.player.position = hub.world.pads.rod.node.global_position+Vector3(0,0.05,0)
	await tree.create_timer(1.5).timeout
	check(int(economy.data.rod) == 1 and int(economy.data.coins) == 170, "dwell purchase visibly upgrades rod with exact cost")
	await tree.create_timer(1.5).timeout
	check(int(economy.data.rod) == 1 and int(economy.data.coins) == 170, "remaining on pad cannot buy twice")
	economy.purchase("worker")
	hub.worker_time = 3.9
	await tree.create_timer(0.3).timeout
	check(economy.data.worker_crate.size() == 5 and hub.world.worker.visible, "hired fisher appears and fills visible crate")
	economy.data.coins = 200
	economy.purchase("dock")
	check(hub.world.second_dock.visible and hub.walkable(Vector3(5, 0, -5)), "expansion activates real second dock")
	economy.data = economy.fresh_data()
	for i in 4: economy.catch_fish(0,1)
	hub.player.position = hub.world.pads.merge.node.global_position+Vector3(0,0.05,0)
	hub.find_station()
	hub.hud.show_collection()
	await hub.camera_settled
	hub.hud.confirm_merge(0)
	hub.hud.commit_merge(0)
	hub.hud.commit_merge(0)
	check(economy.data.raw.size() == 3 and economy.data.raw.back().reserved, "merge confirmation commits one pair and protects the result")
	await tree.create_timer(0.65).timeout
	hub.hud.display_species(1)
	check(economy.data.displayed[1] and hub.world.displays[1].visible and economy.data.raw.size() == 2, "display UI consumes one fish and activates visible bonus")
	hub.hud.close_modal()
	await hub.camera_settled
	hub.cancel_fishing()
	hub.hud.held = false
	economy.data = original
	economy.changed.emit()
	hub.player.position = original_position
	economy.save_path=protected_save_path
	economy.saving_enabled = original_saving
	hub.machine_time = 0
	hub.worker_time = 0
	hub.sale_time = 0
	hub.hud.toast("Playtest complete")
	print("RESULT %d checks / %d failures" % [checks, failures.size()])
	return {"checks": checks, "failures": failures}
