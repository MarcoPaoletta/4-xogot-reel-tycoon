extends Node
## Authoritative transactions. Visual effects never award currency.
signal changed
const MACHINE_COUNT = 5
const FISHER_COUNT = 7
const MARKET_COUNT = 3
const DEFAULT_SAVE_PATH = "user://reel_tycoon_v1.json"
const SPECIES = ["Goldfish", "Clownfish", "Puffer", "Swordfish"]
const RARITIES = ["Common", "Uncommon", "Rare", "Epic"]
const DISPLAY_BONUSES = ["+6% sale value", "+12% reel control", "+15% cutting speed", "+12% sale value"]
const VALUES = [12, 20, 34, 58]
const RECIPES = {0: 1, 1: 2, 2: 3}
const CATCH_BATCH = 5
const PORTIONS = 5
const QUEUE_CAP = 200
const OUTPUT_CAP = 1000
const STOCK_CAP = 1000
const WORKER_CAP = 100
const COLORS = [Color("ffae46"), Color("ff734d"), Color("c6df69"), Color("58b7df")]
var save_path = DEFAULT_SAVE_PATH
var data: Dictionary
var saving_enabled = true
var load_notice = ""
var batch_depth = 0
var batch_dirty = false

func _ready() -> void:
	data = fresh_data()
	load_game()

func fresh_data() -> Dictionary:
	return {"version": 1, "expansions": fresh_expansions(), "coins": 0, "raw": [], "goods": [], "queue": [], "output": [], "stock": [], "cash": 0, "sale_fraction": 0, "rod": 0, "bag": 0, "machine": 0, "worker": false, "dock": false, "worker_crate": [], "discoveries": [false, false, false, false], "displayed": [false, false, false, false], "tutorial": 0, "settings": {"sfx": 0.7, "music": 0.3, "reduced_motion": false, "toggle_reel": false, "assist": false, "low_quality": false}}

func capacity() -> int:
	return 100 + int(data.bag) * 100

func goods_capacity() -> int:
	return capacity() * PORTIONS

func bonus(kind: String) -> float:
	match kind:
		"sale": return minf(0.25, (0.06 if data.displayed[0] else 0.0) + (0.12 if data.displayed[3] else 0.0))
		"control": return 0.12 if data.displayed[1] else 0.0
		"machine": return 0.15 if data.displayed[2] else 0.0
	return 0.0

func commit() -> void:
	if batch_depth > 0:
		batch_dirty = true
		return
	changed.emit()
	if saving_enabled:
		save_game()

func catch_fish(species: int, quantity: int = CATCH_BATCH) -> bool:
	if species < 0 or species >= SPECIES.size() or quantity < 1 or data.raw.size() >= capacity(): return false
	for i in mini(quantity, capacity() - data.raw.size()):
		data.raw.append({"species":species,"value":VALUES[species],"reserved":false})
	data.discoveries[species] = true
	data.tutorial = maxi(data.tutorial, 1)
	commit()
	return true

func package_value(package: Variant) -> int:
	return int(package.value) if package is Dictionary else int(package)

func package_species(package: Variant) -> int:
	# Old saves contain untyped portions; they remain usable mixed-catch stock.
	return int(package.get("species", -1)) if package is Dictionary else -1

func stock_index(species: int = -1) -> int:
	for i in data.stock.size():
		var available = package_species(data.stock[i])
		if species < 0 or available == species or available < 0: return i
	return -1

func stock_count(species: int) -> int:
	var count = 0
	for package in data.stock:
		if package_species(package) == species or package_species(package) < 0: count += 1
	return count

func feed_machine(station: int = 0) -> Dictionary:
	var queue = queue_for(station)
	if not machine_owned(station) or data.raw.is_empty() or queue.size() >= QUEUE_CAP:
		return {}
	var index = -1
	for i in data.raw.size():
		if not data.raw[i].get("reserved", false):
			index = i
			break
	if index == -1: return {}
	var fish: Dictionary = data.raw[index]
	data.raw.remove_at(index)
	queue.append(fish)
	data.tutorial = maxi(data.tutorial, 2)
	commit()
	return fish

func process_fish(station: int = 0) -> Dictionary:
	var queue = queue_for(station)
	var output = output_for(station)
	if not machine_owned(station) or queue.is_empty() or output.size() > OUTPUT_CAP - PORTIONS: return {}
	var fish: Dictionary = queue.pop_front()
	# Five visible, species-colored portions. Their total is exactly the fish value.
	var part_value = floori(float(fish.value) / PORTIONS)
	var remainder = int(fish.value) % PORTIONS
	for i in PORTIONS:
		output.append({"species":int(fish.species), "value":int(part_value) + (1 if i < remainder else 0)})
	commit()
	return fish

