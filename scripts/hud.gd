extends CanvasLayer
signal action_pressed
signal action_released
signal collection_requested
signal settings_requested
var hub: Node3D
var root: Control
var joystick: Control
var coins: Label
var inventory: Label
var objective: Label
var business_status: Label
var toast_label: Label
var action_button: Button
var context_label: Label
var fish_panel: PanelContainer
var fish_title: Label
var progress: ProgressBar
var tension: ProgressBar
var tension_text: Label
var dwell: ProgressBar
var modal_layer: ColorRect
var modal_body: VBoxContainer
var modal_open = false
var modal_kind = ""
var guide: Label
var merge_committing = false
var touch_action_id = -1
var held = false
var toast_time = 0.0
var coin_display = 0.0
const NAVY = Color("163b47")
const MINT = Color("80efd0")
const GOLD = Color("ffdb79")

func style(color: Color, radius: int = 18, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	if border.a > 0:
		s.border_color = border
		s.set_border_width_all(2)
	return s

func label(text: String, font_size: int = 18, color: Color = Color.WHITE) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func button(text: String, callback: Callable, color: Color = MINT) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size.y = 46
	b.add_theme_stylebox_override("normal", style(color, 13))
	b.add_theme_stylebox_override("hover", style(color.lightened(0.12), 13))
	b.add_theme_stylebox_override("pressed", style(color.darkened(0.15), 13))
	b.add_theme_stylebox_override("disabled", style(Color("56737c"), 13))
	b.add_theme_stylebox_override("focus", style(Color.TRANSPARENT, 13, Color.WHITE))
	b.add_theme_color_override("font_color", NAVY)
	b.add_theme_color_override("font_hover_color", NAVY)
	b.add_theme_color_override("font_pressed_color", NAVY)
	b.add_theme_font_size_override("font_size", 18)
	if callback.is_valid(): b.pressed.connect(callback)
	return b

func panel() -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(Color(0.055, 0.16, 0.20, 0.94), 20))
	return p

func bar(color: Color) -> ProgressBar:
	var b = ProgressBar.new()
	b.max_value = 1
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, 16)
	b.add_theme_stylebox_override("background", style(Color("0b2734"), 8))
	b.add_theme_stylebox_override("fill", style(color, 8))
	return b

func _ready() -> void:
	root = Control.new()
	root.name = "Interface"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var top = HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 22
	top.offset_right = -22
	top.offset_top = 18
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	var wallet = panel()
	top.add_child(wallet)
	var wallet_box = VBoxContainer.new()
	wallet_box.add_theme_constant_override("separation", 0)
	wallet.add_child(wallet_box)
	wallet_box.add_child(label("REEL TYCOON", 12, MINT))
	coins = label("0 coins", 27, GOLD)
	wallet_box.add_child(coins)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	var bag = panel()
	top.add_child(bag)
	inventory = label("FISH 0 / 5   •   PACKAGES 0 / 10", 16)
	bag.add_child(inventory)
	top.add_child(button("Collection", func(): collection_requested.emit(), Color("d8f3e5")))
	top.add_child(button("Settings", func(): settings_requested.emit(), Color("d8f3e5")))
	var objective_panel = panel()
	objective_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	objective_panel.position = Vector2(22, 110)
	root.add_child(objective_panel)
	var objective_box = VBoxContainer.new()
	objective_panel.add_child(objective_box)
	objective_box.add_child(label("YOUR NEXT STEP", 11, MINT))
	objective = label("Walk to the dock → Cast", 17)
	objective_box.add_child(objective)
	business_status = label("CUT 0   ·   OUT 0   ·   STOCK 0", 12, Color("bbd8d8"))
	objective_box.add_child(business_status)
	joystick = Control.new()
	joystick.set_script(load("res://scripts/joystick.gd"))
	joystick.name = "Joystick"
	root.add_child(joystick)
	joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.offset_left = 22
	joystick.offset_top = -188
	joystick.offset_right = 182
	joystick.offset_bottom = -28
	var movement_hint = label("WASD / ARROWS", 11, Color("d9f6eb"))
	movement_hint.position = Vector2(26, 157)
	joystick.add_child(movement_hint)
	var actions = VBoxContainer.new()
	root.add_child(actions)
	actions.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.offset_left = -253
	actions.offset_right = -22
	actions.offset_top = -142
	actions.offset_bottom = -24
	context_label = label("Walk onto a station pad", 14)
	context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions.add_child(context_label)
	action_button = button("CAST  ·  SPACE", Callable())
	action_button.custom_minimum_size = Vector2(230, 62)
	action_button.button_down.connect(func():
		if touch_action_id == -1:
			held = true
			action_pressed.emit())
	action_button.button_up.connect(func():
		if touch_action_id == -1:
			held = false
			action_released.emit())
	actions.add_child(action_button)
	dwell = bar(GOLD)
	dwell.visible = false
	actions.add_child(dwell)
	fish_panel = panel()
	root.add_child(fish_panel)
	fish_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	fish_panel.offset_left = -240
	fish_panel.offset_right = 240
	fish_panel.offset_top = -181
	fish_panel.offset_bottom = -24
	var fish_box = VBoxContainer.new()
	fish_panel.add_child(fish_box)
	fish_title = label("Goldfish • HOLD TO REEL", 19, MINT)
	fish_box.add_child(fish_title)
	fish_box.add_child(label("LANDING PROGRESS", 11))
	progress = bar(MINT)
	fish_box.add_child(progress)
	tension_text = label("LINE TENSION  ·  SAFE", 11)
	fish_box.add_child(tension_text)
	tension = bar(GOLD)
	fish_box.add_child(tension)
	fish_panel.visible = false
	toast_label = label("", 20, GOLD)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(toast_label)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_left = -340
	toast_label.offset_right = 340
	toast_label.offset_top = 100
	toast_label.add_theme_color_override("font_shadow_color", NAVY)
	toast_label.add_theme_constant_override("shadow_offset_y", 2)
	guide = label("↑ CAST", 20, GOLD)
	guide.add_theme_color_override("font_shadow_color", NAVY)
	guide.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(guide)
	Economy.changed.connect(refresh)
	coin_display = float(Economy.data.coins)
	refresh()

