extends CanvasLayer
## Authored HUD scene: this script binds controls, it does not construct the UI.
signal action_pressed
signal action_released
var hub: Node3D
@onready var root: Control = $Interface
@onready var play: Control = $Interface/Play
@onready var joystick: Control = $Interface/Play/Joystick
@onready var coins: Label = $Interface/Play/Wallet/Coins
@onready var inventory: Label = $Interface/Play/Inventory/FishCount
@onready var goods_label: Label = $Interface/Play/Inventory/GoodsCount
@onready var objective: Label = $Interface/Play/Quest/Objective
@onready var business_status: Label = $Interface/Play/Quest/Status
@onready var toast_label: Label = $Interface/Play/Toast
@onready var action_button: Button = $Interface/Play/Action
@onready var context_label: Label = $Interface/Play/ActionHint
@onready var fish_panel: Panel = $Interface/Play/Fishing
@onready var fish_title: Label = $Interface/Play/Fishing/Title
@onready var progress: ProgressBar = $Interface/Play/Fishing/Progress
@onready var tension: ProgressBar = $Interface/Play/Fishing/Tension
@onready var tension_text: Label = $Interface/Play/Fishing/TensionLabel
@onready var landed: Label = $Interface/Play/Fishing/Landed
@onready var dwell: ProgressBar = $Interface/Play/Dwell
@onready var guide: Label = $Interface/Play/Guide
@onready var board: Control = $Interface/MergeBoard
@onready var settings: Control = $Interface/Settings
@onready var debug_panel: Control = $Interface/DebugPanel
@onready var reset_confirm: Control = $Interface/ResetConfirm
@onready var cutter_view: Control = $Interface/CutterView
@onready var station_badges: Control = $Interface/Play/StationLabels
var queued_modal: String = ""
var reset_pending: bool = false
var modal_open: bool = false
var modal_kind: String = ""
var held: bool = false
var touch_action_id: int = -1
var toast_time: float = 0
var coin_display: float = 0
var merge_committing: bool = false
var danger_last: bool = false
const NAVY = Color("173e50")
const MINT = Color("36bfa5")
const GOLD = Color("f4bb48")

func style(color: Color, radius: int = 12) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	return s

func _ready() -> void:
	hub = get_parent()
	board.hud = self
	board.bind_workbench(hub.get_node("Lakeside/MergeGarden/Workbench"), hub.get_node("FollowCamera"))
	debug_panel.hud = self
	cutter_view.get_node("Close").pressed.connect(close_modal)
	settings.get_node("Debug").visible = OS.is_debug_build()
	settings.get_node("Debug").pressed.connect(show_debug)
	settings.get_node("Reset").pressed.connect(request_reset)
	reset_confirm.get_node("Panel/Cancel").pressed.connect(cancel_reset)
	reset_confirm.get_node("Panel/Confirm").pressed.connect(confirm_reset)
	$Interface/Play/Collection.pressed.connect(show_collection)
	$Interface/Play/SettingsButton.pressed.connect(show_settings)
	$Interface/Settings/Close.pressed.connect(close_modal)
	action_button.button_down.connect(func():
		if touch_action_id == -1:
			held = true
			action_pressed.emit())
	action_button.button_up.connect(func():
		if touch_action_id == -1:
			held = false
			action_released.emit())
	for key in ["music", "sfx"]:
		var slider: HSlider = settings.get_node(key)
		slider.value = Economy.data.settings[key]
		slider.value_changed.connect(func(value): Economy.update_setting(key, value))
	for key in ["toggle_reel", "assist", "reduced_motion", "low_quality"]:
		var toggle: CheckButton = settings.get_node(key)
		toggle.button_pressed = Economy.data.settings[key]
		toggle.toggled.connect(func(value): Economy.update_setting(key, value); hub.apply_settings())
	Economy.changed.connect(refresh)
	coin_display = float(Economy.data.coins)
	board.hide()
	settings.hide()
	fish_panel.hide()
	dwell.hide()
	refresh()