func take_output(station: int = 0) -> bool:
	var output = output_for(station)
	if not machine_owned(station) or output.is_empty() or data.goods.size() >= goods_capacity():
		return false
	data.goods.append(output.pop_front())
	data.tutorial = maxi(data.tutorial, 3)
	commit()
	return true

func stock_stall() -> bool:
	if data.goods.is_empty() or data.stock.size() >= STOCK_CAP:
		return false
	data.stock.append(data.goods.pop_front())
	data.tutorial = maxi(data.tutorial, 4)
	commit()
	return true

func sell(species: int = -1) -> int:
	var index = stock_index(species)
	if index < 0: return 0
	var percent = int(round(bonus("sale") * 100.0))
	var cents = package_value(data.stock[index]) * (100 + percent) + int(data.sale_fraction)
	data.stock.remove_at(index)
	var value = floori(float(cents) / 100.0)
	data.sale_fraction = cents % 100
	data.cash += value
	commit()
	return value

func collect() -> int:
	var value = int(data.cash)
	if value == 0:
		return 0
	data.coins += value
	data.cash = 0
	data.tutorial = maxi(data.tutorial, 5)
	commit()
	return value

func upgrade_cost(kind: String) -> int:
	if kind in ["machine2","machine3","machine4","machine5"]:
		var slot=int(kind.right(1))-2
		return -1 if data.expansions.machines[slot].purchased else [220,480,760,1100][slot]
	if kind in ["dock2","dock3"]:
		var slot=int(kind.right(1))-2
		return -1 if data.expansions.docks[slot] else [240,480][slot]
	if kind in ["worker2","worker3","worker4","worker5","worker6","worker7"]:
		var slot=int(kind.right(1))-2
		return -1 if data.expansions.fishers[slot].hired else [180,360,600,900,1200,1500][slot]
	match kind:
		"rod": return 30 + int(data.rod) * 45 if int(data.rod) < 4 else -1
		"bag": return 40 + int(data.bag) * 50 if int(data.bag) < 3 else -1
		"machine": return 50 + int(data.machine) * 65 if int(data.machine) < 3 else -1
		"worker": return -1 if data.worker else 90
		"dock": return -1 if data.dock else 110
	return -1

func purchase(kind: String) -> bool:
	var cost = upgrade_cost(kind)
	if cost < 0 or int(data.coins) < cost:
		return false
	data.coins -= cost
	if kind in ["machine2","machine3","machine4","machine5"]:
		data.expansions.machines[int(kind.right(1))-2].purchased=true
	elif kind in ["dock2","dock3"]:
		data.expansions.docks[int(kind.right(1))-2]=true
	elif kind in ["worker2","worker3","worker4","worker5","worker6","worker7"]:
		data.expansions.fishers[int(kind.right(1))-2].hired=true
	elif kind == "worker" or kind == "dock":
		data[kind] = true
	else:
		data[kind] += 1
	data.tutorial = maxi(data.tutorial, 6)
	commit()
	return true

func merge(species: int) -> int:
	var indices: Array[int] = []
	for i in data.raw.size():
		if int(data.raw[i].species) == species: indices.append(i)
	return merge_indices(indices[0], indices[1]) if indices.size() >= 2 else -1

func merge_indices(first: int, second: int) -> int:
	if first == second or first < 0 or second < 0 or first >= data.raw.size() or second >= data.raw.size(): return -1
	var species = int(data.raw[first].species)
	if species != int(data.raw[second].species) or not RECIPES.has(species): return -1
	var next = int(RECIPES[species])
	var total = int(data.raw[first].value) + int(data.raw[second].value)
	data.raw.remove_at(maxi(first, second))
	data.raw.remove_at(mini(first, second))
	data.raw.append({"species": next, "value": mini(VALUES[next], total), "reserved": true})
	data.discoveries[next] = true
	commit()
	return next

func display_fish(species: int) -> bool:
	for i in data.raw.size():
		if int(data.raw[i].species) == species: return display_index(i)
	return false

func display_index(index: int) -> bool:
	if index < 0 or index >= data.raw.size(): return false
	var species = int(data.raw[index].species)
	if data.displayed[species]: return false
	data.raw.remove_at(index)
	data.displayed[species] = true
	commit()
	return true