func _process(delta: float) -> void:
	coin_display = move_toward(coin_display, float(Economy.data.coins), maxf(25, absf(coin_display - float(Economy.data.coins)) * 6) * delta)
	coins.text = "%d coins" % int(round(coin_display))
	toast_time -= delta
	toast_label.visible = toast_time > 0

func refresh() -> void:
	if inventory == null: return
	inventory.text = "FISH %d / %d  ·  PACKAGES %d / %d" % [Economy.data.raw.size(), Economy.capacity(), Economy.data.goods.size(), Economy.goods_capacity()]
	var steps = ["Walk to the dock → Cast", "Take your catch to CUT", "Pick up the OUT packages", "Deliver packages to STOCK", "Collect your sales from CASH", "Buy a better rod • 30 coins", "Merge pairs, display discoveries & hire help"]
	objective.text = steps[mini(6, int(Economy.data.tutorial))]
	business_status.text = "CUT %d  ·  OUT %d  ·  STOCK %d  ·  CASH %d" % [Economy.data.queue.size(), Economy.data.output.size(), Economy.data.stock.size(), int(Economy.data.cash)]

func toast(text: String) -> void:
	toast_label.text = text
	toast_time = 3.0

func context(text: String, caption: String, enabled: bool = true) -> void:
	context_label.text = text
	action_button.text = caption
	action_button.disabled = not enabled

func fishing(species: int, state: String, landing: float, strain: float, warning: bool) -> void:
	fish_panel.visible = state != "idle"
	if state == "idle": return
	fish_title.text = Economy.SPECIES[species] + " • " + Economy.RARITIES[species] + (" · Waiting for a bite…" if state in ["casting", "waiting"] else " · Hold / release to cool")
	progress.value = landing
	tension.value = strain
	var danger = strain > 0.82
	tension_text.text = "! LUNGE INCOMING — RELEASE" if warning else ("!! DANGER — RELEASE TO COOL" if danger else "✓ SAFE  ·  LINE TENSION %d%%" % int(strain * 100))
	tension.add_theme_stylebox_override("fill", style(Color("ff8c7d") if danger or warning else GOLD, 8))

