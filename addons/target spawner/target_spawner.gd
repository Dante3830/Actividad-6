@tool
extends EditorPlugin

var spawn_button
const SPAWN_BUTTON = preload("res://addons/target spawner/target_spawner_button.tscn")

func _enter_tree() -> void:
	spawn_button = SPAWN_BUTTON.instantiate()
	
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UR, spawn_button)

func _exit_tree() -> void:
	remove_control_from_docks(spawn_button)
	spawn_button.queue_free()