func worker_catch(species: int, quantity: int = CATCH_BATCH, fisher: int = 0) -> bool:
	var crate = crate_for(fisher)
	if species < 0 or species > 3 or quantity < 1 or not fisher_hired(fisher) or crate.size() >= WORKER_CAP: return false
	for i in mini(quantity, WORKER_CAP - crate.size()):
		crate.append({"species":species,"value":VALUES[species],"reserved":false})
	commit()
	return true

func take_worker(fisher: int = 0) -> bool:
	var crate = crate_for(fisher)
	if not fisher_hired(fisher) or crate.is_empty() or data.raw.size() >= capacity():
		return false
	var fish: Dictionary = crate.pop_front()
	data.raw.append(fish)
	data.discoveries[int(fish.species)] = true
	commit()
	return true

func update_setting(key: String, value: Variant) -> void:
	if data.settings.has(key):
		data.settings[key] = value
		commit()

func valid_data(candidate: Variant) -> bool:
	if not candidate is Dictionary or candidate.get("version") != 1:
		return false
	for key in fresh_data():
		if key != "expansions" and not candidate.has(key): return false
	for key in ["coins", "cash", "sale_fraction", "rod", "bag", "machine", "tutorial"]:
		if not valid_integer(candidate[key]): return false
	if candidate.rod > 4 or candidate.bag > 3 or candidate.machine > 3 or candidate.sale_fraction > 99: return false
	for key in ["raw", "queue", "worker_crate"]:
		if not candidate[key] is Array: return false
		for fish in candidate[key]:
			if not fish is Dictionary or not fish.has("species") or not fish.has("value"): return false
			if not valid_integer(fish.species) or not valid_integer(fish.value): return false
			if fish.species < 0 or fish.species > 3 or fish.value < 0: return false
			if fish.has("reserved") and not fish.reserved is bool: return false
	for key in ["goods", "output", "stock"]:
		if not candidate[key] is Array: return false
		for package in candidate[key]:
			if package is Dictionary:
				if not valid_integer(package.get("value")): return false
				var species = package.get("species", -1)
				if species != -1 and (not valid_integer(species) or species > 3): return false
			elif not valid_integer(package): return false
	for key in ["discoveries", "displayed"]:
		if not candidate[key] is Array or candidate[key].size() != 4: return false
		for flag in candidate[key]:
			if not flag is bool: return false
	if not candidate.worker is bool or not candidate.dock is bool or not candidate.settings is Dictionary: return false
	if candidate.raw.size() > (100 + int(candidate.bag) * 100) or candidate.goods.size() > (100 + int(candidate.bag) * 100) * PORTIONS: return false
	if candidate.queue.size() > QUEUE_CAP or candidate.output.size() > OUTPUT_CAP or candidate.stock.size() > STOCK_CAP or candidate.worker_crate.size() > WORKER_CAP: return false
	for key in fresh_data().settings:
		if not candidate.settings.has(key): return false
		if key in ["sfx", "music"]:
			if not (candidate.settings[key] is float or candidate.settings[key] is int) or candidate.settings[key] < 0 or candidate.settings[key] > 1: return false
		elif not candidate.settings[key] is bool: return false
	if candidate.has("expansions") and not valid_expansions(candidate.expansions): return false
	for i in 4:
		if candidate.displayed[i] and not candidate.discoveries[i]: return false
	return true

func valid_integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0 and value <= 9007199254740991 and float(value) == floor(float(value))

func read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return {}
	var wrapper = parser.data
	if not wrapper is Dictionary or not wrapper.get("payload") is String or not wrapper.get("checksum") is String: return {}
	if wrapper.payload.sha256_text() != wrapper.checksum: return {}
	if parser.parse(wrapper.payload) != OK: return {}
	var candidate = parser.data
	if candidate is Dictionary and not candidate.has("sale_fraction"): candidate["sale_fraction"] = 0
	if candidate is Dictionary and not candidate.has("expansions"): candidate["expansions"] = fresh_expansions()
	if not valid_data(candidate): return {}
	# Extend only after checksum and old/new layout validation; never drop old items.
	while candidate.expansions.machines.size()<MACHINE_COUNT-1:candidate.expansions.machines.append({"purchased":false,"queue":[],"output":[]})
	while candidate.expansions.fishers.size()<FISHER_COUNT-1:candidate.expansions.fishers.append({"hired":false,"crate":[]})
	# JSON numbers are floats; normalize integer quantities for stable round-trips.
	for key in ["version", "coins", "cash", "sale_fraction", "rod", "bag", "machine", "tutorial"]: candidate[key] = int(candidate[key])
	for key in ["raw", "queue", "worker_crate"]:
		for fish in candidate[key]:
			fish.species = int(fish.species)
			fish.value = int(fish.value)
			if not fish.has("reserved"): fish["reserved"] = false
	for key in ["goods", "output", "stock"]:
		for i in candidate[key].size():
			if candidate[key][i] is Dictionary:
				candidate[key][i].species = int(candidate[key][i].get("species", -1))
				candidate[key][i].value = int(candidate[key][i].value)
			else: candidate[key][i] = int(candidate[key][i])
	for machine in candidate.expansions.machines:
		normalize_raw(machine.queue)
		normalize_packages(machine.output)
	for fisher in candidate.expansions.fishers: normalize_raw(fisher.crate)
	return candidate

