extends PanelContainer
signal merge_requested(species: int)
var species = 0
var inventory_index = 0

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview = Label.new()
	preview.text = "Merge " + Economy.SPECIES[species]
	preview.add_theme_font_size_override("font_size", 20)
	set_drag_preview(preview)
	return {"species": species, "index": inventory_index}

func _can_drop_data(_at_position: Vector2, drag: Variant) -> bool:
	return drag is Dictionary and drag.get("species") == species and drag.get("index") != inventory_index and Economy.RECIPES.has(species)

func _drop_data(_at_position: Vector2, _drag: Variant) -> void:
	merge_requested.emit(species)