func _process(delta: float) -> void:
	coin_display = move_toward(coin_display, float(Economy.data.coins), maxf(30, absf(coin_display - float(Economy.data.coins)) * 7) * delta)
	coins.text = "%d" % int(round(coin_display))
	toast_time -= delta
	toast_label.visible = toast_time > 0 and not modal_open
	toast_label.modulate.a = clampf(toast_time * 2, 0, 1)
	update_orders()
	if cutter_view.visible: update_cutter_view()

func refresh() -> void:
	if inventory == null: return
	inventory.text = "%d / %d" % [Economy.data.raw.size(), Economy.capacity()]
	goods_label.text = "%d / %d" % [Economy.data.goods.size(), Economy.goods_capacity()]
	var steps = ["Your first catch", "Bring your catch to Cut", "Pick up your packages", "Stock the lakeside market", "Collect your earnings", "A better rod awaits", "Discover something rare"]
	objective.text = steps[mini(6, int(Economy.data.tutorial))]
	$Interface/Play/Quest/Progress.value = mini(6, int(Economy.data.tutorial))
	$Interface/Play/Quest/Progress.visible = int(Economy.data.tutorial)<6
	$Interface/Play/Quest/Overline.text = "NEXT STEP" if int(Economy.data.tutorial)<6 else "YOUR NEXT GOAL"
	if Economy.data.raw.size() >= Economy.capacity(): business_status.text = "Basket full · deliver or merge"
	elif Economy.data.output.size() >= Economy.OUTPUT_CAP: business_status.text = "Output full · pick up packages"
	elif not Economy.data.goods.is_empty(): business_status.text = "Take your packages to STOCK"
	elif int(Economy.data.cash) > 0: business_status.text = "Coin pile ready at CASH"
	elif not Economy.data.stock.is_empty(): business_status.text = "Market stocked · customers are buying"
	else: business_status.text = "Catch → Cut → Stock → Sell"

func update_orders() -> void:
	if hub == null or not hub.initialized: return
	var active: Array = []
	for customer in hub.world.customers:
		if customer.state != "leaving": active.append(customer)
	active.sort_custom(func(a,b): return int(a.slot)<int(b.slot))
	var on_screen = 0
	for customer in active:
		var point = hub.camera.unproject_position(customer.person.get_node("OrderBubble").global_position)
		if get_viewport().get_visible_rect().grow(-100).has_point(point): on_screen += 1
	$Interface/Play/Orders.visible = on_screen == 0
	for i in 3:
		var label: Label = $Interface/Play/Orders.get_node("Order%d"%i)
		if i >= active.size(): label.text = "Next customer arriving…"; continue
		var customer: Dictionary = active[i]
		var species = int(customer.get("species",0))
		var have = Economy.PORTIONS-int(customer.get("remaining",Economy.PORTIONS))
		label.text = "%s · %d/%d" % [Economy.SPECIES[species],have,Economy.PORTIONS]
		label.modulate = Color("1a6550") if Economy.stock_count(species)>0 else Color("283e45")

func toast(text: String) -> void:
	toast_label.text = text
	toast_time = 3.2

func context(text: String, caption: String, enabled: bool = true) -> void:
	context_label.text = text
	action_button.disabled = not enabled
	var title = "CAST" if caption.begins_with("CAST") else ("REEL" if "REEL" in caption or "TOGGLE" in caption else ("MERGE" if "MERGE" in caption else ("SAW" if "SAW" in caption else "WALK")))
	if not enabled:
		if "PICKING" in caption: title = "PICK UP"
		elif "STOCKING" in caption: title = "STOCK"
		elif "COLLECTING" in caption or "CASH" in caption: title = "CASH"
		elif "FULL" in caption or "BLOCKED" in caption: title = "FULL"
		elif "EMPTY" in caption: title = "EMPTY"
		elif "FISH" in caption: title = "FISH"
		elif "BUY" in caption: title = "BUY"
		elif "NEED" in caption: title = "NEED"
		elif "COMPLETE" in caption: title = "DONE"
	action_button.text = "\n" + title
	var icon = preload("res://ui/icons/hook.svg")
	if title == "MERGE": icon = preload("res://ui/icons/book.svg")
	elif title == "SAW": icon = preload("res://ui/icons/saw.svg")
	elif hub.world.pad_kind(hub.nearest_station) in ["out","stock"]: icon = preload("res://ui/icons/box.svg")
	elif hub.nearest_station == "cash": icon = preload("res://ui/icons/coin.svg")
	elif hub.world.pad_kind(hub.nearest_station) in ["cut","crate"]: icon = preload("res://ui/icons/fish.svg")
	action_button.get_node("Icon").texture = icon
	action_button.get_node("Key").visible = true
	action_button.get_node("Key").text = "SPACE" if enabled else ("MOVE" if title=="WALK" else ("STAND" if hub.world.is_purchase_pad(hub.nearest_station) else "AUTO"))