func save_game() -> void:
	if not saving_enabled: return
	var payload = JSON.stringify(data)
	var file = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		push_warning("Could not save Reel Tycoon")
		return
	file.store_string(JSON.stringify({"payload": payload, "checksum": payload.sha256_text()}))
	file.close()
	if not read_save(save_path).is_empty():
		DirAccess.copy_absolute(save_path, save_path + ".bak")
	DirAccess.rename_absolute(save_path + ".tmp", save_path)

func load_game() -> bool:
	var candidate = read_save(save_path)
	if candidate.is_empty():
		candidate = read_save(save_path + ".bak")
		if not candidate.is_empty(): load_notice = "Recovered your backup save."
	if candidate.is_empty(): return false
	data = candidate
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func reserve_fish(index: int, reserved: bool) -> bool:
	if index < 0 or index >= data.raw.size(): return false
	data.raw[index].reserved = reserved
	commit()
	return true

func processable_count() -> int:
	var count = 0
	for fish in data.raw:
		if not fish.get("reserved", false): count += 1
	return count

func debug_action(command: String) -> bool:
	# Deliberate development cheats, never cosmetic reward callbacks.
	if not OS.is_debug_build(): return false
	match command:
		"coins100", "coins1000":
			data.coins = mini(int(data.coins) + (100 if command == "coins100" else 1000), 9007199254740000)
		"fish0", "fish1", "fish2", "fish3":
			if data.raw.size() + 10 > capacity(): return false
			var species = int(command.right(1))
			for i in 10: data.raw.append({"species":species, "value":VALUES[species], "reserved":false})
			data.discoveries[species] = true
			data.tutorial = maxi(data.tutorial, 1)
		"goods", "output", "stock":
			var cap = goods_capacity() if command == "goods" else OUTPUT_CAP
			var quantity = mini(40, cap - data[command].size())
			if quantity <= 0: return false
			for i in quantity: data[command].append({"species":0,"value":3})
		"upgrades":
			data.rod = 4
			data.bag = 3
			data.machine = 3
			data.worker = true
			data.dock = true
			data.tutorial = maxi(data.tutorial, 6)
		"worker":
			if not data.worker or data.worker_crate.size() >= WORKER_CAP: return false
			while data.worker_crate.size() < WORKER_CAP: data.worker_crate.append({"species":0,"value":VALUES[0],"reserved":false})
		"cut":
			if data.queue.is_empty() or data.output.size() > OUTPUT_CAP - PORTIONS: return false
			# Use the real processing transaction; values do not multiply.
			while not data.queue.is_empty() and data.output.size() <= OUTPUT_CAP - PORTIONS: process_fish()
			return true
		_: return false
	commit()
	return true

func reset_all_data() -> bool:
	var fresh = fresh_data()
	if saving_enabled:
		# Prepare and verify the new checksum first. Do not copy the old primary
		# into .bak as ordinary saving does, or reset progress could be recovered.
		var reset_path = save_path + ".reset"
		var payload = JSON.stringify(fresh)
		var file = FileAccess.open(reset_path, FileAccess.WRITE)
		if file == null: return false
		file.store_string(JSON.stringify({"payload":payload,"checksum":payload.sha256_text()}))
		file.close()
		if read_save(reset_path).is_empty():
			DirAccess.remove_absolute(reset_path)
			return false
		for suffix in [".bak", ".tmp"]:
			var path = save_path + suffix
			if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
				DirAccess.remove_absolute(reset_path)
				return false
		if DirAccess.rename_absolute(reset_path, save_path) != OK:
			DirAccess.remove_absolute(reset_path)
			return false
	data = fresh
	load_notice = ""
	changed.emit()
	return true

