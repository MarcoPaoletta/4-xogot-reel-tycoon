extends Node
## Authoritative transactions. Visual effects never award currency.
signal changed
const DEFAULT_SAVE_PATH = "user://reel_tycoon_v1.json"
const SPECIES = ["Goldfish", "Clownfish", "Puffer", "Swordfish"]
const RARITIES = ["Common", "Uncommon", "Rare", "Epic"]
const DISPLAY_BONUSES = ["+6% sale value", "+12% reel control", "+15% cutting speed", "+12% sale value"]
const VALUES = [12, 20, 34, 58]
const RECIPES = {0: 1, 1: 2, 2: 3}
var save_path = DEFAULT_SAVE_PATH
var data: Dictionary
var saving_enabled = true
var load_notice = ""

func _ready() -> void:
	data = fresh_data()
	load_game()

func fresh_data() -> Dictionary:
	return {"version": 1, "coins": 0, "raw": [], "goods": [], "queue": [], "output": [], "stock": [], "cash": 0, "sale_fraction": 0, "rod": 0, "bag": 0, "machine": 0, "worker": false, "dock": false, "worker_crate": [], "discoveries": [false, false, false, false], "displayed": [false, false, false, false], "tutorial": 0, "settings": {"sfx": 0.7, "music": 0.3, "reduced_motion": false, "toggle_reel": false, "assist": false, "low_quality": false}}

func capacity() -> int:
	return 5 + int(data.bag) * 3

func goods_capacity() -> int:
	return capacity() * 2

func bonus(kind: String) -> float:
	match kind:
		"sale": return minf(0.25, (0.06 if data.displayed[0] else 0.0) + (0.12 if data.displayed[3] else 0.0))
		"control": return 0.12 if data.displayed[1] else 0.0
		"machine": return 0.15 if data.displayed[2] else 0.0
	return 0.0

func commit() -> void:
	changed.emit()
	if saving_enabled:
		save_game()

func catch_fish(species: int) -> bool:
	if species < 0 or species >= SPECIES.size() or data.raw.size() >= capacity():
		return false
	data.raw.append({"species": species, "value": VALUES[species], "reserved": false})
	data.discoveries[species] = true
	data.tutorial = maxi(data.tutorial, 1)
	commit()
	return true

func feed_machine() -> Dictionary:
	if data.raw.is_empty() or data.queue.size() >= 10:
		return {}
	var index = -1
	for i in data.raw.size():
		if not data.raw[i].get("reserved", false):
			index = i
			break
	if index == -1: return {}
	var fish: Dictionary = data.raw[index]
	data.raw.remove_at(index)
	data.queue.append(fish)
	data.tutorial = maxi(data.tutorial, 2)
	commit()
	return fish

func process_fish() -> Dictionary:
	if data.queue.is_empty() or data.output.size() > 18:
		return {}
	var fish: Dictionary = data.queue.pop_front()
	var half = floori(float(fish.value) / 2.0)
	data.output.append(int(half))
	data.output.append(int(fish.value) - int(half))
	commit()
	return fish

func take_output() -> bool:
	if data.output.is_empty() or data.goods.size() >= goods_capacity():
		return false
	data.goods.append(data.output.pop_front())
	data.tutorial = maxi(data.tutorial, 3)
	commit()
	return true

func stock_stall() -> bool:
	if data.goods.is_empty() or data.stock.size() >= 20:
		return false
	data.stock.append(data.goods.pop_front())
	data.tutorial = maxi(data.tutorial, 4)
	commit()
	return true

func sell() -> int:
	if data.stock.is_empty():
		return 0
	# Preserve sub-coin bonuses across sales instead of rounding each portion.
	var percent = int(round(bonus("sale") * 100.0))
	var cents = int(data.stock.pop_front()) * (100 + percent) + int(data.sale_fraction)
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
	if kind == "worker" or kind == "dock":
		data[kind] = true
	else:
		data[kind] += 1
	data.tutorial = maxi(data.tutorial, 6)
	commit()
	return true

func merge(species: int) -> int:
	if not RECIPES.has(species):
		return -1
	var indices: Array[int] = []
	for i in data.raw.size():
		if int(data.raw[i].species) == species:
			indices.append(i)
	if indices.size() < 2:
		return -1
	var first = indices[0]
	var second = indices[1]
	var next = int(RECIPES[species])
	var total = int(data.raw[first].value) + int(data.raw[second].value)
	data.raw.remove_at(second)
	data.raw.remove_at(first)
	data.raw.append({"species": next, "value": mini(VALUES[next], total), "reserved": true})
	data.discoveries[next] = true
	commit()
	return next

func display_fish(species: int) -> bool:
	if species < 0 or species > 3 or data.displayed[species]:
		return false
	for i in data.raw.size():
		if int(data.raw[i].species) == species:
			data.raw.remove_at(i)
			data.displayed[species] = true
			commit()
			return true
	return false

func worker_catch(species: int) -> bool:
	if not data.worker or data.worker_crate.size() >= 5:
		return false
	data.worker_crate.append({"species": species, "value": VALUES[species], "reserved": false})
	commit()
	return true

func take_worker() -> bool:
	if data.worker_crate.is_empty() or data.raw.size() >= capacity():
		return false
	var fish: Dictionary = data.worker_crate.pop_front()
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
		if not candidate.has(key): return false
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
		for value in candidate[key]:
			if not valid_integer(value): return false
	for key in ["discoveries", "displayed"]:
		if not candidate[key] is Array or candidate[key].size() != 4: return false
		for flag in candidate[key]:
			if not flag is bool: return false
	if not candidate.worker is bool or not candidate.dock is bool or not candidate.settings is Dictionary: return false
	if candidate.raw.size() > 5 + int(candidate.bag) * 3 or candidate.goods.size() > (5 + int(candidate.bag) * 3) * 2: return false
	if candidate.queue.size() > 10 or candidate.output.size() > 20 or candidate.stock.size() > 20 or candidate.worker_crate.size() > 5: return false
	for key in fresh_data().settings:
		if not candidate.settings.has(key): return false
		if key in ["sfx", "music"]:
			if not (candidate.settings[key] is float or candidate.settings[key] is int) or candidate.settings[key] < 0 or candidate.settings[key] > 1: return false
		elif not candidate.settings[key] is bool: return false
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
	if not valid_data(candidate): return {}
	# JSON numbers are floats; normalize integer quantities for stable round-trips.
	for key in ["version", "coins", "cash", "sale_fraction", "rod", "bag", "machine", "tutorial"]: candidate[key] = int(candidate[key])
	for key in ["raw", "queue", "worker_crate"]:
		for fish in candidate[key]:
			fish.species = int(fish.species)
			fish.value = int(fish.value)
			if not fish.has("reserved"): fish["reserved"] = false
	for key in ["goods", "output", "stock"]:
		for i in candidate[key].size(): candidate[key][i] = int(candidate[key][i])
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