func show_cutter() -> void:
	if modal_open or hub.camera_transition or hub.world.pad_kind(hub.nearest_station) != "cut": return
	lock_ui("cutter")
	cutter_view.show()
	hub.focus_cutter()

func update_cutter_view() -> void:
	var machine = hub.world.machine_factory(hub.cutter_slot)
	cutter_view.get_node("Readout/Species").text = "%s · %d / 10 slices"%[Economy.SPECIES[machine.species],machine.cut_count] if machine.active else "Feed another catch at CUT"
	cutter_view.get_node("Readout/Progress").value = machine.cut_count

func fishing(species: int, state: String, landing: float, strain: float, warning: bool) -> void:
	fish_panel.visible = state != "idle" and not modal_open
	if state == "idle": return
	fish_title.text = Economy.SPECIES[species] + "  ·  " + Economy.RARITIES[species]
	progress.value = landing
	landed.text = "%d%% LANDED" % int(landing * 100)
	tension.value = strain
	var danger = strain > 0.82 or warning
	tension_text.text = "! Lunge — let go" if warning else ("! Release to cool" if danger else "✓ Line tension · %d%%" % int(strain * 100))
	if danger != danger_last:
		danger_last = danger
		tension.add_theme_stylebox_override("fill", style(Color("f17d68") if danger else GOLD, 7))

func lock_ui(kind: String) -> void:
	modal_open = true
	modal_kind = kind
	held = false
	touch_action_id = -1
	joystick.reset()
	joystick.enabled = false
	play.hide()
	$Interface/Dimmer.show()
	if kind in ["collection","cutter"]: $Interface/Dimmer.hide()
	hub.cancel_fishing()

func close_modal() -> void:
	if board.busy or reset_pending: return
	if reset_confirm.visible:
		cancel_reset()
		return
	if modal_kind == "returning": return
	board.deactivate()
	settings.hide()
	debug_panel.hide()
	cutter_view.hide()
	$Interface/Dimmer.hide()
	if modal_kind in ["collection","cutter"] or hub.camera_mode in ["board","cutter"]:
		modal_kind = "returning"
		hub.return_from_workbench()
		return
	finish_close_modal()

func finish_close_modal() -> void:
	modal_open = false
	modal_kind = ""
	held = false
	touch_action_id = -1
	joystick.reset()
	joystick.enabled = true
	play.show()
	var next = queued_modal
	queued_modal = ""
	if next == "settings": show_settings()
	elif next == "debug": show_debug()

func show_collection() -> void:
	if board.busy or reset_confirm.visible or modal_kind in ["collection", "cutter", "returning"]: return
	close_modal()
	lock_ui("collection")
	board.open(hub.nearest_station == "merge")

func show_settings() -> void:
	if board.busy or reset_confirm.visible: return
	if modal_kind in ["collection", "cutter", "returning"]:
		queued_modal = "settings"
		close_modal()
		return
	close_modal()
	lock_ui("settings")
	settings.show()

