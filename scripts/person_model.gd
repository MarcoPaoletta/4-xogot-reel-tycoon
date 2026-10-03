@tool
extends Node3D
## Authored scenes place this node where a character goes. It adds the itHappy model when
## it exists locally, otherwise the CC0 fallback, so the scenes never depend on private files.
const PEOPLE_LIB = preload("res://scripts/people.gd")
@export var character: String = "Pescador"

func _ready() -> void:
	var instance = PEOPLE_LIB.instantiate(character)
	if instance != null: add_child(instance)