func open_modal(title: String, subtitle: String, kind: String) -> void:
	close_modal()
	modal_open = true
	modal_kind = kind
	held = false
	joystick.reset()
	if hub != null: hub.cancel_fishing()
	modal_layer = ColorRect.new()
	modal_layer.color = Color(0.01, 0.07, 0.1, 0.72)
	root.add_child(modal_layer)
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var p = panel()
	modal_layer.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.offset_left = -385
	p.offset_right = 385
	p.offset_top = -286
	p.offset_bottom = 286
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	p.add_child(box)
	var title_row = HBoxContainer.new()
	box.add_child(title_row)
	var l = label(title, 28, MINT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(l)
	title_row.add_child(button("Close  ×", close_modal, Color("d8f3e5")))
	var sub = label(subtitle, 15)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(sub)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	modal_body = VBoxContainer.new()
	modal_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_body.add_theme_constant_override("separation", 12)
	scroll.add_child(modal_body)

func close_modal() -> void:
	if is_instance_valid(modal_layer):
		modal_layer.queue_free()
		modal_layer = null
	modal_open = false
	modal_kind = ""
	touch_action_id = -1
	held = false

func show_collection() -> void:
	var at_station = hub != null and hub.nearest_station == "merge"
	open_modal("The lake collection", "Drag matching fish together, or use a recipe. Keep protects a fish from automatic cutting. Visit MERGE to combine or display.", "collection")
	modal_body.add_child(label("ACTIVE TOTALS  ·  Sales +%d%%   Reel +%d%%   Cutting +%d%%" % [int(round(Economy.bonus("sale") * 100)), int(round(Economy.bonus("control") * 100)), int(round(Economy.bonus("machine") * 100))], 15, MINT))
	modal_body.add_child(label("CARRIED FISH  ·  Drag matching cards to preview a merge", 12, GOLD))
	var cards = HFlowContainer.new()
	cards.add_theme_constant_override("h_separation", 10)
	cards.add_theme_constant_override("v_separation", 10)
	modal_body.add_child(cards)
	for i in Economy.data.raw.size():
		var f: Dictionary = Economy.data.raw[i]
		var card = PanelContainer.new()
		card.set_script(load("res://scripts/fish_card.gd"))
		card.species = int(f.species)
		card.inventory_index = i
		card.custom_minimum_size = Vector2(164, 140)
		card.add_theme_stylebox_override("panel", style(Color("315767"), 14))
		var text = label("%s • %s\n%d coins" % [Economy.SPECIES[int(f.species)], str(int(f.species) + 1) + "★", int(f.value)], 16)
		var contents = VBoxContainer.new()
		card.add_child(contents)
		contents.add_child(text)
		var keep = button("Kept ✓" if f.get("reserved", false) else "Keep", toggle_reservation.bind(i), Color("d7e1ff") if f.get("reserved", false) else Color("c3e7dc"))
		keep.add_theme_font_size_override("font_size", 15)
		contents.add_child(keep)
		if at_station: card.merge_requested.connect(confirm_merge)
		cards.add_child(card)
	if Economy.data.raw.is_empty(): cards.add_child(label("Your basket is empty. Catch a fish first.", 16))
	var colors = [Color("ffce71"), Color("ffae80"), Color("b6ef9e"), Color("a4d9ff")]
	var bonuses = Economy.DISPLAY_BONUSES
	for s in 4:
		var row = HBoxContainer.new()
		modal_body.add_child(row)
		var discovered = bool(Economy.data.discoveries[s])
		var displayed = bool(Economy.data.displayed[s])
		var text = label((Economy.SPECIES[s] if discovered else "???") + "  ·  " + bonuses[s] + ("  ✓ DISPLAYED" if displayed else ""), 17, colors[s])
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		if not displayed:
			var b = button("Display", display_species.bind(s), colors[s])
			b.disabled = not at_station or not has_fish(s)
			row.add_child(b)
		if s < 3:
			var recipe = button("2 %s → %s  ·  Preview merge" % [Economy.SPECIES[s], Economy.SPECIES[s + 1]], confirm_merge.bind(s), Color("d5eceb"))
			recipe.disabled = not at_station or count_fish(s) < 2
			modal_body.add_child(recipe)
	modal_body.add_child(label("Water-filled barrel displays are prototype jar stand-ins.", 12, Color("9dc1c5")))

func count_fish(species: int) -> int:
	var count = 0
	for f in Economy.data.raw:
		if int(f.species) == species: count += 1
	return count

func has_fish(species: int) -> bool:
	return count_fish(species) > 0

func confirm_merge(species: int) -> void:
	if species >= 3 or count_fish(species) < 2: return
	merge_committing = false
	open_modal("A new discovery", "Preview before committing. Two fish are consumed exactly once. Unmatched species never merge.", "confirm")
	modal_body.add_child(label("2 × %s\n↓\n1 × %s • %s  ·  %d coins" % [Economy.SPECIES[species], Economy.SPECIES[species + 1], Economy.RARITIES[species + 1], Economy.VALUES[species + 1]], 28, GOLD))
	modal_body.add_child(label("Available display bonus: " + Economy.DISPLAY_BONUSES[species + 1], 18, MINT))
	var note = label("Discovery stays forever. The result is kept safe from CUT until you uncheck Keep. Display it to activate its bonus.", 16)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_body.add_child(note)
	modal_body.add_child(button("Merge pair", commit_merge.bind(species)))
	modal_body.add_child(button("Keep both fish", show_collection, Color("d5eceb")))

func commit_merge(species: int) -> void:
	if merge_committing: return
	merge_committing = true
	var result = Economy.merge(species)
	if result >= 0:
		close_modal()
		hub.merge_effect(result)
		toast(Economy.SPECIES[result] + " • " + Economy.RARITIES[result] + "! Kept safe for merge or display.")
	else:
		show_collection()

func display_species(species: int) -> void:
	if Economy.display_fish(species):
		close_modal()
		hub.display_effect(species)
		toast(Economy.SPECIES[species] + " displayed • bonus active!")
	else:
		show_collection()

func show_settings() -> void:
	open_modal("Make yourself comfortable", "Casting stops while this menu is open. Your business saves after every transaction.", "settings")
	for item in [["music", "Music volume"], ["sfx", "Sound effects"]]:
		modal_body.add_child(label(item[1], 17))
		var slider = HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.05
		slider.value = Economy.data.settings[item[0]]
		slider.custom_minimum_size.y = 32
		var setting_key: String = item[0]
		slider.value_changed.connect(func(value): Economy.update_setting(setting_key, value))
		modal_body.add_child(slider)
	for item in [["toggle_reel", "Tap to toggle reeling (instead of holding)"], ["assist", "Forgiving fishing assist"], ["reduced_motion", "Reduced motion and flashes"], ["low_quality", "Battery saver • 30 FPS"]]:
		var check = CheckButton.new()
		check.text = item[1]
		check.button_pressed = Economy.data.settings[item[0]]
		check.custom_minimum_size.y = 44
		check.add_theme_font_size_override("font_size", 18)
		var setting_key: String = item[0]
		check.toggled.connect(func(value): Economy.update_setting(setting_key, value); hub.apply_settings())
		modal_body.add_child(check)
	modal_body.add_child(label("HOW TO PLAY\nWASD / arrows or joystick to walk. Space / action to cast & reel.\nRelease to cool the line. Moving away cancels fishing.\nWalk onto CUT → OUT → STOCK → CASH pads.\nStand on an upgrade pad for 1.2 seconds to buy. Step off to cancel.\nWorkers fill crates, never your wallet. No offline earnings.", 15, Color("cce6e5")))

# Native multitouch action: the joystick and reel can use separate fingers.
# Mouse emulation alone only represents one touch and is insufficient here.
func _input(event: InputEvent) -> void:
	if not event is InputEventScreenTouch: return
	if not event.pressed and event.index == touch_action_id:
		touch_action_id = -1
		held = false
		action_button.modulate = Color.WHITE
		action_released.emit()
		get_viewport().set_input_as_handled()
	elif event.pressed and not modal_open and not action_button.disabled and touch_action_id == -1 and action_button.get_global_rect().has_point(event.position):
		touch_action_id = event.index
		held = true
		action_button.modulate = Color(0.8, 0.9, 0.85)
		action_pressed.emit()
		get_viewport().set_input_as_handled()

func toggle_reservation(index: int) -> void:
	if index < 0 or index >= Economy.data.raw.size(): return
	Economy.reserve_fish(index, not Economy.data.raw[index].get("reserved", false))
	show_collection()

func cash_sweep(start: Vector2) -> void:
	var end = coins.get_global_rect().get_center()
	for i in (3 if Economy.data.settings.reduced_motion else 8):
		var coin = label("●", 29, GOLD)
		root.add_child(coin)
		var origin = start + Vector2(randf_range(-20, 20), randf_range(-10, 10))
		coin.position = origin
		var tween = create_tween()
		tween.tween_interval(i * 0.04)
		tween.tween_method(func(t: float): coin.position = origin.lerp(end, t) + Vector2(0, -sin(t * PI) * 35), 0.0, 1.0, 0.6)
		tween.tween_callback(coin.queue_free)