func show_debug() -> void:
	if not OS.is_debug_build() or board.busy or reset_confirm.visible: return
	if modal_kind in ["collection", "cutter", "returning"]:
		queued_modal = "debug"
		close_modal()
		return
	close_modal()
	lock_ui("debug")
	debug_panel.show()
	debug_panel.get_node("Panel/PauseBusiness").set_pressed_no_signal(hub.debug_pause_business)

func request_reset() -> void:
	if reset_pending or modal_kind != "settings": return
	reset_confirm.show()

func cancel_reset() -> void:
	if reset_pending: return
	reset_confirm.hide()

func confirm_reset() -> void:
	if reset_pending or not reset_confirm.visible or modal_kind != "settings": return
	reset_pending = true
	reset_confirm.get_node("Panel/Confirm").disabled = true
	if not Economy.reset_all_data():
		reset_pending = false
		reset_confirm.get_node("Panel/Confirm").disabled = false
		reset_confirm.get_node("Panel/Warning").text = "Reset could not be saved. Your current game is still loaded. Check available storage and try again."
		return
	joystick.reset()
	for action in ["move_left", "move_right", "move_up", "move_down", "interact", "menu", "debug_toggle"]: Input.action_release(action)
	# Recreate transient timers, customers, player and cameras as well as saved data.
	get_tree().call_deferred("reload_current_scene")

func update_station_badges() -> void:
	if not is_instance_valid(hub.camera) or hub.world.pads.is_empty(): return
	var viewport_size = get_viewport().get_visible_rect().size
	for badge in station_badges.get_children():
		var anchor: Vector3
		var show_badge = not modal_open
		var title = ""
		var detail = ""
		var active_badge = false
		if badge.has_meta("pad_id"):
			var id: String = badge.get_meta("pad_id")
			var pad: Dictionary = hub.world.pads[id]
			show_badge = show_badge and pad.node.is_visible_in_tree()
			# Near edge, not under the player's feet or the center stencil.
			anchor = pad.node.to_global(Vector3(0, 0.055, pad.size.y * 0.5 + 0.22))
			active_badge = id == hub.nearest_station
			var names = {"fish":"CAST", "fish2":"RARE DOCK", "cut":"CUT", "out":"OUT", "stock":"STOCK", "cash":"CASH", "merge":"MERGE", "crate":"PICK UP", "rod":"ROD", "bag":"BASKET", "machine":"CUT SPEED", "worker":"HIRE FISHER", "dock":"NEW DOCK"}
			title = names.get(id,String(pad.title) if String(pad.title)!="" else String(pad.kind).to_upper())
			match String(pad.kind):
				"fish", "fish2": detail = "Basket full" if Economy.data.raw.size() >= Economy.capacity() else "Catch 5 · Space / action"
				"cut": detail = "Output full · collect" if Economy.output_for(int(pad.machine_slot)).size() >= Economy.OUTPUT_CAP else "%d fish ready · %d queued" % [Economy.processable_count(), Economy.queue_for(int(pad.machine_slot)).size()]
				"out": detail = "%d packages ready" % Economy.output_for(int(pad.machine_slot)).size()
				"stock": detail = "%d / %d stocked" % [Economy.data.stock.size(),Economy.STOCK_CAP]
				"cash": detail = "%d coins to collect" % Economy.data.cash
				"merge": detail = "Open the workbench"
				"crate": detail = "%d / %d catches" % [Economy.crate_for(int(pad.fisher_slot)).size(),Economy.WORKER_CAP]
				_:
					var cost = Economy.upgrade_cost(id)
					show_badge = show_badge and cost >= 0
					if id in ["rod", "bag", "machine"]: title += " · %d" % (int(Economy.data[id]) + 1)
					detail = "✓ Complete" if cost < 0 else ("%d coins · stand to buy" % cost if Economy.data.coins >= cost else "%d coins · need %d" % [cost, cost - int(Economy.data.coins)])
		else:
			var id: String = badge.get_meta("station_ref")
			show_badge = false
			anchor = hub.world.labels[id].global_position
			if id == "worker": show_badge = false
			match id:
				"cut": title = "CUTTER"; detail = "Queue %d/%d · out %d/%d" % [Economy.data.queue.size(),Economy.QUEUE_CAP,Economy.data.output.size(),Economy.OUTPUT_CAP]
				"stall": title = "MARKET"; detail = "%d/%d · fish orders" % [Economy.data.stock.size(),Economy.STOCK_CAP]
				"worker": title = "FISHER CRATE"; detail = "%d/%d · stops when full" % [Economy.data.worker_crate.size(),Economy.WORKER_CAP]
		if hub.camera.is_position_behind(anchor): show_badge = false
		var point = hub.camera.unproject_position(anchor)
		badge.position = (point - Vector2(badge.size.x * 0.5, 0)).round()
		var rect: Rect2 = badge.get_global_rect()
		show_badge = show_badge and rect.position.x >= 12 and rect.end.x <= viewport_size.x - 12 and rect.position.y >= 105 and rect.end.y <= viewport_size.y - 24
		for protected in [$Interface/Play/Quest, $Interface/Play/Wallet, $Interface/Play/Inventory, $Interface/Play/Collection, $Interface/Play/SettingsButton,$Interface/Play/Orders]:
			if rect.intersects(protected.get_global_rect()): show_badge = false
		badge.visible = show_badge
		badge.get_node("Title").text = title
		badge.get_node("Subtitle").text = detail
		badge.get_node("Subtitle").visible = badge.has_meta("pad_id") and (hub.world.is_purchase_pad(String(badge.get_meta("pad_id"))) or hub.world.pad_kind(String(badge.get_meta("pad_id"))) in ["fish","fish2","merge"])
		badge.size.y = 50 if badge.get_node("Subtitle").visible else 30
		badge.modulate = Color("b8f4d9") if active_badge else Color.WHITE

