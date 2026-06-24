@tool
extends VBoxContainer

@export var target_scene : PackedScene

func _on_spawn_button_pressed() -> void:
	var selection = EditorInterface.get_selection()
	
	for node in selection.get_selected_nodes():
		if node is Area2D:
			var spawned_child = %AddonResourcePicker.edited_resource.instantiate()
			node.add_child(spawned_child)
			spawned_child.owner = get_tree().edited_scene_root
