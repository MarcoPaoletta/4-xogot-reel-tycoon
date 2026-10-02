extends Node
func _ready():
	Economy.saving_enabled=false
	Economy.save_path="user://reel_v7_validation.json"
	Economy.data=Economy.fresh_data()
	get_tree().call_deferred("change_scene_to_file","res://scenes/main.tscn")