func confirm_merge(species: int) -> void:
	if board.busy or board.transitioning or not board.can_merge: return
	var pair: Array[int] = []
	for slot in board.slots:
		if int(Economy.data.raw[int(board.slots[slot])].species)==species: pair.append(slot)
	if pair.size()>=2:
		board.preview.assign([pair[0],pair[1]])
		board.commit_preview()

func commit_merge(_species: int) -> void:
	# Compatibility only. Matching drops already commit immediately.
	board.commit_preview()

func display_species(species: int) -> void:
	if board.busy: return
	for slot in board.slots:
		if int(Economy.data.raw[int(board.slots[slot])].species) == species:
			board.selected = slot
			board.display_selected()
			return

func _input(event: InputEvent) -> void:
	# Godot can emit the synthetic mouse press BEFORE the native touch. The action
	# is owned by native touch, so never let that emulation toggle reeling twice.
	if not modal_open and event is InputEventMouseButton and event.device == -1 and (touch_action_id >= 0 or action_button.get_global_rect().has_point(event.position)):
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventScreenTouch or modal_open: return
	if not event.pressed and event.index == touch_action_id:
		touch_action_id = -1
		held = false
		action_button.modulate = Color.WHITE
		action_released.emit()
		get_viewport().set_input_as_handled()
	elif event.pressed and not action_button.disabled and touch_action_id == -1 and action_button.get_global_rect().has_point(event.position):
		touch_action_id = event.index
		held = true
		action_button.modulate = Color(0.86, 0.95, 0.91)
		action_pressed.emit()
		get_viewport().set_input_as_handled()

func cash_sweep(start: Vector2) -> void:
	# Cosmetic only; the saved economy was committed before this animation.
	var end = coins.get_global_rect().get_center()
	for i in (5 if Economy.data.settings.reduced_motion else 27):
		var sprite = TextureRect.new()
		sprite.texture = preload("res://ui/icons/coin.svg")
		sprite.size = Vector2(24, 24)
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		play.add_child(sprite)
		var origin = start + Vector2((i%3-1)*12,-floori(float(i)/9)*7+(floori(float(i)/3)%3-1)*9)
		sprite.position = origin
		var tween = create_tween()
		tween.tween_interval(i * 0.018)
		tween.tween_property(sprite, "position", end, 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(sprite.queue_free)
