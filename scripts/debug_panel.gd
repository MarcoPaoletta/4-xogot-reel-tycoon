extends Control
## Development-only tooling. Changes go through Economy and intentionally persist.
var hud: CanvasLayer
var status_time: float = 0.0
@onready var status: Label = $Panel/Status
@onready var feedback: Label = $Panel/Feedback

func _ready() -> void:
	$Panel/Close.pressed.connect(func(): hud.close_modal())
	for button in $Panel.get_children():
		if button is Button and button.has_meta("debug_action"):
			button.pressed.connect(func(): execute(String(button.get_meta("debug_action"))))
	$Panel/PauseBusiness.toggled.connect(func(value):
		if hud != null: hud.hub.debug_pause_business = value)

func _process(delta: float) -> void:
	if not visible or hud == null: return
	status_time += delta
	if status_time < 0.2: return
	status_time = 0
	status.text = "%d FPS · %d coins · cash %d · fish %d/%d · packages %d/%d\nQueue %d · output %d · stock %d · worker %d · camera %s" % [Engine.get_frames_per_second(), Economy.data.coins, Economy.data.cash, Economy.data.raw.size(), Economy.capacity(), Economy.data.goods.size(), Economy.goods_capacity(), Economy.data.queue.size(), Economy.data.output.size(), Economy.data.stock.size(), Economy.data.worker_crate.size(), hud.hub.camera_mode]

func execute(command: String) -> void:
	if not OS.is_debug_build() or hud == null: return
	if command.begins_with("teleport_"):
		var id = command.trim_prefix("teleport_")
		var pad: Dictionary = hud.hub.world.pads[id]
		hud.hub.player.global_position = pad.node.global_position + Vector3(0, 0.05, 0)
		hud.hub.player.velocity = Vector3.ZERO
		hud.joystick.reset()
		hud.hub.find_station()
		feedback.text = "Moved to " + id.to_upper()
		return
	feedback.text = "Applied · " + command if Economy.debug_action(command) else "No change · capacity / unlock limit"