func fresh_expansions() -> Dictionary:
	var result={"machines":[],"docks":[false,false],"fishers":[]}
	for i in MACHINE_COUNT-1:result.machines.append({"purchased":false,"queue":[],"output":[]})
	for i in FISHER_COUNT-1:result.fishers.append({"hired":false,"crate":[]})
	return result

func fisher_dock(fisher: int) -> int:
	return fisher % 4

func machine_owned(station: int) -> bool:
	return station==0 or (station>0 and station<MACHINE_COUNT and bool(data.expansions.machines[station-1].purchased))
func queue_for(station: int) -> Array:
	return data.queue if station==0 else (data.expansions.machines[station-1].queue if station>0 and station<MACHINE_COUNT else [])
func output_for(station: int) -> Array:
	return data.output if station==0 else (data.expansions.machines[station-1].output if station>0 and station<MACHINE_COUNT else [])
func fisher_hired(fisher: int) -> bool:
	return bool(data.worker) if fisher==0 else (bool(data.expansions.fishers[fisher-1].hired) if fisher>0 and fisher<FISHER_COUNT else false)
func crate_for(fisher: int) -> Array:
	return data.worker_crate if fisher==0 else (data.expansions.fishers[fisher-1].crate if fisher>0 and fisher<FISHER_COUNT else [])
func dock_owned(dock: int) -> bool:
	return true if dock==0 else (bool(data.dock) if dock==1 else (bool(data.expansions.docks[dock-2]) if dock>=2 and dock<=3 else false))

func transfer_school(action: String, station: int = 0, quantity: int = 5) -> Array:
	var accepted: Array=[]
	batch_depth+=1
	for i in mini(quantity,20):
		var item: Variant
		match action:
			"feed":
				item=feed_machine(station)
				if item.is_empty():break
			"output":
				if output_for(station).is_empty():break
				item=output_for(station)[0]
				if not take_output(station):break
			"stock":
				if data.goods.is_empty():break
				item=data.goods[0]
				if not stock_stall():break
			"worker":
				if crate_for(station).is_empty():break
				item=crate_for(station)[0]
				if not take_worker(station):break
			_:break
		accepted.append(item)
	batch_depth-=1
	if batch_depth==0 and batch_dirty:
		batch_dirty=false
		commit()
	return accepted

func valid_raw_list(items: Variant, cap: int) -> bool:
	if not items is Array or items.size()>cap:return false
	for fish in items:
		if not fish is Dictionary or not valid_integer(fish.get("species")) or fish.species>3 or not valid_integer(fish.get("value")):return false
		if fish.has("reserved") and not fish.reserved is bool:return false
	return true
func valid_package_list(items: Variant, cap: int) -> bool:
	if not items is Array or items.size()>cap:return false
	for package in items:
		if package is Dictionary:
			if not valid_integer(package.get("value")):return false
			var species=package.get("species",-1)
			if species!=-1 and (not valid_integer(species) or species>3):return false
		elif not valid_integer(package):return false
	return true
func valid_expansions(value: Variant) -> bool:
	if not value is Dictionary:return false
	if not value.get("machines") is Array or value.machines.size() not in [2,MACHINE_COUNT-1] or not value.get("fishers") is Array or value.fishers.size() not in [3,FISHER_COUNT-1] or not value.get("docks") is Array or value.docks.size()!=2:return false
	for machine in value.machines:
		if not machine is Dictionary or not machine.get("purchased") is bool or not valid_raw_list(machine.get("queue"),QUEUE_CAP) or not valid_package_list(machine.get("output"),OUTPUT_CAP):return false
		if not machine.purchased and (not machine.queue.is_empty() or not machine.output.is_empty()):return false
	for fisher in value.fishers:
		if not fisher is Dictionary or not fisher.get("hired") is bool or not valid_raw_list(fisher.get("crate"),WORKER_CAP):return false
		if not fisher.hired and not fisher.crate.is_empty():return false
	for dock in value.docks:
		if not dock is bool:return false
	return true
func normalize_raw(items: Array) -> void:
	for fish in items:
		fish.species=int(fish.species)
		fish.value=int(fish.value)
		if not fish.has("reserved"):fish["reserved"]=false
func normalize_packages(items: Array) -> void:
	for i in items.size():
		if items[i] is Dictionary:
			items[i].species=int(items[i].get("species",-1))
			items[i].value=int(items[i].value)
		else:items[i]=int(items[i])
